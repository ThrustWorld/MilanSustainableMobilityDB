# Urban Sustainable Mobility Database (Milan)

*Click below to switch language / Clicca sotto per cambiare lingua:*

## 📌 Project Overview

Relational database designed to model and manage the shared urban green mobility infrastructure for the Municipality of Milan. The system handles docked bicycles (traditional and e-bikes), electric vehicle rental fleets (cars and scooters), citizen subscriptions, reservation tracking, and cycle route usage statistics.

## 📖 Domain Entity Mapping

The physical database implementation adopts Italian domain naming. Below is the mapping to the corresponding business concepts:

| 

| **Italian Table** | **English Concept** | **Description** | 
| `RESIDENTE` | Resident / User | Registered citizens with Standard or Premium membership tiers. | 
| `MEZZO` | Base Vehicle | General vehicle superclass entity. | 
| `BICICLETTA` | Bicycle | Docked bikes (traditional or pedal-assisted). | 
| `VEICOLO_ELETTRICO` | Electric Vehicle | Fleet of e-scooters and electric cars. | 
| `DEPOSITO` | Bike Hub / Depot | Physical stations with maximum bicycle capacities. | 
| `PUNTO_DI_NOLEGGIO` | EV Rental Station | Designated stations for electric vehicle pick-up and drop-off. | 
| `PRENOTAZIONE` | Reservation | Booking events linking a user to a vehicle with timestamps. | 
| `PISTA_CICLABILE` | Bike Lane | Urban cycle paths tracked by length and average slope. | 
| `STATISTICA` | Transit Record | Historical logs tracking citizen transits on bike lanes. | 

## 🏛 Conceptual & Logical Architecture

### 1. Conceptual E-R Model

Initial modeling with generalization hierarchies:

* Base vehicle (`Mezzo`) specialized into `Bicicletta` and `Veicolo Elettrico`.

* `Veicolo Elettrico` specialized into `Scooter` and `Automobile`.

* `Residente` specialized into `Standard` and `Premium`.

### 2. Restructured E-R Model (Generalization Elimination)

To optimize physical schema performance and avoid unnecessary joins:

* **`Residente`**: Merged upwards into the parent table. The boolean flag `Abbonamento` discriminates between Standard (`FALSE`) and Premium (`TRUE`) accounts.

* **`Veicolo Elettrico`**: Merged upwards into the parent table. The boolean flag `Tipo` discriminates between electric cars (`TRUE`) and scooters (`FALSE`), leaving car-exclusive attributes conditionally nullable.

* **`Mezzo`**: Preserved as a distinct parent table with $(1,1) \leftrightarrow (0,1)$ relationships. Bicycles and electric vehicles belong to incompatible operational logistics (depots vs. staffed rental hubs); keeping them physically distinct prevents structural null-bloat.

### 3. Logical Relational Model

Primary keys (underlined) and foreign key integrity constraints (arrows):

## 🛡 Business Rules & Integrity Constraints

* **Subscription Discount Coherence**: Standard accounts cannot have discounts, while Premium accounts must have a discount strictly between $0\%$ and $100\%$:

  ```
  CHECK ((Abbonamento = TRUE AND PercentualeScontoPremium BETWEEN 0 AND 100) OR 
         (Abbonamento = FALSE AND PercentualeScontoPremium IS NULL))
  
  ```

* **Vehicle Subtype Integrity**: Technical car attributes (seats, mileage) are strictly forbidden for scooters:

  ```
  CHECK ((Tipo = TRUE AND NumeroPostiOmologatiAutomobile > 0 AND ChilometriPercorsiAutomobile >= 0) OR 
         (Tipo = FALSE AND NumeroPostiOmologatiAutomobile IS NULL AND ChilometriPercorsiAutomobile IS NULL))
  
  ```

* **Depot Physical Capacity**: Bicycle counts cannot exceed maximum station capacity:

  ```
  CHECK (NumeroBiciclette BETWEEN 0 AND CapacitaMassima)
  
  ```

