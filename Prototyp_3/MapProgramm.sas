libname perma '/home/u64050406/permanent';
/*Kundendaten aus den Rechnungen ermitteln*/
data perma.new;
	infile "/home/u64050406/MapProgramm/Testdaten/*.txt"
	/* Mehrere Dateien verarbeiten, eov wird bei jeder neuen Datei auf 1 gesetzt */
	eov=eof truncover;
	/* Variablenlängen definieren */
	length plz $4 geld 8;
	/* Behält die Variablenwerte zwischen den Zeilen  */
	retain plz_count 0 plz strasse summe_flag;
	/* Zeile einlesen */
	input;
	/* Aktuelle Zeile speichern */
	line=_infile_;
	/* Zum Debuggen wird die Zeile in die Log-Datei schreiben */
	put "Zeile: " line;
	/*eov wird auf 1 bei Beginn einer neuen Datei gesetzt*/
	if eof=1 then
		do;
			/* Variablen zurücksetzen */
			plz="";
			geld=.;
			plz_count=0;
			eof=0;
		end;
	/* Firmen-PLZ überspringen (erste erkannte PLZ) */
	if prxmatch("/\b\d{4}\s+[A-Za-z]+\b/", line) and plz_count ^=0 then
		do;
			plz_count + 1;
			/* Firmen-PLZ erkannt und übersprungen */
			put "INFO: Firmen-PLZ erkannt und übersprungen: " line;
		end;
	/* Kunden-PLZ extrahieren (zweite erkannte PLZ) */
	else if prxmatch("/\b\d{4}\s+[A-Za-z]+\b/", line) and plz_count=0 then
		do;
			plz=scan(line, 1);
			if length(plz)=4 then
				do;
					plz_count + 1;
					/* Kunden-PLZ erkannt */
					put "INFO: Kunden-PLZ erkannt: " plz;
				end;
			else
				do;
					plz="";
					put "INFO: 5-stellige PLZ erkannt und übersprungen: " plz;
				end;
		end;
	/*Strasse speichern*/
	else if prxmatch("/\b[A-Za-z]+\s+\d+\b/", line) and plz_count=0 then
		do;
			/* '09'x für Tabulator als Trennzeichen */
			strasse=scan(line, 1, '09'x);
			put "INFO:Strasse erkannt: " line;
		end;		
	/*Rechnungsbetrag für Rechnungen mit "Summe" extrahieren */
	if summe_flag=1 then
		do;
			/* Trennzeichen: Leerzeichen, Doppelpunkt, Euro-Zeichen */
			geld=compress(scan(line, 1, ' :€'), '.', 'A');
			put "INFO: Rechnungsbetrag erkannt: " geld;
			summe_flag=0;
			/* Ausgabe, wenn PLZ und Rechnungsbetrag gefunden wurden */
			if not missing(plz) and not missing(geld) then
				output;
		end;
	/* Rechnungsbetrag extrahieren */
	if index(upcase(line), "RECHNUNGSBETRAG") > 0 then
		do;
			/* Bestimmt, ob die Zeile "RECHNUNGSBETRAG" oder "SUMME" enthält */
			geld=compress(scan(line, 2, ' :€'), '.', 'A');
			/* Trennzeichen: Leerzeichen, Doppelpunkt, Euro-Zeichen */
			put "INFO: Rechnungsbetrag erkannt: " geld;
			/* Ausgabe, wenn PLZ und Rechnungsbetrag gefunden wurden */
			if not missing(plz) and not missing(geld) then
				output;
		end;
	if index(upcase(line), "SUMME") > 0 then
		do;
			summe_flag=1;
		end;
run;
/* Daten sortieren */
proc sort data=perma.new;
	by plz;
run;
/*Gleiche Kunden werden zusammengefasst, das Kriterium ist gleiche PLZ und Strasse*/
proc sql;
	create table noDouble as select strip(plz) as plz, strip(strasse) as strasse, 
		/*Das Geld der Einzelaufträge wird zusammengefasst*/
		sum(geld) as geld, count(*) as Anzahl from perma.new group by plz, strasse;
quit;
/*Einlesen des PLZ-Verzeichnisses um die PLZ den richtigen Bundesläner zuordnen zu können*/
data plz_verzeichnis;
	infile "/home/u64050406/MapProgramm/PLZ_Verzeichnis.csv" dlm=';' missover dsd 
		firstobs=2;
	/* Bundeslandlänge anpassen */
	length plz $4 bundesland $2;
	input plz bundesland;
