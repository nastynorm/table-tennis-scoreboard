#!/bin/bash

# Table Tennis Scoreboard - Anthias Management Script
# Comprehensive management for Anthias deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ASSET_NAME="Table Tennis Scoreboard"
API_BASE="http://localhost/api/v1"
LOG_FILE="/var/log/anthias-management.log"

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Anthias Scoreboard Manager${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
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

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_anthias() {
    if ! systemctl is-active --quiet screenly-web; then
        print_error "Anthias web service not running"
        return 1
    fi
    
    if ! systemctl is-active --quiet screenly-viewer; then
        print_error "Anthias viewer service not running"
        return 1
    fi
    
    return 0
}

get_asset_id() {
    local asset_id=$(curl -s "$API_BASE/assets" 2>/dev/null | \
        python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for asset in data:
        if asset.get('name') == '$ASSET_NAME':
            print(asset.get('asset_id', ''))
            break
except:
    pass
" 2>/dev/null)
    
    echo "$asset_id"
}

show_status() {
    print_header
    
    echo -e "${CYAN}=== System Status ===${NC}"
    
    # Service status
    if systemctl is-active --quiet screenly-web; then
        print_success "Web service: Running"
    else
        print_error "Web service: Stopped"
    fi
    
    if systemctl is-active --quiet screenly-viewer; then
        print_success "Viewer service: Running"
    else
        print_error "Viewer service: Stopped"
    fi
    
    # Network status
    local ip_address=$(hostname -I | awk '{print $1}')
    if [[ -n "$ip_address" ]]; then
        print_success "Network: Connected ($ip_address)"
    else
        print_error "Network: Disconnected"
    fi
    
    # API status
    if curl -s "$API_BASE/info" >/dev/null 2>&1; then
        print_success "API: Responding"
    else
        print_error "API: Not responding"
    fi
    
    echo ""
    echo -e "${CYAN}=== Asset Status ===${NC}"
    
    local asset_id=$(get_asset_id)
    if [[ -n "$asset_id" ]]; then
        print_success "Scoreboard asset found (ID: $asset_id)"
        
        # Get asset details
        local asset_info=$(curl -s "$API_BASE/assets/$asset_id" 2>/dev/null)
        if [[ -n "$asset_info" ]]; then
            local url=$(echo "$asset_info" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('uri', 'N/A'))" 2>/dev/null)
            local enabled=$(echo "$asset_info" | python3 -c "import json, sys; data=json.load(sys.stdin); print('Yes' if data.get('is_enabled') else 'No')" 2>/dev/null)
            local duration=$(echo "$asset_info" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('duration', 'N/A'))" 2>/dev/null)
            
            print_info "URL: $url"
            print_info "Enabled: $enabled"
            print_info "Duration: $duration seconds"
            
            # Test URL accessibility
            if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
                print_success "URL accessible"
            else
                print_warning "URL not accessible"
            fi
        fi
    else
        print_error "Scoreboard asset not found"
    fi
    
    echo ""
    echo -e "${CYAN}=== System Resources ===${NC}"
    
    # Memory usage
    local mem_info=$(free -h | grep "Mem:")
    local mem_used=$(echo "$mem_info" | awk '{print $3}')
    local mem_total=$(echo "$mem_info" | awk '{print $2}')
    print_info "Memory: $mem_used / $mem_total"
    
    # Disk usage
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}')
    print_info "Disk usage: $disk_usage"
    
    # CPU temperature
    local temp=$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 || echo "N/A")
    print_info "CPU temperature: $temp"
    
    # Load average
    local load=$(uptime | awk -F'load average:' '{print $2}')
    print_info "Load average:$load"
}

