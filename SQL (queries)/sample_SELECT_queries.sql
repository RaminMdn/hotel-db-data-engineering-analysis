--1. Find rooms that have never been booked but have a Jacuzzi

--Goal: Identify rooms with HasJacuzzi = TRUE that have zero entries in RoomReservation.

-- Method 1: LEFT JOIN with IS NULL
SELECT r.RoomNumber
FROM Room r
LEFT JOIN RoomReservation rr ON rr.RoomNumber = r.RoomNumber
WHERE r.HasJacuzzi = TRUE
  AND rr.RoomNumber IS NULL;

-- Method 2: NOT EXISTS Correlated Subquery
SELECT r.RoomNumber
FROM Room r
WHERE r.HasJacuzzi = TRUE
  AND NOT EXISTS (
    SELECT 1
    FROM RoomReservation rr
    WHERE rr.RoomNumber = r.RoomNumber
  );

-- Method 3: NOT IN
SELECT r.RoomNumber
FROM Room r
WHERE r.HasJacuzzi = TRUE
  AND r.RoomNumber NOT IN (
    SELECT rr.RoomNumber
    FROM RoomReservation rr
  );


-- 2. Find the top 3 guests by total spending (total of all their Reservations)

-- Goal: Identify the top 3 guests ranked by the sum of Total in their reservations.

-- Method 1: Aggregate with JOIN + GROUP BY
SELECT g.GuestId, g.FirstName, g.LastName, SUM(r.Total) AS TotalSpent
FROM Guest g
JOIN GuestReservation gr ON gr.GuestId = g.GuestId
JOIN Reservation r ON r.ReservationId = gr.ReservationId
GROUP BY g.GuestId, g.FirstName, g.LastName
ORDER BY TotalSpent DESC
LIMIT 3;

-- Method 2: Use Window Functions
SELECT GuestId, FirstName, LastName, TotalSpent
FROM (
  SELECT g.GuestId, g.FirstName, g.LastName, SUM(r.Total) AS TotalSpent,
         RANK() OVER (ORDER BY SUM(r.Total) DESC) AS rk
  FROM Guest g
  JOIN GuestReservation gr ON gr.GuestId = g.GuestId
  JOIN Reservation r ON r.ReservationId = gr.ReservationId
  GROUP BY g.GuestId, g.FirstName, g.LastName
) t
WHERE rk <= 3;

-- Method 3: Subquery with ORDER BY + LIMIT
SELECT GuestId, FirstName, LastName, TotalSpent FROM (
  SELECT g.GuestId, g.FirstName, g.LastName, SUM(r.Total) AS TotalSpent
  FROM Guest g
  JOIN GuestReservation gr ON gr.GuestId = g.GuestId
  JOIN Reservation r ON r.ReservationId = gr.ReservationId
  GROUP BY g.GuestId, g.FirstName, g.LastName
) sub
ORDER BY TotalSpent DESC
LIMIT 3;


--3. Average price per night per room type, including extra person charge

-- We actually want to: compute average (basePrice + extraPerson) grouped by roomType.

--Assume a reservation always has exactly StandardOccupancy people; or you could adjust based on actual occupancy—here we illustrate with standard.

--Method 1: Simple Average
SELECT RoomType,
       AVG(BasePrice + ExtraPerson) AS AvgNightlyCharge
FROM Room
GROUP BY RoomType;

--Method 2: Weighted by Maximum Occupancy
SELECT RoomType,
       SUM((BasePrice + ExtraPerson) * MaximumOccupancy) / SUM(MaximumOccupancy) AS WeightedAvg
FROM Room
GROUP BY RoomType;

--Method 3: CTE + AVG
WITH nightly AS (
  SELECT RoomType, (BasePrice + ExtraPerson)::NUMERIC AS night_charge
  FROM Room
)
SELECT RoomType, AVG(night_charge) AS AvgNightly
FROM nightly
GROUP BY RoomType;


--4. Find guests who shared a Reservation with someone else (i.e., roommates)

--We actually want to: Find all guests who co-reserved with at least one other guest (i.e., reservations having >1 guest linked).

--Method 1: Self-join on GuestReservation
SELECT DISTINCT g1.GuestId, g1.FirstName, g1.LastName
FROM GuestReservation g1
JOIN GuestReservation g2
  ON g1.ReservationId = g2.ReservationId
 AND g1.GuestId <> g2.GuestId
JOIN Guest g1g ON g1g.GuestId = g1.GuestId;

--Method 2: Aggregation + HAVING COUNT > 1
SELECT g.GuestId, g.FirstName, g.LastName
FROM GuestReservation gr
JOIN Guest g ON g.GuestId = gr.GuestId
GROUP BY g.GuestId, g.FirstName, g.LastName
HAVING COUNT(gr.ReservationId) FILTER (WHERE gr.ReservationId IN (
    SELECT ReservationId
    FROM GuestReservation
    GROUP BY ReservationId
    HAVING COUNT(*) > 1
)) > 0;

--Method 3: Use Window Function Partitioned by Reservation
SELECT DISTINCT GuestId
FROM (
  SELECT GuestId, ReservationId,
         COUNT(*) OVER (PARTITION BY ReservationId) AS GuestCount
  FROM GuestReservation
) t
WHERE GuestCount > 1;


--  5. For each amenity, Count how many ADA-C,ompliant rooms have it

--Goal: For each amenity type (e.g., "WiFi"), count ADA rooms (IsADA = TRUE) that offer that amenity.

--Method 1: JOIN + Conditional Aggregation
SELECT a.AmenityType,
       COUNT(DISTINCT rr.RoomNumber) AS NumADArooms
FROM Amenity a
JOIN RoomAmenity ra ON ra.AmenityId = a.AmenityId
JOIN Room r ON r.RoomNumber = ra.RoomNumber
WHERE r.IsADA = TRUE
GROUP BY a.AmenityType;

--Method 2: Subquery per Amenity
SELECT a.AmenityType,
      (SELECT COUNT(*)
       FROM RoomAmenity ra
       JOIN Room r ON r.RoomNumber = ra.RoomNumber
       WHERE ra.AmenityId = a.AmenityId
         AND r.IsADA = TRUE) AS NumADArooms
FROM Amenity a;

--Method 3: Using JOIN + GROUP BY a.AmenityId
SELECT a.AmenityType, COUNT(DISTINCT ra.RoomNumber) AS ADAcount
FROM Amenity a
LEFT JOIN RoomAmenity ra ON ra.AmenityId = a.AmenityId
LEFT JOIN Room r ON r.RoomNumber = ra.RoomNumber AND r.IsADA = TRUE
GROUP BY a.AmenityType;




-- 6. Find overlapping reservations in the same room (double booking detection)

-- Method 1: Using self join and date range
SELECT 
    r1.ReservationId AS Res1,
    r2.ReservationId AS Res2,
    rr1.RoomNumber
FROM RoomReservation rr1
JOIN Reservation r1 ON rr1.ReservationId = r1.ReservationId
JOIN RoomReservation rr2 ON rr1.RoomNumber = rr2.RoomNumber
JOIN Reservation r2 ON rr2.ReservationId = r2.ReservationId
WHERE rr1.ReservationId <> rr2.ReservationId
  AND r1.CheckInDate < r2.CheckOutDate
  AND r2.CheckInDate < r1.CheckOutDate
ORDER BY rr1.RoomNumber, Res1, Res2;
