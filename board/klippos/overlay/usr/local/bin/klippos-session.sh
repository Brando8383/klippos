#!/bin/bash
# KlippOS X Session Startup
# Launches openbox and Fluidd kiosk after Klipper stack is running

LOGFILE="/var/log/klippos-session.log"

echo "Starting KlippOS session: $(date)" >> $LOGFILE

# Disable screen blanking and power management
xset s off
xset s noblank
xset -dpms

# Set trackpad and mouse options via xinput
xinput --set-prop "$(xinput list --name-only | grep -i touchpad | head -1)" \
    "libinput Tapping Enabled" 1 2>/dev/null

# Hide cursor when idle
unclutter -idle 3 &

# Wait for Fluidd to be ready
echo "Waiting for Fluidd..." >> $LOGFILE
for i in $(seq 1 60); do
    if curl -s http://localhost > /dev/null; then
        break
    fi
    sleep 2
done

# Launch Chromium in kiosk mode
chromium-browser \
    --kiosk \
    --no-sandbox \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --autoplay-policy=no-user-gesture-required \
    --start-fullscreen \
    http://localhost &

# Start openbox
exec openbox-session
