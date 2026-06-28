USE coffeeshop_db;

-- =========================================================
-- ADVANCED SQL ASSIGNMENT
-- Subqueries, CTEs, Window Functions, Views
-- =========================================================
-- Notes:
-- - Unless a question says otherwise, use orders with status = 'paid'.
-- - Write ONE query per prompt.
-- - Keep results readable (use clear aliases, ORDER BY where it helps).

-- =========================================================
-- Q1) Correlated subquery: Above-average order totals (PAID only)
-- =========================================================
-- For each PAID order, compute order_total (= SUM(quantity * products.price)).
select o.order_id, sum(OI.quantity * p.price) as order_total from Order_items as OI
join products as p on p.product_id = OI.product_id
join orders as o on o.order_id = OI.order_id
where status in (select status from products as p where status ='paid')
group by order_id;

-- Return: order_id, customer_name, store_name, order_datetime, order_total.
select o.order_id, c.first_name, c.last_name, s.name as store_name, o.order_datetime, sum(OI.quantity * p.price) as order_total 
from Order_items as OI
join products as p on p.product_id = OI.product_id
join orders as o on o.order_id = OI.order_id
join customers as c on c.customer_id = o.customer_id
join stores as s on s.store_id = o.store_id
where status in (select status from products as p where status ='paid')
group by order_id; 
-- Filter to orders where order_total is greater than the average PAID order_total

select o.order_id, c.first_name, c.last_name, s.name as store_name, o.order_datetime, sum(OI.quantity * p.price) as order_total 
from Order_items as OI
join products as p on p.product_id = OI.product_id
join orders as o on o.order_id = OI.order_id
join customers as c on c.customer_id = o.customer_id
join stores as s on s.store_id = o.store_id
where status in (select status from products as p where status ='paid')
group by order_id 
having sum(OI.quantity * p.price) > (select avg(avg_paid_order_total.order_total) from (select o.order_id, sum(OI.quantity * p.price) as order_total 
from Order_items as OI
join products as p on p.product_id = OI.product_id
join orders as o on o.order_id = OI.order_id
join customers as c on c.customer_id = o.customer_id
join stores as s on s.store_id = o.store_id
where status in (select status from products as p where status ='paid')
group by order_id) as avg_paid_order_total);
 
-- for THAT SAME store (correlated subquery).
-- Sort by store_name, then order_total DESC.
select o.order_id, c.first_name, c.last_name, s.name as store_name, o.order_datetime, sum(OI.quantity * p.price) as order_total 
from Order_items as OI
join products as p on p.product_id = OI.product_id
join orders as o on o.order_id = OI.order_id
join customers as c on c.customer_id = o.customer_id
join stores as s on s.store_id = o.store_id
where status in (select status from products as p where status ='paid')
group by order_id
having sum(OI.quantity * p.price) > (select avg(avg_paid_order_total.order_total) from (select o.order_id, sum(OI.quantity * p.price) as order_total 
from Order_items as OI
join products as p on p.product_id = OI.product_id
join orders as o on o.order_id = OI.order_id
join customers as c on c.customer_id = o.customer_id
join stores as s on s.store_id = o.store_id
where status in (select status from products as p where status ='paid')
group by order_id) as avg_paid_order_total)
order by store_name, order_total desc;


-- =========================================================
-- Q2) CTE: Daily revenue and 3-day rolling average (PAID only)
-- =========================================================
-- Using a CTE, compute daily revenue per store:
--   revenue_day = SUM(quantity * products.price) grouped by store_id and DATE(order_datetime).

With
daily_revenue as 
(select o.order_id, date(o.order_datetime), sum(OI.quantity * p.price) as revenue_day, s.store_id from order_items as OI
join products as p on p.product_id = OI.product_id
join orders as o on o.order_id = OI.order_id
join stores as s on s.store_id = o.store_id
where o.status = 'paid'
group by o.order_id, date(o.order_datetime))
Select * from daily_revenue;

-- Then, for each store and date, return:
--   store_name, order_date, revenue_day,

With
daily_revenue as (
select date(o.order_datetime) as order_date, sum(OI.quantity * p.price) as revenue_day, s.name as store_name from order_items as OI
join products as p on p.product_id = OI.product_id
join orders as o on o.order_id = OI.order_id
join stores as s on s.store_id = o.store_id
where o.status = 'paid'
group by o.order_id, date(o.order_datetime))
Select * from daily_revenue;


--   rolling_3day_avg = average of revenue_day over the current day and the prior 2 days.
-- Use a window function for the rolling average.
-- Sort by store_name, order_date.
with 
daily_revenue as (
select date(o.order_datetime) as order_date, sum(OI.quantity * p.price) as revenue_day, s.name as store_name from order_items as OI
join products as p on p.product_id = OI.product_id
join orders as o on o.order_id = OI.order_id
join stores as s on s.store_id = o.store_id
where o.status = 'paid'
group by o.order_id, date(o.order_datetime))


select store_name, order_date, revenue_day, avg(revenue_day) over (partition by store_name order by order_date rows between 2 preceding and current row) as rolling_3day_avg
from daily_revenue order by store_name, order_date;



-- =========================================================
-- Q3) Window function: Rank customers by lifetime spend (PAID only)
-- =========================================================
-- Compute each customer's total spend across ALL stores (PAID only).
-- Return: customer_id, customer_name, total_spend,
--         spend_rank (DENSE_RANK by total_spend DESC).
select o.customer_id, c.first_name, c.last_name, s.store_id, sum(OI.quantity * p.price) as total_spend,
dense_rank () over (order by sum(OI.quantity * p.price) desc)
as spend_rank from orders as o
join stores as s on s.store_id = o.store_id
join order_items as OI on OI.order_id = o.order_id
join products as p on p.product_id = OI.product_id
join customers as c on o.customer_id = c.customer_id
where status = 'paid'
group by o.customer_id, c.first_name, c.last_name, s.store_id;



