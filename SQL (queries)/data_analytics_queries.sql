

/* Query 1: Daily Occupied Room Counts Over a Date Range

Problem: For a given date range, say from '2025-09-01' to '2025-09-07', return the number of rooms occupied each day—including partial overlaps. This requires generating a series of dates and counting reservations active on each day.

Method: Using a date series with Joins + Aggregation*/

WITH date_range AS (
  SELECT generate_series('2025-09-01'::date, '2025-09-07'::date, '1 day') AS dt
),
occupied AS (
  SELECT dr.dt,
         COUNT(DISTINCT rr.RoomNumber) AS occupied_rooms
  FROM date_range dr
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


-- Alternative Approach: window Function Over flattened days

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


-- Recursive CTE for summarized availability trends
WITH RECURSIVE date_range AS (
  SELECT '2025-09-01'::date AS dt
  UNION ALL
  SELECT dt + INTERVAL '1 day'
  FROM date_range
  WHERE dt + INTERVAL '1 day' <= '2025-09-07'::date
),
counts AS (
  SELECT dr.dt,
         COUNT(DISTINCT rr.RoomNumber) AS occupied_rooms
  FROM date_range dr
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

/* Query 2: Identify Guests Who Shared at Least Three Different Reservations Together

Problem: Find pairs of guests who have been co-guests in at least three different reservations together. This compares pairwise guest relationships across reservations and counts the number of shared bookings.

Approach: self Join + pair ordering + aggregation */
SELECT
  gr1.GuestId AS guest1,
  gr2.GuestId AS guest2,
  COUNT(*) AS shared_count
FROM GuestReservation gr1
JOIN GuestReservation gr2
  ON gr1.ReservationId = gr2.ReservationId
 AND gr1.GuestId < gr2.GuestId  -- ensures unique pairs
GROUP BY gr1.GuestId, gr2.GuestId
HAVING COUNT(*) >= 3;


-- Alternative with CTE and Joining Guest Names
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



-- Sophisticated Window Function Method (optional)
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
