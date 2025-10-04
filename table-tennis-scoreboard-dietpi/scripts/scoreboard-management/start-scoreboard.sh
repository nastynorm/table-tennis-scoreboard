#!/bin/bash

# Table Tennis Scoreboard Kiosk Startup Script
# Optimized for Pi Zero 2W with DietPi
# Version: 1.0

# Configuration
SCOREBOARD_DIR="/home/dietpi/scoreboard"
SERVER_PORT=3000
LOG_FILE="/var/log/scoreboard-kiosk.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting Table Tennis Scoreboard Kiosk..."

# Wait for network connection
log "Waiting for network connection..."
NETWORK_TIMEOUT=60
NETWORK_COUNTER=0

while ! ping -c 1 -W 2 google.com >/dev/null 2>&1; do
    if [ $NETWORK_COUNTER -ge $NETWORK_TIMEOUT ]; then
        log "Network timeout reached. Continuing without network verification."
        break
    fi
    log "Network not ready, waiting... ($NETWORK_COUNTER/$NETWORK_TIMEOUT)"
    sleep 2
    NETWORK_COUNTER=$((NETWORK_COUNTER + 2))
done

if [ $NETWORK_COUNTER -lt $NETWORK_TIMEOUT ]; then
    log "Network connection established."
fi

# Change to scoreboard directory
cd "$SCOREBOARD_DIR" || {
    log "Error: Cannot access scoreboard directory: $SCOREBOARD_DIR"
    exit 1
}

# Start local server for built application
log "Starting scoreboard server on port $SERVER_PORT..."
serve dist -l $SERVER_PORT &
SERVER_PID=$!

if [ $? -eq 0 ]; then
    log "Server started successfully with PID: $SERVER_PID"
else
    log "Error: Failed to start server"
    exit 1
fi

# Wait for server to start
log "Waiting for server to initialize..."
sleep 5

# Verify server is running
if ! kill -0 $SERVER_PID 2>/dev/null; then
    log "Error: Server failed to start properly"
    exit 1
fi

# Test server response
SERVER_READY=false
for i in {1..10}; do
    if curl -s "http://localhost:$SERVER_PORT" >/dev/null 2>&1; then
        SERVER_READY=true
        log "Server is responding to requests"
        break
    fi
    log "Server not ready, attempt $i/10..."
    sleep 2
done

if [ "$SERVER_READY" = false ]; then
    log "Warning: Server may not be fully ready, but continuing..."
fi

# Configure display settings
log "Configuring display settings..."
export DISPLAY=:0

# Disable screen blanking and power management
xset s off 2>/dev/null || log "Warning: Could not disable screen saver"
xset s noblank 2>/dev/null || log "Warning: Could not disable screen blanking"
xset -dpms 2>/dev/null || log "Warning: Could not disable DPMS"

# Clean up any existing browser processes
log "Cleaning up existing browser processes..."
pkill -9 chromium-browser 2>/dev/null || true
pkill -9 chrome 2>/dev/null || true
sleep 2

# Clean up Chromium cache and preferences to prevent restore prompts
log "Cleaning up browser cache..."
CHROMIUM_CONFIG_DIR="$HOME/.config/chromium"
CHROMIUM_DEFAULT_DIR="$CHROMIUM_CONFIG_DIR/Default"

