-- [ENG] Find all pedal-assisted bicycles reserved by premium residents.
-- [IT] Trovare tutte le bici a pedalata assistita che sono state prenotate da residenti premium.

SELECT DISTINCT B.CodiceMezzo
FROM BICICLETTA B 
JOIN PRENOTAZIONE PR ON B.CodiceMezzo = PR.CodiceMezzo 
JOIN RESIDENTE R ON PR.CodiceFiscaleResidente = R.CodiceFiscale
WHERE B.Tipo = TRUE AND R.Abbonamento = TRUE;

-- [ENG] Find all residents whose total expenditure on electric vehicle reservations was the highest.
-- [IT] Trovare tutti i residenti la cui spesa per prenotazione di veicoli elettrici è stata la massima.

SELECT PR1.CodiceFiscaleResidente, SUM(PR1.CostoComplessivo)
FROM PRENOTAZIONE PR1 JOIN VEICOLO_ELETTRICO VE1 ON PR1.CodiceMezzo = VE1.CodiceMezzo 
GROUP BY PR1.CodiceFiscaleResidente
HAVING SUM(PR1.CostoComplessivo) >= ALL (SELECT SUM(PR2.CostoComplessivo)
					 FROM PRENOTAZIONE PR2 JOIN VEICOLO_ELETTRICO VE2 ON PR2.CodiceMezzo = VE2.CodiceMezzo
					 GROUP BY PR2.CodiceFiscaleResidente);

-- [ENG] Display, for each electric car, the number of distinct users who booked it.
-- [IT] Visualizzare, per ogni automobile elettrica il numero di utenti distinti che l’hanno prenotata.

SELECT VE.CodiceMezzo, COUNT(DISTINCT PR.CodiceFiscaleResidente)
FROM PRENOTAZIONE PR RIGHT JOIN VEICOLO_ELETTRICO VE ON PR.CodiceMezzo = VE.CodiceMezzo
WHERE VE.Tipo = TRUE
GROUP BY VE.CodiceMezzo; 				

-- [ENG] Display the resident(s) who always booked electric vehicles from the exact same rental station.
-- [IT] Visualizzare il residente (o i residenti) che hanno prenotato veicoli elettrici sempre dallo stesso punto di noleggio.

SELECT PR.CodiceFiscaleResidente
FROM PRENOTAZIONE PR JOIN VEICOLO_ELETTRICO VE ON PR.CodiceMezzo = VE.CodiceMezzo
GROUP BY PR.CodiceFiscaleResidente
HAVING COUNT(DISTINCT VE.CodicePuntoNoleggio) = 1;

-- [ENG] Display all rental stations managing more than 30 vehicles where no booking has ever been made by a premium user.
-- [IT] Visualizzare tutti i punti di noleggio che hanno un numero di veicoli maggiore di 30, in cui non è mai effettuata una prenotazione (per un mezzo del punto di noleggio) da parte di un utente premium.

SELECT PG.CodicePuntoNoleggio
FROM PUNTO_DI_NOLEGGIO PG JOIN VEICOLO_ELETTRICO VE1 ON PG.CodicePuntoNoleggio = VE1.CodicePuntoNoleggio
WHERE PG.CodicePuntoNoleggio NOT IN (SELECT VE2.CodicePuntoNoleggio
                                     FROM VEICOLO_ELETTRICO VE2 
                                     JOIN PRENOTAZIONE PR ON VE2.CodiceMezzo = PR.CodiceMezzo
                                     JOIN RESIDENTE R ON PR.CodiceFiscaleResidente = R.CodiceFiscale
                                     WHERE R.Abbonamento = TRUE)
GROUP BY PG.CodicePuntoNoleggio
HAVING COUNT(DISTINCT VE1.CodiceMezzo) > 30;
