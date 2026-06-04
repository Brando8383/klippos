#!/bin/bash
# KlipOS First Boot Setup Script
# Runs once on first boot to install Klipper stack via KIAUH

LOGFILE="/var/log/klipos-setup.log"
KIAUH_DIR="/home/klipos/kiauh"
KIAUH_REPO="https://github.com/dw-0/kiauh.git"
SETUP_DONE="/etc/klipos/.setup_complete"

echo "========================================" | tee -a $LOGFILE
echo "KlipOS First Boot Setup" | tee -a $LOGFILE
echo "Started: $(date)" | tee -a $LOGFILE
echo "========================================" | tee -a $LOGFILE

# Check if setup already completed
if [ -f "$SETUP_DONE" ]; then
    echo "Setup already completed. Skipping." | tee -a $LOGFILE
    exit 0
fi

# Wait for network
echo "Waiting for network..." | tee -a $LOGFILE
for i in $(seq 1 30); do
    if ping -c 1 github.com &>/dev/null; then
        echo "Network is up." | tee -a $LOGFILE
        break
    fi
    sleep 2
done

# Create klipos user
echo "Creating klipos user..." | tee -a $LOGFILE
useradd -m -s /bin/bash klipos
usermod -aG tty,dialout,sudo klipos
echo "klipos:klipos" | chpasswd

# Clone KIAUH
echo "Cloning KIAUH..." | tee -a $LOGFILE
git clone $KIAUH_REPO $KIAUH_DIR
chown -R klipos:klipos $KIAUH_DIR

# Run KIAUH silent install
echo "Installing Klipper stack..." | tee -a $LOGFILE
sudo -u klipos bash $KIAUH_DIR/kiauh.sh

# Mark setup complete
mkdir -p /etc/klipos
touch $SETUP_DONE

echo "KlipOS setup complete: $(date)" | tee -a $LOGFILE
