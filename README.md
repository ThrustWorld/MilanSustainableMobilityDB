# Urban Sustainable Mobility Database System (Milan)

<div align="center">

[![RDBMS](https://img.shields.io/badge/RDBMS-MySQL%208.0-blue.svg)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-Academic%20Project-lightgrey.svg)]()

*Click below to switch language / Clicca sotto per cambiare lingua:*

</div>

---

<details open>
<summary>🇬🇧 <b>English Version (Click to collapse/expand)</b></summary>

<br>

Relational database system designed to model and manage the municipal green transport infrastructure for the City of Milan[cite: 1, 14]. The system handles docked bicycles, electric mobility fleets (cars and scooters), citizen subscription tiers, reservations, and urban cycling statistics[cite: 1, 14].

---

### 📖 Domain Entity Mapping

The database schema implements standard Italian domain naming conventions[cite: 10, 20]. The table below maps internal relational tables to their English business concepts:

| Italian Table | English Concept | Description |
| :--- | :--- | :--- |
| `RESIDENTE` | Resident / User | Registered citizens with Standard or Premium membership tiers[cite: 1, 14, 22]. |
| `MEZZO` | Base Vehicle | General vehicle superclass entity[cite: 15, 23]. |
| `BICICLETTA` | Bicycle | Docked traditional or pedal-assisted bikes[cite: 1, 14, 24]. |
| `VEICOLO_ELETTRICO` | Electric Vehicle | Fleet of e-scooters and electric cars[cite: 1, 14, 24, 25]. |
| `DEPOSITO` | Bike Hub / Depot | Physical stations with maximum bicycle capacities[cite: 1, 14, 23]. |
| `PUNTO_DI_NOLEGGIO` | EV Rental Station | Designated stations for electric vehicle pick-up and drop-off[cite: 1, 14, 23]. |
| `PRENOTAZIONE` | Reservation | Booking events linking a user to a vehicle with timestamps[cite: 1, 14, 25]. |
| `PISTA_CICLABILE` | Bike Lane | Urban cycle paths tracked by length and average slope[cite: 1, 14, 22]. |
| `STATISTICA` | Transit Record | Usage records tracking citizen transits on bike lanes[cite: 1, 14, 26]. |

---

### 🏛 Architecture & Data Modeling

#### 1. Conceptual E-R Model
Initial modeling with generalization hierarchies[cite: 8, 15]:
* General vehicle (`Mezzo`) specialized into `Bicicletta` and `Veicolo Elettrico`[cite: 15].
* `Veicolo Elettrico` specialized into `Scooter` and `Automobile`[cite: 15].
* `Residente` specialized into `Standard` and `Premium`[cite: 15].

![Conceptual E-R Diagram](docs/schema-er-concettuale.png)[cite: 8]

#### 2. Restructured E-R Model (Generalization Elimination)
To optimize physical schema performance and simplify joins, hierarchies were restructured[cite: 19]:
* **`Residente`**: Folded into parent entity[cite: 19]. A boolean flag `Abbonamento` discriminates between Standard and Premium accounts[cite: 19, 22].
* **`Veicolo Elettrico`**: Folded into parent entity[cite: 19]. A boolean flag `Tipo` discriminates between electric cars and scooters, keeping car-exclusive attributes conditionally nullable[cite: 17, 19, 24, 25].
* **`Mezzo`**: Preserved as a distinct parent table with $(1,1) \leftrightarrow (0,1)$ relationships[cite: 19]. Bicycles and electric vehicles follow incompatible operational logistics (docking depots vs. staffed rental stations) and keeping them distinct prevents structural null-bloat[cite: 1, 14, 19].

![Restructured E-R Diagram](docs/schema-er-ristrutturato.png)[cite: 9]

#### 3. Logical Relational Model
Mapping of primary keys, foreign keys, and referential constraints[cite: 11, 20]:

![Relational Model](docs/schema-relazionale.png)[cite: 11, 20]

---

### 🛡 Business Rules & Integrity Constraints

All domain rules are enforced directly at the schema level via DDL constraints[cite: 22, 23, 24, 25]:

* **Subscription Discount Coherence**: Standard accounts cannot have discounts, while Premium discounts must fall within $(0, 100]$[cite: 22]:
  ```sql
  CHECK ((Abbonamento = TRUE AND PercentualeScontoPremium BETWEEN 0 AND 100) OR 
         (Abbonamento = FALSE AND Percent
