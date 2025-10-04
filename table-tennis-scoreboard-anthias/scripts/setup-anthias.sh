#!/bin/bash

# Table Tennis Scoreboard - Anthias (Screenly OSE) Setup Script
# Optimized for Raspberry Pi Zero 2W with Waveshare 5" LCD

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCOREBOARD_URL=""
ASSET_NAME="Table Tennis Scoreboard"
ASSET_DURATION="86400"
DISPLAY_ROTATION="0"
WIFI_SSID=""
WIFI_PASSWORD=""

# Logging
LOG_FILE="/var/log/anthias-setup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Anthias Scoreboard Setup${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

check_anthias() {
    print_step "Checking Anthias installation"
    
    if ! systemctl is-active --quiet screenly-web; then
        print_error "Anthias web service not running"
        print_info "Please ensure Anthias is properly installed"
        exit 1
    fi
    
    if ! systemctl is-active --quiet screenly-viewer; then
        print_error "Anthias viewer service not running"
        print_info "Please ensure Anthias is properly installed"
        exit 1
    fi
    
    print_info "Anthias services are running"
}

get_user_input() {
    print_step "Gathering configuration information"
    
    if [[ -z "$SCOREBOARD_URL" ]]; then
        echo -n "Enter scoreboard URL (e.g., https://your-scoreboard.com): "
        read -r SCOREBOARD_URL
    fi
    
    if [[ -z "$SCOREBOARD_URL" ]]; then
        print_error "Scoreboard URL is required"
        exit 1
    fi
    
    echo -n "Enter display rotation (0=normal, 1=90°, 2=180°, 3=270°) [0]: "
    read -r rotation_input
    DISPLAY_ROTATION=${rotation_input:-0}
    
    echo -n "Enter asset duration in seconds [86400]: "
    read -r duration_input
    ASSET_DURATION=${duration_input:-86400}
    
    print_info "Configuration:"
    print_info "  Scoreboard URL: $SCOREBOARD_URL"
    print_info "  Display Rotation: $DISPLAY_ROTATION"
    print_info "  Asset Duration: $ASSET_DURATION seconds"
}

configure_display() {
    print_step "Configuring display settings"
    
    # Backup original config
    sudo cp /boot/config.txt /boot/config.txt.backup.$(date +%Y%m%d_%H%M%S)
    
    # Add Waveshare 5" LCD configuration
    cat << EOF | sudo tee -a /boot/config.txt

# Waveshare 5" LCD Configuration (Added by Anthias setup)
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=1
display_rotate=$DISPLAY_ROTATION
disable_overscan=1
gpu_mem=64
dtparam=audio=off
camera_auto_detect=0
display_auto_detect=0
hdmi_blanking=0
EOF
    
    print_info "Display configuration added to /boot/config.txt"
    print_warning "Reboot required for display changes to take effect"
}

configure_wifi() {
    if [[ -n "$WIFI_SSID" && -n "$WIFI_PASSWORD" ]]; then
        print_step "Configuring WiFi"
        
        # Backup original wpa_supplicant
        sudo cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.backup.$(date +%Y%m%d_%H%M%S)
        
        # Add network configuration
        cat << EOF | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
    priority=1
}
EOF
        
        print_info "WiFi configuration added"
        sudo systemctl restart wpa_supplicant
    else
        print_info "Skipping WiFi configuration (no credentials provided)"
    fi
}

wait_for_anthias() {
    print_step "Waiting for Anthias web interface"
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
            print_info "Anthias web interface is ready"
            return 0
        fi
        
        print_info "Waiting for Anthias... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    print_error "Anthias web interface not responding after $max_attempts attempts"
    return 1
}

add_scoreboard_asset() {
    print_step "Adding scoreboard asset to Anthias"
    
    # Create asset JSON
    local asset_json=$(cat << EOF
{
    "name": "$ASSET_NAME",
    "uri": "$SCOREBOARD_URL",
    "duration": "$ASSET_DURATION",
    "mimetype": "webpage",
    "is_enabled": 1,
    "nocache": 0,
    "play_order": 0,
    "skip_asset_check": 0
}
EOF
)
    
    # Add asset via API
    local response=$(curl -s -X POST http://localhost/api/v1/assets \
        -H "Content-Type: application/json" \
        -d "$asset_json")
    
    if echo "$response" | grep -q "error"; then
        print_error "Failed to add asset: $response"
        return 1
    fi
    
    print_info "Scoreboard asset added successfully"
    
    # Get asset ID from response
    local asset_id=$(echo "$response" | grep -o '"asset_id":"[^"]*"' | cut -d'"' -f4)
    
    if [[ -n "$asset_id" ]]; then
        print_info "Asset ID: $asset_id"
        
        # Activate asset
        curl -s -X PUT "http://localhost/api/v1/assets/$asset_id" \
            -H "Content-Type: application/json" \
            -d '{"is_enabled": 1}'
        
        print_info "Asset activated"
    fi
}

optimize_performance() {
    print_step "Optimizing performance for Pi Zero 2W"
    
    # Reduce GPU memory if not already set
    if ! grep -q "gpu_mem" /boot/config.txt; then
        echo "gpu_mem=64" | sudo tee -a /boot/config.txt
    fi
    
    # Disable unnecessary services
    sudo systemctl disable bluetooth 2>/dev/null || true
    sudo systemctl disable hciuart 2>/dev/null || true
    
    # Configure swap
    if [[ ! -f /var/swap ]]; then
        sudo dphys-swapfile swapoff 2>/dev/null || true
        sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=512/' /etc/dphys-swapfile
        sudo dphys-swapfile setup
        sudo dphys-swapfile swapon
    fi
    
    print_info "Performance optimizations applied"
}

