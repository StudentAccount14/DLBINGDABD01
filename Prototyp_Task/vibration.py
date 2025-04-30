import pandas as pd
import random
import os
# Funktion zur Generierung der Daten
def generate_data():
    num_records = 50000
    data = {
        "Vibration": [],
        "Pump_Power": [],
    }
    for x in range(num_records):
        # Simuliert fehlende Werte (hier fehlen beide Messwerte)
        # Die Verarbeitung einzelner fehlender Werte ist auch möglich (siehe Prototyp I)
        if random.randint(0, 1000) < 1:
            data["Vibration"].append('NaN')
            data["Pump_Power"].append('NaN')
            continue
        #Zum Erzeugen von Ausreißern
        # Erzeugt Ausreißer im oberen Wertebereich
        if random.randint(0,2000) < 1:
            vibration = round(random.uniform(4.6, 4.8), 2)
            data["Vibration"].append(vibration)
            power = 60.0 * (1 - ((vibration - 3.0) ** 2 / 4.0))
            data["Pump_Power"].append(power)
            continue
        # Erzeugt Ausreißer im unteren Wertebereich
        if random.randint(0, 2000) < 1:
            vibration = round(random.uniform(1.5, 1.7), 2)
            data["Vibration"].append(vibration)
            power = 60.0 * (1 - ((vibration - 3.0) ** 2 / 4.0))
            data["Pump_Power"].append(power)
            continue
        vibration = round(random.uniform(2.5, 3.8), 2)
        data["Vibration"].append(vibration)
        #ergibt bei einer Vibration von 3.0 exakt 60 und fällt symmetrisch um diesen Wert ab
        power = 60.0 * (1 - ((vibration -3.0)**2/4.0))
        data["Pump_Power"].append(power)
    return pd.DataFrame(data)
#Speichert das Dataframe als xlsx-Datei
def save_to_xlsx(df, filename):
    filepath = os.path.join('C:\\Users\\WorkTablet\\Desktop\\Vibration\\Testdaten', filename)
    df.to_excel(filepath, index=False)
    print(f"Daten erfolgreich in {filepath} gespeichert.")
def generate_multiple_excel_files(n):
    for i in range(1, n + 1):
        data = generate_data()
        filename = f"testdaten_{i}.xlsx"
        save_to_xlsx(data, filename)
if __name__ == "__main__":
    num_files = int(input("Wie viele Excel-Dateien sollen erstellt werden? "))
    generate_multiple_excel_files(num_files)