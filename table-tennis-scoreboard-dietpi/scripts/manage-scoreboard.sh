#!/bin/bash

# Table Tennis Scoreboard Service Management Script
# For DietPi deployment
# Version: 1.0

SERVICE_NAME="scoreboard-kiosk"
SCOREBOARD_DIR="/home/dietpi/scoreboard"
LOG_FILE="/var/log/scoreboard-kiosk.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if service exists
check_service() {
    if ! systemctl list-unit-files | grep -q "$SERVICE_NAME"; then
        print_status $RED "Error: Service '$SERVICE_NAME' not found."
        echo "Please run the deployment script first."
        exit 1
    fi
}

# Function to show service status with details
show_status() {
    print_status $BLUE "=== Scoreboard Service Status ==="
    systemctl status $SERVICE_NAME --no-pager
    
    echo ""
    print_status $BLUE "=== Process Information ==="
    
    # Check for server process
    SERVER_PID=$(pgrep -f "serve dist")
    if [ -n "$SERVER_PID" ]; then
        print_status $GREEN "✓ Server process running (PID: $SERVER_PID)"
    else
        print_status $RED "✗ Server process not found"
    fi
    
    # Check for Chromium process
    CHROMIUM_PID=$(pgrep -f "chromium-browser.*kiosk")
    if [ -n "$CHROMIUM_PID" ]; then
        print_status $GREEN "✓ Chromium kiosk running (PID: $CHROMIUM_PID)"
    else
        print_status $RED "✗ Chromium kiosk not found"
    fi
    
    # Check network connectivity
    if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
        print_status $GREEN "✓ Network connectivity OK"
    else
        print_status $YELLOW "⚠ Network connectivity issues"
    fi
    
    # Check local server
    if curl -s "http://localhost:3000" >/dev/null 2>&1; then
        print_status $GREEN "✓ Local server responding"
    else
        print_status $RED "✗ Local server not responding"
    fi
    
    # Show memory usage
    echo ""
    print_status $BLUE "=== Memory Usage ==="
    free -h
    
    # Show disk usage
    echo ""
    print_status $BLUE "=== Disk Usage ==="
    df -h /
}

# Function to start service
start_service() {
    print_status $BLUE "Starting scoreboard service..."
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_status $YELLOW "Service is already running."
        return 0
    fi
    
    systemctl start $SERVICE_NAME
    
    if [ $? -eq 0 ]; then
        print_status $GREEN "✓ Service started successfully"
        sleep 3
        show_status
    else
        print_status $RED "✗ Failed to start service"
        echo "Check logs with: $0 logs"
        exit 1
    fi
}

# Function to stop service
stop_service() {
    print_status $BLUE "Stopping scoreboard service..."
    
    if ! systemctl is-active --quiet $SERVICE_NAME; then
        print_status $YELLOW "Service is already stopped."
        return 0
    fi
    
    systemctl stop $SERVICE_NAME
    
    # Force kill any remaining processes
    pkill -f "serve dist" 2>/dev/null || true
    pkill -f "chromium-browser.*kiosk" 2>/dev/null || true
    
    if [ $? -eq 0 ]; then
        print_status $GREEN "✓ Service stopped successfully"
    else
        print_status $RED "✗ Failed to stop service"
        exit 1
    fi
}

# Function to restart service
restart_service() {
    print_status $BLUE "Restarting scoreboard service..."
    stop_service
    sleep 2
    start_service
}

# Function to show logs
show_logs() {
    local lines=${2:-50}
    
    print_status $BLUE "=== Recent Service Logs (last $lines lines) ==="
    journalctl -u $SERVICE_NAME -n $lines --no-pager
    
    if [ -f "$LOG_FILE" ]; then
        echo ""
        print_status $BLUE "=== Application Logs (last $lines lines) ==="
        tail -n $lines "$LOG_FILE"
    fi
}