-- Also include percent_of_total = customer's total_spend / total spend of all customers.
-- Sort by total_spend DESC.


-- =========================================================
-- Q4) CTE + window: Top product per store by revenue (PAID only)
-- =========================================================
-- For each store, find the top-selling product by REVENUE (not units).
-- Revenue per product per store = SUM(quantity * products.price).
-- Return: store_name, product_name, category_name, product_revenue.
select s.store_id, s.name as store_name, 
p.name as product_name, 
c.name as category_name,
sum(oi.quantity * p.price) as product_revenue
from orders as o
join stores as s on s.store_id = o.store_id
join order_items as oi on oi.order_id = o.order_id
join products as p on p.product_id = oi.product_id
join categories as c on c.category_id = p.category_id
where o.status = 'paid'
group by s.store_id, p.name, c.name, s.name;

 
-- Use a CTE to compute product_revenue, then a window function (ROW_NUMBER)
-- partitioned by store to select the top 1.
-- Sort by store_name.
With 
revenue as (select s.store_id, s.name as store_name, 
p.name as product_name, 
c.name as category_name,
sum(oi.quantity * p.price) as product_revenue
from orders as o
join stores as s on s.store_id = o.store_id
join order_items as oi on oi.order_id = o.order_id
join products as p on p.product_id = oi.product_id
join categories as c on c.category_id = p.category_id
where o.status = 'paid'
group by s.store_id, p.name, c.name, s.name)

select store_name, product_name, category_name, product_revenue
from ( select *,
ROW_NUMBER() over (partition by store_id
order by product_revenue desc) as by_store
From revenue)
as ranked where by_store = 1
order by store_name;
-- =========================================================
-- Q5) Subquery: Customers who have ordered from ALL stores (PAID only)
-- =========================================================
-- Return customers who have at least one PAID order in every store in the stores table.
-- Return: customer_id, customer_name.
-- Hint: Compare count(distinct store_id) per customer to (select count(*) from stores).
select c.customer_id,
concat(c.first_name, ' ', c.last_name) as customer_name
from customers as c
join orders as o on c.customer_id = o.customer_id
join stores as s on s.store_id = o.store_id
where o.status = 'paid'
group by c.customer_id, customer_name
having count(distinct o.store_id) = (select 
count(*) from stores);
-- =========================================================
-- Q6) Window function: Time between orders per customer (PAID only)
-- =========================================================
-- For each customer, list their PAID orders in chronological order and compute:
--   prev_order_datetime (LAG),
--   minutes_since_prev (difference in minutes between current and previous order).
-- Return: customer_name, order_id, order_datetime, prev_order_datetime, minutes_since_prev.
-- Only show rows where prev_order_datetime is NOT NULL.
-- Sort by customer_name, order_datetime.


-- =========================================================
-- Q7) View: Create a reusable order line view for PAID orders
-- =========================================================
-- Create a view named v_paid_order_lines that returns one row per PAID order item:
--   order_id, order_datetime, store_id, store_name,
--   customer_id, customer_name,
--   product_id, product_name, category_name,
--   quantity, unit_price (= products.price),
--   line_total (= quantity * products.price)
create view paid_orders as
Select
o.order_id, o.order_datetime, 
s.store_id, s.name as store_name,
c.customer_id, concat(c.first_name, ' ', c.last_name) as customer_name,
p.product_id, p.name as product_name, p.price as unit_price,
ct.name as category_name,
oi.quantity,
(oi.quantity * p.price) as line_total
from orders as o
join stores as s on s.store_id = o.store_id
join customers as c on c.customer_id = o.customer_id
join order_items as oi on oi.order_id = o.order_id
join products as p on p.product_id = oi.product_id
join categories as ct on ct.category_id = p.category_id
where o.status = 'paid';



-- After creating the view, write a SELECT that uses the view to return:
--   store_name, category_name, revenue
-- where revenue is SUM(line_total),
-- sorted by revenue DESC.
Select store_name,
category_name,
sum(line_total) as revenue
from paid_orders 
group by store_name, category_name
order by revenue desc;

-- =========================================================
-- Q8) View + window: Store revenue share by payment method (PAID only)
-- =========================================================
-- Create a view named v_paid_store_payments with:
--   store_id, store_name, payment_method, revenue
-- where revenue is total PAID revenue for that store/payment_method.
create view v_paid_store_payments as
Select
s.store_id, s.name as store_name,
o.payment_method, 
sum(oi.quantity * p.price) as revenue
from orders as o
join stores as s on s.store_id = o.store_id
join order_items as oi on oi.order_id = o.order_id
join products as p on p.product_id = oi.product_id
where o.status = 'paid'
group by s.store_id, s.name, o.payment_method;

-- Then query the view to return:
--   store_name, payment_method, revenue,
--   store_total_revenue (window SUM over store),
--   pct_of_store_revenue (= revenue / store_total_revenue)
-- Sort by store_name, revenue DESC.
select store_name, payment_method, revenue,
sum(revenue) over (partition by store_id) as store_revenue 
from v_paid_store_payments
order by store_name, revenue;
-- =========================================================
-- Q9) CTE: Inventory risk report (low stock relative to sales)
-- =========================================================
-- Identify items where on_hand is low compared to recent demand:
-- Using a CTE, compute total_units_sold per store/product for PAID orders.
-- Then join inventory to that result and return rows where:
--   on_hand < total_units_sold
-- Return: store_name, product_name, on_hand, total_units_sold, units_gap (= total_units_sold - on_hand)
-- Sort by units_gap DESC.
