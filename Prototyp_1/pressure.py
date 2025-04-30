import pandas as pd
import random
import os
# Für die Wartungstermine
from datetime import datetime, timedelta
#Funktion, damit jede Maschine einen zufälligen Initialwartungstermin hat
def random_date():
    #  1. Januar 2023
    start_date = datetime(2023, 1, 1)
    # 31. Dezember 2024
    end_date = datetime(2024, 12, 31)
    # Berechnet die Differenz in Tagen zwischen den beiden Datumswerten
    delta_days = (end_date - start_date).days
    # Generiert eine zufällige Anzahl von Tagen zwischen 0 und der ermittelten Differenz
    random_days = random.randint(0, delta_days)
    # Erhöht das Startdatum um die zufällige Anzahl an Tagen
    return start_date + timedelta(days=random_days)
# Berechnet den neuen Wartungstermin basierend auf dem vorherigen
def new_date(last_date, passed_days):
    return last_date + timedelta(days=passed_days)
# Funktion zur Generierung der Daten
def generate_data():
    # Die Anzahl der Datensätze pro csv-Datei (für alle einheitlich 300)
    num_records = 300
    # Damit einige Maschinen einen höheren Druck haben
    num_outliers = min(random.randint(0,3), random.randint(0,3))
    # Die Messgrößen
    data = {
        "Intake Pressure": [],
        "Maintenance Date": [],
    }
    # Generiert die Daten, dabei werden die Zeilen schrittweise befüllt.
    # Eine Maschine muss dann gewartet werden, wenn ihre Lebenserwartung (life) <=0 ist.
    for x in range(num_records):
        if x ==0:
            maintanence = random_date()
            pressure = 0
            life = 20
        #Simuliert gelegentlich auftrettende fehlende Daten (ein bisschen unter 1%)
        if random.randint(0, 101) < 1:
            data["Intake Pressure"].append("-")
            data["Maintenance Date"].append(maintanence)
        else:
            #Erhöhte Druckbereiche bei Vorhandensein von Ausreißern
            if num_outliers > 0:
                pressure = round(random.uniform(475 + 25.0*num_outliers , 640+ 25.0*num_outliers), 2)
            else:
                pressure = round(random.uniform(475, 640), 2)
            data["Intake Pressure"].append(pressure)
            # Es gibt eine Chance Lebenserwartung (life) zu reduzieren, wenn pressure > 610
            if pressure > 610:
                life -=  random.randint(0,1)
            if pressure > 625:
                life -= random.randint(0, 1)
            #Zusätzliche (erhöhte) Chance Lebenserwartung (life) zu reduzieren, wenn pressure > 650
            if pressure > 650:
                life -=  random.randint(0,2)
            #Zusätzliche (erhöhte) Chance Lebenserwartung (life) zu reduzieren, wenn pressure > 700
            if pressure > 700:
                life -= random.randint(0,2)
            #Wenn die Lebenserwartung <= 0 ist, wird eine Wartung durchgeführt
            if life <= 0:
                life = 20
                maintanence = new_date(maintanence, x)
            data["Maintenance Date"].append(maintanence)
    return pd.DataFrame(data)
# Speichert den Dataframe als csv-Datei
def save_to_csv(df, filename):
    filepath = os.path.join('C:\\Users\\WorkTablet\\Desktop\\Pressure', filename)
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




