-- selecting sakila database
show databases;
use sakila;
show tables;

-- Count number of customers
select count(*) as no_of_customers from customer;

-- Count number of stores
select count(*) as no_of_stores from store;

-- Find earliest and latest payment date 
select min(payment_date) as earliest_payment_date, max(payment_date) as latest_payment_date from payment;

-- Find revenue earned from each film
SELECT f.title , sum(p.amount) as revenue from payment as p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
GROUP BY f.title
ORDER BY revenue desc;

-- Find revenue earned from each city
SELECT c1.country, c2.city , sum(p.amount) as revenue from payment as p
JOIN customer c3 ON p.customer_id = c3.customer_id
JOIN address a ON c3.address_id= a.address_id
JOIN city c2 ON a.city_id= c2.city_id
JOIN country c1 ON c2.country_id= c1.country_id
GROUP BY c2.city, c1.country
ORDER BY revenue desc;
