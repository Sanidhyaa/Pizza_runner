---How many pizzas were ordered?

select count(order_id) from customer_orders

---How many unique customer orders were made?

select count(distinct order_id) from co

---How many successful orders were delivered by each runner?

select runner_id,count(*) from runner_orders where distance is not null group by 1 order by 1

---How many of each type of pizza was delivered?

---How many Vegetarian and Meatlovers were ordered by each customer?

with cte as
(select t1.customer_id,t2.pizza_name from co as t1 
 join pizza_names as t2 on t1.pizza_id=t2.pizza_id)
select customer_id,
sum(case when pizza_name='Meatlovers' then 1 else 0 end) as Meatlovers,
sum(case when pizza_name='Vegetarian' then 1 else 0 end) as Vegetarian 
from cte
group by 1 
order by 1

select * from co


---What was the maximum number of pizzas delivered in a single order?

select t1.order_id,count(*) from co as t1 join runner_orders as t2 on t1.order_id=t2.order_id where distance is not null group by 1 order by 2 desc

---For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

with cte as(select t1.order_id,t1.customer_id,t1.exclusions,t1.extras from co as t1 join runner_orders as t2 on t1.order_id=t2.order_id
where distance is not null)
select customer_id,sum(case when exclusions is null and extras is null then 1 else 0 end),sum(case when exclusions is not null or extras is not null then 1 else 0 end)  from cte group by 1

---How many pizzas were delivered that had both exclusions and extras?

with cte as(select t1.order_id,t1.customer_id,t1.exclusions,t1.extras from co as t1 join runner_orders as t2 on t1.order_id=t2.order_id
where distance is not null)
select count(*) from cte where exclusions is not null and extras is not null

---What was the total volume of pizzas ordered for each hour of the day?

select count(*),extract(hour from order_time) from co group by 2

---What was the volume of orders for each day of the week?

select count(*),to_char(order_time,'day') from co group by 2

---How many runners signed up for each 1 week period?

select count(*),extract(week from registration_date+3) from runners group by 2

---What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick u

with cte as(select runner_id,order_id,pickup_time as p1,extract(min from pickup_time) as m1 from ro),
cte2 as(select order_id,order_time as o1,extract(min from order_time) as m2 from co),
cte3 as(select runner_id,p1-o1 as diff from cte join cte2 on cte.order_id=cte2.order_id),
cte4 as(select runner_id,extract(min from diff) as min_diff from cte3)
select runner_id,round(avg(min_diff),4) from cte4 group by 1

---Is there any relationship between the number of pizzas and how long the order takes to prepare?

with cte as(select order_id,count(order_id) as count_order_id from co group by 1),
cte2 as(select pickup_time,order_time,count_order_id from co join cte on co.order_id=cte.order_id join ro on cte.order_id=ro.order_id),
cte3 as(select count_order_id,pickup_time-order_time as t from cte2),
cte4 as(select count_order_id,extract(min from t) as time_diff from cte3)
select distinct count_order_id,time_diff from cte4

---What was the average distance travelled for each customer?

with cte as(select customer_id,distance from co join runner_orders on co.order_id=runner_orders.order_id where distance is not null)
select customer_id,round(cast(avg(distance) as numeric),2) from cte group by 1 order by 1

---What was the difference between the longest and shortest delivery times for all orders?

select max(duration)-min(duration) from ro

---What was the average speed for each runner for each delivery and do you notice any trend for these values?

with cte as(select runner_id,round(cast(distance/(duration/60) as numeric),2) as speed,distance from ro)
select runner_id,round(avg(speed),2) as avg_speed,round(cast(avg(distance) as numeric),2) as avg_distance
from cte group by 1 order by 1

---What is the successful delivery percentage for each runner?

with cte as(select runner_id,sum(case when cancellation is null then 1 else 0 end) as succesfull,sum(case when cancellation is not null then 1 else 0 end) as not_succesfull
from runner_orders
group by 1 order by 1),
cte2 as(select *,succesfull+not_succesfull as total from cte)
select runner_id,round((cast(succesfull as numeric)/cast(total as numeric))*100,0) success_percent from cte2

---What are the standard ingredients for each pizza?

with cte as(select pizza_id,unnest(string_to_array(toppings,',')) as topping_id from pizza_recipes),
cte2 as(select pizza_id,cast(topping_id as integer) from cte),
cte3 as(select pizza_id,t2.topping_name from cte2 as t1 join pizza_toppings as t2 on t1.topping_id=t2.topping_id order by 1)
select pizza_id,string_agg(topping_name,',') as standard_ingredients from cte3 group by 1

---What was the most commonly added extra?

