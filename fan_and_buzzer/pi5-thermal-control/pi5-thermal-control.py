#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Raspberry Pi 5 - Temperatur-Lüfter-Buzzer Steuerung (lgpio Version)
Noctua NF-A4x20 5V PWM + Aktiver Buzzer
"""

import time
import threading
import logging
import signal
import sys
import lgpio

# -------------------
# Hardware-Pins
# -------------------
FAN_PWM_PIN = 18    # GPIO18 (Pin 12) - PWM Steuerung (Blau)
BUZZER_PIN = 26     # GPIO26 (Pin 37) - Aktiver Buzzer
# Noctua NF-A4x20 5V PWM Farben: Gelb=5V, Schwarz=GND, Grün=Tach, Blau=PWM

# -------------------
# Temperatur -> Lüfter %
# -------------------
#TEMP_CONFIG = {
#    30: 25,   # 30°C → 25%
#    40: 40,   # 40°C → 40%
#    50: 70,   # 50°C → 70%
#    60: 100   # 60°C → 100%
#}

TEMP_CONFIG = {
    30: 30,   # 30°C → 30%
    40: 50,   # 40°C → 50%
    50: 70,   # 50°C → 70%
    55: 100   # 55°C → 100%
}

# -------------------
# Buzzer-Konfiguration
# -------------------
BUZZER_INTERVAL = 0.1       # Piepen alle 0.5s
BUZZER_TEMP_THRESHOLD = 55  # Ab 40°C aktiv

# -------------------
# PWM-Konfiguration
# -------------------
PWM_FREQ = 5000  # 5 kHz - kompatibel mit lgpio

# -------------------
# Logging
# -------------------
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/pi5-thermal-control.log'),
        logging.StreamHandler()
    ]
)

class ThermalController:
    def __init__(self):
        self.current_fan_speed = 0
        self.buzzer_active = False
        self.buzzer_thread = None
        self.buzzer_stop_event = threading.Event()
        self.running = True

        # GPIO-Chip öffnen
        self.chip = lgpio.gpiochip_open(0)

        # Fan PWM Setup
        lgpio.gpio_claim_output(self.chip, FAN_PWM_PIN)
        lgpio.tx_pwm(self.chip, FAN_PWM_PIN, PWM_FREQ, 0)  # Duty=0%

        # Buzzer Setup
        lgpio.gpio_claim_output(self.chip, BUZZER_PIN)
        lgpio.gpio_write(self.chip, BUZZER_PIN, 0)

        logging.info("🌡️ Thermal Controller initialisiert")
        self.log_hardware_info()

    def get_cpu_temp(self):
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                return int(f.read().strip()) / 1000.0
        except:
            return 0

    def calculate_fan_speed(self, temp):
        if temp < 30:
            return 0
        for t in sorted(TEMP_CONFIG.keys(), reverse=True):
            if temp >= t:
                return TEMP_CONFIG[t]
        return 0

    def set_fan_speed(self, percent):
        if percent != self.current_fan_speed:
            lgpio.tx_pwm(self.chip, FAN_PWM_PIN, PWM_FREQ, percent)
            self.current_fan_speed = percent
            logging.info(f"🌀 Lüfter auf {percent}% gesetzt")

    def buzzer_worker(self):
        while not self.buzzer_stop_event.is_set():
            lgpio.gpio_write(self.chip, BUZZER_PIN, 1)
            time.sleep(BUZZER_INTERVAL / 2)
            lgpio.gpio_write(self.chip, BUZZER_PIN, 0)
            time.sleep(BUZZER_INTERVAL * 40)

    def start_buzzer(self):
        if not self.buzzer_active:
            self.buzzer_active = True
            self.buzzer_stop_event.clear()
            self.buzzer_thread = threading.Thread(target=self.buzzer_worker, daemon=True)
            self.buzzer_thread.start()
            logging.warning(f"🚨 BUZZER aktiviert (Temp ≥ {BUZZER_TEMP_THRESHOLD}°C)")

    def stop_buzzer(self):
        if self.buzzer_active:
            self.buzzer_active = False
            self.buzzer_stop_event.set()
            lgpio.gpio_write(self.chip, BUZZER_PIN, 0)
            logging.info("🔇 Buzzer deaktiviert")

    def log_status(self, temp):
        buzzer_status = "🚨" if self.buzzer_active else "🔇"
        fan_status = f"🌀{self.current_fan_speed}%"
        print(f"🌡️ {temp:.1f}°C | {fan_status} | {buzzer_status}")

    def log_hardware_info(self):
        logging.info("="*50)
        logging.info(f"PWM Pin (Blau): GPIO{FAN_PWM_PIN}")
        logging.info(f"Buzzer Pin: GPIO{BUZZER_PIN}")
        logging.info(f"PWM Frequenz: {PWM_FREQ} Hz")
        for t, s in TEMP_CONFIG.items():
            logging.info(f"{t}°C → {s}%")
        logging.info("="*50)

    def cleanup(self):
        try:
            self.stop_buzzer()
            self.set_fan_speed(0)
            time.sleep(0.5)
            lgpio.gpiochip_close(self.chip)
            logging.info("GPIO geschlossen")
        except Exception as e:
            logging.error(f"Fehler beim cleanup: {e}")

    def run(self):
        try:
            while self.running:
                temp = self.get_cpu_temp()
                fan_speed = self.calculate_fan_speed(temp)
                self.set_fan_speed(fan_speed)

                if temp >= BUZZER_TEMP_THRESHOLD:
                    self.start_buzzer()
                else:
                    self.stop_buzzer()

                self.log_status(temp)
                time.sleep(2)
        except KeyboardInterrupt:
            pass
        finally:
            self.cleanup()

def signal_handler(sig, frame):
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    controller = ThermalController()
    controller.run()
