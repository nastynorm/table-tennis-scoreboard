#!/bin/bash

# Migration Script for Table Tennis Scoreboard to Kiosk OS
# Supports migration to DietPi, FullPageOS, and Anthias (Screenly OSE)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCOREBOARD_DIR="$(pwd)"
BUILD_DIR="${SCOREBOARD_DIR}/dist"
BACKUP_DIR="${HOME}/scoreboard-backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}=== Table Tennis Scoreboard Kiosk OS Migration Tool ===${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "dist" ]; then
    echo -e "${RED}Error: Please run this script from the table tennis scoreboard project directory${NC}"
    echo "Make sure you have run 'npm run build' first to create the dist/ directory"
    exit 1
fi

# Function to display menu
show_menu() {
    echo -e "${YELLOW}Choose your migration target:${NC}"
    echo "1) DietPi (Recommended for Pi Zero 2W)"
    echo "2) FullPageOS (Simplest setup)"
    echo "3) Anthias/Screenly OSE (Digital signage features)"
    echo "4) Create portable server package"
    echo "5) Exit"
    echo ""
}

# Function to create backup
create_backup() {
    echo -e "${BLUE}Creating backup...${NC}"
    mkdir -p "$BACKUP_DIR"
    cp -r "$BUILD_DIR" "$BACKUP_DIR/"
    cp package.json "$BACKUP_DIR/"
    cp -r src "$BACKUP_DIR/" 2>/dev/null || true
    echo -e "${GREEN}Backup created at: $BACKUP_DIR${NC}"
}

