#!/bin/bash

while true; do
    clear
    echo "=== Bitcoin Node Status ==="
    bitcoin-cli -conf=/mnt/nvme-4tb/bitcoin/bitcoin.conf getblockchaininfo | jq '{
      chain,
      blocks,
      headers,
      verificationprogress
    }'

    echo ""
    echo "=== Electrs Status ==="
    systemctl is-active electrs &> /dev/null && echo "Electrs läuft ✅" || echo "Electrs NICHT aktiv ❌"

    echo ""
    echo "=== Mempool Frontend (Port 8080) ==="
    curl -s --max-time 2 http://127.0.0.1:8080 > /dev/null && \
        echo "Mempool Frontend erreichbar ✅" || \
        echo "Mempool Frontend NICHT erreichbar ❌"

    echo ""
    echo "=== Mempool API (Port 8999) ==="
    ss -tln | grep -q ':8999' && \
        echo "Mempool API lauscht ✅" || \
        echo "Mempool API NICHT erreichbar ❌"

    echo ""
    echo "=== Monero Node Status ==="
    # Check ob monerod läuft
    systemctl is-active monerod &> /dev/null && echo "monerod läuft ✅" || echo "monerod NICHT aktiv ❌"

    # RPC-Status über curl
    MONERO_RPC='{"jsonrpc":"2.0","id":"0","method":"get_block_count"}'
    RPC_RESULT=$(curl -s -d "$MONERO_RPC" -H "Content-Type: application/json" http://127.0.0.1:18081/json_rpc)

    if echo "$RPC_RESULT" | jq .result.count &>/dev/null; then
        HEIGHT=$(echo "$RPC_RESULT" | jq .result.count)
        echo "Monero Blockhöhe: $HEIGHT"
    else
        echo "Monero RPC nicht erreichbar ❌"
    fi

    echo ""
    date
    sleep 5
done