update_url() {
    local new_url="$1"
    
    if [[ -z "$new_url" ]]; then
        print_error "URL is required"
        echo "Usage: $0 update-url <new-url>"
        return 1
    fi
    
    print_info "Updating scoreboard URL to: $new_url"
    
    local asset_id=$(get_asset_id)
    if [[ -z "$asset_id" ]]; then
        print_error "Scoreboard asset not found"
        return 1
    fi
    
    # Test URL accessibility first
    if ! curl -s -o /dev/null -w "%{http_code}" "$new_url" | grep -q "200"; then
        print_warning "URL may not be accessible: $new_url"
        echo -n "Continue anyway? (y/N): "
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            print_info "Update cancelled"
            return 1
        fi
    fi
    
    # Update asset
    local response=$(curl -s -X PUT "$API_BASE/assets/$asset_id" \
        -H "Content-Type: application/json" \
        -d "{\"uri\": \"$new_url\"}" 2>/dev/null)
    
    if echo "$response" | grep -q "error"; then
        print_error "Failed to update URL: $response"
        return 1
    fi
    
    print_success "URL updated successfully"
    log_action "Updated scoreboard URL to: $new_url"
    
    # Restart viewer to apply changes
    print_info "Restarting viewer to apply changes..."
    sudo systemctl restart screenly-viewer
    print_success "Viewer restarted"
}

restart_services() {
    print_info "Restarting Anthias services..."
    
    sudo systemctl restart screenly-web
    print_info "Web service restarted"
    
    sudo systemctl restart screenly-viewer
    print_info "Viewer service restarted"
    
    # Wait for services to start
    sleep 5
    
    if check_anthias; then
        print_success "All services restarted successfully"
        log_action "Services restarted"
    else
        print_error "Some services failed to start"
        return 1
    fi
}

show_logs() {
    local service="$1"
    local lines="${2:-50}"
    
    case "$service" in
        web)
            echo -e "${CYAN}=== Web Service Logs (last $lines lines) ===${NC}"
            journalctl -u screenly-web --no-pager -l -n "$lines"
            ;;
        viewer)
            echo -e "${CYAN}=== Viewer Service Logs (last $lines lines) ===${NC}"
            journalctl -u screenly-viewer --no-pager -l -n "$lines"
            ;;
        all|"")
            echo -e "${CYAN}=== Web Service Logs (last $lines lines) ===${NC}"
            journalctl -u screenly-web --no-pager -l -n "$lines"
            echo ""
            echo -e "${CYAN}=== Viewer Service Logs (last $lines lines) ===${NC}"
            journalctl -u screenly-viewer --no-pager -l -n "$lines"
            ;;
        management)
            echo -e "${CYAN}=== Management Logs ===${NC}"
            if [[ -f "$LOG_FILE" ]]; then
                tail -n "$lines" "$LOG_FILE"
            else
                print_info "No management logs found"
            fi
            ;;
        *)
            print_error "Unknown log type: $service"
            echo "Available logs: web, viewer, all, management"
            return 1
            ;;
    esac
}

follow_logs() {
    local service="$1"
    
    case "$service" in
        web)
            print_info "Following web service logs (Ctrl+C to stop)"
            journalctl -u screenly-web -f
            ;;
        viewer)
            print_info "Following viewer service logs (Ctrl+C to stop)"
            journalctl -u screenly-viewer -f
            ;;
        all|"")
            print_info "Following all service logs (Ctrl+C to stop)"
            journalctl -u screenly-web -u screenly-viewer -f
            ;;
        *)
            print_error "Unknown log type: $service"
            echo "Available logs: web, viewer, all"
            return 1
            ;;
    esac
}

