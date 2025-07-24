#!/bin/bash
export BITCOINCLI="bitcoin-cli -conf=/mnt/nvme-4tb/bitcoin/bitcoin.conf"

while true; do
  clear
  echo "=== Bitcoin Node Sync-Status ==="
  $BITCOINCLI getblockchaininfo | jq '{
    "Blockchain": .chain,
    "Blocks": .blocks,
    "Headers": .headers,
    "Sync Progress (%)": (.verificationprogress * 100 | round),
    "Pruned": .pruned
  }'

  echo ""
  echo "=== Verbindungen ==="

  inbound=$($BITCOINCLI getpeerinfo | jq '[.[] | select(.inbound == true)] | length')
  outbound=$($BITCOINCLI getpeerinfo | jq '[.[] | select(.inbound == false)] | length')
  total=$(($inbound + $outbound))

  echo "Gesamt:       $total"
  echo "Eingehend:    $inbound"
  echo "Ausgehend:    $outbound"

  sleep 5
done