* **Rental Timing & Free Pricing**: Enforces `DataOraInizio < DataOraFine`. Bicycle reservations are free (`CostoComplessivo IS NULL`), whereas electric vehicle bookings require positive charges:

  ```
  CHECK ((CostoComplessivo IS NULL) OR (CostoComplessivo > 0))
  
  ```

* **Referential Cleanup Policies (`ON DELETE`)**:

  * `CASCADE` on `RESIDENTE`: User account deletion automatically purges associated bookings and transit records.

  * `NO ACTION` on `DEPOSITO` and `PUNTO_DI_NOLEGGIO`: Prevents accidental deletion of physical stations containing active vehicles.

## 📊 Analytical Queries Showcase

### 1. Top Spender on Electric Vehicles

Retrieves the resident(s) who accumulated the highest aggregate spending on electric vehicle rentals:

```
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

| **CodiceFiscaleResidente** | **TotalSpent** | 
| `VRDLGI90A01F205X` | 43.50 | 

### 2. Fleet Utilization per Electric Car

Computes the count of unique registered citizens who rented each electric car (including cars with zero bookings via `RIGHT JOIN`):

```
SELECT VE.CodiceMezzo, COUNT(DISTINCT PR.CodiceFiscaleResidente) AS DistinctUsers
FROM PRENOTAZIONE PR 
RIGHT JOIN VEICOLO_ELETTRICO VE ON PR.CodiceMezzo = VE.CodiceMezzo
WHERE VE.Tipo = TRUE
GROUP BY VE.CodiceMezzo;

```

### 3. Untapped High-Capacity Rental Stations

Identifies rental stations managing more than 30 vehicles that have never recorded a booking from a Premium subscriber:

```
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

## 🚀 Setup & Execution

1. Clone this repository:

   ```
   git clone https://github.com/<your-username>/milan-sustainable-mobility-db.git
   cd milan-sustainable-mobility-db
   
   ```

2. Build schema and populate test seed data:

   ```
   mysql -u root -p < sql/01_schema_e_popolamento.sql
   
   ```

3. Run analytical queries:

   ```
   mysql -u root -p progetto_basi_di_dati < sql/02_interrogazioni.sql
   
   ```

## 📌 Descrizione del Progetto

Progettazione concettuale, logica e fisica di una base di dati relazionale a supporto del servizio di mobilità sostenibile per il Comune di Milano. Il sistema gestisce il parco biciclette condivise (tradizionali e a pedalata assistita), i veicoli elettrici (scooter e automobili), i profili dei residenti con abbonamento agevolato, le prenotazioni e il monitoraggio delle piste ciclabili cittadine.

## 🏛 Architettura e Scelte di Progettazione

### 1. Schema E-R Concettuale

Nel modello iniziale sono state individuate tre gerarchie di generalizzazione:

* `Mezzo` specializzato in `Bicicletta` e `Veicolo Elettrico`.

* `Veicolo Elettrico` specializzato in `Scooter` e `Automobile`.

* `Residente` specializzato in `Standard` e `Premium`.

Per l'entità **Bicicletta** non è stata usata una generalizzazione poiché i modelli tradizionali e a pedalata assistita condividono i medesimi attributi; la distinzione è operata tramite l'attributo discriminatore booleano `Tipo`.

### 2. Ristrutturazione Schema E-R (Eliminazione Generalizzazioni)

* **Generalizzazione `Residente`**: Ristrutturata tramite **accorpamento delle figlie nel padre**. L'attributo discriminatore `Abbonamento` (`BOOLEAN`) definisce se il cliente è Premium, abilitando l'attributo `PercentualeScontoPremium`.

* **Generalizzazione `Veicolo Elettrico`**: Ristrutturata tramite **accorpamento delle figlie nel padre**. La discriminante `Tipo` (`TRUE = Automobile`, `FALSE = Scooter`) controlla la valorizzazione dei dati specifici delle auto.

* **Generalizzazione `Mezzo`**: Mantenuta tramite **relazioni esplicite 1:1** con vincolo di copertura esclusiva (cardinalità $(0,1)$ per il padre e $(1,1)$ per le figlie). La separazione fisica è necessaria perché biciclette e veicoli elettrici rispondono a modelli logistici incompatibili (depositi per biciclette vs punti noleggio veicoli).