create_management_scripts() {
    print_step "Creating management scripts"
    
    # Create asset management script
    cat << 'EOF' | sudo tee /usr/local/bin/manage-scoreboard > /dev/null
#!/bin/bash

ASSET_NAME="Table Tennis Scoreboard"
API_BASE="http://localhost/api/v1"

case "$1" in
    status)
        echo "=== Anthias System Status ==="
        systemctl status screenly-web --no-pager -l
        systemctl status screenly-viewer --no-pager -l
        echo ""
        echo "=== Assets ==="
        curl -s "$API_BASE/assets" | python3 -m json.tool
        ;;
    
    update-url)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 update-url <new-url>"
            exit 1
        fi
        
        # Get asset ID
        asset_id=$(curl -s "$API_BASE/assets" | grep -A5 -B5 "$ASSET_NAME" | grep -o '"asset_id":"[^"]*"' | cut -d'"' -f4 | head -1)
        
        if [[ -n "$asset_id" ]]; then
            curl -X PUT "$API_BASE/assets/$asset_id" \
                -H "Content-Type: application/json" \
                -d "{\"uri\": \"$2\"}"
            echo "Asset URL updated to: $2"
        else
            echo "Asset not found: $ASSET_NAME"
            exit 1
        fi
        ;;
    
    restart)
        sudo systemctl restart screenly-web
        sudo systemctl restart screenly-viewer
        echo "Anthias services restarted"
        ;;
    
    logs)
        echo "=== Web Service Logs ==="
        journalctl -u screenly-web --no-pager -l -n 50
        echo ""
        echo "=== Viewer Service Logs ==="
        journalctl -u screenly-viewer --no-pager -l -n 50
        ;;
    
    info)
        echo "=== System Information ==="
        curl -s "$API_BASE/info" | python3 -m json.tool
        ;;
    
    *)
        echo "Usage: $0 {status|update-url|restart|logs|info}"
        echo ""
        echo "Commands:"
        echo "  status      - Show system and asset status"
        echo "  update-url  - Update scoreboard URL"
        echo "  restart     - Restart Anthias services"
        echo "  logs        - Show service logs"
        echo "  info        - Show system information"
        exit 1
        ;;
esac
EOF
    
    sudo chmod +x /usr/local/bin/manage-scoreboard
    
    print_info "Management script created: /usr/local/bin/manage-scoreboard"
}

test_setup() {
    print_step "Testing setup"
    
    # Test web interface
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        print_info "✓ Web interface accessible"
    else
        print_warning "✗ Web interface not accessible"
    fi
    
    # Test API
    if curl -s "$API_BASE/info" | grep -q "version"; then
        print_info "✓ API responding"
    else
        print_warning "✗ API not responding"
    fi
    
    # Test asset
    if curl -s "$API_BASE/assets" | grep -q "$ASSET_NAME"; then
        print_info "✓ Scoreboard asset found"
    else
        print_warning "✗ Scoreboard asset not found"
    fi
    
    # Test scoreboard URL
    if curl -s -o /dev/null -w "%{http_code}" "$SCOREBOARD_URL" | grep -q "200"; then
        print_info "✓ Scoreboard URL accessible"
    else
        print_warning "✗ Scoreboard URL not accessible"
    fi
}

show_completion_info() {
    print_step "Setup completed!"
    
    local ip_address=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo -e "${GREEN}=== Access Information ===${NC}"
    echo -e "Web Interface: ${BLUE}http://$ip_address${NC}"
    echo -e "Scoreboard URL: ${BLUE}$SCOREBOARD_URL${NC}"
    echo -e "Asset Name: ${BLUE}$ASSET_NAME${NC}"
    echo ""
    echo -e "${GREEN}=== Management Commands ===${NC}"
    echo -e "Status: ${BLUE}manage-scoreboard status${NC}"
    echo -e "Update URL: ${BLUE}manage-scoreboard update-url <new-url>${NC}"
    echo -e "Restart: ${BLUE}manage-scoreboard restart${NC}"
    echo -e "Logs: ${BLUE}manage-scoreboard logs${NC}"
    echo ""
    echo -e "${GREEN}=== Next Steps ===${NC}"
    echo "1. Access web interface to verify asset is active"
    echo "2. Reboot if display configuration was changed"
    echo "3. Monitor logs for any issues"
    echo "4. Test scoreboard functionality"
    echo ""
    echo -e "${YELLOW}Note: Reboot required for display changes to take effect${NC}"
}

main() {
    print_header
    
    check_root
    check_anthias
    get_user_input
    configure_display
    configure_wifi
    wait_for_anthias
    add_scoreboard_asset
    optimize_performance
    create_management_scripts
    test_setup
    show_completion_info
}

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --url)
            SCOREBOARD_URL="$2"
            shift 2
            ;;
        --wifi-ssid)
            WIFI_SSID="$2"
            shift 2
            ;;
        --wifi-password)
            WIFI_PASSWORD="$2"
            shift 2
            ;;
        --rotation)
            DISPLAY_ROTATION="$2"
            shift 2
            ;;
        --duration)
            ASSET_DURATION="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --url <url>           Scoreboard URL"
            echo "  --wifi-ssid <ssid>    WiFi network name"
            echo "  --wifi-password <pwd> WiFi password"
            echo "  --rotation <0-3>      Display rotation"
            echo "  --duration <seconds>  Asset duration"
            echo "  --help               Show this help"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main