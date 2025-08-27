
# Hotel Data Engineering and Analysis

A demonstration project showcasing data engineering and analysis practices using a hotel reservation database. It includes SQL scripts (schema, inserts, stored procedures), Python integration, ERD diagrams, and sample data workflows.

---
<br><br>

##  Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Usage Examples](#usage-examples)
- [Visuals](#visuals)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---
<br><br>


## Overview  
This project demonstrates core data engineering workflows with a realistic hotel reservation system:  
1. **Database schema design** using SQL  
2. **Sample data population** for testing  
3. **Stored procedures/business logic** in SQL  
4. **Python scripts** for automated data querying and ETL  
5. **ERD diagram** for visual schema understanding  

---
<br><br>


hotel-data-engineering-demo/
├── README.md
├── assets/
│   └── erd.png
├── sql/
│   ├── create_tables.sql
│   ├── insert_data.sql
│   └── stored_procedures.sql
├── python/
│   └── db_connect_and_query.py
├── data/
│   └── sample_data.csv (not yet needed, possible data dumps)
├── diagrams/
│   └── erd.png
└── docs/
    └── description.md (not yet needed)


---
<br><br>


##  Getting Started

### Prerequisites
- PostgreSQL (or your target DB)
- Python 3.x with appropriate DB driver (`psycopg2` or similar)
<br>
### Setup Steps
```bash
# 1. Create the database
createdb hotel_db

# 2. Load schema and data
psql -d hotel_db -f sql/create_tables.sql
psql -d hotel_db -f sql/insert_data.sql
psql -d hotel_db -f sql/stored_procedures.sql

# 3. Run Python demo
python3 python/db_connect_and_query.py
```
---

<br><br>

## Usage Examples

### SQL Example

```bash
SELECT r.RoomNumber,
       r.RoomType,
       COUNT(a.AmenityType) AS AmenityCount
FROM Room r
JOIN RoomAmenity ra ON r.RoomNumber = ra.RoomNumber
JOIN Amenity a ON ra.AmenityId = a.AmenityId
WHERE r.HasJacuzzi = TRUE
GROUP BY r.RoomNumber, r.RoomType;
```

<br>

### Python Example

```bash
from db_connect_and_query import run_query

query = "SELECT COUNT(*) FROM Room;"
total_rooms = run_query(query).fetchone()[0]
print("Total rooms available in the hotel:", total_rooms)
```

---
<br><br>


## Visuals
The ERD above visualizes the main tables and relationships in the hotel reservation system, including Room, Amenity, Guest, Reservation, and their junction tables.

placeholder for the ERD diagram

---
<br><br>


## Contributing

This repository is a personal showcase, so there's no external collaboration expected, but I will be very glad to have contributions or suggestions, feel free to:

Share feedback or improvements viapull requests or GitHub issues

---
<br><br>

## Contact
GitHub: RaminMdn

<br><br>