with cte as(select cast(unnest(string_to_array(extras,',')) as integer) as extras_added from co where extras is not null),
cte2 as(select extras_added,topping_name from cte join pizza_toppings on cte.extras_added=pizza_toppings.topping_id)
select topping_name,count(*) as count_of_extras from cte2 group by 1 order by 2 desc

--- What was the most common exclusion?

with cte as(select cast(unnest(string_to_array(exclusions,',')) as integer) as exclusions from co where exclusions is not null),
cte2 as(select exclusions,topping_name from cte join pizza_toppings on cte.exclusions=pizza_toppings.topping_id)
select topping_name,count(*) as count_of_exclusions from cte2 group by 1 order by 2 desc

---Generate an order item for each record in the customers_orders table in the format of one of the following:
---Meat Lovers
select distinct order_id from co where pizza_id=1

----Meat Lovers - Exclude Beef
select * from co where pizza_id=1

---Meat Lovers - Extra Bacon
select * from co where pizza_id=1 and extras like '%1%'

----Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
select * from co where pizza_id=1 and exclusions like '%4'

---Generate an alphabetically ordered comma separated ingredient list for each pizza order 
---from the customer_orders table and add a 2x in front of any relevant ingredients. 
---For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"



cte4 as(select pizza_id,string_agg(topping_name,',') as ingredients from cte3 group by 1)
select concat(a1.pizza_name,':',a2.ingredients) from cte as a1 join cte4 as a2 on a1.pizza_id=a2.pizza_id


with cte as(select row_number() over() as row,pizza_id,unnest(string_to_array(extras,',')) from co),
ctex as(select row_number() over() as row,pizza_id from co),
cte2 as(select t1.row,t1.pizza_id,cast(t2.unnest as integer) as extras from ctex as t1 left join cte as t2 on t1.row=t2.row),
cte3 as(select pizza_id,cast(unnest(string_to_array(toppings,',')) as integer) as topping_id from pizza_recipes),
cte4 as(select t1.pizza_id,t3.topping_name,t3.topping_id
from cte3 as t1 join pizza_toppings as t3 on t1.topping_id=t3.topping_id order by 1),
cte5 as(select t1.row,t1.pizza_id,t2.topping_name from cte2 as t1 join cte4 as t2 on t1.pizza_id=t2.pizza_id),
cte6 as(select distinct extras,topping_name from cte2 as t1 join cte4 as t2 on t1.extras=t2.topping_id),
cte7 as(select t1.row,t1.pizza_id,t1.topping_name,t2.extras from cte5 as t1 left join cte6 as t2 on t1.topping_name=t2.topping_name),
cte8 as(select row,pizza_id,case when extras is null then topping_name else concat('2x',topping_name) end as ingregient from cte7),
cte9 as(select t1.row,t2.pizza_name,t1.ingregient from cte8 as t1 join pizza_names as t2 on t1.pizza_id=t2.pizza_id),
cte10 as(select row,concat(pizza_name,':',ingregient) as final_ingredients from cte9)
select row,string_agg(final_ingredients,',') as Final_Ingredients from cte10 group by 1 order by 1



with cte as(select row_number() over() as row,pizza_id,unnest(string_to_array(extras,',')) from co),
cte2 as(select row_number() over() as row,pizza_id from co),
cte3 as(select t1.row,t1.pizza_id,cast(t2.unnest as integer) as extras from cte2 as t1 left join cte as t2 on t1.row=t2.row),
cte4 as(select t1.row,t1.pizza_id,t2.pizza_name,t1.extras from cte3 as t1 join pizza_names as t2 on t1.pizza_id=t2.pizza_id),
cte5 as(select pizza_id,cast(unnest(string_to_array(toppings,',')) as integer) as topping_id from pizza_recipes),
cte6 as(select t1.pizza_id,t1.topping_id,t2.topping_name from cte5 as t1 join pizza_toppings as t2 on t1.topping_id=t2.topping_id order by 1),
cte7 as(select row,t1.pizza_id,t1.pizza_name,t2.topping_name,t1.extras from cte4 as t1 join cte6 as t2 on t1.pizza_id=t2.pizza_id)
cte8 as(select t1.row,t1.pizza_id,t1.pizza_name,t1.topping_name as t1,t2.topping_name as t2 from cte7 as t1 left join cte6 as t2 on
t1.extras=t2.topping_id)
select row,case wehn t2 is null then t1 else 

---What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