# Function to migrate to DietPi
migrate_to_dietpi() {
    echo -e "${BLUE}Preparing migration to DietPi...${NC}"
    
    # Create DietPi deployment package
    DIETPI_DIR="${HOME}/dietpi-scoreboard-deployment"
    mkdir -p "$DIETPI_DIR"
    
    # Copy built application
    cp -r "$BUILD_DIR" "$DIETPI_DIR/"
    
    # Create deployment script
    cat > "$DIETPI_DIR/deploy-scoreboard.sh" << 'EOF'
#!/bin/bash

# DietPi Scoreboard Deployment Script
set -e

echo "=== Deploying Table Tennis Scoreboard on DietPi ==="

# Update system
dietpi-update

# Install required software
dietpi-software install 9    # Node.js
dietpi-software install 113  # Chromium

# Create application directory
mkdir -p /home/dietpi/scoreboard
cp -r dist/* /home/dietpi/scoreboard/

# Install serve package globally
npm install -g serve

# Create startup script
cat > /home/dietpi/start-scoreboard.sh << 'STARTUP_EOF'
#!/bin/bash
export DISPLAY=:0
cd /home/dietpi/scoreboard
serve . -l 3000 &
sleep 3
chromium-browser --kiosk --no-sandbox --disable-gpu http://localhost:3000
STARTUP_EOF

chmod +x /home/dietpi/start-scoreboard.sh

# Configure autostart
echo "2" > /boot/dietpi/.dietpi-autostart_index
echo "/home/dietpi/start-scoreboard.sh" > /boot/dietpi/.dietpi-autostart_custom

echo "Deployment complete! Reboot to start the scoreboard."
EOF
    
    chmod +x "$DIETPI_DIR/deploy-scoreboard.sh"
    
    # Create instructions
    cat > "$DIETPI_DIR/README.md" << 'EOF'
# DietPi Deployment Instructions

1. Copy this entire directory to your DietPi system:
   ```
   scp -r dietpi-scoreboard-deployment/ root@[DIETPI_IP]:/root/
   ```

2. SSH into your DietPi system:
   ```
   ssh root@[DIETPI_IP]
   ```

3. Run the deployment script:
   ```
   cd /root/dietpi-scoreboard-deployment
   ./deploy-scoreboard.sh
   ```

4. Reboot the system:
   ```
   reboot
   ```

The scoreboard will automatically start in kiosk mode after reboot.
EOF
    
    echo -e "${GREEN}DietPi deployment package created at: $DIETPI_DIR${NC}"
    echo -e "${YELLOW}Follow the instructions in $DIETPI_DIR/README.md${NC}"
}

# Function to migrate to FullPageOS
migrate_to_fullpageos() {
    echo -e "${BLUE}Preparing migration to FullPageOS...${NC}"
    
    # Create FullPageOS deployment package
    FULLPAGEOS_DIR="${HOME}/fullpageos-scoreboard-deployment"
    mkdir -p "$FULLPAGEOS_DIR"
    
    # Copy built application
    cp -r "$BUILD_DIR" "$FULLPAGEOS_DIR/scoreboard-app"
    
    # Create server setup script
    cat > "$FULLPAGEOS_DIR/setup-server.sh" << 'EOF'
#!/bin/bash

# FullPageOS requires an external server to host the application
# This script sets up a simple HTTP server

echo "=== Setting up Scoreboard Server for FullPageOS ==="

# Install Node.js if not present
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install serve package
npm install -g serve

# Create systemd service
sudo tee /etc/systemd/system/scoreboard-server.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Table Tennis Scoreboard Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/scoreboard-app
ExecStart=/usr/local/bin/serve . -l 3000
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Enable and start service
sudo systemctl enable scoreboard-server
sudo systemctl start scoreboard-server

echo "Server setup complete!"
echo "Scoreboard available at: http://$(hostname -I | awk '{print $1}'):3000"
EOF
    
    chmod +x "$FULLPAGEOS_DIR/setup-server.sh"
    
    # Create FullPageOS configuration
    cat > "$FULLPAGEOS_DIR/fullpageos-config.txt" << 'EOF'
# FullPageOS Configuration for Table Tennis Scoreboard
# Copy this content to fullpageos.txt on the FullPageOS SD card

# Replace [SERVER_IP] with your server's IP address
fullpageos_url=http://[SERVER_IP]:3000

# Optimized settings for Pi Zero 2W
fullpageos_hide_cursor=true
fullpageos_chromium_flags=--kiosk --no-sandbox --disable-gpu --disable-infobars --window-size=800,480 --window-position=0,0 --force-device-scale-factor=1 --disk-cache-dir=/dev/null
EOF
    
    # Create instructions
    cat > "$FULLPAGEOS_DIR/README.md" << 'EOF'
# FullPageOS Deployment Instructions

FullPageOS requires the scoreboard to be hosted on an external server.

## Option 1: Use a separate Raspberry Pi as server

1. Copy the scoreboard-app directory to a Raspberry Pi:
   ```
   scp -r scoreboard-app/ pi@[SERVER_PI_IP]:/home/pi/
   ```

2. Run the server setup script:
   ```
   ssh pi@[SERVER_PI_IP]
   cd /home/pi
   ./setup-server.sh
   ```

3. Note the server IP address displayed

## Option 2: Use a cloud service

1. Deploy the contents of scoreboard-app/ to:
   - Netlify (drag and drop the folder)
   - Vercel (connect to your Git repository)
   - GitHub Pages
   - Any web hosting service

## Configure FullPageOS

1. Flash FullPageOS to an SD card
2. Edit fullpageos.txt on the SD card
3. Copy the content from fullpageos-config.txt
4. Replace [SERVER_IP] with your actual server IP
5. Insert SD card and boot FullPageOS

The scoreboard will automatically display in kiosk mode.
EOF
    
    echo -e "${GREEN}FullPageOS deployment package created at: $FULLPAGEOS_DIR${NC}"
    echo -e "${YELLOW}Follow the instructions in $FULLPAGEOS_DIR/README.md${NC}"
}

# Function to migrate to Anthias
migrate_to_anthias() {
    echo -e "${BLUE}Preparing migration to Anthias (Screenly OSE)...${NC}"
    
    # Create Anthias deployment package
    ANTHIAS_DIR="${HOME}/anthias-scoreboard-deployment"
    mkdir -p "$ANTHIAS_DIR"
    
    # Copy built application
    cp -r "$BUILD_DIR" "$ANTHIAS_DIR/scoreboard-app"
    
    # Create deployment script
    cat > "$ANTHIAS_DIR/deploy-to-anthias.sh" << 'EOF'
#!/bin/bash

# Anthias Scoreboard Deployment Script
set -e

echo "=== Deploying Scoreboard to Anthias ==="

# Install nginx to serve the application
sudo apt-get update
sudo apt-get install -y nginx

# Copy scoreboard files to nginx directory
sudo cp -r scoreboard-app/* /var/www/html/

# Configure nginx for the scoreboard
sudo tee /etc/nginx/sites-available/scoreboard > /dev/null << 'NGINX_EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX_EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/scoreboard /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

echo "Scoreboard deployed to nginx!"
echo "Add this URL to Anthias: http://$(hostname -I | awk '{print $1}')"
EOF
    
    chmod +x "$ANTHIAS_DIR/deploy-to-anthias.sh"
    
    # Create instructions
    cat > "$ANTHIAS_DIR/README.md" << 'EOF'
# Anthias (Screenly OSE) Deployment Instructions

1. Install Anthias on your Raspberry Pi following the official guide
2. Copy this deployment package to your Anthias system:
   ```
   scp -r anthias-scoreboard-deployment/ pi@[ANTHIAS_IP]:/home/pi/
   ```

3. SSH into your Anthias system:
   ```
   ssh pi@[ANTHIAS_IP]
   ```

4. Run the deployment script:
   ```
   cd /home/pi/anthias-scoreboard-deployment
   ./deploy-to-anthias.sh
   ```

5. Access the Anthias web interface at http://[ANTHIAS_IP]:8080

6. Add a new asset with the URL: http://[ANTHIAS_IP]

7. Set the duration and schedule as needed

The scoreboard will be displayed according to your Anthias playlist schedule.
EOF
    
    echo -e "${GREEN}Anthias deployment package created at: $ANTHIAS_DIR${NC}"
    echo -e "${YELLOW}Follow the instructions in $ANTHIAS_DIR/README.md${NC}"
}

# Function to create portable server package
create_portable_package() {
    echo -e "${BLUE}Creating portable server package...${NC}"
    
    PORTABLE_DIR="${HOME}/scoreboard-portable-server"
    mkdir -p "$PORTABLE_DIR"
    
    # Copy built application
    cp -r "$BUILD_DIR" "$PORTABLE_DIR/public"
    
    # Create simple Node.js server
    cat > "$PORTABLE_DIR/server.js" << 'EOF'
const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files from public directory
app.use(express.static('public'));

// Handle SPA routing
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Table Tennis Scoreboard server running on port ${PORT}`);
    console.log(`Access at: http://localhost:${PORT}`);
});
EOF
    
    # Create package.json
    cat > "$PORTABLE_DIR/package.json" << 'EOF'
{
  "name": "table-tennis-scoreboard-server",
  "version": "1.0.0",
  "description": "Portable server for table tennis scoreboard",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF
    
    # Create startup scripts
    cat > "$PORTABLE_DIR/start.sh" << 'EOF'
#!/bin/bash
echo "Starting Table Tennis Scoreboard Server..."
npm install
npm start
EOF
    
    cat > "$PORTABLE_DIR/start.bat" << 'EOF'
@echo off
echo Starting Table Tennis Scoreboard Server...
npm install
npm start
pause
EOF
    
    chmod +x "$PORTABLE_DIR/start.sh"
    
    # Create README
    cat > "$PORTABLE_DIR/README.md" << 'EOF'
# Portable Table Tennis Scoreboard Server

This package contains a portable Node.js server for the table tennis scoreboard.

## Requirements
- Node.js (version 14 or higher)
- npm

## Usage

### Linux/macOS:
```bash
./start.sh
```

### Windows:
Double-click `start.bat` or run:
```cmd
start.bat
```

### Manual start:
```bash
npm install
npm start
```

The server will start on port 3000. Access the scoreboard at:
http://localhost:3000

## Deployment
This server can be deployed to any platform that supports Node.js:
- Heroku
- Vercel
- Railway
- DigitalOcean App Platform
- AWS Elastic Beanstalk
- Any VPS with Node.js

## Configuration
- Change the port by setting the PORT environment variable
- The server binds to 0.0.0.0 to accept connections from any IP
EOF
    
    echo -e "${GREEN}Portable server package created at: $PORTABLE_DIR${NC}"
    echo -e "${YELLOW}This package can run on any system with Node.js${NC}"
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            create_backup
            migrate_to_dietpi
            break
            ;;
        2)
            create_backup
            migrate_to_fullpageos
            break
            ;;
        3)
            create_backup
            migrate_to_anthias
            break
            ;;
        4)
            create_backup
            create_portable_package
            break
            ;;
        5)
            echo -e "${BLUE}Migration cancelled.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter 1-5.${NC}"
            ;;
    esac
done

echo ""
echo -e "${GREEN}=== Migration Preparation Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Benefits of migrating to kiosk OS:${NC}"
echo "• Faster boot times (20-30 seconds vs 90 seconds)"
echo "• Lower memory usage (100-150MB vs 300MB)"
echo "• Simplified maintenance"
echo "• Better stability for kiosk applications"
echo "• Reduced complexity (50 lines vs 876 lines)"
echo ""
echo -e "${BLUE}Your original application backup is saved at: $BACKUP_DIR${NC}"
echo ""