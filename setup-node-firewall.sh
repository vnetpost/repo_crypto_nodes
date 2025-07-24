#!/bin/bash
# Firewall & IPv6-Deaktivierungs-Skript für Bitcoin/Monero-Fullnode im Heimnetz

set -e

echo "🔧 Setze UFW-Standardregeln..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "✅ Erlaube LAN-Zugriff auf Bitcoin & Monero (RPC & P2P)..."
sudo ufw allow from 192.168.0.0/16 to any port 8332 proto tcp comment 'Bitcoin RPC nur LAN'
sudo ufw allow from 192.168.0.0/16 to any port 8333 proto tcp comment 'Bitcoin P2P nur LAN'
sudo ufw allow from 192.168.0.0/16 to any port 18080 proto tcp comment 'Monero P2P nur LAN'
sudo ufw allow from 192.168.0.0/16 to any port 18081 proto tcp comment 'Monero RPC nur LAN'

echo "✅ Erlaube SSH nur aus dem LAN..."
sudo ufw allow from 192.168.0.0/16 to any port 22 proto tcp comment 'SSH nur LAN'

echo "🚫 Blockiere externen Zugriff auf alle sensiblen Ports..."
sudo ufw deny in to any port 8332 proto tcp comment 'Block: Bitcoin RPC aus Internet'
sudo ufw deny in to any port 8333 proto tcp comment 'Block: Bitcoin P2P aus Internet'
sudo ufw deny in to any port 18080 proto tcp comment 'Block: Monero P2P aus Internet'
sudo ufw deny in to any port 18081 proto tcp comment 'Block: Monero RPC aus Internet'
sudo ufw deny in to any port 22 proto tcp comment 'Block: SSH aus Internet'

echo "🛑 Deaktiviere IPv6 in UFW..."
sudo sed -i 's/^IPV6=.*/IPV6=no/' /etc/ufw/ufw.conf

echo "🛑 Deaktiviere IPv6 systemweit..."
sudo bash -c 'cat > /etc/sysctl.d/99-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF'

echo "📡 wende sysctl-Änderungen an..."
sudo sysctl -p /etc/sysctl.d/99-disable-ipv6.conf

echo "🔥 Aktiviere UFW..."
sudo ufw --force enable

echo "✅ Firewall aktiv. IPv6 deaktiviert."
