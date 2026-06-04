#!/bin/bash
# KlippOS WiFi Setup Wizard
# Runs on first boot to configure WiFi before KIAUH install

LOGFILE="/var/log/klippos-setup.log"
WIFI_DONE="/etc/klippos/.wifi_configured"

# Skip if already configured
if [ -f "$WIFI_DONE" ]; then
    exit 0
fi

# Check if already connected
if ping -c 1 github.com &>/dev/null; then
    echo "Already connected to internet, skipping WiFi setup." | tee -a $LOGFILE
    mkdir -p /etc/klippos
    touch $WIFI_DONE
    exit 0
fi

clear
echo "========================================="
echo "          KlippOS WiFi Setup"
echo "========================================="
echo ""
echo "KlippOS needs internet access to install"
echo "Klipper, Moonraker, and Fluidd."
echo ""

# List available networks
echo "Scanning for WiFi networks..."
nmcli device wifi rescan 2>/dev/null
sleep 3
echo ""
echo "Available networks:"
echo "-----------------------------------------"
nmcli -f SSID,SIGNAL,SECURITY device wifi list 2>/dev/null | head -20
echo "-----------------------------------------"
echo ""

# Get credentials
read -p "Enter WiFi network name (SSID): " WIFI_SSID
read -s -p "Enter WiFi password: " WIFI_PASS
echo ""

if [ -z "$WIFI_SSID" ]; then
    echo "No SSID entered. Skipping WiFi setup."
    echo "You can configure WiFi manually later using: nmcli"
    exit 0
fi

# Connect
echo ""
echo "Connecting to $WIFI_SSID..."
nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASS" 2>&1 | tee -a $LOGFILE

# Verify connection
sleep 5
if ping -c 1 github.com &>/dev/null; then
    echo ""
    echo "Successfully connected to $WIFI_SSID!" | tee -a $LOGFILE
    mkdir -p /etc/klippos
    touch $WIFI_DONE
else
    echo ""
    echo "Could not connect to $WIFI_SSID." | tee -a $LOGFILE
    echo "Check your password and try again."
    echo "You can configure WiFi manually later using: nmcli"
    rm -f $WIFI_DONE
fi
