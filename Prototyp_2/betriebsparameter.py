import pandas as pd
import random
import os

def generate_data():
    # Anzahl der Datensätze (zwischen 24 und 60, bei mehr Ausreißern tendenziell weniger)
    num_records = random.randint(24, 60)
    # Anzahl der Ausreißer bestimmen (wenige Ausreißer sind wahrscheinlicher)
    num_outliers = min(min(random.randint(0,4), random.randint(0,4)),random.randint(1,4))
    # Liste zur Speicherung der Art der Ausreißer
    typ_outliers = [0,0,0,0]
    # Zähler für die While-Schleife
    x = 0
    # Wenn es Ausreißer gibt, soll die Lebenserwartung der Pumpen reduziert sein
    if num_outliers > 0:
        num_records = random.randint(24 - num_outliers *5, 60 - num_outliers * 11)
        #Zufällige Zuweisung der Art des Ausreißers
        while x < num_outliers:
            i = random.randint(0,3)
            if typ_outliers[i] == 0:
                typ_outliers[i] = 1
                x = x + 1
    #Welche Daten gemessen wurden
    data = {
        "Motor Ampere": [],
        "Temperature Motor": [],
        "Intake Pressure": [],
        "Discharge Pressure": [],
        "Room Temperature": []
    }
    # Generiert die Daten
    for x in range(num_records):
        # Motorstrom (in A)
        if typ_outliers[0] == 1:
            data["Motor Ampere"].append(round(random.uniform(25, 26), 2))
        else:
            base_value = round(random.uniform(20, 21), 2)
            data["Motor Ampere"].append(base_value)
        # Temperatur des Motors
        if typ_outliers[1] == 1:
            data["Temperature Motor"].append(round(random.uniform(160, 170), 2))
        else:
            base_value = round(random.uniform(90, 130), 2)
            data["Temperature Motor"].append(base_value)
        # Ansaugdruck
        if  typ_outliers[2] == 1:
            data["Intake Pressure"].append(round(random.uniform(800, 850), 2))
        else:
            base_value = round(random.uniform(500, 600), 2)
            data["Intake Pressure"].append(base_value)
        # Austrittsdruck
        if  typ_outliers[3] == 1:
            data["Discharge Pressure"].append(round(random.uniform(800, 850), 2))
        else:
            base_value = round(random.uniform(500, 600), 2)
            data["Discharge Pressure"].append(base_value)
        #Für das Simulieren von erhöhter Raumtemperatur
        ran = random.randint(0, 4)
        # Raumtemperatur
        if ran == 4:
            base_value = round(random.uniform(36, 48), 2)
            data["Room Temperature"].append(base_value)
        else:
            base_value = round(random.uniform(18, 30), 2)
            data["Room Temperature"].append(base_value)
    return pd.DataFrame(data)
# Speichert den Dataframe als csv-Datei
def save_to_csv(df, filename):
    filepath = os.path.join('C:\\Users\\WorkTablet\\Desktop\\Machine', filename)
    df.to_csv(filepath, index=False)
    print(f"Daten erfolgreich in {filepath} gespeichert.")
#Funktion, um mehrere csv-Dateien zu schreiben
def generate_multiple_excel_files(n):
    for i in range(1, n + 1):
        data = generate_data()
        filename = f"testdaten_{i}.csv"
        save_to_csv(data, filename)
#Hauptprogramm
if __name__ == "__main__":
    num_files = int(input("Wie viele Excel-Dateien sollen erstellt werden? "))
    generate_multiple_excel_files(num_files)