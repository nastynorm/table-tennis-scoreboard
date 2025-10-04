#!/bin/bash

# Migration Script for Table Tennis Scoreboard to DietPi Kiosk
# Prepares the built application for deployment on DietPi

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

echo -e "${BLUE}=== Table Tennis Scoreboard DietPi Migration Tool ===${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "dist" ]; then
    echo -e "${RED}Error: Please run this script from the table tennis scoreboard project directory${NC}"
    echo "Make sure you have run 'npm run build' first to create the dist/ directory"
    exit 1
fi

# Function to display menu
show_menu() {
    echo -e "${YELLOW}Choose your migration option:${NC}"
    echo "1) Create DietPi deployment package"
    echo "2) Create portable server package"
    echo "3) Exit"
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
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            create_backup
            migrate_to_dietpi
            break
            ;;
        2)
            create_backup
            create_portable_package
            break
            ;;
        3)
            echo -e "${BLUE}Migration cancelled.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter 1-3.${NC}"
            ;;
    esac
done

echo ""
echo -e "${GREEN}=== Migration Preparation Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Benefits of migrating to DietPi kiosk:${NC}"
echo "• Faster boot times (20-30 seconds vs 90 seconds)"
echo "• Lower memory usage (100-150MB vs 300MB)"
echo "• Simplified maintenance"
echo "• Better stability for kiosk applications"
echo "• Complete local hosting solution"
echo ""
echo -e "${BLUE}Your original application backup is saved at: $BACKUP_DIR${NC}"
echo ""