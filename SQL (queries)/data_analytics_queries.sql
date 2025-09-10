
/* 1: Find daily occupied room counts Over a date range:

For a given date range, say from '2025-09-01' to '2025-09-07', return the number of rooms occupied each day, 
including partial overlaps. This requires generating a series of dates and counting reservations active on each day.*/

-- Method 1: Using a date series with Joins + Aggregation

WITH DateRange AS (
  SELECT generate_series('2025-09-01'::date, '2025-09-07'::date, '1 day') AS dt
),
occupied AS (
  SELECT dr.dt,
         COUNT(DISTINCT rr.RoomNumber) AS occupied_rooms
  FROM DateRange dr
  LEFT JOIN RoomReservation rr
    JOIN Reservation res
      ON res.ReservationId = rr.ReservationId
     AND res.CheckInDate <= dr.dt
     AND res.CheckOutDate > dr.dt  -- checkout date is exclusive
    ON true
  GROUP BY dr.dt
)
SELECT dt AS date, occupied_rooms
FROM occupied
ORDER BY dt;


-- Method 2: window function over flattened days

-- First create one row per room per day within bookings and then count.

WITH expanded AS (
  SELECT rr.RoomNumber,
         generate_series(res.CheckInDate, res.CheckOutDate - INTERVAL '1 day', '1 day')::date AS dt
  FROM Reservation res
  JOIN RoomReservation rr ON rr.ReservationId = res.ReservationId
  WHERE res.CheckInDate <= '2025-09-07'
    AND res.CheckOutDate > '2025-09-01'
),
daily_counts AS (
  SELECT dt, COUNT(DISTINCT RoomNumber) AS occupied_rooms
  FROM expanded
  GROUP BY dt
)
SELECT dt AS date, occupied_rooms
FROM daily_counts
ORDER BY dt;


-- Method 3: Recursive CTE for summarized availability trends
WITH RECURSIVE DateRange AS (
  SELECT '2025-09-01'::date AS dt
  UNION ALL
  SELECT dt + INTERVAL '1 day'
  FROM DateRange
  WHERE dt + INTERVAL '1 day' <= '2025-09-07'::date
),
counts AS (
  SELECT dr.dt,
         COUNT(DISTINCT rr.RoomNumber) AS occupied_rooms
  FROM DateRange dr
  LEFT JOIN RoomReservation rr
    JOIN Reservation res
      ON res.ReservationId = rr.ReservationId
     AND res.CheckInDate <= dr.dt
     AND res.CheckOutDate > dr.dt
    ON true
  GROUP BY dr.dt
)
SELECT dt AS date, occupied_rooms
FROM counts
ORDER BY dt;




/* 2: Identify guests who shared at least three different reservations together:

Find pairs of guests who have been co-guests in at least three different reservations together. 
This compares pairwise guest relationships across reservations and counts the number of shared bookings.*/

-- Method 1: self Join + pair ordering + aggregation 
SELECT
  gr1.GuestId AS guest1,
  gr2.GuestId AS guest2,
  COUNT(*) AS shared_count
FROM GuestReservation gr1
JOIN GuestReservation gr2
  ON gr1.ReservationId = gr2.ReservationId
 AND gr1.GuestId < gr2.GuestId  -- unique pairs
GROUP BY gr1.GuestId, gr2.GuestId
HAVING COUNT(*) >= 3;


-- Method 2: Alternatively, we can go with CTE and joining guest names
WITH pairs AS (
  SELECT
    LEAST(gr1.GuestId, gr2.GuestId) AS g1,
    GREATEST(gr1.GuestId, gr2.GuestId) AS g2,
    gr1.ReservationId
  FROM GuestReservation gr1
  JOIN GuestReservation gr2
    ON gr1.ReservationId = gr2.ReservationId
   AND gr1.GuestId <> gr2.GuestId
)
SELECT
  g1.g1 AS guest1_id,
  g2.g2 AS guest2_id,
  COUNT(DISTINCT g1.ReservationId) AS shared_reservations
FROM pairs g1
JOIN pairs g2
  ON g1.g1 = g2.g1
 AND g1.g2 = g2.g2
GROUP BY g1.g1, g1.g2
HAVING COUNT(DISTINCT g1.ReservationId) >= 3;


-- Method 3: Window Function Method (not an original solution, might be more sophisticated)
WITH pair_counts AS (
  SELECT
    LEAST(gr1.GuestId, gr2.GuestId) AS guest_a,
    GREATEST(gr1.GuestId, gr2.GuestId) AS guest_b,
    COUNT(*) OVER (PARTITION BY
      LEAST(gr1.GuestId, gr2.GuestId),
      GREATEST(gr1.GuestId, gr2.GuestId)
    ) AS cnt
  FROM GuestReservation gr1
  JOIN GuestReservation gr2
    ON gr1.ReservationId = gr2.ReservationId
   AND gr1.GuestId < gr2.GuestId
)
SELECT DISTINCT guest_a AS guest1, guest_b AS guest2
FROM pair_counts
WHERE cnt >= 3;



-- 3: Find most popular room types based on number of nights booked in the past year

-- Method 1: 
SELECT 
    ro.RoomType,
    SUM(re.CheckOutDate - re.CheckInDate) AS TotalNightsBooked
FROM Room ro
JOIN RoomReservation rr ON ro.RoomNumber = rr.RoomNumber
JOIN Reservation re ON rr.ReservationId = re.ReservationId
WHERE re.CheckInDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY ro.RoomType
ORDER BY TotalNightsBooked DESC;