with cte1 as(select pizza_id,extras,exclusions from co join ro on co.order_id=ro.order_id),
cte14 as(select cast(unnest(string_to_array(extras,',')) as integer) as extras_added from cte1 where extras is not null),
cte2 as(select extras_added,topping_name from cte14 join pizza_toppings on cte14.extras_added=pizza_toppings.topping_id),
cte3 as(select topping_name,count(*) as count_of_extras from cte2 group by 1 order by 2 desc),
cte4 as(select cast(unnest(string_to_array(exclusions,',')) as integer) as exclusions from cte1 where exclusions is not null),
cte5 as(select exclusions,topping_name from cte4 join pizza_toppings on cte4.exclusions=pizza_toppings.topping_id),
cte6 as(select topping_name,count(*) as count_of_exclusions from cte5 group by 1 order by 2 desc),
cte7 as(select pizza_id,cast(unnest(string_to_array(toppings,',')) as integer) as topping_id from pizza_recipes),
cte8 as(select pizza_id,t2.topping_name from cte7 as t1 join pizza_toppings as t2 on t1.topping_id=t2.topping_id order by 1),
cte9 as(select pizza_id from co join ro on co.order_id=ro.order_id),
cte10 as(select t1.pizza_id,t2.topping_name from cte9 as t1 join cte8 as t2 on t1.pizza_id=t2.pizza_id),
cte11 as(select topping_name,count(*) from cte10 group by 1),
cte12 as(select t1.topping_name,count as Count_of_initial,count_of_extras,count_of_exclusions from cte11 as t1 
left join cte3 on t1.topping_name=cte3.topping_name
left join cte6 on t1.topping_name=cte6.topping_name),
cte13 as(select topping_name,count_of_initial,case when count_of_extras is null then 0 else count_of_extras end as count_of_extras,
case when count_of_exclusions is null then 0 else 
count_of_exclusions end as count_of_exclusions from cte12)
select topping_name,count_of_initial+count_of_extras+count_of_exclusions as Total_Quantity from cte13 order by 2 desc

---If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes -
---how much money has Pizza Runner made so far if there are no delivery fees?

with cte as(select pizza_id from co natural join ro),
cte2 as(select pizza_id,case when pizza_id=1 then 12 else 0 end as MeatLovers,case when pizza_id=2 then 10 else 0 end as Vegetarians 
		from cte)
select sum(MeatLovers),sum(Vegetarians) from cte2

---What if there was an additional 1 charge for any pizza extras?
with cte as(select pizza_id,case when pizza_id = 1 then 12 else 10 end as cost from co natural join ro),
cte2 as(select cast(unnest(string_to_array(extras,',')) as integer) as extras from co natural join ro),
cte3 as(select sum( case when extras is not null then 1 end) as extras_cost from cte2),
cte4 as(select sum(cost) as cost_normal from cte)
select cost_normal+extras_cost as Total from cte4,cte3

---The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner,
---how would you design an additional table for this new dataset - 
---generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

CREATE TABLE ratings 
 (order_id INTEGER,
    rating INTEGER);
INSERT INTO ratings
 (order_id ,rating)
VALUES 
(1,3),
(2,4),
(3,5),
(4,2),
(5,1),
(6,3),
(7,4),
(8,1),
(9,3),
(10,5); 

SELECT * from ratings

---Using your newly generated table - can you join all of the information together to form a table which has the following
---information for successful deliveries?
--customer_id
--order_id
--runner_id
--rating
--order_time
---pickup_time
---Time between order and pickup
---Delivery duration
---Average speed
---Total number of pizzas

with cte as(select t1.customer_id,t1.order_id,t3.runner_id,t2.rating,t1.order_time,t3.pickup_time,t3.distance,pickup_time-order_time as diff,t3.duration,pizza_id from co as t1 join ratings
as t2 on t1.order_id=t2.order_id join ro as t3 on t1.order_id=t3.order_id),
cte2 as(select pizza_id,customer_id,order_id,runner_id,rating,order_time,pickup_time,extract(min from diff) as "Time between order and pickup",duration,distance from cte)
select customer_id,order_id,runner_id,rating,order_time,pickup_time,"Time between order and pickup",duration,round(cast(distance/(duration/60) as numeric),2) as Speed,count(pizza_id) from cte2
group by 1,2,3,4,5,6,7,8,9 order by 1

--- If a Meat Lovers pizza was 12andVegetarian10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre 
---traveled - how much money does Pizza Runner have left over after these deliveries?

with cte as(select order_id,runner_id,distance*0.30 as total_cost,case when pizza_id = 1 then 12 else 10 end as cost from co natural join ro),
cte2 as(select cost,total_cost,round(cast(cost-total_cost as numeric),2) as profit from cte)
select sum(cost),sum(total_cost),sum(profit) from cte2








 




