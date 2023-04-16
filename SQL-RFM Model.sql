
--Inspecting data 
select * from tableRetail;


--Checking data values.
select distinct country  from tableRetail; --only United Kingdom
select count (distinct invoice)  from tableRetail; --717 invoices
select count (distinct customer_id)  from tableRetail; --110 customer
select distinct price from tableRetail; --128 prices
select count (distinct stockcode)  from tableRetail; --2335
select count (distinct INVOICEDATE)from tableRetail; --714 date
select avg(QUANTITY) from tableRetail; --13.73


 --- Find out the highest Price per StockCode for each customer 
 Select X.StockCode  ,X.Price
 from (
 select   StockCode,  Price,
 rank ( ) over ( PARTITION by StockCode order by Price desc)  RNK
 from  tableRetail 
 )   X  
  
 where x.rnk =1;
 
 --- Find out the Rank of StockCode per no. of purchase 
 
 SELECT stockcode, COUNT(*) AS "no. of purchase ",
       DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS "Rank"
FROM tableretail 
GROUP BY stockcode
ORDER BY "no. of purchase " DESC;
 
 -- Ranking Customer according to their Total number of Trades

 select customer_id,count(*) as " Total number of Trades ",
dense_rank() over ( order by count(invoice) desc ) as "Rank"
from tableretail
group by customer_id;
  --  Top 3 customers paid for the orders 
  

with Top_3 as
 ( 
  SELECT customer_id,
               sum(price) AS "Total Trades",
    DENSE_RANK() OVER (ORDER BY sum(price) DESC) AS "Rank"
  FROM tableretail
  GROUP BY customer_id
)
SELECT * FROM Top_3
WHERE "Rank" <= 3;
--querey last purchasing and first purchasing for each customer 
select distinct customer_id,
first_value(invoicedate) over( partition by customer_id 
						order by invoicedate rows between unbounded preceding and unbounded following) first_purchase ,
last_value(invoicedate) over( partition by customer_id 
						order by invoicedate  rows between unbounded preceding and unbounded following) last_purchase from  tableRetail;
----------------------------------------------------------------------------------------------------------------------------------------




with RFM   as (
 SELECT  Customer_ID,Frequency ,Monetary, recency
,ntile(5) over (order by recency)  r_score
,ntile(5) over ( order by avg(Frequency+ Monetary) ) fm_score
FROM
 (
select distinct  Customer_ID,
count (*) over ( partition by Customer_ID 
                       order by InvoiceDate 
                       range  between unbounded preceding and unbounded following )   Frequency,
ROUND (AVG(Price*Quantity)over ( partition by Customer_ID
                        order by InvoiceDate 
                        range  between unbounded preceding and unbounded following ),2) Monetary
-- their is more than one solution here  the following comment is one of them 
-- max (InvoiceDate) over ( partition by Customer_ID order by InvoiceDate  range  between unbounded preceding and unbounded following )   Max_order_date
, ROUND(
                last_value (TO_DATE(invoicedate,'MM/DD/YYYY HH24:MI')) over (order by InvoiceDate
                                     range  between unbounded preceding and unbounded following   )  -- Over all most recent order as a refernce
                - last_value (TO_DATE(invoicedate,'MM/DD/YYYY HH24:MI')) over ( partition by Customer_ID
                                    order by InvoiceDate 
                                    range  between unbounded preceding and unbounded following ) --Customer_Max_order_date
,2) as recency 

FROM tableRetail
 )
GROUP BY Customer_ID, Frequency ,Monetary, recency )

select Customer_ID,Frequency ,Monetary, recency, r_score ,fm_score ,
    case 
                when    recency = 5 and fm_score =5 then 'champions'  
                when    recency = 5 and fm_score =4 then 'champions'   
                when    recency = 4 and fm_score =5 then 'champions'   
                when    recency = 5 and fm_score =2 then 'potential loyalists'  
                when    recency = 4 and fm_score =2 then 'potential loyalists'   
                when    recency = 3 and fm_score =3 then 'potential loyalists'   
                when    recency = 4 and fm_score =3 then 'potential loyalists'   
                when    recency = 5 and fm_score =5 then 'potential loyalists' 
                when    recency = 5 and fm_score =3 then 'loyal customers'   
                when    recency = 4 and fm_score =4 then 'loyal customers' 
                when    recency = 3 and fm_score =5 then 'loyal customers' 
                when    recency = 3 and fm_score =4 then 'loyal customers'  
                when    recency = 5 and fm_score =1 then 'recent customers'   
                when    recency = 4 and fm_score =1 then 'promising'
                when    recency = 3 and fm_score =1 then 'promising'
                when    recency = 3 and fm_score =2 then 'Customers Needing Attention' 
                when    recency = 2 and fm_score =3 then 'Customers Needing Attention' 
                when    recency = 2 and fm_score =2 then 'Customers Needing Attention' 
                when    recency = 2 and fm_score =5 then 'at risk' 
                when    recency = 2 and fm_score =4 then 'at risk' 
                when    recency = 1 and fm_score =3 then 'at risk' 
                when    recency = 1 and fm_score =5 then 'cant lose them' 
                when    recency = 1 and fm_score =4 then 'cant lose them' 
                when    recency = 1 and fm_score =2 then 'hibernating' 
                when    recency = 1 and fm_score =1 then 'lost' 
    end AS cust_segment
      from RFM ;
