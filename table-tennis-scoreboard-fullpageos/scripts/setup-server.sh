#!/bin/bash

# Table Tennis Scoreboard Server Setup Script
# For hosting the application to be displayed by FullPageOS
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCOREBOARD_DIR="/home/pi/scoreboard"
SERVER_PORT=3000
SERVICE_NAME="scoreboard-server"

echo -e "${BLUE}=== Table Tennis Scoreboard Server Setup ===${NC}"
echo "This script sets up a server to host the scoreboard application"
echo "for FullPageOS kiosk displays."
echo ""

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_status $RED "Please do not run this script as root."
        echo "Run as regular user: ./setup-server.sh"
        exit 1
    fi
}

# Function to update system
update_system() {
    print_status $BLUE "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    print_status $GREEN "System updated successfully."
}

# Function to install Node.js
install_nodejs() {
    print_status $BLUE "Installing Node.js..."
    
    # Check if Node.js is already installed
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        print_status $YELLOW "Node.js already installed: $NODE_VERSION"
        
        # Check if version is recent enough (v14+)
        NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
        if [ "$NODE_MAJOR" -lt 14 ]; then
            print_status $YELLOW "Node.js version is too old, updating..."
        else
            print_status $GREEN "Node.js version is sufficient."
            return 0
        fi
    fi
    
    # Install Node.js via NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Verify installation
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        print_status $GREEN "✓ Node.js installed successfully: $(node --version)"
        print_status $GREEN "✓ npm installed successfully: $(npm --version)"
    else
        print_status $RED "✗ Failed to install Node.js"
        exit 1
    fi
}

# Function to install PM2 for process management
install_pm2() {
    print_status $BLUE "Installing PM2 process manager..."
    
    if command -v pm2 >/dev/null 2>&1; then
        print_status $YELLOW "PM2 already installed: $(pm2 --version)"
        return 0
    fi
    
    sudo npm install -g pm2
    
    if command -v pm2 >/dev/null 2>&1; then
        print_status $GREEN "✓ PM2 installed successfully: $(pm2 --version)"
    else
        print_status $RED "✗ Failed to install PM2"
        exit 1
    fi
}

