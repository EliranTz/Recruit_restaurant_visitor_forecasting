select * 
from store_id_relation

select * 
From air_visit_data

drop table if exists visit_data_relation_id
select a.*, b.hpg_store_id
into visit_data_relation_id
From air_visit_data a left join store_id_relation b 
on a.air_store_id = b.air_store_id

select * 
from visit_data_relation_id

drop table if exists air_hpg_id
select air_store_id, hpg_store_id
into air_hpg_id
from visit_data_relation_id
group by air_store_id, hpg_store_id

select *
from air_hpg_id

alter table air_hpg_id
add restaurant_id int identity(1,1)

select *
from air_hpg_id

drop table if exists air_visit_data_final
select a.*, b.hpg_store_id ,b.restaurant_id
into air_visit_data_final
from air_visit_data a left join air_hpg_id b
on a.air_store_id = b.air_store_id

select *
from air_visit_data_final


drop table if exists store_id_relation_final
select a.*, b.restaurant_id
into store_id_relation_final
from store_id_relation a left join air_hpg_id b
on a.air_store_id = b.air_store_id

select *
From store_id_relation_final
--------------

drop table if exists hpg_1
select a.*, b.restaurant_id
into hpg_1
from hpg_reserve a inner join air_visit_data_final b
on a.hpg_store_id = b.hpg_store_id

select *
from hpg_1

-- 8,752,969 rows

select distinct hpg_store_id
from hpg_1
group by hpg_store_id

--150 stores 

---hpg_reserve + store_id_relation + hpg_store_info

drop table if exists hpg_2
select a.*
into hpg_2
from hpg_1 a left join hpg_store_info b
on a.hpg_store_id = b.hpg_store_id

select count(*)
from hpg_2

--150 stores and 8,752,969 rows
-----

--air_reserve + store_id_relation
drop table if exists air_1
select a.*, b.hpg_store_id, b.restaurant_id
into air_1
from air_reserve a inner join store_id_relation_final b
on a.air_store_id = b.air_store_id

select * 
from air_1

-- 36264 rows 

select air_store_id
from air_1
group by air_store_id
--131 stores


drop table if exists air_2
select a.*, left(b.air_area_name, CHARINDEX(' ',b.air_area_name)) as area,
b.air_genre_name as genre, b.latitude, b.longitude
into air_2
from air_1 a left join air_store_info b
on a.air_store_id = b.air_store_id

select * 
from air_2

-- 36264 rows 

select * 
From store_id_relation_final

select * 
from air_visit_data_final

drop table if exists visit_data_air
select a.*, b.area, b.genre, b.latitude, b.longitude, b.reserve_datetime as reserve_date, b.reserve_visitors
into visit_data_air
From air_visit_data_final a left join air_2 b
on a.restaurant_id = b.restaurant_id
and a.visit_date = b.visit_datetime

select * 
from visit_data_air


-- date preparation 

ALTER TABLE date_info
ALTER COLUMN calendar_date date;

select * 
from date_info

drop table if exists date_new 
select convert(date, calendar_date) as short_date,
		YEAR(calendar_date) as year, month(calendar_date) as month , DATEPART (week , calendar_date) week_number,
		CONVERT(varchar(10), DATEPART (week , calendar_date) )+'_'+CONVERT(varchar(10), YEAR(calendar_date)) as week_year,
		day_of_week, holiday_flg,
case 
	When day_of_week NOT IN ('Saturday','Sunday') and holiday_flg = 1 THEN 1
	ELSE 0
END AS holiday_week,
Case
	when day_of_week IN ('Saturday','Sunday') Then 1
	else 0 
End AS weekend 
into date_new
from date_info

select * 
from date_new

drop table if exists holiday_days
select week_year ,sum(holiday_flg) as number_of_holiday_days
into holiday_days
from date_new
group by week_year

select * 
From holiday_days

drop table if exists date_update
select a.*, b.number_of_holiday_days
into date_update
from date_new a left join holiday_days b
on a.week_year = b.week_year

select * 
From date_update

--additing dates
select * 
from visit_data_air

drop table if exists visit_data_air_date
select a.* , DATEPART(week, a.visit_date) as visit_week ,
DATEPART(year,a.visit_date) as visit_year, 
CONVERT(varchar(10), DATEPART(week ,a.visit_date))+'_'+CONVERT(varchar(10), YEAR(a.visit_date)) as week_year_visit,
DATEPART(week,a.reserve_date) as reserve_week ,
DATEPART(year,a.reserve_date) as reserve_year ,
CONVERT(varchar(10), DATEPART(week ,a.reserve_date))+'_'+CONVERT(varchar(10), YEAR(a.reserve_date)) as week_year_reserve,
DATEDIFF(day, a.reserve_date, a.visit_date) AS diff_days_between_reserve_visit,
b.holiday_flg as holiday_flg_visit, b.holiday_week as holiday_week_visit, b.number_of_holiday_days as number_of_holiday_days_visit, b.weekend
into visit_data_air_date
From visit_data_air a left join date_update b
on CONVERT(varchar(10), DATEPART(week ,a.visit_date))+'_'+CONVERT(varchar(10), YEAR(a.visit_date)) = b.week_year

select *
from visit_data_air_date

-- weekend visitors 
drop table if exists weekend_visitors
select distinct visit_year, visit_week, week_year_visit, restaurant_id ,weekend, sum(visitors) weekend_visitors
into weekend_visitors
from visit_data_air_date
where weekend = 1
group by visit_year, visit_week, week_year_visit, restaurant_id ,weekend
order by week_year_visit

select * 
from weekend_visitors

-- 1922750 rows

-- before final table with relevant calculations

