-- [ENG] DATABASE DEFINITION (TABLES, INTEGRITY CONSTRAINTS) | [IT] DEFINIZIONE DEL DATABASE (TABELLE, VINCOLI DI INTEGRITA')

CREATE TABLE RESIDENTE
(
	CodiceFiscale CHAR(16) PRIMARY KEY,
	Nome VARCHAR(50) NOT NULL,
	Cognome VARCHAR(50) NOT NULL,
	NumeroDiTelefono VARCHAR(20),
	Via VARCHAR(50) NOT NULL,
	NumeroCivico VARCHAR(10) NOT NULL,
	CAP VARCHAR(10) NOT NULL,
	Email VARCHAR(100) NOT NULL UNIQUE,
	Password VARCHAR(100) NOT NULL,
	Abbonamento BOOLEAN NOT NULL,
	PercentualeScontoPremium DECIMAL(5,2), 
		
	CHECK ((Abbonamento = TRUE AND PercentualeScontoPremium BETWEEN 0 AND 100) OR 
		(Abbonamento = FALSE AND PercentualeScontoPremium IS NULL))	
);

CREATE TABLE PISTA_CICLABILE
(
	NumeroProgressivo INTEGER PRIMARY KEY,
	Lunghezza DECIMAL(5,2) NOT NULL CHECK (Lunghezza > 0),
	PendenzaMedia DECIMAL(5,2) NOT NULL CHECK (PendenzaMedia BETWEEN 0 AND 100)
);

CREATE TABLE MEZZO
(
	CodiceMezzo INTEGER PRIMARY KEY
);

CREATE TABLE PUNTO_DI_NOLEGGIO
(
	CodicePuntoNoleggio INTEGER PRIMARY KEY,
	Nome VARCHAR(50) NOT NULL,
	Email VARCHAR(100) NOT NULL,
	SitoWeb VARCHAR(100),
	NumeroDiTelefono VARCHAR(20) NOT NULL,
	Via VARCHAR(50) NOT NULL,
	NumeroCivico VARCHAR(10) NOT NULL,
	CAP VARCHAR(10) NOT NULL
);

CREATE TABLE DEPOSITO
(
	CodiceDeposito INTEGER PRIMARY KEY,
	NumeroBiciclette INTEGER NOT NULL,
	CapacitaMassima INTEGER NOT NULL CHECK (CapacitaMassima > 0),
	Via VARCHAR(50) NOT NULL,
	NumeroCivico VARCHAR(10) NOT NULL,
	CAP VARCHAR(10) NOT NULL,
	Latitudine DECIMAL(7,4) NOT NULL,
	Longitudine DECIMAL(7,4) NOT NULL,
	
	CHECK (NumeroBiciclette BETWEEN 0 AND CapacitaMassima)	
);

CREATE TABLE BICICLETTA
(
	CodiceMezzo INTEGER PRIMARY KEY,
	Marca	VARCHAR(50) NOT NULL,
	Colore	VARCHAR(30) NOT NULL,
	Tipo	BOOLEAN NOT NULL,
	CodiceDeposito INTEGER NOT NULL,

	FOREIGN KEY (CodiceMezzo) REFERENCES MEZZO(CodiceMezzo) 
	ON DELETE CASCADE 
	ON UPDATE CASCADE,
	FOREIGN KEY (CodiceDeposito) REFERENCES DEPOSITO(CodiceDeposito) 
	ON DELETE NO ACTION 
	ON UPDATE CASCADE
);

CREATE TABLE VEICOLO_ELETTRICO
(
	CodiceMezzo INTEGER PRIMARY KEY,
	Targa CHAR(7) UNIQUE NOT NULL,
	Nome VARCHAR(50) NOT NULL,
	Modello VARCHAR(50) NOT NULL,
	CostoNoleggio DECIMAL(5,2) NOT NULL CHECK(CostoNoleggio > 0),
	Cilindrata VARCHAR(20) NOT NULL,
	Autonomia DECIMAL(6,2) NOT NULL CHECK(Autonomia > 0),
	Tipo BOOLEAN NOT NULL,
	ChilometriPercorsiAutomobile DECIMAL(9,2),
	NumeroPostiOmologatiAutomobile INTEGER,
	CodicePuntoNoleggio INTEGER NOT NULL,

	CHECK ((Tipo = TRUE AND NumeroPostiOmologatiAutomobile > 0 AND ChilometriPercorsiAutomobile >= 0) OR 
		(Tipo = FALSE AND NumeroPostiOmologatiAutomobile IS NULL AND ChilometriPercorsiAutomobile IS NULL)),
	FOREIGN KEY (CodiceMezzo) REFERENCES MEZZO(CodiceMezzo) 
	ON DELETE CASCADE 
	ON UPDATE CASCADE,
	FOREIGN KEY (CodicePuntoNoleggio) REFERENCES PUNTO_DI_NOLEGGIO(CodicePuntoNoleggio)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
);

CREATE TABLE PRENOTAZIONE
(
	CodicePrenotazione INTEGER,
	CodiceFiscaleResidente CHAR(16),
	DataOraInizio TIMESTAMP NOT NULL,
	DataOraFine TIMESTAMP NOT NULL,
	CostoComplessivo DECIMAL(5,2) CHECK ((CostoComplessivo IS NULL) OR (CostoComplessivo > 0)),
	CodiceMezzo INTEGER NOT NULL,
	
	CHECK (DataOraInizio < DataOraFine),
	PRIMARY KEY (CodicePrenotazione, CodiceFiscaleResidente),
	FOREIGN KEY (CodiceFiscaleResidente) REFERENCES RESIDENTE(CodiceFiscale)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	FOREIGN KEY (CodiceMezzo) REFERENCES MEZZO(CodiceMezzo)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
);

CREATE TABLE STATISTICA
(
	Data DATE,
	CodiceFiscaleResidente CHAR(16),
	NumeroProgressivoPistaCiclabile INTEGER,
	NumeroVoltePercorso INTEGER NOT NULL CHECK (NumeroVoltePercorso > 0),

	PRIMARY KEY (Data, CodiceFiscaleResidente, NumeroProgressivoPistaCiclabile),
	FOREIGN KEY (CodiceFiscaleResidente) REFERENCES RESIDENTE(CodiceFiscale)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	FOREIGN KEY (NumeroProgressivoPistaCiclabile) REFERENCES PISTA_CICLABILE(NumeroProgressivo)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
);

-- [ENG] SEED DATA | [IT] POPOLAMENTO DEI DATI NELLE TABELLE

INSERT INTO RESIDENTE VALUES
('RSSMRA85M01H501Z', 'Mario', 'Rossi', '021234567', 'Via Roma', '10', '20121', 'mario.rossi@email.it', 'Pass_123', TRUE, 10.00),
('VRDLGI90A01F205X', 'Luigi', 'Verdi', '027654321', 'Corso Buenos Aires', '25', '20124', 'luigi.verdi@email.it', 'Pass_456', TRUE, 15.00),
('BNCLRA92H41F205W', 'Laura', 'Bianchi', '029876543', 'Via Dante', '5', '20121', 'laura.bianchi@email.it', 'Pass_789', TRUE, 20.00),
('FRRMRC78B12F205K', 'Marco', 'Ferrari', '023456789', 'Via Torino', '14', '20123', 'marco.ferrari@email.it', 'Pass_101', TRUE, 12.50),
('ESPSTF95C15F205Y', 'Stefano', 'Esposito', '024567890', 'Via Manzoni', '8', '20121', 'stefano.esposito@email.it', 'Pass_202', TRUE, 10.00),
('RROMRA91D20F205J', 'Maria', 'Russo', '025678901', 'Corso Venezia', '30', '20121', 'maria.russo@email.it', 'Pass_303', FALSE, NULL),
('COLGPP88E05F205L', 'Giuseppe', 'Colombo', '026789012', 'Via Montenapoleone', '12', '20121', 'giuseppe.colombo@email.it', 'Pass_404', FALSE, NULL),
('GLLGLL93L50F205M', 'Giulia', 'Galli', '027890123', 'Via Brera', '18', '20121', 'giulia.galli@email.it', 'Pass_505', FALSE, NULL),
('VRNLCU86T10A345K', 'Luca', 'Veronesi', '023344556', 'Via Padova', '12', '20127', 'luca.veronesi@email.it', 'Pass_808', FALSE, NULL),
('CNTNTN80P10F205N', 'Antonio', 'Conti', '028901234', 'Via Solferino', '22', '20121', 'antonio.conti@email.it', 'Pass_606', FALSE, NULL),
('MRNFRC99M25F205P', 'Francesca', 'Marino', '029012345', 'Corso Magenta', '45', '20123', 'francesca.marino@email.it', 'Pass_707', FALSE, NULL),
('NOCLRA95E41F205Q', 'Chiara', 'Neri', '021122334', 'Via Larga', '3', '20122', 'chiara.neri@email.it', 'Pass_909', FALSE, NULL),
('SNTPLA89C22F205R', 'Paolo', 'Santoro', '023322114', 'Viale Abruzzi', '18', '20131', 'paolo.santoro@email.it', 'Pass_112', TRUE, 10.00),
('MNTMRT93T45F205S', 'Marta', 'Monti', '024455667', 'Via Ripamonti', '50', '20141', 'marta.monti@email.it', 'Pass_131', FALSE, NULL);

INSERT INTO PISTA_CICLABILE VALUES
(1, 5.50, 1.20),
(2, 12.00, 0.50),
(3, 3.20, 2.80),
(4, 8.40, 1.10),
(5, 15.60, 3.50),
(6, 4.00, 0.00),
(7, 6.75, 1.80),
(8, 9.30, 2.10),
(9, 2.50, 0.20),
(10, 11.10, 4.20),
(11, 7.20, 1.50),
(12, 4.80, 0.80),
(13, 10.50, 2.30);

INSERT INTO MEZZO VALUES
(1), (2), (3), (4), (5), (6), (7), (8), (9), (10),
(11), (12), (13), (14), (15), (16), (17), (18), (19), (20),
(21), (22), (23), (24), (25), (26), (27), (28), (29), (30),
(31), (32), (33), (34), (35), (36), (37), (38), (39), (40),
(41), (42), (43), (44), (45), (46), (47), (48), (49), (50),
(51), (52), (53), (54);

INSERT INTO PUNTO_DI_NOLEGGIO VALUES
(1, 'Duomo Mobility Hub', 'duomo@noleggio.milano.it', 'https://www.duomomobility.it', '0288451001', 'Piazza Duomo', '1', '20121'),
(2, 'Centrale E-Station', 'centrale@noleggio.milano.it', 'https://www.centralerent.it', '0288451002', 'Piazza Duca d Aosta', '1', '20124'),
(3, 'Cadorna Sharing', 'cadorna@noleggio.milano.it', NULL, '0288451003', 'Piazzale Cadorna', '5', '20123'),
(4, 'Garibaldi Green Hub', 'garibaldi@noleggio.milano.it', 'https://www.garibaldirent.it', '0288451004', 'Piazza Gae Aulenti', '2', '20124'),
(5, 'Navigli Eco Rent', 'navigli@noleggio.milano.it', NULL, '0288451005', 'Ripa di Porta Ticinese', '15', '20143'),
(6, 'Bicocca Smart Point', 'bicocca@noleggio.milano.it', 'https://www.bicoccagreen.it', '0288451006', 'Viale Sarca', '100', '20126'),
(7, 'Lambrate E-Point', 'lambrate@noleggio.milano.it', NULL, '0288451007', 'Via Bassini', '20', '20133'),
(8, 'Porta Romana Sharing', 'romana@noleggio.milano.it', 'https://www.portaromanarent.it', '0288451008', 'Corso di Porta Romana', '80', '20122'),
(9, 'San Siro Mobility', 'sansiro@noleggio.milano.it', NULL, '0288451009', 'Piazzale Axum', '4', '20151'),
(10, 'Sempione Rent Point', 'sempione@noleggio.milano.it', 'https://www.sempionerent.it', '0288451010', 'Corso Sempione', '33', '20154'),
(11, 'Porta Nuova Hub', 'portanuova@noleggio.milano.it', 'https://www.portanuovarent.it', '0288451011', 'Piazza Gae Aulenti', '8', '20124'),
(12, 'CityLife Eco Station', 'citylife@noleggio.milano.it', 'https://www.cityliferent.it', '0288451012', 'Piazza Tre Torri', '2', '20145'),
(13, 'Rogoredo Mobility', 'rogoredo@noleggio.milano.it', NULL, '0288451013', 'Via Cassinis', '10', '20139');

INSERT INTO DEPOSITO VALUES
(1, 10, 20, 'Via Dante', '2', '20121', 45.4660, 9.1860),
(2, 5, 15, 'Corso Buenos Aires', '10', '20124', 45.4780, 9.2050),
(3, 12, 25, 'Piazza Cordusio', '3', '20123', 45.4655, 9.1855),
(4, 8, 20, 'Largo Cairoli', '1', '20121', 45.4680, 9.1820),
(5, 0, 10, 'Via Torino', '15', '20123', 45.4610, 9.1870),
(6, 15, 30, 'Piazza della Scala', '4', '20121', 45.4670, 9.1895),
(7, 7, 15, 'Viale Monza', '25', '20127', 45.4920, 9.2180),
(8, 6, 12, 'Corso di Porta Ticinese', '40', '20123', 45.4550, 9.1820),
(9, 9, 18, 'Via San Vittore', '12', '20123', 45.4625, 9.1720),
(10, 4, 10, 'Via Melchiorre Gioia', '8', '20124', 45.4850, 9.1960),
(11, 8, 15, 'Corso Vercelli', '20', '20145', 45.4682, 9.1550),
(12, 6, 12, 'Viale Zara', '35', '20159', 45.4950, 9.1930),
(13, 10, 20, 'Via Lorenteggio', '40', '20146', 45.4490, 9.1350);

INSERT INTO BICICLETTA VALUES
(1, 'Atala', 'Rosso', FALSE, 1),
(2, 'Bianchi', 'Celeste', TRUE, 1),
(3, 'Torpado', 'Nero', FALSE, 2),
(4, 'Bottecchia', 'Bianco', TRUE, 3),
(5, 'Olmo', 'Giallo', FALSE, 4),
(6, 'Legnano', 'Verde', TRUE, 4),
(7, 'Cinelli', 'Grigio', FALSE, 6),
(8, 'De Rosa', 'Blu', TRUE, 7),
(9, 'Colnago', 'Nero', TRUE, 8),
(10, 'Wilier', 'Rosso', FALSE, 9),
(52, 'Atala', 'Nero', TRUE, 1),
(53, 'Bianchi', 'Verde', FALSE, 2),
(54, 'Torpado', 'Bianco', TRUE, 3);

INSERT INTO VEICOLO_ELETTRICO VALUES
(11, 'GA123AB', 'Fiat', '500e', 12.50, '87 kW', 320.00, TRUE, 14250.00, 4, 1),
(12, 'GB234CD', 'Smart', 'EQ fortwo', 9.00, '60 kW', 135.00, TRUE, 22100.50, 2, 2),
(13, 'GC345EF', 'Renault', 'Zoe', 11.00, '100 kW', 395.00, TRUE, 31800.00, 5, 3),
(14, 'GD456GH', 'Peugeot', 'e-208', 13.00, '100 kW', 362.00, TRUE, 18400.00, 5, 4),
(15, 'GE567IL', 'Volkswagen', 'ID.3', 15.00, '150 kW', 425.00, TRUE, 8900.25, 5, 5),
(16, 'GF678MN', 'Askoll', 'NGS3', 4.50, '50cc eq.', 87.00, FALSE, NULL, NULL, 1),
(17, 'GG789OP', 'Silence', 'S01', 6.00, '125cc eq.', 120.00, FALSE, NULL, NULL, 6),
(18, 'GH890QR', 'Piaggio', '1 Active', 5.00, '50cc eq.', 68.00, FALSE, NULL, NULL, 7),
(19, 'GI901ST', 'Niu', 'MQi GT', 5.50, '125cc eq.', 105.00, FALSE, NULL, NULL, 8),
(20, 'GL012UV', 'Super Soco', 'CPx', 6.50, '125cc eq.', 140.00, FALSE, NULL, NULL, 10),
(21, 'ZA021AA', 'Smart', 'EQ fortwo', 9.00, '60 kW', 135.00, TRUE, 12000.00, 2, 2),
(22, 'ZA022AB', 'Smart', 'EQ fortwo', 9.00, '60 kW', 135.00, TRUE, 14500.00, 2, 2),
(23, 'ZA023AC', 'Fiat', '500e', 12.00, '87 kW', 320.00, TRUE, 9800.00, 4, 2),
(24, 'ZA024AD', 'Fiat', '500e', 12.00, '87 kW', 320.00, TRUE, 11200.00, 4, 2),
(25, 'ZA025AE', 'Renault', 'Zoe', 11.00, '100 kW', 395.00, TRUE, 20100.00, 5, 2),
(26, 'ZA026AF', 'Renault', 'Zoe', 11.00, '100 kW', 395.00, TRUE, 18300.00, 5, 2),
(27, 'ZA027AG', 'Peugeot', 'e-208', 13.00, '100 kW', 362.00, TRUE, 15400.00, 5, 2),
(28, 'ZA028AH', 'Peugeot', 'e-208', 13.00, '100 kW', 362.00, TRUE, 16200.00, 5, 2),
(29, 'ZA029AI', 'Volkswagen', 'ID.3', 15.00, '150 kW', 425.00, TRUE, 7500.00, 5, 2),
(30, 'ZA030AL', 'Volkswagen', 'ID.3', 15.00, '150 kW', 425.00, TRUE, 8100.00, 5, 2),
(31, 'ZA031AM', 'Askoll', 'NGS3', 4.50, '50cc eq.', 87.00, FALSE, NULL, NULL, 2),
(32, 'ZA032AN', 'Askoll', 'NGS3', 4.50, '50cc eq.', 87.00, FALSE, NULL, NULL, 2),
(33, 'ZA033AO', 'Silence', 'S01', 6.00, '125cc eq.', 120.00, FALSE, NULL, NULL, 2),
(34, 'ZA034AP', 'Silence', 'S01', 6.00, '125cc eq.', 120.00, FALSE, NULL, NULL, 2),
(35, 'ZA035AQ', 'Piaggio', '1 Active', 5.00, '50cc eq.', 68.00, FALSE, NULL, NULL, 2),
(36, 'ZA036AR', 'Piaggio', '1 Active', 5.00, '50cc eq.', 68.00, FALSE, NULL, NULL, 2),
(37, 'ZA037AS', 'Niu', 'MQi GT', 5.50, '125cc eq.', 105.00, FALSE, NULL, NULL, 2),
(38, 'ZA038AT', 'Niu', 'MQi GT', 5.50, '125cc eq.', 105.00, FALSE, NULL, NULL, 2),
(39, 'ZA039AU', 'Super Soco', 'CPx', 6.50, '125cc eq.', 140.00, FALSE, NULL, NULL, 2),
(40, 'ZA040AV', 'Super Soco', 'CPx', 6.50, '125cc eq.', 140.00, FALSE, NULL, NULL, 2),
(41, 'ZA041AZ', 'Smart', 'EQ fortwo', 9.00, '60 kW', 135.00, TRUE, 17200.00, 2, 2),
(42, 'ZA042BA', 'Fiat', '500e', 12.00, '87 kW', 320.00, TRUE, 13400.00, 4, 2),
(43, 'ZA043BB', 'Renault', 'Zoe', 11.00, '100 kW', 395.00, TRUE, 22000.00, 5, 2),
(44, 'ZA044BC', 'Askoll', 'NGS3', 4.50, '50cc eq.', 87.00, FALSE, NULL, NULL, 2),
(45, 'ZA045BD', 'Silence', 'S01', 6.00, '125cc eq.', 120.00, FALSE, NULL, NULL, 2),
(46, 'ZA046BE', 'Piaggio', '1 Active', 5.00, '50cc eq.', 68.00, FALSE, NULL, NULL, 2),
(47, 'ZA047BF', 'Niu', 'MQi GT', 5.50, '125cc eq.', 105.00, FALSE, NULL, NULL, 2),
(48, 'ZA048BG', 'Super Soco', 'CPx', 6.50, '125cc eq.', 140.00, FALSE, NULL, NULL, 2),
(49, 'ZA049BH', 'Smart', 'EQ fortwo', 9.00, '60 kW', 135.00, TRUE, 19100.00, 2, 2),
(50, 'ZA050BI', 'Fiat', '500e', 12.00, '87 kW', 320.00, TRUE, 10500.00, 4, 2),
(51, 'ZA051BL', 'Askoll', 'NGS3', 4.50, '50cc eq.', 87.00, FALSE, NULL, NULL, 2);

INSERT INTO PRENOTAZIONE VALUES
(1, 'RSSMRA85M01H501Z', '2026-05-10 09:00:00', '2026-05-10 10:30:00', NULL, 2),
(2, 'RSSMRA85M01H501Z', '2026-05-12 14:00:00', '2026-05-12 16:00:00', 25.00, 11),
(3, 'RSSMRA85M01H501Z', '2026-05-18 10:00:00', '2026-05-18 11:30:00', 6.75, 16),
(1, 'BNCLRA92H41F205W', '2026-05-14 10:00:00', '2026-05-14 11:45:00', NULL, 4),
(2, 'BNCLRA92H41F205W', '2026-05-23 10:00:00', '2026-05-23 11:30:00', 15.00, 13),
(3, 'BNCLRA92H41F205W', '2026-05-25 09:00:00', '2026-05-25 11:00:00', 26.00, 14),
(1, 'FRRMRC78B12F205K', '2026-05-16 11:00:00', '2026-05-16 12:15:00', NULL, 6),
(1, 'VRDLGI90A01F205X', '2026-05-11 08:30:00', '2026-05-11 09:15:00', NULL, 1),
(2, 'VRDLGI90A01F205X', '2026-05-15 17:00:00', '2026-05-15 18:30:00', 13.50, 16),
(3, 'VRDLGI90A01F205X', '2026-05-19 14:00:00', '2026-05-19 16:00:00', 30.00, 15),
(1, 'RROMRA91D20F205J', '2026-05-18 15:00:00', '2026-05-18 16:30:00', NULL, 3),
(2, 'RROMRA91D20F205J', '2026-05-20 09:00:00', '2026-05-20 11:00:00', 18.00, 12),
(1, 'COLGPP88E05F205L', '2026-05-21 16:00:00', '2026-05-21 17:30:00', 10.00, 17),
(2, 'COLGPP88E05F205L', '2026-05-24 15:00:00', '2026-05-24 16:15:00', NULL, 7),
(3, 'COLGPP88E05F205L', '2026-05-26 10:00:00', '2026-05-26 12:00:00', 10.00, 18),
(1, 'GLLGLL93L50F205M', '2026-05-22 18:00:00', '2026-05-22 19:00:00', NULL, 5),
(1, 'CNTNTN80P10F205N', '2026-05-27 09:00:00', '2026-05-27 11:00:00', 18.00, 21),
(2, 'CNTNTN80P10F205N', '2026-05-28 15:00:00', '2026-05-28 17:00:00', 18.00, 22),
(1, 'NOCLRA95E41F205Q', '2026-05-29 10:00:00', '2026-05-29 11:30:00', NULL, 52);

INSERT INTO STATISTICA VALUES
('2026-05-01', 'RSSMRA85M01H501Z', 1, 2),
('2026-05-02', 'RSSMRA85M01H501Z', 2, 1),
('2026-05-03', 'VRDLGI90A01F205X', 1, 3),
('2026-05-04', 'VRDLGI90A01F205X', 3, 1),
('2026-05-05', 'BNCLRA92H41F205W', 2, 4),
('2026-05-06', 'FRRMRC78B12F205K', 4, 2),
('2026-05-07', 'ESPSTF95C15F205Y', 5, 1),
('2026-05-08', 'RROMRA91D20F205J', 1, 2),
('2026-05-09', 'COLGPP88E05F205L', 6, 3),
('2026-05-10', 'GLLGLL93L50F205M', 7, 1),
('2026-05-11', 'CNTNTN80P10F205N', 8, 2),
('2026-05-12', 'RSSMRA85M01H501Z', 3, 2),
('2026-05-13', 'VRDLGI90A01F205X', 2, 1),
('2026-05-14', 'BNCLRA92H41F205W', 4, 3),
('2026-05-15', 'NOCLRA95E41F205Q', 1, 1);

-- [ENG] SAMPLE UPDATE/DELETE STATEMENTS | [IT] ISTRUZIONI DIMOSTRATIVE DI MODIFICA/ELIMINAZIONE

UPDATE RESIDENTE 
SET NumeroDiTelefono = '0299887766' 
WHERE CodiceFiscale = 'VRNLCU86T10A345K';

DELETE FROM RESIDENTE 
WHERE CodiceFiscale = 'MRNFRC99M25F205P';


UPDATE PISTA_CICLABILE 
SET PendenzaMedia = 2.00 
WHERE NumeroProgressivo = 10;

DELETE FROM PISTA_CICLABILE 
WHERE NumeroProgressivo = 10;


UPDATE PUNTO_DI_NOLEGGIO 
SET SitoWeb = 'https://www.lambratesmartpoint.it' 
WHERE CodicePuntoNoleggio = 7;

DELETE FROM PUNTO_DI_NOLEGGIO 
WHERE CodicePuntoNoleggio = 9;


UPDATE DEPOSITO 
SET CapacitaMassima = 25 
WHERE CodiceDeposito = 10;

DELETE FROM DEPOSITO 
WHERE CodiceDeposito = 5;


UPDATE BICICLETTA 
SET Colore = 'Grigio Titanio' 
WHERE CodiceMezzo = 10;

DELETE FROM BICICLETTA 
WHERE CodiceMezzo = 10;


UPDATE VEICOLO_ELETTRICO 
SET CostoNoleggio = 7.00 
WHERE CodiceMezzo = 20;

DELETE FROM VEICOLO_ELETTRICO 
WHERE CodiceMezzo = 20;


UPDATE PRENOTAZIONE 
SET CostoComplessivo = 28.50, DataOraInizio = DataOraInizio
WHERE CodicePrenotazione = 2 AND CodiceFiscaleResidente = 'RSSMRA85M01H501Z';

DELETE FROM PRENOTAZIONE 
WHERE CodicePrenotazione = 1 AND CodiceFiscaleResidente = 'GLLGLL93L50F205M';


UPDATE STATISTICA 
SET NumeroVoltePercorso = 5 
WHERE Data = '2026-05-06' 
  AND CodiceFiscaleResidente = 'FRRMRC78B12F205K' 
  AND NumeroProgressivoPistaCiclabile = 4;

DELETE FROM STATISTICA 
WHERE Data = '2026-05-11' 
  AND CodiceFiscaleResidente = 'CNTNTN80P10F205N' 
  AND NumeroProgressivoPistaCiclabile = 8;


UPDATE MEZZO 
SET CodiceMezzo = 99 
WHERE CodiceMezzo = 51;

DELETE FROM MEZZO 
WHERE CodiceMezzo = 99;

/* 
-- [ENG] Delete the data related to a resident who has made at least one reservation, 
		 having defined appropriate violation remediation policies (first identify a 
		 resident who has made at least one reservation and then delete the user from 
		 the corresponding table, without previously deleting their reservations).

-- [IT] Eliminare i dati relativi ad un residente che ha effettuato almeno una prenotazione, 
		avendo specificato opportune politiche di rimedio alle violazioni 
	 	(individuare prima un residente che ha effettuato almeno una prenotazione e poi eliminare 
	 	l’utente dalla tabella corrispondente, senza aver eliminato precedentemente le sue prenotazioni).
*/

SELECT * 
FROM PRENOTAZIONE
WHERE CodiceFiscaleResidente = 'RROMRA91D20F205J';

DELETE FROM RESIDENTE
WHERE CodiceFiscale = 'RROMRA91D20F205J';

SELECT * 
FROM PRENOTAZIONE
WHERE CodiceFiscaleResidente = 'RROMRA91D20F205J';
