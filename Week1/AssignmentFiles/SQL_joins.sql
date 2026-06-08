USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
select p.name as product_name,
p.category_id as category_name,
price
from products as p
join categories as c on p.category_id = c.category_id;


-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.
select * from order_items;
select * from products;
select * from orders;
select * from stores;

select o.order_id,
o.order_datetime,
OI.quantity,
p.name as product_name,
s.name as store_name,
(OI.quantity * p.price) as line_total
from orders as o
join stores as s on o.store_id = s.store_id
join order_items as OI on o.order_id = OI.order_id
join products as p on OI.product_id = p.product_id
order by o.order_datetime, o.order_id;




-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).

select * from customers; -- first_name, last_name, city, customer_id
select * from stores; -- name, city, store_id
select * from orders; -- order_datetime, customer_id, store_id, order_id
select * from order_items; -- quantity, order_id, product_id
select * from products; -- price, product_id, category_id

select concat(c.first_name, ' ', c.last_name) as customer_name,
s.name as store_name,
o.order_datetime,
sum(OI.quantity * p.price) as order_total
from orders as o
join customers as c on o.customer_id = c.customer_id
join stores as s on o.store_id = s.store_id
join order_items as OI on o.order_id = OI.order_id
join products as p on p.product_id = OI.product_id
group by 
o.order_datetime,
s.name,
c.first_name, c.last_name,
o.order_datetime
;


-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
select * from orders;
select c.first_name, c.last_name, 
c.city, c.state from customers as c
left join orders as o on c.customer_id = o.customer_id
where o.order_id is null;





-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
select s.name as store_name, 
p.name as product_name, 
-- sum(OI.quantity) as total_units,
row_number() over (partition by s.name order by max(OI.quantity)) as total_units
from stores as s
join orders as o on o.store_id = s.store_id
join order_items as OI on OI.order_id = o.order_id
join products as p on p.product_id = OI.product_id
where status = 'paid'
group by OI.order_item_id;


-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
select s.name as store_name, p.name as product_name, on_hand from inventory as i
join stores as s on i.store_id = s.store_id
join products as p on i.product_id = p.product_id
where on_hand < 12;



-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').

select concat(first_name,' ', last_name) as manager_name, hire_date from employees
where title = 'Manager';

-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.
select avg(OI.quantity * p.price) as revenue from order_items as OI
join products as p on OI.product_id = p.product_id
group by order_id;

-- CTE
With 
total_paid_revenue as (select sum(OI.quantity * p.price) as total_revenue, p.name as product_name from order_items as OI
join products as p on OI.product_id = p.product_id
join orders as o on o.order_id = OI.order_id
where o.status = 'paid'
group by p.name),

average_revenue as (select avg(total_revenue) as average_revenue from total_paid_revenue)

Select TPR.product_name, TPR.total_revenue
from total_paid_revenue as TPR
cross join average_revenue as AR 
where TPR.total_revenue > AR.average_revenue;


-- Subquery
select product_name, total_revenue
from (select sum(OI.quantity * p.price) as total_revenue, p.name as product_name from order_items as OI
join products as p on OI.product_id = p.product_id
join orders as o on o.order_id = OI.order_id
where o.status = 'paid'
group by p.name) as total_paid_revenue where total_revenue > (select avg (total_revenue) from (select sum(OI.quantity * p.price) as total_revenue, p.name as product_name from order_items as OI
join products as p on OI.product_id = p.product_id
join orders as o on o.order_id = OI.order_id
where o.status = 'paid'
group by p.name) as average_paid_revenue);


-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
select concat(c.first_name, ' ', c.last_name) as customer_name,
max(date(o.order_datetime)) as last_paid_order_date from orders as o
left join customers as c on o.customer_id = c.customer_id
and status = 'paid'
group by c.first_name, c.last_name;



-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).

select s.name as store, 
c.name as category, 
sum(OI.quantity) as total_units, 
sum(OI.quantity * p.price) as total_revenue 
from order_items as OI
join products as p on p.product_id = OI.product_id
join orders as o on o.order_id = OI.order_id
join stores as s on o.store_id = s.store_id
join categories as c on p.category_id = c.category_id
where status = 'paid'
group by s.name, c.name; 