drop table if exists before_final_table_restaurant
select visit_year, visit_week, week_year_visit, restaurant_id ,air_store_id,
sum(visitors) as sum_visitors,
max(visitors) as max_visitors,
min(visitors) as min_visitors,
avg(visitors) as avg_visitors,
count(visitors) as count_visitors,
ISNULL(sum(reserve_visitors),0) as sum_reserve_visitors,
ISNULL(max(reserve_visitors),0) as max_reserve_visitors,
ISNULL(min(reserve_visitors),0) as min_reserve_visitors,
ISNULL(avg(reserve_visitors),0) as avg_reserve_visitors,
count(reserve_visitors) as count_reserve_visitors,
sum(diff_days_between_reserve_visit) as sum_diff_days_between_reserve_visit,
max(diff_days_between_reserve_visit) as max_diff_days_between_reserve_visit,
min(diff_days_between_reserve_visit) as min_diff_days_between_reserve_visit,
avg(diff_days_between_reserve_visit) as avg_diff_days_between_reserve_visit,
count(diff_days_between_reserve_visit) as count_diff_days_between_reserve_visit,
max(holiday_flg_visit) as holiday_flg_visit, 
max(holiday_week_visit) as holiday_week_visit,
max(number_of_holiday_days_visit) as number_of_holiday_days_visit
into before_final_table_restaurant
from visit_data_air_date
group by visit_year, visit_week, week_year_visit, restaurant_id, air_store_id

select * 
from  before_final_table_restaurant

select count(*) 
from before_final_table_restaurant
--42281


--weather + area
select *
from air_store_info_with_nearest_active_station

select *
from air_hpg_id


drop table if exists air_hpg_id_weather
select a.*, left(b.air_area_name, CHARINDEX(' ',b.air_area_name)) as area,
b.station_name, b.station_latitude, b.air_genre_name as genre,
b.station_longitude, b.station_vincenty, b.station_great_circle
,b.latitude as restaurant_latitude, b.longitude as restaurant_longitude
into air_hpg_id_weather
from air_hpg_id a left join air_store_info_with_nearest_active_station b 
on a.air_store_id = b.air_store_id 

select distinct * 
from air_hpg_id_weather

drop table if exists air_hpg_id_weather_station
select station_name
into air_hpg_id_weather_station
from air_hpg_id_weather
group by station_name

select * 
From air_hpg_id_weather_station

alter table air_hpg_id_weather_station
add station_id int identity(1,1)

select * 
From air_hpg_id_weather_station

drop table if exists air_hpg_id_weather_station_id
select a.*, b.station_id
into air_hpg_id_weather_station_id
from air_hpg_id_weather a join air_hpg_id_weather_station b
on a.station_name = b.station_name

select * 
from air_hpg_id_weather_station_id

drop table if exists restaurants_per_area
select left(air_area_name, CHARINDEX(' ',air_area_name)) as area,
count(air_store_id) as number_of_restaurants_in_area
into restaurants_per_area
from air_store_info
group by left(air_area_name, CHARINDEX(' ',air_area_name))

select * 
from restaurants_per_area

drop table if exists air_hpg_id_weather_area
select a.*, b.number_of_restaurants_in_area
into air_hpg_id_weather_area
from air_hpg_id_weather a left join restaurants_per_area b 
on a.area = b.area

select * 
from air_hpg_id_weather_area

drop table if exists area_for_id
select area
into area_for_id
from air_hpg_id_weather_area
group by area


alter table area_for_id
add area_id int identity(1,1)

select * 
from area_for_id

drop table if exists air_hpg_id_weather_area_id
select a.*, b.area_id
into air_hpg_id_weather_area_id
from air_hpg_id_weather_area a left join area_for_id b 
on a.area = b.area

select *
from air_hpg_id_weather_area_id

drop table if exists air_hpg_id_weather_id
select a.*, b.station_id
into air_hpg_id_weather_id
from air_hpg_id_weather_area_id a left join air_hpg_id_weather_station_id b 
on a.restaurant_id = b.restaurant_id

-- genre

drop table if exists genre
select genre
into genre
from air_hpg_id_weather
group by genre

alter table genre
add genre_id int identity(1,1)

select * 
from genre

drop table if exists weather_id_final
select a.*, b.genre_id
into weather_id_final
from air_hpg_id_weather_id a left join genre b 
on a.genre = b.genre

select * 
from weather_id_final

drop table if exists air_2_data 
select restaurant_id, area , genre, latitude, longitude
into air_2_data
from air_2
group by restaurant_id, area, genre,  latitude, longitude

select * 
from air_2_data

drop table if exists genre_for_id
select genre
into genre_for_id
from air_2_data
group by genre

alter table genre_for_id
add genre_id int identity(1,1)

select * 
from genre_for_id

drop table if exists air_2_data_genre_id
select a.*, b.genre_id
into air_2_data_genre_id
from air_2_data a left join genre_for_id b 
on a.genre = b.genre


drop table if exists final_table_restaurant
select a.*, b.area, b.area_id, b.genre, b.genre_id, b.station_name, b.station_id,
b.station_latitude, b.station_longitude, b.station_vincenty, b.station_great_circle,
b.restaurant_latitude, b.restaurant_longitude,b.number_of_restaurants_in_area, c.weekend_visitors
into final_table_restaurant
from before_final_table_restaurant a left join weather_id_final b 
on a.restaurant_id = b.restaurant_id left join weekend_visitors c 
on a.restaurant_id = c.restaurant_id and a.week_year_visit = c.week_year_visit

select * 
from final_table_restaurant
order by weekend_visitors


select count(*) 
from final_table_restaurant
-- 42281 rows