# Remove problematic cache files
find "$CHROMIUM_DEFAULT_DIR" -type f \( -name "Cookies" -o -name "History" -o -name "*.log" -o -name "*.ldb" -o -name "*.sqlite" \) -delete 2>/dev/null || true
rm -rf "$CHROMIUM_DEFAULT_DIR/Logs"/* 2>/dev/null || true

# Prevent Chromium restore prompts
if [ -f "$CHROMIUM_CONFIG_DIR/Local State" ]; then
    sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' "$CHROMIUM_CONFIG_DIR/Local State" 2>/dev/null || true
fi

if [ -f "$CHROMIUM_DEFAULT_DIR/Preferences" ]; then
    sed -i 's/"exit_type":"[^"]\+"/"exit_type":"Normal"/' "$CHROMIUM_DEFAULT_DIR/Preferences" 2>/dev/null || true
fi

log "Starting Chromium in kiosk mode..."

# Start Chromium with Pi Zero 2W optimizations
chromium-browser \
    --kiosk \
    --no-sandbox \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-dev-shm-usage \
    --disable-extensions \
    --disable-plugins \
    --disable-java \
    --disable-translate \
    --disable-infobars \
    --disable-features=TranslateUI \
    --disable-session-crashed-bubble \
    --disable-notifications \
    --disable-sync-preferences \
    --disable-background-mode \
    --disable-popup-blocking \
    --no-first-run \
    --disable-logging \
    --disable-default-apps \
    --disable-crash-reporter \
    --disable-pdf-extension \
    --disable-new-tab-first-run \
    --start-maximized \
    --mute-audio \
    --hide-scrollbars \
    --memory-pressure-off \
    --force-device-scale-factor=1 \
    --window-position=0,0 \
    --window-size=800,480 \
    --disk-cache-dir=/dev/null \
    --user-data-dir=/tmp/chromium-kiosk \
    --disable-background-timer-throttling \
    --disable-renderer-backgrounding \
    --disable-backgrounding-occluded-windows \
    --disable-features=VizDisplayCompositor \
    "http://localhost:$SERVER_PORT" &

CHROMIUM_PID=$!

if [ $? -eq 0 ]; then
    log "Chromium started successfully with PID: $CHROMIUM_PID"
else
    log "Error: Failed to start Chromium"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

# Monitor processes and restart if needed
log "Starting process monitoring..."
RESTART_COUNT=0
MAX_RESTARTS=5

while true; do
    # Check server process
    if ! kill -0 $SERVER_PID 2>/dev/null; then
        log "Server crashed, restarting... (restart count: $RESTART_COUNT)"
        
        if [ $RESTART_COUNT -ge $MAX_RESTARTS ]; then
            log "Maximum restart attempts reached. Exiting."
            exit 1
        fi
        
        cd "$SCOREBOARD_DIR"
        serve dist -l $SERVER_PORT &
        SERVER_PID=$!
        RESTART_COUNT=$((RESTART_COUNT + 1))
        sleep 5
        
        # Verify server restarted
        if ! kill -0 $SERVER_PID 2>/dev/null; then
            log "Failed to restart server"
            exit 1
        fi
        
        log "Server restarted successfully with PID: $SERVER_PID"
    fi
    
    # Check Chromium process
    if ! kill -0 $CHROMIUM_PID 2>/dev/null; then
        log "Chromium crashed, restarting... (restart count: $RESTART_COUNT)"
        
        if [ $RESTART_COUNT -ge $MAX_RESTARTS ]; then
            log "Maximum restart attempts reached. Exiting."
            exit 1
        fi
        
        # Clean up any remaining processes
        pkill -9 chromium-browser 2>/dev/null || true
        sleep 2
        
        # Restart Chromium with simplified options for recovery
        chromium-browser \
            --kiosk \
            --no-sandbox \
            --disable-gpu \
            --disable-dev-shm-usage \
            --no-first-run \
            --disable-logging \
            --window-size=800,480 \
            --user-data-dir=/tmp/chromium-kiosk-recovery \
            "http://localhost:$SERVER_PORT" &
        
        CHROMIUM_PID=$!
        RESTART_COUNT=$((RESTART_COUNT + 1))
        
        if [ $? -eq 0 ]; then
            log "Chromium restarted successfully with PID: $CHROMIUM_PID"
        else
            log "Failed to restart Chromium"
            exit 1
        fi
    fi
    
    # Health check every 10 seconds
    sleep 10
    
    # Reset restart counter if both processes have been stable for 5 minutes
    if [ $RESTART_COUNT -gt 0 ]; then
        STABLE_TIME=$((STABLE_TIME + 10))
        if [ $STABLE_TIME -ge 300 ]; then  # 5 minutes
            log "Processes stable for 5 minutes, resetting restart counter"
            RESTART_COUNT=0
            STABLE_TIME=0
        fi
    else
        STABLE_TIME=0
    fi
done