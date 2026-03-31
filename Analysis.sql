___Cancellations trend__

select date(scheduled_dep) as flight_date,
   count(*) as total_flights,
   sum(case when status = 'cancelled' then 1 else 0 end) as cancellation_flights
   from indigo_flights
   group by flight_date
   order by flight_date;
   ---------------------------------------------
   
   __Highest cancellation days__
   
   select date(scheduled_dep) as flight_date,
     count(*) as cancellation_flights
     from indigo_flights
     where status = 'cancelled'
     group by flight_date
     order by cancellation_flights desc;
     -----------------------------------------------
     
     ___Highest cancellation days__
     
     SELECT 
    COUNT(*) AS total,
    SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(100 * SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END)/COUNT(*),2) AS cancel_pct
FROM indigo_flights;
-----------------------------------
___Route impact___

select origin, destination,
   count(*) as total,
sum(case when status = 'cancelled' then 1 else 0 end) as cancelled
from indigo_flights
group by origin, destination
order by cancelled desc;
------------------------------------------------------------------------------------------
___crew_duty_logs_all__

select count(*) as non_complaint
from crew_duty_logs_all
where Fdtl_complaint = 'False';
-----------------------------------------------
___FDTL Trend__

select Dep_date,
 count(*) as total,
    sum(case when Fdtl_complaint = 'False' then 1 else 0 end) as Violations
    from crew_duty_logs_all
    group by Dep_date;
 --------------------------------------------
 __Rest gap___
 
 select avg(Rest_hrs_before_duty - Block_hours) as Avg_rest_gap
 from crew_duty_logs_all;
 -----------------------------------------------------------------------------------------------
 __Night flight %__
 
 select 
 count(*) as total,
 sum(is_night_flight) as night_flights,
 round(100* sum(is_night_flight)/count(*),2) as night_flight_percen
 from indigo_flights;
 ---------------------------------------------
__Night vs day cancellations__

SELECT is_night_flight,
       COUNT(*) AS total,
       SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled
FROM indigo_flights
GROUP BY is_night_flight;
---------------------------------------------
__Weather vs delay__

SELECT w.weather_code,
       AVG(f.delay_minutes)
FROM indigo_flights f
JOIN airport_mapping m
ON f.origin = m.iata_code
JOIN weather_metar w
ON m.icao_code = w.station
AND DATE(f.scheduled_dep) = DATE(w.obs_datetime)
GROUP BY w.weather_code;
------------------------------------------
__ Low visibility impact__

SELECT w.low_vis,
       AVG(f.delay_minutes) AS avg_delay
FROM indigo_flights f
JOIN airport_mapping m
ON f.origin = m.iata_code
JOIN weather_metar w
ON m.icao_code = w.station
AND DATE(f.scheduled_dep) = DATE(w.obs_datetime)
GROUP BY w.low_vis;		
---------------------------------
__Competitor cancellations___

select airline_name,
   count(*) as total,
  sum(case when flight_status = 'cancelled' then 1 else 0 end) as cancelled
  from competitor_flights
  group by airline_name;
------------------------------------------
__Delay comparison__

select 'indigo'as airline, avg(delay_minutes) as avg_delay
from indigo_flights
union
select airline_name, avg(delay_min)
from competitor_flights
group by airline_name;
-------------------------------------

___Revenue loss proxy__

SELECT round(SUM(avg_fare * pax_boarded), 0) AS revenue
FROM revenue_all;
--------------------------
__Revenue by route__

SELECT origin, destination,
       round(SUM(revenue), 0) AS total_revenue
FROM revenue_all
GROUP BY origin, destination
ORDER BY total_revenue DESC;
-----------------------------------------
__Load factor__

SELECT AVG(load_factor) AS avg_load
FROM revenue_all;
-----------------------------------
__Total Refunds__
 select sum(refunds_issued) as total_refunds
  from revenue_all;
------------------------------

__Flights vs crew mismatch__

SELECT f.flight_number,
       COUNT(DISTINCT f.flight_id) AS flights,
       COUNT(DISTINCT c.Employee_id) AS crew
FROM indigo_flights f
LEFT JOIN crew_duty_logs_all c
ON f.flight_number = c.Flt_number
GROUP BY f.flight_number;
---------------------------------------
__Airport delays__

SELECT origin,
       AVG(delay_minutes) AS avg_delay
