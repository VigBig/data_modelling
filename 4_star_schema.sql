-- Creating Star Schema
-- selecting sakila database
show databases;
use sakila;
show tables;

-- Creating 4 dimension tables
-- Creating dimension table : dim_date
CREATE TABLE dim_date (
	date_key int not null primary key,
    date date not null,
    year smallint not null,
    quarter smallint not null,
    month smallint not null,
    day smallint not null,
    week smallint not null,
    is_weekend boolean
);

-- Creating dimension table : dim_customer
CREATE TABLE dim_customer (
	customer_key serial primary key,
    customer_id smallint not null,
    first_name varchar(45) not null,
    last_name varchar(45) not null,
    email varchar(50),
    address varchar(50) not null,
    address2 varchar(50),
    district varchar(20) not null,
    city varchar(50) not null,
    country varchar(50) not null,
    postal_code varchar(10),
    phone varchar(20) not null,
    active smallint not null,
    create_date timestamp not null,
    start_date date not null,
    end_date date not null
);

-- Creating dimension table : dim_movie
CREATE TABLE dim_movie (
	movie_key serial primary key,
    film_id smallint not null,
    title varchar(255) not null,
    description text,
    release_year year,
    language varchar(20) NOT Null,
    rental_duration smallint not null,
    length smallint not null,
    rating varchar(5) not null,
    special_features varchar(60) not null
);

-- Creating dimension table : dim_store
CREATE TABLE dim_store (
	store_key serial primary key,
    store_id smallint not null,
    address varchar(50) not null,
    address2 varchar(50),
    district varchar(20) not null,
    city varchar(50) not null,
    country varchar(50) not null,
    postal_code varchar(10),
	manager_first_name varchar(45) not null,
    manager_last_name varchar(45) not null,
    start_date date not null,
    end_date date not null
);

-- Inserting records into dim_date from payment table
INSERT INTO dim_date (date_key, date, year, quarter, month, day, week, is_weekend)
SELECT
	distinct(convert(replace(convert(payment_date,date), '-', ''),unsigned)) as date_key,
	date(payment_date) as date, 
	EXTRACT(year FROM payment_date) as year,
    EXTRACT(quarter FROM payment_date) as quarter,
    EXTRACT(month FROM payment_date) as month,
    EXTRACT(day FROM payment_date) as day,
    EXTRACT(week FROM payment_date) as week,
--     CASE WHEN weekday(payment_date) IN (6,7) THEN true ELSE FALSE end
	IF(weekday(payment_date) in (6,7), true,false) as is_weekend
FROM payment;

SELECT * FROM dim_date;

-- Inserting records into dim_customer from customer, address, city, country
INSERT INTO dim_customer (customer_key,customer_id,first_name,last_name,email,address,address2,district,city,country,postal_code,phone,active,create_date,start_date, end_date)
SELECT
	c.customer_id as customer_key,
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    a.address,
    a.address2,
    a.district,
    ci.city,
    co.country,
    postal_code,
    a.phone,
    c.active,
    c.create_date,
    now() as start_date,
    now() as end_date
FROM customer c
JOIN address a ON (c.address_id = a.address_id)
JOIN city ci ON (a.city_id = ci.city_id)
JOIN country co ON (ci.country_id = co.country_id);

SELECT * FROM dim_customer;

-- Inserting records into dim_movie from film and language
INSERT INTO dim_movie (	movie_key,film_id,title,description,release_year,language,rental_duration,length,rating,special_features)
SELECT
	f.film_id as film_key,
    f.film_id,
    f.title,
    f.description,
    f.release_year,
    l.name,
    f.rental_duration,
    f.length,
    f.rating,
    f.special_features
FROM film f
JOIN language l ON (f.language_id = l.language_id);

select * from dim_movie;

-- Inserting records into dim_movie from film and language
INSERT INTO dim_store (	store_key,store_id,address,address2,district,city,country,postal_code,manager_first_name,manager_last_name,start_date,end_date)
SELECT
	s2.store_id as store_key,
    s2.store_id,
    a.address,
    a.address2,
    a.district,
    c1.city,
    c2.country,
    a.postal_code,
    s1.first_name,
    s1.last_name,
    now() as start_date,
    now() as end_date 
FROM staff s1
JOIN store s2 on (s1.store_id = s2.store_id)
JOIN address a on (s2.address_id = a.address_id)
JOIN city c1 on (a.city_id = c1.city_id)
JOIN country c2 on (c1.country_id = c2.country_id);

select * from dim_store;

-- Creating Fact Table
-- Creating Fact Table : fact_sales
CREATE TABLE fact_sales (
	sales_key SERIAL primary key,
    date_key int,
    customer_key bigint unsigned,
    movie_key bigint unsigned,
    store_key bigint unsigned,
    foreign key (date_key) REFERENCES dim_date(date_key),
	foreign key (customer_key) REFERENCES dim_customer(customer_key),
    foreign key (movie_key) REFERENCES dim_movie(movie_key),
    foreign key (store_key) REFERENCES dim_store(store_key),
    sales_amount numeric
);

-- Inserting records into fact_sales
INSERT INTO fact_sales (date_key,customer_key,movie_key,store_key,sales_amount)
select
	convert(replace(convert(payment_date,date), '-', ''),unsigned) as date_key,
    p.customer_id as customer_key,
    i.film_id as movie_key,
    i.store_id as store_key,
    p.amount as sales_amount
FROM payment p 
JOIN rental r ON (p.rental_id = r.rental_id)
JOIN inventory i ON (r.inventory_id = i.inventory_id);

select * from fact_sales;

-- Query to find revenue of films sold in a month by city
SELECT f.title,  monthname(p.payment_date) as month, ci.city, sum(p.amount) as revenue
FROM payment p
JOIN rental r ON (p.rental_id = r.rental_id)
JOIN inventory i ON (r.inventory_id = i.inventory_id)
JOIN film f ON (i.film_id = f.film_id)
JOIN customer c ON (p.customer_id = c.customer_id)
JOIN address a ON (c.address_id = a.address_id)
JOIN city ci ON (a.city_id = ci.city_id)
GROUP BY f.title, month, ci.city
ORDER BY f.title, month, ci.city, revenue desc;