CREATE TABLE Room (
    RoomNumber     INT PRIMARY KEY,
    RoomType       VARCHAR(10) NOT NULL,
    IsADA          BOOLEAN NOT NULL,
    StandardOccupancy  INT NOT NULL,
    MaximumOccupancy   INT NOT NULL,
    BasePrice      DECIMAL(7, 2) NOT NULL,
    ExtraPerson    DECIMAL(7, 2) NOT NULL,
    HasJacuzzi     BOOLEAN NOT NULL
);


CREATE TABLE Amenity (
    AmenityId SERIAL PRIMARY KEY,
    AmenityType VARCHAR(30)
);

-- Junction table for Room-Amenity many-to-many relationship
CREATE TABLE RoomAmenity (
    RoomNumber INT NOT NULL,
    AmenityId  INT NOT NULL,
    PRIMARY KEY (RoomNumber, AmenityId),
    FOREIGN KEY (RoomNumber) REFERENCES Room (RoomNumber),
    FOREIGN KEY (AmenityId)  REFERENCES Amenity (AmenityId)
);

-- Reservation table with auto-increment ID
CREATE TABLE Reservation (
    ReservationId SERIAL PRIMARY KEY,
    Adults     INT NOT NULL,
    Children   INT NOT NULL,
    CheckInDate  DATE,
    CheckOutDate DATE,
    Total      DECIMAL(10, 2) NOT NULL
);

-- Guest table with auto-increment ID
CREATE TABLE Guest (
    GuestId   SERIAL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName  VARCHAR(50) NOT NULL,
    Street    VARCHAR(100),
    City      VARCHAR(50),
    State     CHAR(2),
    Zip       CHAR(5),
    Phone     VARCHAR(14)
);

-- Junction table for Guest-Reservation many-to-many relationship
CREATE TABLE GuestReservation (
    GuestId       INT NOT NULL,
    ReservationId INT NOT NULL,
    PRIMARY KEY (GuestId, ReservationId),
    FOREIGN KEY (GuestId)       REFERENCES Guest (GuestId),
    FOREIGN KEY (ReservationId) REFERENCES Reservation (ReservationId)
);

-- Junction table for Room-Reservation many-to-many relationship
CREATE TABLE RoomReservation (
    RoomNumber    INT NOT NULL,
    ReservationId INT NOT NULL,
    PRIMARY KEY (RoomNumber, ReservationId),
    FOREIGN KEY (RoomNumber)    REFERENCES Room (RoomNumber),
    FOREIGN KEY (ReservationId) REFERENCES Reservation (ReservationId)
);


/* using nextval() instead of SERIAL for the three tables with Auto increment:

-- Create sequence for Amenity
CREATE SEQUENCE amenity_amenityid_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE Amenity (
  AmenityId INT PRIMARY KEY DEFAULT nextval('amenity_amenityid_seq'),
  AmenityType VARCHAR(30)
);

-- Create sequence for Reservation
CREATE SEQUENCE reservation_reservationid_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE Reservation (
  ReservationId INT PRIMARY KEY DEFAULT nextval('reservation_reservationid_seq'),
  Adults INT NOT NULL,
  Children INT NOT NULL,
  CheckInDate DATE,
  CheckOutDate DATE,
  Total DECIMAL(10,2) NOT NULL
);

-- Create sequence for Guest
CREATE SEQUENCE guest_guestid_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE Guest (
  GuestId INT PRIMARY KEY DEFAULT nextval('guest_guestid_seq'),
  FirstName VARCHAR(50) NOT NULL,
  LastName VARCHAR(50) NOT NULL,
  Street VARCHAR(100),
  City VARCHAR(50),
  State CHAR(2),
  Zip CHAR(5),
  Phone VARCHAR(14)
);

*/