run;
/*PLZ umwandeln von String in Zahl */
data noDouble_numeric;
	set noDouble;
	plz_num=input(plz, 4.);
run;
/*Clustering*/
/*Clusteranalyse mit PROC FASTCLUS */
proc fastclus data=noDouble_numeric maxclusters=3 out=clustered_data;
	var geld;
	title "Clustering von Kunden nach Gesamtbestellwert";
run;
/*Ergebnisse anzeigen */
proc print data=clustered_data;
	var plz_num geld Cluster;
run;

/*Ergebnisse plotten mit Streuungsdiagramm */
proc sgplot data=clustered_data;
	scatter x=plz_num y=geld / group=Cluster markerattrs=(symbol=circlefilled);
	title "Cluster-Darstellung von Kunden basierend auf Gesamtbestellwert und PLZ";
	xaxis label="PLZ";
	yaxis label="Umsatz (Geld)";
run;
/* Sortiert das PLZ-Verzeichnis nach PLZ */
proc sort data=plz_verzeichnis;
	by plz;
run;
/* Liest die Zuordnungstabelle der Bundesländer zu ID ein */
data plz_id;
	infile "/home/u64050406/MapProgramm/PLZ_ID.csv" dlm=';' missover dsd 
		firstobs=2;
	length id 4. bundesland $2;
	input id bundesland;
run;
/* Verknüpft die Kundendaten mit den Bundesländern basierend auf der PLZ */
proc sql;
	create table match1 as select A.plz, A.strasse, A.geld, B.bundesland from 
		noDouble as A left join plz_verzeichnis as B on A.PLZ=B.PLZ;
quit;
/* Verknüpft die Bundesländer mit ihrer ID  */
proc sql;
	create table match2 as select A.geld, B.id from match1 as A left join plz_id 
		as B on A.bundesland=B.bundesland;
quit;
/* Zählt die Anzahl der Kunden pro Bundesland*/
proc sql;
	create table Kunden_Pro_Bundesland as select id, count(*) as Kundenanzahl from 
		match2 group by id;
quit;
/* Zählt den Umsatz pro Bundesland*/
proc sql;
	create table Umsatz_Pro_Bundesland as select id, sum(geld) as Umsatz from 
		match2 group by id;
quit;
/* Verknüpft die geclusterten Daten mit den Bundesländern über die ID*/
proc sql;
	create table Austria_Kunden as select a.*, b.Kundenanzahl from maps.austria as 
		a left join Kunden_Pro_Bundesland as b on a.id=b.id;
quit;
/*Für die Färbung der Choromap, 'cx' ist als Präfix für RGB notwendig siehe "Color-Naming Schemes"
(https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/graphref/p0edl20cvxxmm9n1i9ht3n21eict.htm)*/
/*Die Werte entsprechen blauen Farbtönen, aufsteigend nach Intensität des Blau */
pattern1 v=ms c=cxe8f0f7;
pattern2 v=ms c=cxd2e2f0;
pattern3 v=ms c=cxa6c6e1;
pattern4 v=ms c=cx90b8da;
pattern5 v=ms c=cx79a9d2;
pattern6 v=ms c=cx4d8dc3;
pattern7 v=ms c=cx377fbc;
pattern8 v=ms c=cx2171b5;
pattern9 v=ms c=cx1d65a2;
pattern10 v=ms c=cx174f7e;
pattern11 v=ms c=cx10385a;
pattern12 v=ms c=cx092136;
/*Map zur Veranschaulichung der Kundenverteilung in Österreich*/
proc gmap data=Austria_Kunden map=maps.austria;
	/* Verwendet die ID der Bundesländer */
	id id;
	/* Färbt nach Kundenanzahl */
	choro Kundenanzahl / coutline=gray;
	title "Kundenverteilung in Österreich";
	run;
quit;
/* Verknüpft anhand der ID */
proc sql;
	create table Austria_Umsatz as select a.*, b.Umsatz from maps.austria as a 
		left join Umsatz_Pro_Bundesland as b on a.id=b.id;
quit;
/*Map zur Veranschaulichung der Umsatzverteilung in Österreich*/
proc gmap data=Austria_Umsatz map=maps.austria;
	id id;
	/* Färbt nach Umsatz */
	choro Umsatz / levels=4 coutline=black legend=legend1;
	title "Umsatzverteilung in Österreich";
	run;
quit;