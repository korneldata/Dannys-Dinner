
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


select * from members
select * from menu
select * from sales

--1.What is the total amount each customer spent at the restaurant?

select 
customer_id,
sum(price) as total_spending
from sales s
inner join menu m
on s.product_id = m.product_id
group by customer_id

--2. How many days has each customer visited the restaurant?

select 
customer_id,
count (distinct order_date) as days_visited
from sales
group by customer_id

--3.What was the first item from the menu purchased by each customer?

select 
customer_id,
FIRST_VALUE(product_id) over (
partition by customer_id 
order by order_date) as first_dish
from sales


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1
s.product_id,
product_name,
count(s.product_id) as dish_orders
--rank() over (order by count(s.product_id) desc) as dishes_ranking
from sales s
inner join menu m
on m.product_id = s.product_id
group by s.product_id, product_name
order by dish_orders desc


--5. Which item was the most popular for each customer?

select 
customer_id,
product_id,
count(product_id) as dishes_count,
rank() over (partition by customer_id order by count(product_id) desc) as dish_rank
from sales
group by customer_id, product_id
order by customer_id



--6. Which item was purchased first by the customer after they became a member?

select 
s.customer_id,
product_id,
order_date,
FIRST_VALUE(product_id) over 
(partition by s.customer_id
order by order_date
range between unbounded preceding and unbounded following) as after_membership
from sales s
inner join members m
on s.customer_id = m.customer_id
where order_date > join_date
order by order_date  

--7. Which item was purchased just before the customer became a member?

select 
s.customer_id,
s.product_id,
order_date,
LAST_VALUE(product_id) over 
(partition by s.customer_id 
order by order_date
range between unbounded preceding and unbounded following) as before_membership
from sales s
inner join members m
on s.customer_id = m.customer_id
where order_date < join_date
order by order_date  

--8. What is the total items and amount spent for each member before they became a member?

select 
m.customer_id,
count(s.product_id) as ordered_items,
sum(price) as items_spending
from sales s
inner join members m
on s.customer_id = m.customer_id
inner join menu
on menu.product_id = s.product_id 
where order_date < join_date
group by m.customer_id


--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- -how many points would each customer have?


with points as
(
select 
product_id,
case product_id
	when 1 then price * 20
	else price * 10
end as points
from menu
)
select 
customer_id,
sum(points) as points_sum
from points p
inner join sales s
on p.product_id = s.product_id
group by customer_id


--10. In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with January_points as
(
select 
members.customer_id,
case
	when menu.product_id = 1 OR order_date <= DATEADD(day, 7, join_date) then price * 20
	else price * 10
end as points
from menu
inner join sales
on menu.product_id = sales.product_id
inner join members
on members.customer_id = sales.customer_id  
where order_date >= join_date and order_date < '2021-02-01'
)
select 
customer_id,
sum(points) as jan_points
from January_points
group by customer_id

--11. Recreate the following table output using the available data:
--	customer_id	order_date	product_name	price	member

select 
sales.customer_id,
order_date,
product_name,
price,
case
	when order_date >= join_date then 'Y'
	else 'N'
end as member
into ##join_table
from sales
inner join menu
on sales.product_id = menu.product_id
left join members
on members.customer_id = sales.customer_id 

select * from ##join_table

