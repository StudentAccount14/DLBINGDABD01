import random
from mailmerge import MailMerge
import os
import win32com.client
from docx import Document
#Konstanten
# Pfade zu den Templates
TEMPLATE_PATH = ['C:\\Users\\WorkTablet\\Desktop\\Vorlagen\\Rechnung_Vorlage.docx',
                'C:\\Users\\WorkTablet\\Desktop\\Vorlagen\\Rechnung_Vorlage_mehrseitig.docx',
                'C:\\Users\\WorkTablet\\Desktop\\Vorlagen\\Dienstleistungsrechnung.docx',
                'C:\\Users\\WorkTablet\\Desktop\\Vorlagen\\Dienstleistungsrechnung_mehrseitig.docx'
                 ]
# Ordner, in dem die Rechnungen als docx gespeichert werden
OUTPUT_DIR = 'C:\\Users\\WorkTablet\\Desktop\\Vorlagen\\Testdaten\\'
# Ordner, in dem die Rechnungen als txt gespeichert werden
TEXT_OUTPUT_DIR = 'C:\\Users\\WorkTablet\\Desktop\\Vorlagen\\Testdaten_txt\\'
# Liste der möglichen PLZ-Werte aus Österreich für Kleinkunden und Mittelgroße Kunden
PLZ_LIST_A = [
    '1000', '1004', '1006', '1010', '2000', '2051', '3110', '3121', '3720',
    '4141', '5724', '5730', '7332', '6022', '9992'
]
# Liste der möglichen PLZ-Werte von Großkunden
# Es soll nur an 2 möglichen Standorten Großkunden geben
PLZ_LARGE_CUSTOMER = [
    '1211', '8700',
]
# Liste der vorgegebenen PLZ-Werte aus Deutschland
PLZ_LIST_D = [
    '84076', '93195', '07557', '18069', '92711', '93138', '84427'
]
#Liste der möglichen Straßen
STREET_LIST = [
    'Musterstraße 1', 'Mustergasse 1', 'Musterweg 1', 'Musterplatz 1',
    'Musterstraße 2', 'Mustergasse 2', 'Musterweg 2', 'Musterplatz 2',
    'Musterstraße 3', 'Mustergasse 3', 'Musterweg 3', 'Musterplatz 3',
    'Musterstraße 4', 'Mustergasse 4', 'Musterweg 4', 'Musterplatz 4',
    'Musterstraße 7B', 'Mustergasse 12', 'Musterweg 101', 'Musterplatz 19A',
]
#Die möglichen Länder
COUNTRY_LIST = [
    'Österreich', 'Deutschland'
]
# Funktion zur Generierung eines zufälligen Rechnungsbetrags
def generate_invoice_amount():
    rand = random.randint(0,10)
    # Damit Kleinkunden im Datensatz häufiger sind
    if rand < 7:
        #Kleinkunden
        ret = random.randint(100, 20000)
    else:
        #Mittelgroße Kunden
        ret = random.randint(50000, 250000)
    return ret
# Funktion um  ein Word-Dokument in eine Textdatei zu konvertieren
def word_to_txt_pywin32(word_file, text_file):
    # Überprüft, ob die Eingabedatei existiert
    if not os.path.exists(word_file):
        print(f"Fehler: Die Datei {word_file} existiert nicht.")
        return
    # Öffnet die Word-Anwendung
    word = win32com.client.Dispatch("Word.Application")
    # Versteckt die Anwendung im Hintergrund
    word.Visible = False
    try:
        # Öffnet das Word-Dokument
        doc = word.Documents.Open(word_file)
        # Öffnet die TXT-Datei zum Schreiben
        with open(text_file, 'w', encoding='utf-8') as f:
            # Iteriert durch alle Absätze im Dokument
            for paragraph in doc.Paragraphs:
                # Schreibt den Absatztext ohne das abschließende Steuerzeichen
                text = paragraph.Range.Text.strip()
                # Überspringt leere Absätze
                if text:
                    # Verwendet '\n' für den Zeilenumbruch
                    f.write(text + '\n')
        print(f"Textdatei erfolgreich erstellt: {text_file}")
    # Fehlerbehandlung
    except Exception as e:
        print(f"Ein Fehler ist aufgetreten: {e}")
    finally:
        # Schließt das Dokument und beendet Word
        doc.Close(False)
        word.Quit()

def generate_invoice(num_files):
    #Um die verschiedenen Rechnungsformate zu erstellen
    for i in range(1, num_files + 1):
        index = 0
        rand = random.randint(0,20)
        match rand:
            case num if num in range(19, 21):
                index = 3
            case num if num in range(15, 19):
                index = 2
            case num if num in range(11, 15):
                index = 1
        # Lädt die jeweilige Word-Vorlage
        with MailMerge(TEMPLATE_PATH[index]) as template:
            # Zufällige Auswahl der PLZ und Generierung des Rechnungsbetrags
            street = random.choice(STREET_LIST)
            #Großkunden kaufen mehr Ware
            if random.randint(0,100) < 2:
                country = COUNTRY_LIST[0]
                plz = random.choice(PLZ_LARGE_CUSTOMER)
                invoice_amount = random.randint(500000, 5000000)
            else:
                if random.randint(0, 26) == 25:
                    country = COUNTRY_LIST[1]
                    plz = random.choice(PLZ_LIST_D)
                else:
                    country = COUNTRY_LIST[0]
                    plz = random.choice(PLZ_LIST_A)
                invoice_amount = generate_invoice_amount()
            # Daten für den aktuellen Datensatz
            data = {
                'PLZ': plz,
                'Strasse': street,
                'Land': country,
                'Rechnungsbetrag': f"{invoice_amount:,} €".replace(',', '.')
            }
            # Führt den Merge durch
            template.merge(**data)
            # Um Verwechslungen zu vermeiden sind die Variablen auf deutsch
            # Dateiname für die ausgegebene Rechnung
            datei_name = f"Rechnung_{i}.docx"
            ausgabe_pfad = os.path.join(OUTPUT_DIR, datei_name)
            # Speichert die ausgefüllten Rechnungen
            template.write(ausgabe_pfad)
            print(f"Rechnung {i} erstellt: {ausgabe_pfad}")
            # Konvertiert das Word-Dokument zu einer Textdatei
            text_dateiname = os.path.splitext(datei_name)[0] + ".txt"
            text_ausgabe_pfad = os.path.join(TEXT_OUTPUT_DIR, text_dateiname)
            word_to_txt_pywin32(ausgabe_pfad, text_ausgabe_pfad)
print("Alle Rechnungen wurden erfolgreich erstellt.")

if __name__ == "__main__":
    num_files = int(input("Wie viele Rechnungen sollen erstellt werden? "))
    generate_invoice(num_files)

