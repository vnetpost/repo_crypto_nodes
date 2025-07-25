#!/bin/bash

echo "=== BITCOIN + ELECTRS + MONERO NODE STATUS ==="
echo

# 1. Prüfe systemd Service Status
echo "1. Systemd Service Status:"
for svc in bitcoind electrs monerod; do
    status=$(systemctl is-active $svc 2>/dev/null || echo "not found")
    echo "  $svc: $status"
done
echo

# 2. Prüfe offene Ports
echo "2. Offene Ports (Bitcoin, Electrs, Monero):"
ss -tlnp | grep -E "8332|8333|50001|4224|18081|18080" || echo "Keine relevanten Ports offen!"
echo

# 3. Electrs Server-Version via HTTP Monitoring Port (4224)
echo "3. Electrs Server-Version (HTTP Monitoring Port 4224):"
ELECTRS_VERSION=$(curl -s http://localhost:4224/metrics | grep ^electrs_banner | cut -d'"' -f2)
if [ -n "$ELECTRS_VERSION" ]; then
    echo "$ELECTRS_VERSION"
else
    echo "Electrs HTTP Monitoring nicht erreichbar oder keine Versionsinfo"
fi
echo

# 4. Bitcoin Core Blockchain-Height
BTC_HEIGHT=$(bitcoin-cli -datadir=/mnt/nvme-4tb/bitcoin getblockchaininfo | jq -r .blocks)
echo "4. Bitcoin Core Blockchain Height: $BTC_HEIGHT"
echo

# 5. Electrs Index Height via HTTP Monitoring
ELECTRS_HEIGHT=$(curl -s http://localhost:4224/metrics | grep '^electrs_index_height' | awk '{print $2}')
echo "5. Electrs Index Height: $ELECTRS_HEIGHT"
echo

# 6. Sync Status Vergleich Bitcoin Core vs Electrs
if [ "$BTC_HEIGHT" = "$ELECTRS_HEIGHT" ]; then
    echo "✅ Electrs ist synchron mit Bitcoin Core"
else
    echo "❌ Electrs ist NICHT synchron"
fi
echo

# 7. Monero Daemon Status via RPC (Standard-Port 18081)
echo "6. Monero Daemon Status:"
MONERO_STATUS=$(curl -s http://127.0.0.1:18081/get_info | jq -r '.status' 2>/dev/null)
if [ "$MONERO_STATUS" == "OK" ] || [ -z "$MONERO_STATUS" ]; then
    echo "Monero Daemon antwortet korrekt"
else
    echo "Monero Daemon antwortet nicht oder Status unbekannt"
fi
echo

# 8. Monero Blockchain Height
MONERO_HEIGHT=$(curl -s http://127.0.0.1:18081/get_info | jq -r '.height')
if [ -n "$MONERO_HEIGHT" ]; then
    echo "Monero Blockchain Height: $MONERO_HEIGHT"
else
    echo "Monero Blockchain Height nicht verfügbar"
fi
echo

# 9. Letzte electrs Logs (5 Zeilen Fehler)
echo "7. Letzte electrs Logs (Fehler):"
journalctl -u electrs --no-pager -n 5 | grep -i error || echo "Keine Fehler in electrs-Logs"
echo

# 10. Electrs Datenbank Größe
echo "8. Electrs DB Größe:"
du -sh /mnt/nvme-4tb/electrs/db/
echo

echo "=== STATUS ABGESCHLOSSEN ==="