### 3. Traduzione nel Modello Relazionale

Rappresentazione del modello logico con identificazione delle chiavi primarie (sottolineate) e delle chiavi esterne con frecce direzionali:

## 🛡 Vincoli di Integrità e Regole di Business

* **Coerenza Sconto Residenti**: Un utente Standard non può avere sconti; un utente Premium deve avere un valore compreso tra 0 e 100:

  ```
  CHECK ((Abbonamento = TRUE AND PercentualeScontoPremium BETWEEN 0 AND 100) OR 
         (Abbonamento = FALSE AND PercentualeScontoPremium IS NULL))
  
  ```

* **Consistenza Parco Auto**: Posti omologati e chilometraggio sono consentiti e obbligatori solo per le automobili (`Tipo = TRUE`):

  ```
  CHECK ((Tipo = TRUE AND NumeroPostiOmologatiAutomobile > 0 AND ChilometriPercorsiAutomobile >= 0) OR 
         (Tipo = FALSE AND NumeroPostiOmologatiAutomobile IS NULL AND ChilometriPercorsiAutomobile IS NULL))
  
  ```

* **Capacità Massima Depositi**: Il numero di bici presenti non può eccedere la capienza autorizzata del deposito:

  ```
  CHECK (NumeroBiciclette BETWEEN 0 AND CapacitaMassima)
  
  ```

* **Date e Gratuità Noleggi**: La data/ora di inizio deve precedere il termine. Per policy le biciclette sono gratuite (`CostoComplessivo IS NULL`), mentre per i veicoli a motore il costo deve essere maggiore di zero:

  ```
  CHECK (DataOraInizio < DataOraFine),
  CHECK ((CostoComplessivo IS NULL) OR (CostoComplessivo > 0))
  
  ```

* **Politiche di Cancellazione (`ON DELETE`)**:

  * `CASCADE` su `RESIDENTE`: Rimuovendo un cittadino, le relative prenotazioni e statistiche d'uso vengono eliminate a cascata per garantire la consistenza.

  * `NO ACTION` su `DEPOSITO` e `PUNTO_DI_NOLEGGIO`: Impedisce la cancellazione di stazioni fisiche qualora vi siano ancora mezzi o biciclette ad esse assegnati.

## 📊 Interrogazioni SQL di Esempio

### 1. Residente con Spesa Massima per Veicoli Elettrici

Calcola la spesa totale per residente sui veicoli elettrici ed estrae il massimo tramite il quantificatore universale `>= ALL`:

```
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

| **CodiceFiscaleResidente** | **SpesaTotale** | 
| `VRDLGI90A01F205X` | 43.50 | 

### 2. Residenti Fedeli allo Stesso Punto di Noleggio

Estrae i residenti che hanno effettuato prenotazioni di veicoli elettrici sempre e solo dal medesimo punto di noleggio:

```
SELECT PR.CodiceFiscaleResidente
FROM PRENOTAZIONE PR 
JOIN VEICOLO_ELETTRICO VE ON PR.CodiceMezzo = VE.CodiceMezzo
GROUP BY PR.CodiceFiscaleResidente
HAVING COUNT(DISTINCT VE.CodicePuntoNoleggio) = 1;

```

**Risultato:**

* `CNTNTN80P10F205N`

* `RSSMRA85M01H501Z`

### 3. Punti di Noleggio ad Alta Capacità Senza Utenza Premium

Identifica i punti di noleggio con oltre 30 veicoli in cui non è mai avvenuta una prenotazione da parte di residenti con abbonamento premium:

```
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

## 🚀 Istruzioni per l'Esecuzione

1. Clonare la repository locale:

   ```
   git clone https://github.com/<your-username>/milan-sustainable-mobility-db.git
   cd milan-sustainable-mobility-db
   
   ```

2. Creare e popolare il database in MySQL:

   ```
   mysql -u root -p < sql/01_schema_e_popolamento.sql
   
   ```

3. Eseguire le interrogazioni analitiche:

   ```
   mysql -u root -p progetto_basi_di_dati < sql/02_interrogazioni.sql
   
   ```