show_info() {
    print_header
    
    echo -e "${CYAN}=== System Information ===${NC}"
    
    # Anthias version
    local version=$(curl -s "$API_BASE/info" 2>/dev/null | \
        python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('version', 'Unknown'))" 2>/dev/null)
    print_info "Anthias version: $version"
    
    # Hardware info
    local model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0' || echo "Unknown")
    print_info "Hardware: $model"
    
    # OS info
    local os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
    print_info "OS: $os_info"
    
    # Network info
    local ip_address=$(hostname -I | awk '{print $1}')
    print_info "IP Address: $ip_address"
    
    # Display info
    local display_info=$(tvservice -s 2>/dev/null || echo "Unknown")
    print_info "Display: $display_info"
    
    echo ""
    echo -e "${CYAN}=== Asset Information ===${NC}"
    
    local assets=$(curl -s "$API_BASE/assets" 2>/dev/null)
    if [[ -n "$assets" ]]; then
        echo "$assets" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for asset in data:
        print(f\"Name: {asset.get('name', 'N/A')}\")
        print(f\"URL: {asset.get('uri', 'N/A')}\")
        print(f\"Enabled: {'Yes' if asset.get('is_enabled') else 'No'}\")
        print(f\"Duration: {asset.get('duration', 'N/A')} seconds\")
        print(f\"ID: {asset.get('asset_id', 'N/A')}\")
        print()
except:
    print('Failed to parse asset information')
"
    else
        print_info "No assets found"
    fi
}

enable_asset() {
    local asset_id=$(get_asset_id)
    if [[ -z "$asset_id" ]]; then
        print_error "Scoreboard asset not found"
        return 1
    fi
    
    curl -s -X PUT "$API_BASE/assets/$asset_id" \
        -H "Content-Type: application/json" \
        -d '{"is_enabled": 1}' >/dev/null
    
    print_success "Asset enabled"
    log_action "Asset enabled"
}

disable_asset() {
    local asset_id=$(get_asset_id)
    if [[ -z "$asset_id" ]]; then
        print_error "Scoreboard asset not found"
        return 1
    fi
    
    curl -s -X PUT "$API_BASE/assets/$asset_id" \
        -H "Content-Type: application/json" \
        -d '{"is_enabled": 0}' >/dev/null
    
    print_success "Asset disabled"
    log_action "Asset disabled"
}

update_duration() {
    local new_duration="$1"
    
    if [[ -z "$new_duration" ]]; then
        print_error "Duration is required"
        echo "Usage: $0 update-duration <seconds>"
        return 1
    fi
    
    local asset_id=$(get_asset_id)
    if [[ -z "$asset_id" ]]; then
        print_error "Scoreboard asset not found"
        return 1
    fi
    
    curl -s -X PUT "$API_BASE/assets/$asset_id" \
        -H "Content-Type: application/json" \
        -d "{\"duration\": \"$new_duration\"}" >/dev/null
    
    print_success "Duration updated to $new_duration seconds"
    log_action "Duration updated to $new_duration seconds"
}

backup_config() {
    local backup_dir="/home/pi/anthias-backup-$(date +%Y%m%d_%H%M%S)"
    
    print_info "Creating backup in: $backup_dir"
    mkdir -p "$backup_dir"
    
    # Backup database
    cp /home/pi/.screenly/screenly.db "$backup_dir/" 2>/dev/null || true
    
    # Backup configuration files
    cp /boot/config.txt "$backup_dir/" 2>/dev/null || true
    cp /etc/wpa_supplicant/wpa_supplicant.conf "$backup_dir/" 2>/dev/null || true
    
    # Export assets via API
    curl -s "$API_BASE/assets" > "$backup_dir/assets.json" 2>/dev/null || true
    
    # Create backup info
    cat << EOF > "$backup_dir/backup_info.txt"
Backup created: $(date)
Anthias version: $(curl -s "$API_BASE/info" 2>/dev/null | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('version', 'Unknown'))" 2>/dev/null)
System: $(uname -a)
EOF
    
    print_success "Backup created: $backup_dir"
    log_action "Backup created: $backup_dir"
}

show_help() {
    echo "Anthias Scoreboard Management Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  status                    - Show system and asset status"
    echo "  update-url <url>          - Update scoreboard URL"
    echo "  restart                   - Restart Anthias services"
    echo "  logs [service] [lines]    - Show logs (web/viewer/all/management)"
    echo "  follow [service]          - Follow logs in real-time"
    echo "  info                      - Show system information"
    echo "  enable                    - Enable scoreboard asset"
    echo "  disable                   - Disable scoreboard asset"
    echo "  update-duration <seconds> - Update asset duration"
    echo "  backup                    - Create configuration backup"
    echo "  help                      - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 update-url https://new-scoreboard.com"
    echo "  $0 logs web 100"
    echo "  $0 follow viewer"
    echo "  $0 update-duration 3600"
}

main() {
    case "$1" in
        status)
            show_status
            ;;
        update-url)
            update_url "$2"
            ;;
        restart)
            restart_services
            ;;
        logs)
            show_logs "$2" "$3"
            ;;
        follow)
            follow_logs "$2"
            ;;
        info)
            show_info
            ;;
        enable)
            enable_asset
            ;;
        disable)
            disable_asset
            ;;
        update-duration)
            update_duration "$2"
            ;;
        backup)
            backup_config
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            show_status
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"