FROM indigo_flights
GROUP BY origin
ORDER BY avg_delay DESC;
--------------------------------
__Delay trend before cancellation__
SELECT DATE(scheduled_dep) AS dt,
       AVG(delay_minutes) AS avg_delay,
       SUM(CASE WHEN status='CANCELLED' THEN 1 ELSE 0 END) AS cancels
FROM indigo_flights
GROUP BY dt
ORDER BY dt;
-------------------------------------

__Night + delay + cancellation combo__

SELECT is_night_flight,
       AVG(delay_minutes) AS avg_delay,
       SUM(CASE WHEN status='CANCELLED' THEN 1 ELSE 0 END) AS cancels
FROM indigo_flights
GROUP BY is_night_flight;

___Delay vs Weather Severity__

SELECT weather_code,
       COUNT(*) AS flights,
       AVG(delay_minutes) AS avg_delay
FROM indigo_flights f
JOIN airport_mapping m ON f.origin = m.iata_code
JOIN weather_metar w 
ON m.icao_code = w.station
AND DATE(f.scheduled_dep) = DATE(w.obs_datetime)
GROUP BY weather_code
ORDER BY avg_delay DESC;

__Cancellation Rate by Airport__

SELECT origin,
       COUNT(*) AS total,
       SUM(status = 'CANCELLED') AS cancelled,
       ROUND(100 * SUM(status = 'CANCELLED')/COUNT(*),2) AS cancel_rate
FROM indigo_flights
GROUP BY origin
ORDER BY cancel_rate DESC;
---------------------------------
__Total penalty imposed__

SELECT SUM(penalty_inr_lakh) AS total_penalty
FROM dgca_penalty_log;
------------------------------
__Penalty trend over time__

SELECT violation_date,
       SUM(penalty_inr_lakh) AS daily_penalty
FROM dgca_penalty_log
GROUP BY violation_date
ORDER BY violation_date;
-------------------------------
__Penalty by violation type__

SELECT violation_type,
       COUNT(*) AS cases,
       round(SUM(penalty_inr_lakh), 0) AS total_penalty
FROM dgca_penalty_log
GROUP BY violation_type
ORDER BY total_penalty DESC;
----------------------------------
__Airline-wise penalty__
SELECT airline,
       SUM(penalty_inr_lakh) AS total_penalty
FROM dgca_penalty_log
GROUP BY airline
ORDER BY total_penalty DESC;
-----------------------------------------
__Highest single penalty__
SELECT *
FROM dgca_penalty_log
ORDER BY penalty_inr_lakh DESC
LIMIT 1;
--------------------------
__Penalty spike vs cancellations__
SELECT DATE(f.scheduled_dep) AS dt,
       SUM(f.status='CANCELLED') AS cancels,
       SUM(d.penalty_inr_lakh) AS penalty
FROM indigo_flights f
LEFT JOIN dgca_penalty_log d
ON DATE(f.scheduled_dep) = d.violation_date
GROUP BY dt
ORDER BY dt;
-----------------
__Root cause via penalties___

SELECT violation_type,
       SUM(penalty_inr_lakh) AS total_penalty
FROM dgca_penalty_log
GROUP BY violation_type
ORDER BY total_penalty DESC;
------------------------------------------
On_time_ peformance_
SELECT 
ROUND(100 * SUM(delay_minutes <= 15)/COUNT(*),2) AS on_time_pct
FROM indigo_flights;
-----------------------------------
__PILOT UTILIZATION__
SELECT pilot_id,
       COUNT(*) AS flights_handled,
       AVG(block_hours) AS avg_hours
FROM pilot_roster
GROUP BY pilot_id
ORDER BY avg_hours DESC;
-----------------------------
__CAPACITY vs DEMAND__
SELECT DATE(scheduled_dep) AS dt,
       COUNT(*) AS flights,
       SUM(r.pax_boarded) AS passengers
FROM indigo_flights f
JOIN revenue_all r
ON f.origin = r.origin
AND f.destination = r.destination
AND DATE(f.scheduled_dep) = r.date
GROUP BY dt;
--------------------------------
_DELAY → CANCELLATION CASCADE__
SELECT 
CASE 
    WHEN delay_minutes < 15 THEN 'On Time'
    WHEN delay_minutes < 60 THEN 'Moderate Delay'
    ELSE 'Heavy Delay'
END AS delay_bucket,
SUM(status='CANCELLED') AS cancels
FROM indigo_flights
GROUP BY delay_bucket;
