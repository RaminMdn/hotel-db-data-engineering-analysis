/* 1. Add a New Reservation with Rooms and Guests

Purpose: Insert a reservation and automatically link it with one or more rooms and guests. */

CREATE OR REPLACE PROCEDURE add_reservation(
  p_adults INT,
  p_children INT,
  p_checkin DATE,
  p_checkout DATE,
  p_total DECIMAL(10,2),
  p_room_numbers INT[],
  p_guest_ids INT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_resid INT;
BEGIN
  -- Insert into Reservation
  INSERT INTO Reservation (Adults, Children, CheckInDate, CheckOutDate, Total)
  VALUES (p_adults, p_children, p_checkin, p_checkout, p_total)
  RETURNING ReservationId INTO v_resid;

  -- Link rooms
  FOREACH rn IN ARRAY p_room_numbers LOOP
    INSERT INTO RoomReservation (RoomNumber, ReservationId) VALUES (rn, v_resid);
  END LOOP;

  -- Link guests
  FOREACH gid IN ARRAY p_guest_ids LOOP
    INSERT INTO GuestReservation (GuestId, ReservationId) VALUES (gid, v_resid);
  END LOOP;

  RAISE NOTICE 'Created reservation ID % with % rooms and % guests', v_resid, array_length(p_room_numbers,1), array_length(p_guest_ids,1);
END;
$$;


/* Why it’s practical: Packages multiple steps—reservation creation, linking rooms and guests—into one reusable unit. This mirrors typical transaction workflows in booking systems.

2. Check Room Availability Between Dates

Purpose: Determine if a specific room is available between two dates (no overlapping reservations).*/

CREATE OR REPLACE PROCEDURE check_room_availability(
  p_room_number INT,
  p_start DATE,
  p_end DATE,
  OUT available BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
  conflict_count INT;
BEGIN
  SELECT COUNT(*) INTO conflict_count
  FROM RoomReservation rr
  JOIN Reservation r ON r.ReservationId = rr.ReservationId
  WHERE rr.RoomNumber = p_room_number
    AND NOT (r.CheckOutDate <= p_start OR r.CheckInDate >= p_end);

  available := (conflict_count = 0);
END;
$$;


-- Usage:

CALL check_room_availability(101, '2025‑09‑01', '2025‑09‑05', NULL);


-- Why it’s useful: Availability checking is a core requirement in any reservation system—encapsulating this logic ensures consistency and reusability.

/* 3. Get Total Spending for a Guest

Purpose: Calculate a guest’s total expenditure across all reservations.*/

CREATE OR REPLACE PROCEDURE guest_total_spent(
  p_guest_id INT,
  OUT total_spent DECIMAL(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT COALESCE(SUM(r.Total), 0) INTO total_spent
  FROM GuestReservation gr
  JOIN Reservation r ON r.ReservationId = gr.ReservationId
  WHERE gr.GuestId = p_guest_id;

  RAISE NOTICE 'Guest ID % has spent total %', p_guest_id, total_spent;
END;
$$;


-- Why it’s helpful: Useful for loyalty programs, analytics, or giving staff quick access to guest spend history.

/* 4. List ADA Rooms with a Specific Amenity

Purpose: Find ADA-compliant rooms offering a given amenity.*/

CREATE OR REPLACE PROCEDURE ada_rooms_with_amenity(
  p_amenity_type VARCHAR,
  OUT room_numbers INT[]
)
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT ARRAY_AGG(r.RoomNumber) INTO room_numbers
  FROM Room r
  JOIN RoomAmenity ra ON ra.RoomNumber = r.RoomNumber
  JOIN Amenity a ON a.AmenityId = ra.AmenityId
  WHERE r.IsADA = TRUE
    AND a.AmenityType = p_amenity_type;

  RAISE NOTICE 'ADA rooms with %: %', p_amenity_type, room_numbers;
END;
$$;


-- Why it’s relevant: Fast retrieval of rooms with specific accessibility features is critical for some bookings and compliance reasons.

/* 5. Compute Average Room Rate across a Date Range

Purpose: Calculate the average nightly rate (BasePrice + ExtraPerson) for rooms booked in a specific period.*/

CREATE OR REPLACE PROCEDURE average_rate_in_period(
  p_start DATE,
  p_end DATE,
  OUT avg_rate DECIMAL(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT AVG(rm.BasePrice + rm.ExtraPerson) INTO avg_rate
  FROM Room r
  JOIN RoomReservation rr ON rr.RoomNumber = r.RoomNumber
  JOIN Reservation res ON res.ReservationId = rr.ReservationId
  WHERE res.CheckInDate >= p_start
    AND res.CheckOutDate <= p_end;

  RAISE NOTICE 'Average rate between % and %: %', p_start, p_end, avg_rate;
END;
$$;


-- Why it’s practical: Supports business intelligence—helpful for seasonal pricing, revenue trends, or performance review.