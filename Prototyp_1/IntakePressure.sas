/* Einlesen der Csv-Dateien */
data machines;
	/*Dateipfad*/
	infile "/home/u64050406/PressureProgramm/Testdaten/*.csv"
	/*erste Zeile wird ignoriert */
	firstobs=2 DSD eov=eof;

	/* Gibt das Eingabeformat für das Datum an */
	informat Maintenance_Date yymmdd10.;

	/* Gibt das Ausgabeformat für das Datum an */
	format Maintenance_Date yymmdd10.;

	/* Einlesen der Variablen in spezifischem Datumsformat */
	input Intake_Pressure Maintenance_Date : yymmdd10.;
	retain ID 1;

	/*Die letzte Zeile und fehlende Werte werden ignoriert */
	if not (missing(Intake_Pressure) or missing(Maintenance_Date)) then
		output;

	/*Zum Identifizieren und Gruppieren der Maschine wird eine fortlaufende ID genutzt */
	if eof=1 then
		do;
			ID=ID +1;
			eof=0;
		end;
run;

/* Berechnung des Mittelwerts vom Ansaugdruck mittels PROC MEANS */
proc means data=machines noprint;
	by ID;
	var Intake_Pressure;
	output out=mean_pressures mean=Mean_Pressure;
run;

/* Berechnung der Anzahl der Wartungen (ohne Initialwartung) mit PROC SQL */
proc sql;
	create table count_maintenances as select ID, count(distinct 
		Maintenance_Date)-1 as Number_Maintenances from machines group by ID;
quit;

/*Zusammenführen der beiden Ergebnisse */
data machines_stats;
	merge mean_pressures (keep=ID Mean_Pressure) count_maintenances;
	by ID;
run;

/*Ergebnis anzeigen */
proc print data=machines_stats;
	title "Statistiken pro Maschine";
run;

/*Statistiken pro Maschine mit Hilfe von PROC CORR*/
proc corr data=machines_stats;
	var Mean_pressure Number_Maintenances;
run;

/*Boxplot*/
proc sgplot data=machines_stats;
	vbox Mean_Pressure / category=Number_Maintenances;
	title "Boxplot zur Darstellung des Ansaugdrucks pro Anzahl an Wartungen";
	yaxis label="Ansaugdruck (Mean_Pressure)";
	xaxis label="Anzahl der Wartungen (Number_Maintenances)";
run;

/*Streudiagramm mit Regressionsgerade*/
proc sgplot data=machines_stats;
	scatter x=Mean_Pressure y=Number_Maintenances / 
		markerattrs=(symbol=circlefilled color=blue);
	reg x=Mean_Pressure y=Number_Maintenances / lineattrs=(color=red thickness=2);
	title "Streudiagramm mit Regressionslinie zur Analyse des Zusammenhangs zwischen Ansaugdruck und Anzahl der Wartungen";
	xaxis label="Durchschnittlicher Ansaugdruck (Mean_Pressure)";
	yaxis label="Anzahl der Wartungen (Number_Maintenances)";
run;