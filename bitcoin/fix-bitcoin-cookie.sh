#!/bin/bash

COOKIE="/mnt/nvme-4tb/bitcoin/.cookie"

# Warte, bis .cookie existiert
while [ ! -f "$COOKIE" ]; do
  sleep 3
done

# Cookie-Berechtigung ändern
chown bitcoin:bitcoin "$COOKIE"
chmod 644 "$COOKIE"

exit 0
