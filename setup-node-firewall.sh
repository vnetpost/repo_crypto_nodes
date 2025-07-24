#!/bin/bash

# UFW aktivieren und Grundeinstellungen setzen
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed
ufw logging on

# ----------- ERLAUBT im LAN (192.168.0.0/16) -----------

# Bitcoin
ufw allow from 192.168.0.0/16 to any port 8332 proto tcp comment 'Bitcoin RPC nur LAN'
ufw allow from 192.168.0.0/16 to any port 8333 proto tcp comment 'Bitcoin P2P nur LAN'

# Monero
ufw allow from 192.168.0.0/16 to any port 18080 proto tcp comment 'Monero P2P nur LAN'
ufw allow from 192.168.0.0/16 to any port 18081 proto tcp comment 'Monero RPC nur LAN'

# SSH & VNC
ufw allow from 192.168.0.0/16 to any port 22 proto tcp comment 'SSH nur LAN'
ufw allow from 192.168.0.0/16 to any port 5900:5999 proto tcp comment 'VNC nur LAN'

# Electrs
ufw allow from 192.168.0.0/16 to any port 50001 proto tcp comment 'Electrs Electrum nur LAN'
ufw allow from 192.168.0.0/16 to any port 4224 proto tcp comment 'Electrs HTTP nur LAN'

# Mempool
ufw allow from 192.168.0.0/16 to any port 80 proto tcp comment 'Mempool Frontend nur LAN'
ufw allow from 192.168.0.0/16 to any port 8080 proto tcp comment 'Mempool Frontend nur LAN'
ufw allow from 192.168.0.0/16 to any port 8999 proto tcp comment 'Mempool API nur LAN'

# MySQL
ufw allow from 192.168.0.0/16 to any port 3306 proto tcp comment 'MySQL nur LAN'

# ----------- VERBIETEN aus dem Internet -----------

# Bitcoin
ufw deny from any to any port 8332 proto tcp comment 'Block: Bitcoin RPC aus Internet'
ufw deny from any to any port 8333 proto tcp comment 'Block: Bitcoin P2P aus Internet'

# Monero
ufw deny from any to any port 18080 proto tcp comment 'Block: Monero P2P aus Internet'
ufw deny from any to any port 18081 proto tcp comment 'Block: Monero RPC aus Internet'

# SSH & VNC
ufw deny from any to any port 22 proto tcp comment 'Block: SSH aus Internet'
ufw deny from any to any port 5900:5999 proto tcp comment 'Block: VNC aus Internet'

# Electrs
ufw deny from any to any port 50001 proto tcp comment 'Block: Electrs aus Internet'
ufw deny from any to any port 4224 proto tcp comment 'Block: Electrs HTTP aus Internet'

# Mempool & MySQL
ufw deny from any to any port 8999 proto tcp comment 'Block: Mempool API aus Internet'
ufw deny from any to any port 3306 proto tcp comment 'Block: MySQL aus Internet'

# Firewall aktivieren (falls noch nicht aktiv)
ufw --force enable

echo "UFW-Regeln wurden erfolgreich angewendet."
