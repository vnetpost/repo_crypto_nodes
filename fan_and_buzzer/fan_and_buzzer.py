# /usr/local/bin/fan_and_buzzer.py
import time
import RPi.GPIO as GPIO

FAN_PIN = 13       # GPIO13 (PWM)
BUZZER_PIN = 26    # GPIO26 (Digital)
FAN_FREQ = 25000   # 25 kHz PWM

GPIO.setmode(GPIO.BCM)
GPIO.setup(FAN_PIN, GPIO.OUT)
GPIO.setup(BUZZER_PIN, GPIO.OUT)

fan = GPIO.PWM(FAN_PIN, FAN_FREQ)
fan.start(0)

def get_cpu_temp():
    with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
        return int(f.read()) / 1000.0

try:
    while True:
        temp = get_cpu_temp()
        print(f"CPU-Temp: {temp:.1f}°C")

        # Lüfterregelung
        if temp < 50:
            fan.ChangeDutyCycle(0)
        elif temp < 60:
            fan.ChangeDutyCycle(30)
        elif temp < 70:
            fan.ChangeDutyCycle(60)
        else:
            fan.ChangeDutyCycle(100)

        # Buzzer bei Überhitzung
        if temp >= 70:
            GPIO.output(BUZZER_PIN, GPIO.HIGH)
            time.sleep(0.2)
            GPIO.output(BUZZER_PIN, GPIO.LOW)
        else:
            GPIO.output(BUZZER_PIN, GPIO.LOW)

        time.sleep(5)

except KeyboardInterrupt:
    print("Beendet.")
finally:
    fan.stop()
    GPIO.cleanup()
