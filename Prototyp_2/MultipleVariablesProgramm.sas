/* Liest die Messdaten mehrerer Maschinen aus mehreren CSV-Dateien ein */
data machines;
  infile "/home/u64050406/MultipleVariablesProgramm/Testdaten/*.csv" 
        firstobs=2
        DSD
        eov=eof;
  		input Motor_Ampere Temperatur_Motor Intake_Pressure Discharge_Pressure Room_Temperature;
  		/* Um die Maschinen-ID über mehrere Dateien hinweg zu behalten */
  		retain ID 1;
  		/*Nur vollständige Datensätze übernehmen (fehlende Werte ignorieren) */
  		if not (missing(Motor_Ampere) or missing(Temperatur_Motor) or missing(Intake_Pressure) or missing(Discharge_Pressure) or missing(Room_Temperature)) then output;
 		/*Zum Identifizieren und Gruppieren der Maschine wird eine fortlaufende ID genutzt */
  		if eof = 1 then do;
  			ID = ID +1;
  			eof = 0;
  		end;
run;

/* Berechnet Mittelwerte pro Maschine (ID) */
proc means data=machines noprint;
  class ID;
  var Motor_Ampere Temperatur_Motor Intake_Pressure Discharge_Pressure Room_Temperature;
  /* Anzahl der Beobachtungen pro Maschine entspricht den Monaten ohne Ausfall */
  output out=summary_means 
    mean=Motor_Ampere_avg Temperatur_Motor_avg Intake_Pressure_avg Discharge_Pressure_avg Room_Temperature_avg
    n=Months;
run;

/*Makro für die Variablen */
%let variables_mean_all = Motor_Ampere_avg Temperatur_Motor_avg Intake_Pressure_avg Discharge_Pressure_avg Room_Temperature_avg;
/* Aufbereiten der berechneten Mittelwerte */
data multi_data;
    set summary_means;
    /* Entfernt die erste Zeile mit den aggregierten Werten */
    If _N_ = 1 then delete;
    /* Nur die benötigten Variablen werden behalten */
    keep ID Motor_Ampere_avg Temperatur_Motor_avg Intake_Pressure_avg Discharge_Pressure_avg Room_Temperature_avg Months;
run;

/* Berechnet Pearson-Korrelation zwischen allen Mittelwerten und der Lebensdauer in Monaten*/
proc corr data=multi_data;
	var &variables_mean_all Months;
	title "Korrelationsanalyse zwischen den Betriebsparametern und der Lebensdauer (in Monaten)";
run; 

/*Makro-Variable für Variablen mit signifikanten Korrelationen */
%let variables_mean = Motor_Ampere_avg Temperatur_Motor_avg Intake_Pressure_avg Discharge_Pressure_avg;

/*Korrelationsmatrix zwischen ausgewählten Variablen und Lebensdauer, inkl. Histogrammen */
proc corr data=multi_data plots=matrix(histogram);
    var &variables_mean;
    with Months;
    title "Zusammenhang zwischen ausgewählten Betriebsparametern und der Lebensdauer (in Monaten)";
run;

/*Einfache lineare Regression (nur mit Motorstrom) */
proc reg data=multi_data;
    model Months = Motor_Ampere_avg;
run;
quit;

/*Multiple Regression mit Motorstrom und Motortemperatur*/
proc reg data=multi_data;
    model Months = Motor_Ampere_avg Temperatur_Motor_avg;
run;
quit;

/*Multiple Regression mit allen signifikant korrelierenden Variablen*/
proc reg data=multi_data;
    model Months = &variables_mean;
run;
quit;

/*Streudiagramm mit Regressionslinie (Motorstrom und Lebensdauer) */
proc sgplot data=multi_data;
    scatter x=Motor_Ampere_avg y=Months / datalabel=ID;
    reg x=Motor_Ampere_avg y=Months / cli;
    title "Streudiagramm zur Beziehung zwischen Motorstrom und Lebensdauer mit Regressionslinie";
    yaxis label="Lebensdauer (in Monaten)";
	xaxis label="Motorstrom (in A)";
run;


/*Erzeugt eine Scatterplot-Matrix für alle Variablen */
proc sgscatter data=multi_data;
    matrix &variables_mean Months / diagonal=(histogram);
    title "Streudiagramm-Matrix der ausgewählten Betriebsparametern mit Histogrammen auf der Diagonalen";
run;

/*Erzeugt Konturplot mit Motorstrom und Motortemperatur*/ 
proc glm data=multi_data
         plots(only)=(contourfit);
    model Months = Motor_Ampere_avg Temperatur_Motor_avg;
    title "Konturplot zur Vorhersage der Lebensdauer mit Motorstrom und Motortemperatur";
run;
quit;    