# Urban Sustainable Mobility Database (Milan)

<div align="center">

[![RDBMS](https://img.shields.io/badge/RDBMS-MySQL%208.0-blue.svg)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-Academic%20Project-lightgrey.svg)]()

<br>

**Click below to switch language / Clicca sotto per cambiare lingua:**

</div>

---

<details open>
<summary>🇬🇧 <b>English Version (Click to collapse/expand)</b></summary>

<br>

## 📌 Project Overview

Relational database system designed to model and manage the shared urban green mobility infrastructure for the Municipality of Milan (*Comune di Milano*). The system coordinates docked municipal bicycles (both traditional and pedal-assisted), electric vehicle rental fleets (cars and scooters), citizen subscription tiers, reservation lifecycles, and cycle route usage statistics.

---

## 📖 Domain Entity Mapping

The physical database schema implements standard Italian domain naming. The table below maps internal relational tables to their English business concepts:

| Italian Table | English Concept | Description |
| :--- | :--- | :--- |
| `RESIDENTE` | Resident / User | Registered Milan citizens holding Standard or Premium accounts. |
| `MEZZO` | Base Vehicle | General vehicle superclass entity providing unique vehicle identification. |
| `BICICLETTA` | Bicycle | Docked bicycles categorized as traditional or pedal-assisted. |
| `VEICOLO_ELETTRICO` | Electric Vehicle | Motorized fleet subdivided into e-scooters and electric cars. |
| `DEPOSITO` | Bike Hub / Depot | Physical stations across Milan with maximum bicycle capacities. |
| `PUNTO_DI_NOLEGGIO` | EV Rental Station | Dedicated rental hubs where electric vehicles are stationed and managed. |
| `PRENOTAZIONE` | Reservation | Booking records linking a user to a vehicle with start/end timestamps. |
| `PISTA_CICLABILE` | Cycle Path / Bike Lane | Milan bike tracks monitored by ID, length, and average slope. |
| `STATISTICA` | Transit Record | Historical logs tracking resident transit frequency across cycle paths. |

---

## 🏛 Conceptual & Logical Architecture

### 1. Conceptual E-R Model
The initial conceptual schema established three key generalization hierarchies ($ISA$):
* Base vehicle (`Mezzo`) specialized into `Bicicletta` and `Veicolo Elettrico`.
* `Veicolo Elettrico` specialized into `Scooter` and `Automobile`.
* `Residente` specialized into `Standard` and `Premium`.

> **Design Choice on Bicycles**: The `Bicicletta` entity does not require an $ISA$ generalization because traditional and pedal-assisted bicycles share identical attributes (brand, color, depot). The distinction is handled via a boolean discriminator `Tipo`.

![Conceptual E-R Diagram](Docs/Schema_ER.png)

### 2. Restructured E-R Model (Generalization Elimination)
To optimize physical schema performance and avoid expensive joins:
* **`Residente`**: Folded upwards into the parent table `RESIDENTE`. A boolean flag `Abbonamento` discriminates between Standard (`FALSE`) and Premium (`TRUE`) users, controlling the conditional discount attribute `PercentualeScontoPremium`.
* **`Veicolo Elettrico`**: Folded upwards into `VEICOLO_ELETTRICO`. The boolean flag `Tipo` discriminates between cars (`TRUE`) and scooters (`FALSE`), regulating car-exclusive metrics (`ChilometriPercorsiAutomobile`, `NumeroPostiOmologatiAutomobile`).
* **`Mezzo`**: Preserved as a distinct parent table with $(1,1) \leftrightarrow (0,1)$ relationships. Bicycles and electric vehicles belong to incompatible operational logistics (automated docking depots vs. staffed rental stations); keeping them physically distinct prevents structural null-bloat and preserves referential integrity.

![Restructured E-R Diagram](Docs/Schema_ER_ristrutturato.png)

### 3. Logical Relational Model
Primary keys are underlined; referential constraints are maintained across relations:

* `MEZZO` (<u>CodiceMezzo</u>)
* `BICICLETTA` (<u>CodiceMezzo</u>, Marca, Colore, Tipo, CodiceDeposito)
* `VEICOLO_ELETTRICO` (<u>CodiceMezzo</u>, Targa, Nome, Modello, CostoNoleggio, Cilindrata, Autonomia, Tipo, ChilometriPercorsiAutomobile, NumeroPostiOmologatiAutomobile, CodicePuntoNoleggio)
* `DEPOSITO` (<u>CodiceDeposito</u>, NumeroBiciclette, CapacitaMassima, Via, NumeroCivico, CAP, Latitudine, Longitudine)
* `PUNTO_DI_NOLEGGIO` (<u>CodicePuntoNoleggio</u>, Nome, Email, SitoWeb, NumeroDiTelefono, Via, NumeroCivico, CAP)
* `PRENOTAZIONE` (<u>CodicePrenotazione</u>, <u>CodiceFiscaleResidente</u>, DataOraInizio, DataOraFine, CostoComplessivo, CodiceMezzo)
* `RESIDENTE` (<u>CodiceFiscale</u>, Nome, Cognome, NumeroDiTelefono, Via, NumeroCivico, CAP, Email, Password, Abbonamento, PercentualeScontoPremium)
* `STATISTICA` (<u>Data</u>, <u>CodiceFiscaleResidente</u>, <u>NumeroProgressivoPistaCiclabile</u>, NumeroVoltePercorso)
* `PISTA_CICLABILE` (<u>NumeroProgressivo</u>, Lunghezza, PendenzaMedia)

![Relational Model](Docs/Traduzione_modello_relazionale.png)
![Relational Model_2](Docs/Traduzione_modello_relazionale_2.png)

---

## 🛡 Business Rules & Integrity Constraints

* **Subscription Discount Coherence**: Standard accounts cannot have discounts, while Premium accounts must have a discount strictly between $0\%$ and $100\%$:
  ```sql
  CHECK ((Abbonamento = TRUE AND PercentualeScontoPremium BETWEEN 0 AND 100) OR 
         (Abbonamento = FALSE AND PercentualeScontoPremium IS NULL))
  ```

* **Vehicle Subtype Integrity**: Technical car attributes (seats, mileage) are strictly forbidden for scooters:
  ```sql
  CHECK ((Tipo = TRUE AND NumeroPostiOmologatiAutomobile > 0 AND ChilometriPercorsiAutomobile >= 0) OR 
         (Tipo = FALSE AND NumeroPostiOmologatiAutomobile IS NULL AND ChilometriPercorsiAutomobile IS NULL))
  ```

* **Depot Physical Capacity**: Bicycle counts cannot exceed maximum station capacity, and capacity must be positive:
  ```sql
  CapacitaMassima INTEGER NOT NULL CHECK (CapacitaMassima > 0),
  CHECK (NumeroBiciclette BETWEEN 0 AND CapacitaMassima)
  ```

* **Rental Timing & Free Pricing**: Enforces chronological coherence (`DataOraInizio < DataOraFine`). Bicycle reservations are free (`CostoComplessivo IS NULL`), whereas electric vehicle bookings require positive charges:
  ```sql
  CHECK (DataOraInizio < DataOraFine),
  CHECK ((CostoComplessivo IS NULL) OR (CostoComplessivo > 0))
  ```

* **Referential Cleanup Policies (`ON DELETE`)**:
  * `CASCADE` on `RESIDENTE`: User account deletion automatically purges associated bookings and transit records.
  * `NO ACTION` on `DEPOSITO` and `PUNTO_DI_NOLEGGIO`: Prevents accidental deletion of physical stations containing active vehicles.

---

## 📊 Analytical Queries Showcase

### 1. Pedal-Assisted Bikes Booked by Premium Users
Finds all pedal-assisted bicycles (`Tipo = TRUE`) reserved by registered Premium citizens:
```sql
SELECT DISTINCT B.CodiceMezzo
FROM BICICLETTA B 
JOIN PRENOTAZIONE PR ON B.CodiceMezzo = PR.CodiceMezzo 
JOIN RESIDENTE R ON PR.CodiceFiscaleResidente = R.CodiceFiscale
WHERE B.Tipo = TRUE AND R.Abbonamento = TRUE;
```
**Output:**
| CodiceMezzo |
| :--- |
| `2` |
| `4` |

---

### 2. Top Spender on Electric Vehicles
Retrieves the resident(s) who accumulated the highest aggregate spending on electric vehicle rentals using the universal quantifier `>= ALL`:
```sql
SELECT PR1.CodiceFiscaleResidente, SUM(PR1.CostoComplessivo) AS TotalSpent
FROM PRENOTAZIONE PR1 
JOIN VEICOLO_ELETTRICO VE1 ON PR1.CodiceMezzo = VE1.CodiceMezzo 
GROUP BY PR1.CodiceFiscaleResidente
HAVING SUM(PR1.CostoComplessivo) >= ALL (
    SELECT SUM(PR2.CostoComplessivo)
    FROM PRENOTAZIONE PR2 
    JOIN VEICOLO_ELETTRICO VE2 ON PR2.CodiceMezzo = VE2.CodiceMezzo
    GROUP BY PR2.CodiceFiscaleResidente
);
```
**Output:**
| CodiceFiscaleResidente | TotalSpent |
| :--- | :--- |
| `VRDLGI90A01F205X` | 43.50 |

---

### 3. Fleet Utilization per Electric Car
Computes the count of unique registered citizens who rented each electric car (`Tipo = TRUE`), including vehicles with zero bookings via `RIGHT JOIN`:
```sql
SELECT VE.CodiceMezzo, COUNT(DISTINCT PR.CodiceFiscaleResidente) AS DistinctUsers
FROM PRENOTAZIONE PR 
RIGHT JOIN VEICOLO_ELETTRICO VE ON PR.CodiceMezzo = VE.CodiceMezzo
WHERE VE.Tipo = TRUE
GROUP BY VE.CodiceMezzo;
```
**Output Excerpt:**
| CodiceMezzo | DistinctUsers |
| :--- | :--- |
| `11` | 1 |
| `12` | 1 |
| `13` | 1 |
| `14` | 1 |
| `15` | 1 |
| `21` | 1 |
| `22` | 1 |
| `23`–`30`, `41`–`43`, `49`–`50` | 0 |

---

### 4. Residents Loyal to a Single Rental Hub
Identifies citizens who booked electric vehicles exclusively from one single rental station:
```sql
SELECT PR.CodiceFiscaleResidente
FROM PRENOTAZIONE PR 
JOIN VEICOLO_ELETTRICO VE ON PR.CodiceMezzo = VE.CodiceMezzo
GROUP BY PR.CodiceFiscaleResidente
HAVING COUNT(DISTINCT VE.CodicePuntoNoleggio) = 1;
```
**Output:**
* `CNTNTN80P10F205N`
* `RSSMRA85M01H501Z`

---

### 5. High-Capacity Rental Stations Without Premium Bookings
Identifies stations managing more than 30 vehicles that have never recorded a booking from a Premium subscriber:
```sql
SELECT PG.CodicePuntoNoleggio
FROM PUNTO_DI_NOLEGGIO PG 
JOIN VEICOLO_ELETTRICO VE1 ON PG.CodicePuntoNoleggio = VE1.CodicePuntoNoleggio
WHERE PG.CodicePuntoNoleggio NOT IN (
    SELECT VE2.CodicePuntoNoleggio
    FROM VEICOLO_ELETTRICO VE2 
    JOIN PRENOTAZIONE PR ON VE2.CodiceMezzo = PR.CodiceMezzo
    JOIN RESIDENTE R ON PR.CodiceFiscaleResidente = R.CodiceFiscale
    WHERE R.Abbonamento = TRUE
)
GROUP BY PG.CodicePuntoNoleggio
HAVING COUNT(DISTINCT VE1.CodiceMezzo) > 30;
```
**Output:** Empty set (all high-capacity stations had at least one booking by a premium user).

---

## 🚀 Setup & Execution

1. Clone this repository:
   ```bash
   git clone https://github.com/<your-username>/milan-sustainable-mobility-db.git
   cd milan-sustainable-mobility-db
   ```
2. Build schema and populate test seed data:
   ```bash
   mysql -u root -p < sql/01_schema_e_popolamento.sql
   ```
3. Run analytical queries:
   ```bash
   mysql -u root -p progetto_basi_di_dati < sql/02_interrogazioni.sql
   ```

</details>

<details>
<summary>🇮🇹 <b>Versione Italiana (Clicca per espandere/comprimere)</b></summary>

<br>

## 📌 Descrizione del Progetto

Progettazione concettuale, logica e fisica di una base di dati relazionale a supporto del servizio di mobilità sostenibile promosso dal **Comune di Milano**. 

Il sistema gestisce il parco biciclette condivise (tradizionali e a pedalata assistita), la flotta di veicoli elettrici a noleggio (scooter e automobili), i profili dei residenti con relative fasce di abbonamento agevolato, le prenotazioni e il monitoraggio statistico dei transiti sulle piste ciclabili cittadine.

---

## 🏛 Architettura e Scelte di Progettazione

### 1. Schema E-R Concettuale (con Generalizzazioni)
Durante la prima fase di modellazione sono state formalizzate tre gerarchie di generalizzazione ($ISA$):
* `Mezzo` (Padre) specializzato nelle figlie `Bicicletta` e `Veicolo Elettrico`.
* `Veicolo Elettrico` (Padre) specializzato nelle figlie `Scooter` e `Automobile`.
* `Residente` (Padre) specializzato nelle figlie `Standard` e `Premium`.

> **Nota su `Bicicletta`**: Per l'entità bicicletta non è stata introdotta una generalizzazione formale in quanto i modelli tradizionali e a pedalata assistita condividono i medesimi attributi (marca, colore, deposito). La distinzione è mantenuta in modo pulito tramite l'attributo discriminatore booleano `Tipo`.

![Schema E-R Concettuale](Docs/Schema_ER.png)

### 2. Ristrutturazione Schema E-R (Eliminazione Generalizzazioni)
Per ottimizzare le prestazioni fisiche su DBMS ed evitare operazioni di join ridondanti:
* **Generalizzazione `Residente`** $\to$ **Accorpamento delle figlie nel padre**: Le due tipologie di utente condividono l'anagrafica e i contatti. Confluiscono nella tabella padre `RESIDENTE` con l'attributo discriminatore `Abbonamento` (`BOOLEAN`: `TRUE = Premium`, `FALSE = Standard`) e l'attributo condizionato `PercentualeScontoPremium`.
* **Generalizzazione `Veicolo Elettrico`** $\to$ **Accorpamento delle figlie nel padre**: Scooter e automobili confluiscono in `VEICOLO_ELETTRICO`. La discriminante `Tipo` (`TRUE = Automobile`, `FALSE = Scooter`) regola la valorizzazione obbligatoria dei dati esclusivi delle auto (`NumeroPostiOmologatiAutomobile`, `ChilometriPercorsiAutomobile`).
* **Generalizzazione `Mezzo`** $\to$ **Mantenimento delle entità con relazioni (1,1) - (0,1)**: L'entità padre `MEZZO` è mantenuta separata e collegata alle figlie `BICICLETTA` e `VEICOLO_ELETTRICO`. Dal lato delle figlie la cardinalità è $(1,1)$, mentre dal lato padre è $(0,1)$ poiché la copertura è esclusiva (un mezzo non può essere contemporaneamente sia bicicletta che auto/scooter). La separazione fisica è necessaria perché le due categorie rispondono a modelli logistici incompatibili (depositi automatizzati per biciclette vs stazioni presidiate per veicoli a motore).

![Schema E-R Ristrutturato](Docs/Schema_ER_ristrutturato.png)

### 3. Traduzione nel Modello Relazionale
Rappresentazione del modello logico con identificazione delle chiavi primarie (sottolineate) e delle chiavi esterne:

* `MEZZO` (<u>CodiceMezzo</u>)
* `BICICLETTA` (<u>CodiceMezzo</u>, Marca, Colore, Tipo, CodiceDeposito)
* `VEICOLO_ELETTRICO` (<u>CodiceMezzo</u>, Targa, Nome, Modello, CostoNoleggio, Cilindrata, Autonomia, Tipo, ChilometriPercorsiAutomobile, NumeroPostiOmologatiAutomobile, CodicePuntoNoleggio)
* `DEPOSITO` (<u>CodiceDeposito</u>, NumeroBiciclette, CapacitaMassima, Via, NumeroCivico, CAP, Latitudine, Longitudine)
* `PUNTO_DI_NOLEGGIO` (<u>CodicePuntoNoleggio</u>, Nome, Email, SitoWeb, NumeroDiTelefono, Via, NumeroCivico, CAP)
* `PRENOTAZIONE` (<u>CodicePrenotazione</u>, <u>CodiceFiscaleResidente</u>, DataOraInizio, DataOraFine, CostoComplessivo, CodiceMezzo)
* `RESIDENTE` (<u>CodiceFiscale</u>, Nome, Cognome, NumeroDiTelefono, Via, NumeroCivico, CAP, Email, Password, Abbonamento, PercentualeScontoPremium)
* `STATISTICA` (<u>Data</u>, <u>CodiceFiscaleResidente</u>, <u>NumeroProgressivoPistaCiclabile</u>, NumeroVoltePercorso)
* `PISTA_CICLABILE` (<u>NumeroProgressivo</u>, Lunghezza, PendenzaMedia)

![Modello Relazionale](Docs/Traduzione_modello_relazionale.png)
![Modello Relazionale_2](Docs/Traduzione_modello_relazionale_2.png)

---

## 🛡 Vincoli di Integrità e Regole di Business

Tutti i requisiti operativi sono formalizzati tramite vincoli SQL espliciti nel DDL:

* **Coerenza Sconto Residenti**: Un utente Standard non può avere percentuali di sconto; un utente Premium deve avere un valore compreso tra 0 e 100:
  ```sql
  CHECK ((Abbonamento = TRUE AND PercentualeScontoPremium BETWEEN 0 AND 100) OR 
         (Abbonamento = FALSE AND PercentualeScontoPremium IS NULL))
  ```

* **Consistenza Parco Auto**: Posti omologati e chilometraggio sono consentiti e obbligatori solo per le automobili (`Tipo = TRUE`):
  ```sql
  CHECK ((Tipo = TRUE AND NumeroPostiOmologatiAutomobile > 0 AND ChilometriPercorsiAutomobile >= 0) OR 
         (Tipo = FALSE AND NumeroPostiOmologatiAutomobile IS NULL AND ChilometriPercorsiAutomobile IS NULL))
  ```

* **Capacità Massima Depositi**: Il conteggio delle biciclette presenti non può eccedere la capienza massima autorizzata del deposito:
  ```sql
  CapacitaMassima INTEGER NOT NULL CHECK (CapacitaMassima > 0),
  CHECK (NumeroBiciclette BETWEEN 0 AND CapacitaMassima)
  ```

* **Date e Gratuità Noleggi**: La data/ora di inizio deve precedere il termine. Per policy le biciclette sono a fruizione gratuita (`CostoComplessivo IS NULL`), mentre per i veicoli a motore il costo deve essere maggiore di zero:
  ```sql
  CHECK (DataOraInizio < DataOraFine),
  CHECK ((CostoComplessivo IS NULL) OR (CostoComplessivo > 0))
  ```

* **Politiche Referenziali (`ON DELETE`)**:
  * `CASCADE` su `RESIDENTE`: Rimuovendo un cittadino, le relative prenotazioni e statistiche d'uso vengono eliminate a cascata per garantire la consistenza referenziale.
  * `NO ACTION` su `DEPOSITO` e `PUNTO_DI_NOLEGGIO`: Impedisce l'eliminazione fisica di stazioni o depositi qualora vi siano ancora mezzi o biciclette ad essi assegnati.

---

## 📊 Interrogazioni SQL di Esempio

### 1. Bici a Pedalata Assistita Prenotate da Utenti Premium
Estrae tutte le biciclette a pedalata assistita (`Tipo = TRUE`) prenotate da residenti con abbonamento Premium:
```sql
SELECT DISTINCT B.CodiceMezzo
FROM BICICLETTA B 
JOIN PRENOTAZIONE PR ON B.CodiceMezzo = PR.CodiceMezzo 
JOIN RESIDENTE R ON PR.CodiceFiscaleResidente = R.CodiceFiscale
WHERE B.Tipo = TRUE AND R.Abbonamento = TRUE;
```
**Risultato:**
| CodiceMezzo |
| :--- |
| `2` |
| `4` |

---

### 2. Residente con Spesa Massima per Veicoli Elettrici
Calcola la spesa totale per residente sui veicoli elettrici ed estrae il massimo tramite il quantificatore universale `>= ALL`:
```sql
SELECT PR1.CodiceFiscaleResidente, SUM(PR1.CostoComplessivo) AS SpesaTotale
FROM PRENOTAZIONE PR1 
JOIN VEICOLO_ELETTRICO VE1 ON PR1.CodiceMezzo = VE1.CodiceMezzo 
GROUP BY PR1.CodiceFiscaleResidente
HAVING SUM(PR1.CostoComplessivo) >= ALL (
    SELECT SUM(PR2.CostoComplessivo)
    FROM PRENOTAZIONE PR2 
    JOIN VEICOLO_ELETTRICO VE2 ON PR2.CodiceMezzo = VE2.CodiceMezzo
    GROUP BY PR2.CodiceFiscaleResidente
);
```
**Risultato:**
| CodiceFiscaleResidente | SpesaTotale |
| :--- | :--- |
| `VRDLGI90A01F205X` | 43.50 |

---

### 3. Numero di Utenti Distinti per Automobile Elettrica
Visualizza per ciascuna automobile elettrica (`Tipo = TRUE`) il numero di utenti distinti che l'hanno prenotata, includendo le auto a zero noleggi tramite `RIGHT JOIN`:
```sql
SELECT VE.CodiceMezzo, COUNT(DISTINCT PR.CodiceFiscaleResidente) AS UtentiDistinti
FROM PRENOTAZIONE PR 
RIGHT JOIN VEICOLO_ELETTRICO VE ON PR.CodiceMezzo = VE.CodiceMezzo
WHERE VE.Tipo = TRUE
GROUP BY VE.CodiceMezzo;
```
**Estratto del Risultato:**
| CodiceMezzo | UtentiDistinti |
| :--- | :--- |
| `11` | 1 |
| `12` | 1 |
| `13` | 1 |
| `14` | 1 |
| `15` | 1 |
| `21` | 1 |
| `22` | 1 |
| `23`–`30`, `41`–`43`, `49`–`50` | 0 |

---

### 4. Residenti Fedeli allo Stesso Punto di Noleggio
Identifica i residenti che hanno effettuato prenotazioni di veicoli elettrici sempre e solo dal medesimo punto di noleggio:
```sql
SELECT PR.CodiceFiscaleResidente
FROM PRENOTAZIONE PR 
JOIN VEICOLO_ELETTRICO VE ON PR.CodiceMezzo = VE.CodiceMezzo
GROUP BY PR.CodiceFiscaleResidente
HAVING COUNT(DISTINCT VE.CodicePuntoNoleggio) = 1;
```
**Risultato:**
* `CNTNTN80P10F205N`
* `RSSMRA85M01H501Z`

---

### 5. Punti di Noleggio ad Alta Capacità Senza Utenza Premium
Identifica i punti di noleggio con oltre 30 veicoli in cui non è mai avvenuta una prenotazione da parte di residenti premium:
```sql
SELECT PG.CodicePuntoNoleggio
FROM PUNTO_DI_NOLEGGIO PG 
JOIN VEICOLO_ELETTRICO VE1 ON PG.CodicePuntoNoleggio = VE1.CodicePuntoNoleggio
WHERE PG.CodicePuntoNoleggio NOT IN (
    SELECT VE2.CodicePuntoNoleggio
    FROM VEICOLO_ELETTRICO VE2 
    JOIN PRENOTAZIONE PR ON VE2.CodiceMezzo = PR.CodiceMezzo
    JOIN RESIDENTE R ON PR.CodiceFiscaleResidente = R.CodiceFiscale
    WHERE R.Abbonamento = TRUE
)
GROUP BY PG.CodicePuntoNoleggio
HAVING COUNT(DISTINCT VE1.CodiceMezzo) > 30;
```
**Risultato:** Insieme vuoto (tutti i centri ad alta capacità hanno registrato almeno una prenotazione da utenti premium).

---

## 🚀 Istruzioni per l'Esecuzione

1. Clonare la repository locale:
   ```bash
   git clone https://github.com/<your-username>/milan-sustainable-mobility-db.git
   cd milan-sustainable-mobility-db
   ```
2. Creare e popolare il database in MySQL:
   ```bash
   mysql -u root -p < sql/01_schema_e_popolamento.sql
   ```
3. Eseguire le interrogazioni analitiche:
   ```bash
   mysql -u root -p progetto_basi_di_dati < sql/02_interrogazioni.sql
   ```

</details>
