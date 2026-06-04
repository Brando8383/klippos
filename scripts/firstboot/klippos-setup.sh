#!/bin/bash
# KlippOS First Boot Setup
# Runs once on first boot to install Klipper stack via KIAUH

LOGFILE="/var/log/klippos-setup.log"
KIAUH_DIR="/home/klippos/kiauh"
KIAUH_REPO="https://github.com/dw-0/kiauh.git"
SETUP_DONE="/etc/klippos/.setup_complete"

echo "========================================" | tee -a $LOGFILE
echo "KlippOS First Boot Setup" | tee -a $LOGFILE
echo "Started: $(date)" | tee -a $LOGFILE
echo "========================================" | tee -a $LOGFILE

# Check if setup already completed
if [ -f "$SETUP_DONE" ]; then
    echo "Setup already completed. Skipping." | tee -a $LOGFILE
    exit 0
fi

# Run WiFi setup wizard first
echo "Starting WiFi setup..." | tee -a $LOGFILE
bash /usr/local/bin/klippos-wifi-setup.sh

# Wait for network
echo "Waiting for network..." | tee -a $LOGFILE
for i in $(seq 1 30); do
    if ping -c 1 github.com &>/dev/null; then
        echo "Network is up." | tee -a $LOGFILE
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Network not available. KIAUH install skipped." | tee -a $LOGFILE
        echo "Reboot to try again."
        exit 1
    fi
    sleep 2
done

# Clone and run KIAUH
echo "Cloning KIAUH..." | tee -a $LOGFILE
cd /home/klippos
git clone $KIAUH_REPO $KIAUH_DIR
chown -R klippos:klippos $KIAUH_DIR
cd $KIAUH_DIR

echo "Running KIAUH installer..." | tee -a $LOGFILE
sudo -u klippos bash $KIAUH_DIR/kiauh.sh

# Mark setup complete
mkdir -p /etc/klippos
touch $SETUP_DONE
echo "KlippOS setup complete: $(date)" | tee -a $LOGFILE