# Function to follow logs in real-time
follow_logs() {
    print_status $BLUE "Following logs in real-time (Ctrl+C to exit)..."
    echo ""
    
    # Follow both systemd and application logs
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE" &
        TAIL_PID=$!
    fi
    
    journalctl -u $SERVICE_NAME -f &
    JOURNAL_PID=$!
    
    # Cleanup on exit
    trap "kill $TAIL_PID $JOURNAL_PID 2>/dev/null; exit 0" INT TERM
    wait
}

# Function to enable/disable service
enable_service() {
    print_status $BLUE "Enabling scoreboard service for auto-start..."
    systemctl enable $SERVICE_NAME
    
    if [ $? -eq 0 ]; then
        print_status $GREEN "✓ Service enabled for auto-start"
    else
        print_status $RED "✗ Failed to enable service"
        exit 1
    fi
}

disable_service() {
    print_status $BLUE "Disabling scoreboard service auto-start..."
    systemctl disable $SERVICE_NAME
    
    if [ $? -eq 0 ]; then
        print_status $GREEN "✓ Service disabled from auto-start"
    else
        print_status $RED "✗ Failed to disable service"
        exit 1
    fi
}

# Function to update application
update_app() {
    print_status $BLUE "Updating scoreboard application..."
    
    if [ ! -d "$SCOREBOARD_DIR" ]; then
        print_status $RED "Error: Scoreboard directory not found: $SCOREBOARD_DIR"
        exit 1
    fi
    
    # Stop service first
    stop_service
    
    cd "$SCOREBOARD_DIR"
    
    # Pull latest changes
    print_status $BLUE "Pulling latest changes..."
    git pull
    
    if [ $? -ne 0 ]; then
        print_status $RED "✗ Failed to pull latest changes"
        exit 1
    fi
    
    # Install dependencies
    print_status $BLUE "Installing dependencies..."
    npm install
    
    if [ $? -ne 0 ]; then
        print_status $RED "✗ Failed to install dependencies"
        exit 1
    fi
    
    # Build application
    print_status $BLUE "Building application..."
    npm run build
    
    if [ $? -ne 0 ]; then
        print_status $RED "✗ Failed to build application"
        exit 1
    fi
    
    print_status $GREEN "✓ Application updated successfully"
    
    # Restart service
    start_service
}

# Function to show help
show_help() {
    echo "Table Tennis Scoreboard Service Management"
    echo ""
    echo "Usage: $0 {command} [options]"
    echo ""
    echo "Commands:"
    echo "  start          Start the scoreboard service"
    echo "  stop           Stop the scoreboard service"
    echo "  restart        Restart the scoreboard service"
    echo "  status         Show detailed service status"
    echo "  logs [lines]   Show recent logs (default: 50 lines)"
    echo "  follow         Follow logs in real-time"
    echo "  enable         Enable service for auto-start on boot"
    echo "  disable        Disable service auto-start"
    echo "  update         Update application and restart service"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start                    # Start the service"
    echo "  $0 logs 100                 # Show last 100 log lines"
    echo "  $0 follow                   # Follow logs in real-time"
    echo "  $0 status                   # Show detailed status"
    echo ""
    echo "Service name: $SERVICE_NAME"
    echo "Application directory: $SCOREBOARD_DIR"
    echo "Log file: $LOG_FILE"
}

# Main script logic
case "$1" in
    start)
        check_service
        start_service
        ;;
    stop)
        check_service
        stop_service
        ;;
    restart)
        check_service
        restart_service
        ;;
    status)
        check_service
        show_status
        ;;
    logs)
        check_service
        show_logs "$@"
        ;;
    follow)
        check_service
        follow_logs
        ;;
    enable)
        check_service
        enable_service
        ;;
    disable)
        check_service
        disable_service
        ;;
    update)
        check_service
        update_app
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        print_status $YELLOW "No command specified. Use '$0 help' for usage information."
        show_help
        exit 1
        ;;
    *)
        print_status $RED "Unknown command: $1"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac