

CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales (customer_id, order_date, product_id) VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu (product_id, product_name, price) VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members (customer_id, join_date) VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  --  ---------------------------------------------Case Study Questions -----------------------------------------------------------------------
# Each of the following case study questions can be answered using a single SQL statement:

-- Q1. What is the total amount each customer spent at the restaurant?
SELECT 
    m.customer_id, SUM(me.price) AS amt_spent
FROM
    members m
        JOIN
    sales s ON m.customer_id = s.customer_id
        JOIN
    menu me ON me.product_id = s.product_id
GROUP BY m.customer_id;


-- Q2. How many days has each customer visited the restaurant?
SELECT 
    customer_id, COUNT(DISTINCT order_date) AS Days
FROM
    sales
GROUP BY customer_id;

-- Q3. What was the first item from the menu purchased by each customer?
SELECT 
    s.customer_id, m.product_name, s.order_date
FROM
    sales s
        JOIN
    menu m ON m.product_id = s.product_id
WHERE
    s.order_date = (SELECT 
            MIN(order_date)
        FROM
            sales s1
        WHERE
            s.customer_id = s1.customer_id);
            
        

-- Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?

 SELECT 
    m.product_name, COUNT(*) AS Purchase_Count
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY m.product_name;


-- Q6. Which item was the most popular for each customer?
With max_purchased_product as 
(
Select s.customer_id,m.product_name,count(m.product_name) as Prod_count from sales s join menu m on s.product_id =m.product_id
Group BY s.customer_id,m.product_name 
)  
Select customer_id, product_name, Prod_count
from max_purchased_product mp 
where Prod_count IN (Select max(Prod_count) from max_purchased_product mp1 where mp.customer_id = mp1.customer_id);


-- Q7. Which item was purchased first by the customer after they became a member?
with min_order_date as 
(Select s.customer_id,min(s.order_date) as order_date from sales s join members m on s.customer_id=m.customer_id 
Where s.order_date > m.join_date
Group By s.customer_id)

SELECT 
    s.customer_id, m.product_name, md.order_date
FROM
    min_order_date md
        JOIN
    sales s ON s.customer_id = md.customer_id AND md.order_date = s.order_date
        JOIN
    menu m ON m.product_id = s.product_id;
    
    


-- Q8. Which item was purchased just before the customer became a member?
With cust_pur_before_join as 
(Select m.customer_id,max(s.order_date) as date_before_joining  
from sales s join members m on s.customer_id=m.customer_id where m.join_date > s.order_date
Group By m.customer_id)

Select c.customer_id,date_before_joining,me.product_name
from cust_pur_before_join c 
join sales s on s.customer_id=c.customer_id And s.order_date=c.date_before_joining 
join menu me on me.product_id =s.product_id;


-- Q9. What is the total items and amount spent for each member before they became a member?
 Select s.customer_id,count(me.product_id) as tot_products,Sum(me.price) as total_amt 
 from Sales s join menu me on s.product_id=me.product_id join members m on m.customer_id=s.customer_id
 Where s.order_date > m.join_date
 group by  s.customer_id
 order by total_amt desc;
 
 



-- Q10. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with 
amt_spent_per_product as 
(Select me.product_name,s.customer_id, sum(me.price) as amt_spent from sales s join menu me on s.product_id=me.product_id 
group by me.product_name,s.customer_id),
Cust_points as
(Select *, Case when product_name = 'sushi' then  amt_spent*20 Else amt_spent *10 End  as Points
from amt_spent_per_product order by product_name desc)
Select customer_id,Sum(Points) as tot_points from Cust_points group by customer_id;


-- Q11. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- - how many points do customer A and B have at the end of January?
With customers_points as 
(SELECT
        s.customer_id,
        me.product_name,
        me.price,
        S.order_date,
        m.join_date,
        Case When s.order_date between m.join_date and date_add(m.join_date, INTERVAL 6 Day)  then me.price*2*10
             When me.product_name = 'sushi' then me.price*2*10 ELse me.price * 10
             End as points
    FROM
        sales s
        JOIN menu me ON s.product_id = me.product_id
        Left Join members m on s.customer_id=m.customer_id)
        
SELECT 
    customer_id, COUNT(points) AS Total_Points
FROM
    customers_points
WHERE
    order_date < '2021-02-01'
GROUP BY customer_id;





-- ------------------------------------------------------------------- Bonus Questions --------------------------------------------------------------------------------------
-- Q12. Determine the name and price of product order by each customer on all orders dates and 
-- find out wether the customer wass a member on order date or not

  Select s.customer_id,s.order_date ,me.product_name,me.price,
  Case When s.order_date >=  m.join_date then 'Yes' else 'No' End as Members
  from  menu me join sales s on me.product_id=s.product_id 
  Left Join members m on m.customer_id = s.customer_id;                                                                                                                                                                                                       
  
  
-- Q13. Rank the previous output from Q11 based on the order date for each customer, display null if customer was not member when dish ordered
  
With 
cust_membership_status as 
(Select s.customer_id,s.order_date ,me.product_name,me.price,
Case When s.order_date >=  m.join_date then 'Yes' else 'No' End as Members
from  menu me join sales s on me.product_id=s.product_id 
Left Join members m on m.customer_id = s.customer_id)
  
Select *, 
      Case When Members = 'Yes' then rank() Over (partition by customer_id,Members order By order_date) ELSE Null End as Ranking
 from cust_membership_status;

  
  
  
  
  
  
  
