USE coffeeshop_db;

-- =========================================================
-- SUBQUERIES & NESTED LOGIC PRACTICE
-- =========================================================

-- Q1) Scalar subquery (AVG benchmark):
--     List products priced above the overall average product price.
--     Return product_id, name, price.
select product_id, 
name, 
price 
from products 
where price > (select avg(price) from products);


-- Q2) Scalar subquery (MAX within category):
--     Find the most expensive product(s) in the 'Beans' category.
--     (Return all ties if more than one product shares the max price.)
--     Return product_id, name, price.
select product_id, 
name, 
price 
from products 
where price = (select max(price) from products);

-- Q3) List subquery (IN with nested lookup):
--     List customers who have purchased at least one product in the 'Merch' category.
--     Return customer_id, first_name, last_name.
--     Hint: Use a subquery to find the category_id for 'Merch', then a subquery to find product_ids.
select category_id from categories;
select category_id, name from categories where name =  'merch'; 
select product_id from products where category_id = '5';

select c.customer_id, c.first_name, c.last_name, OI.product_id 
from customers as c 
join orders as o on o.customer_id = c.customer_id
join order_items as OI on o.order_id = OI.order_id
where OI.product_id 
in (select product_id from products 
where category_id = (select category_id from categories where name = 'merch'));

-- Q4) List subquery (NOT IN / anti-join logic):
--     List products that have never been ordered (their product_id never appears in order_items).
--     Return product_id, name, price.
select product_id from products where product_id not in (select product_id from order_items);

select p.product_id, p.name, p.price 
from products as p 
where product_id 
not in (select product_id from order_items);


-- Q5) Table subquery (derived table + compare to overall average):
--     Build a derived table that computes total_units_sold per product
--     (SUM(order_items.quantity) grouped by product_id).
--     Then return only products whose total_units_sold is greater than the
--     average total_units_sold across all products.
--     Return product_id, product_name, total_units_sold.


select product_id, sum(quantity) as total_units_sold from order_items group by product_id;

Select avg(total_units_sold) from (select product_id, sum(quantity) as total_units_sold from order_items group by product_id) as product_sales
join products as p on p.product_id = product_sales.product_id;

select product_id, sum(quantity) as total_units_sold 
from (
