#!/usr/bin/env python3

import time
from gpiozero import Buzzer
import os

# GPIO 24 verwenden (BCM-Nummerierung)
buzzer = Buzzer(24)

# Temperaturgrenze
TEMP_LIMIT = 60.0

def get_cpu_temp():
    try:
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
            temp_str = f.readline()
            return int(temp_str) / 1000  # in Grad Celsius
    except Exception as e:
        print("Fehler beim Lesen der CPU-Temperatur:", e)
        return 0

print("Starte CPU-Überwachung mit Buzzer-Alarm...")

try:
    while True:
        temp = get_cpu_temp()
        print(f"Aktuelle Temperatur: {temp:.1f} °C")

        if temp >= TEMP_LIMIT:
            print("❗ Temperatur zu hoch – Buzzer aktiv")
            buzzer.on()
            time.sleep(0.1)
            buzzer.off()
            time.sleep(1)  # Piept alle 1 Sekunde
        else:
            buzzer.off()
            time.sleep(5)  # Prüft alle 5 Sekunden erneut

except KeyboardInterrupt:
    print("Programm beendet.")
    buzzer.off()