# Function to setup scoreboard application
setup_application() {
    print_status $BLUE "Setting up scoreboard application..."
    
    # Create application directory
    mkdir -p "$SCOREBOARD_DIR"
    cd "$SCOREBOARD_DIR"
    
    # Check if we have source files
    if [ -d "/tmp/scoreboard-source" ]; then
        print_status $BLUE "Copying local source files..."
        cp -r /tmp/scoreboard-source/* .
    else
        print_status $BLUE "Cloning from repository..."
        # Replace with actual repository URL
        REPO_URL="https://github.com/yourusername/table-tennis-scoreboard.git"
        
        if [ -d ".git" ]; then
            print_status $YELLOW "Repository already exists, pulling latest changes..."
            git pull
        else
            git clone "$REPO_URL" .
        fi
    fi
    
    # Install dependencies
    print_status $BLUE "Installing application dependencies..."
    npm install
    
    # Build application
    print_status $BLUE "Building application..."
    npm run build
    
    if [ -d "dist" ]; then
        print_status $GREEN "✓ Application built successfully"
    else
        print_status $RED "✗ Build failed - dist directory not found"
        exit 1
    fi
}

# Function to create server startup script
create_startup_script() {
    print_status $BLUE "Creating server startup script..."
    
    cat > "$SCOREBOARD_DIR/start-server.sh" << 'EOF'
#!/bin/bash

# Table Tennis Scoreboard Server Startup Script
# Serves the built application for FullPageOS kiosks

SCOREBOARD_DIR="/home/pi/scoreboard"
SERVER_PORT=3000

cd "$SCOREBOARD_DIR"

echo "Starting scoreboard server on port $SERVER_PORT..."
echo "Server will be accessible at:"
echo "  Local: http://localhost:$SERVER_PORT"
echo "  Network: http://$(hostname -I | awk '{print $1}'):$SERVER_PORT"
echo ""
echo "Press Ctrl+C to stop the server"

# Start server with serve package
npx serve dist -l $SERVER_PORT -s
EOF
    
    chmod +x "$SCOREBOARD_DIR/start-server.sh"
    print_status $GREEN "✓ Startup script created"
}

# Function to setup PM2 service
setup_pm2_service() {
    print_status $BLUE "Setting up PM2 service..."
    
    cd "$SCOREBOARD_DIR"
    
    # Stop existing process if running
    pm2 delete $SERVICE_NAME 2>/dev/null || true
    
    # Start new process
    pm2 start "npx serve dist -l $SERVER_PORT -s" --name $SERVICE_NAME
    
    # Save PM2 configuration
    pm2 save
    
    # Setup PM2 to start on boot
    pm2 startup
    
    print_status $GREEN "✓ PM2 service configured"
}

# Function to configure firewall
configure_firewall() {
    print_status $BLUE "Configuring firewall..."
    
    # Check if ufw is installed
    if command -v ufw >/dev/null 2>&1; then
        # Allow SSH (if enabled)
        sudo ufw allow ssh 2>/dev/null || true
        
        # Allow scoreboard server port
        sudo ufw allow $SERVER_PORT/tcp
        
        # Enable firewall if not already enabled
        sudo ufw --force enable
        
        print_status $GREEN "✓ Firewall configured to allow port $SERVER_PORT"
    else
        print_status $YELLOW "⚠ UFW not installed, skipping firewall configuration"
    fi
}

# Function to create management scripts
create_management_scripts() {
    print_status $BLUE "Creating management scripts..."
    
    # Server management script
    cat > "$SCOREBOARD_DIR/manage-server.sh" << 'EOF'
#!/bin/bash

SERVICE_NAME="scoreboard-server"
SERVER_PORT=3000

case "$1" in
    start)
        echo "Starting scoreboard server..."
        pm2 start $SERVICE_NAME
        ;;
    stop)
        echo "Stopping scoreboard server..."
        pm2 stop $SERVICE_NAME
        ;;
    restart)
        echo "Restarting scoreboard server..."
        pm2 restart $SERVICE_NAME
        ;;
    status)
        pm2 status $SERVICE_NAME
        echo ""
        echo "Server URL: http://$(hostname -I | awk '{print $1}'):$SERVER_PORT"
        ;;
    logs)
        pm2 logs $SERVICE_NAME
        ;;
    update)
        echo "Updating scoreboard application..."
        pm2 stop $SERVICE_NAME
        git pull
        npm install
        npm run build
        pm2 start $SERVICE_NAME
        echo "Update complete!"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|update}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$SCOREBOARD_DIR/manage-server.sh"
    
    # Network info script
    cat > "$SCOREBOARD_DIR/network-info.sh" << 'EOF'
#!/bin/bash

echo "=== Network Information ==="
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo "Server Port: 3000"
echo ""
echo "=== Scoreboard URLs ==="
echo "Local: http://localhost:3000"
echo "Network: http://$(hostname -I | awk '{print $1}'):3000"
echo ""
echo "=== QR Code for Mobile Access ==="
if command -v qrencode >/dev/null 2>&1; then
    qrencode -t ANSI "http://$(hostname -I | awk '{print $1}'):3000"
else
    echo "Install qrencode to display QR code: sudo apt install qrencode"
fi
EOF
    
    chmod +x "$SCOREBOARD_DIR/network-info.sh"
    
    print_status $GREEN "✓ Management scripts created"
}

# Function to test server
test_server() {
    print_status $BLUE "Testing server..."
    
    # Wait for server to start
    sleep 3
    
    # Test local connection
    if curl -s "http://localhost:$SERVER_PORT" >/dev/null 2>&1; then
        print_status $GREEN "✓ Server is responding locally"
    else
        print_status $RED "✗ Server not responding locally"
        return 1
    fi
    
    # Get network IP
    NETWORK_IP=$(hostname -I | awk '{print $1}')
    
    if [ -n "$NETWORK_IP" ]; then
        print_status $GREEN "✓ Server accessible at: http://$NETWORK_IP:$SERVER_PORT"
    else
        print_status $YELLOW "⚠ Could not determine network IP"
    fi
}

# Main setup function
main() {
    print_status $YELLOW "Starting server setup process..."
    
    check_root
    update_system
    install_nodejs
    install_pm2
    setup_application
    create_startup_script
    setup_pm2_service
    configure_firewall
    create_management_scripts
    test_server
    
    echo ""
    print_status $GREEN "=== Server Setup Complete! ==="
    echo ""
    print_status $YELLOW "The scoreboard server is now running and accessible at:"
    
    NETWORK_IP=$(hostname -I | awk '{print $1}')
    echo "  Local: http://localhost:$SERVER_PORT"
    if [ -n "$NETWORK_IP" ]; then
        echo "  Network: http://$NETWORK_IP:$SERVER_PORT"
    fi
    
    echo ""
    echo "Management commands:"
    echo "  Start server:    ./manage-server.sh start"
    echo "  Stop server:     ./manage-server.sh stop"
    echo "  Restart server:  ./manage-server.sh restart"
    echo "  Check status:    ./manage-server.sh status"
    echo "  View logs:       ./manage-server.sh logs"
    echo "  Update app:      ./manage-server.sh update"
    echo "  Network info:    ./network-info.sh"
    echo ""
    echo "FullPageOS Configuration:"
    echo "  Add this URL to your fullpageos.txt file:"
    if [ -n "$NETWORK_IP" ]; then
        echo "  fullPageOS_url=http://$NETWORK_IP:$SERVER_PORT"
    else
        echo "  fullPageOS_url=http://[this-server-ip]:$SERVER_PORT"
    fi
    echo ""
    print_status $BLUE "The server will automatically start on boot."
}

# Run main function
main "$@"