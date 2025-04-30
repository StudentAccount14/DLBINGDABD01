data WORK.Filter_num;
    set WORK.Filter;

    /* Alphanumerische Variablen in numerische umwandeln */
    Vibration_num = input(Vibration, best32.);
    Pump_Power_num = input(Pump_Power, best32.);

    /* Ursprüngliche Variablen löschen */
    drop Vibration Pump_Power;

    /* Numerische Variablen umbenennen, um die Originalnamen wiederzuverwenden */
    rename Vibration_num = Vibration
           Pump_Power_num = Pump_Power;
run;


