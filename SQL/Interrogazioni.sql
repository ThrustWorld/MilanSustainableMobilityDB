SELECT DISTINCT B.CodiceMezzo
FROM BICICLETTA B 
JOIN PRENOTAZIONE PR ON B.CodiceMezzo = PR.CodiceMezzo 
JOIN RESIDENTE R ON PR.CodiceFiscaleResidente = R.CodiceFiscale
WHERE B.Tipo = TRUE AND R.Abbonamento = TRUE;


SELECT PR1.CodiceFiscaleResidente, SUM(PR1.CostoComplessivo)
FROM PRENOTAZIONE PR1 JOIN VEICOLO_ELETTRICO VE1 ON PR1.CodiceMezzo = VE1.CodiceMezzo 
GROUP BY PR1.CodiceFiscaleResidente
HAVING SUM(PR1.CostoComplessivo) >= ALL (SELECT SUM(PR2.CostoComplessivo)
					 FROM PRENOTAZIONE PR2 JOIN VEICOLO_ELETTRICO VE2 ON PR2.CodiceMezzo = VE2.CodiceMezzo
					 GROUP BY PR2.CodiceFiscaleResidente);


SELECT VE.CodiceMezzo, COUNT(DISTINCT PR.CodiceFiscaleResidente)
FROM PRENOTAZIONE PR RIGHT JOIN VEICOLO_ELETTRICO VE ON PR.CodiceMezzo = VE.CodiceMezzo
WHERE VE.Tipo = TRUE
GROUP BY VE.CodiceMezzo; 				


SELECT PR.CodiceFiscaleResidente
FROM PRENOTAZIONE PR JOIN VEICOLO_ELETTRICO VE ON PR.CodiceMezzo = VE.CodiceMezzo
GROUP BY PR.CodiceFiscaleResidente
HAVING COUNT(DISTINCT VE.CodicePuntoNoleggio) = 1;


SELECT PG.CodicePuntoNoleggio
FROM PUNTO_DI_NOLEGGIO PG JOIN VEICOLO_ELETTRICO VE1 ON PG.CodicePuntoNoleggio = VE1.CodicePuntoNoleggio
WHERE PG.CodicePuntoNoleggio NOT IN (SELECT VE2.CodicePuntoNoleggio
                                     FROM VEICOLO_ELETTRICO VE2 
                                     JOIN PRENOTAZIONE PR ON VE2.CodiceMezzo = PR.CodiceMezzo
                                     JOIN RESIDENTE R ON PR.CodiceFiscaleResidente = R.CodiceFiscale
                                     WHERE R.Abbonamento = TRUE)
GROUP BY PG.CodicePuntoNoleggio
HAVING COUNT(DISTINCT VE1.CodiceMezzo) > 30;
