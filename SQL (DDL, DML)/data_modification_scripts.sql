-- Delete a Guest and Related Records

------ Method 1: Step-by-Step DELETEs with Subqueries

-- Step 1: Delete from RoomReservation (depends on ReservationId)
DELETE FROM RoomReservation
WHERE ReservationId IN (
    SELECT ReservationId
    FROM GuestReservation
    WHERE GuestId = 3
);

-- Step 2: Delete from GuestReservation
DELETE FROM GuestReservation
WHERE GuestId = 3;

-- Step 3: Delete from Reservation
DELETE FROM Reservation
WHERE ReservationId IN (
    SELECT ReservationId
    FROM GuestReservation
    WHERE GuestId = 3
); -- This SELECT would now be empty; better to save IDs earlier.

-- Step 4: Delete from Guest
DELETE FROM Guest
WHERE GuestId = 3;

-- Important note: Method 1 may seem to be correct, but it has a flaw. If we delete data from GuestReservation table in step 2, 
-- then we can not use this table's data in step 3. So this method won't work, and another method that keeps the ReservationId
-- in memory, or use it somehow before it is removed should be used. The following methods (methods 2, 3, 4) get this task done.


------ Method 2: CTE with one-time reservation lookup (clean + reusable)

-- Step 1: Capture reservation IDs in a CTE

WITH target_reservations AS (
    SELECT ReservationId
    FROM GuestReservation
    WHERE GuestId = 3
)

-- Step 2: Delete from RoomReservation
DELETE FROM RoomReservation
WHERE ReservationId IN (SELECT ReservationId FROM target_reservations);

-- Step 3: Delete from GuestReservation
DELETE FROM GuestReservation
WHERE GuestId = 3;

-- Step 4: Delete from Reservation
DELETE FROM Reservation
WHERE ReservationId IN (SELECT ReservationId FROM target_reservations);

-- Step 5: Delete from Guest
DELETE FROM Guest
WHERE GuestId = 3;

-- -- Alternatively, Step 2 & 3 could be combined using RETURNING:
-- WITH deleted_guest_res AS (
--     DELETE FROM GuestReservation
--     WHERE GuestId = 3
--     RETURNING ReservationId
-- )
-- DELETE FROM RoomReservation
-- WHERE ReservationId IN (SELECT ReservationId FROM deleted_guest_res);



------ Method 3: DELETEs using USING + JOINs (concise SQL)

-- Step 1: Delete from RoomReservation using join

DELETE FROM RoomReservation
USING GuestReservation
WHERE RoomReservation.ReservationId = GuestReservation.ReservationId
  AND GuestReservation.GuestId = 3;

-- Step 2: Delete from Reservation using join
DELETE FROM Reservation
USING GuestReservation
WHERE Reservation.ReservationId = GuestReservation.ReservationId
  AND GuestReservation.GuestId = 3;

-- Step 3: Delete from GuestReservation
DELETE FROM GuestReservation
WHERE GuestId = 3;

-- Step 4: Delete from Guest
DELETE FROM Guest
WHERE GuestId = 3;

------ Method 4: Use a Temporary Table (if no CTEs)

-- Step 1: Save ReservationIds into a temp table
CREATE TEMP TABLE temp_res_ids AS
SELECT ReservationId
FROM GuestReservation
WHERE GuestId = 3;

-- Step 2: Delete from RoomReservation
DELETE FROM RoomReservation
WHERE ReservationId IN (SELECT ReservationId FROM temp_res_ids);

-- Step 3: Delete from GuestReservation
DELETE FROM GuestReservation
WHERE GuestId = 3;

-- Step 4: Delete from Reservation
DELETE FROM Reservation
WHERE ReservationId IN (SELECT ReservationId FROM temp_res_ids);

-- Step 5: Delete from Guest
DELETE FROM Guest
WHERE GuestId = 3;

-- Drop the temp table
DROP TABLE temp_res_ids;
