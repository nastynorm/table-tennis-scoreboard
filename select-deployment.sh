#!/bin/bash

# Table Tennis Scoreboard - Deployment Selector
# Interactive script to help users choose the right kiosk OS deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Deployment options
DEPLOYMENTS=(
    "dietpi:DietPi:Full control and customization"
    "fullpageos:FullPageOS:Simple, stable kiosk displays"
    "anthias:Anthias (Screenly OSE):Professional digital signage"
)

print_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║           ${CYAN}Table Tennis Scoreboard${BLUE}                          ║${NC}"
    echo -e "${BLUE}║              ${YELLOW}Deployment Selector${BLUE}                           ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 ${#1}))${NC}"
    echo ""
}

print_option() {
    echo -e "${GREEN}[$1]${NC} $2"
}

print_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

show_welcome() {
    print_header
    
    echo -e "${CYAN}Welcome to the Table Tennis Scoreboard Deployment Selector!${NC}"
    echo ""
    echo "This interactive tool will help you choose the best kiosk OS deployment"
    echo "for your specific needs and requirements."
    echo ""
    echo -e "${YELLOW}Hardware Requirements (all deployments):${NC}"
    echo "• Raspberry Pi Zero 2W (recommended)"
    echo "• Waveshare 5\" LCD Display (800x480)"
    echo "• 8GB+ MicroSD Card (Class 10)"
    echo "• Stable WiFi Connection"
    echo ""
    echo -e "Press ${GREEN}Enter${NC} to continue..."
    read -r
}

show_deployment_overview() {
    print_header
    print_section "Available Deployment Options"
    
    echo -e "${GREEN}1. DietPi${NC} - ${YELLOW}Full control and customization${NC}"
    echo "   • Lightweight Debian-based OS"
    echo "   • Complete local hosting solution"
    echo "   • SSH access and command-line management"
    echo "   • Best for developers and advanced users"
    echo ""
    
    echo -e "${GREEN}2. FullPageOS${NC} - ${YELLOW}Simple, stable kiosk displays${NC}"
    echo "   • Minimal OS designed for single web page display"
    echo "   • Boots directly to browser in kiosk mode"
    echo "   • Requires external hosting of scoreboard"
    echo "   • Best for simple, set-and-forget installations"
    echo ""
    
    echo -e "${GREEN}3. Anthias (Screenly OSE)${NC} - ${YELLOW}Professional digital signage${NC}"
    echo "   • Web-based management interface"
    echo "   • Remote content management and scheduling"
    echo "   • API for automation and integration"
    echo "   • Best for professional or multi-display setups"
    echo ""
    
    echo -e "Press ${GREEN}Enter${NC} to continue to the questionnaire..."
    read -r
}

ask_question() {
    local question="$1"
    local options="$2"
    local variable="$3"
    
    echo -e "${CYAN}$question${NC}"
    echo ""
    
    IFS='|' read -ra OPTS <<< "$options"
    for i in "${!OPTS[@]}"; do
        echo -e "${GREEN}$((i+1)).${NC} ${OPTS[i]}"
    done
    echo ""
    
    while true; do
        echo -n "Enter your choice (1-${#OPTS[@]}): "
        read -r choice
        
        if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#OPTS[@]}" ]; then
            eval "$variable=$((choice-1))"
            break
        else
            print_error "Invalid choice. Please enter a number between 1 and ${#OPTS[@]}."
        fi
    done
    echo ""
}

run_questionnaire() {
    print_header
    print_section "Deployment Questionnaire"
    
    echo "Please answer the following questions to help determine the best"
    echo "deployment option for your needs:"
    echo ""
    
    # Question 1: Technical expertise
    ask_question "What is your technical expertise level?" \
        "Beginner (I want the simplest setup)|Intermediate (I'm comfortable with basic Linux)|Advanced (I want full control and customization)" \
        "expertise"
    
    # Question 2: Management preference
    ask_question "How do you prefer to manage the display?" \
        "Set it up once and forget about it|Occasional updates via file configuration|Regular management via web interface|Command-line access for full control" \
        "management"
    
    # Question 3: Hosting preference
    ask_question "Where do you want to host the scoreboard application?" \
        "On the same Raspberry Pi (local hosting)|On a separate server or cloud service|I don't mind either way" \
        "hosting"
    
    # Question 4: Use case
    ask_question "What is your primary use case?" \
        "Personal/home use|Small club or organization|Professional/commercial use|Multiple displays in different locations" \
        "usecase"
    
    # Question 5: Remote management
    ask_question "Do you need remote management capabilities?" \
        "No, local access is fine|Basic remote access (SSH)|Full remote management with web interface" \
        "remote"
    
    # Question 6: Performance priority
    ask_question "What is your priority for the Pi Zero 2W?" \
        "Lowest resource usage and fastest boot|Balance of features and performance|Maximum features regardless of resource usage" \
        "performance"
}

calculate_recommendation() {
    local dietpi_score=0
    local fullpageos_score=0
    local anthias_score=0
    
    # Expertise scoring
    case $expertise in
        0) fullpageos_score=$((fullpageos_score + 3)); anthias_score=$((anthias_score + 1)) ;;
        1) fullpageos_score=$((fullpageos_score + 2)); dietpi_score=$((dietpi_score + 2)); anthias_score=$((anthias_score + 2)) ;;
        2) dietpi_score=$((dietpi_score + 3)); anthias_score=$((anthias_score + 2)) ;;
    esac
    
    # Management scoring
    case $management in
        0) fullpageos_score=$((fullpageos_score + 3)) ;;
        1) fullpageos_score=$((fullpageos_score + 2)); dietpi_score=$((dietpi_score + 1)) ;;
        2) anthias_score=$((anthias_score + 3)) ;;
        3) dietpi_score=$((dietpi_score + 3)) ;;
    esac
    
    # Hosting scoring
    case $hosting in
        0) dietpi_score=$((dietpi_score + 3)) ;;
        1) fullpageos_score=$((fullpageos_score + 2)); anthias_score=$((anthias_score + 2)) ;;
        2) dietpi_score=$((dietpi_score + 1)); fullpageos_score=$((fullpageos_score + 1)); anthias_score=$((anthias_score + 1)) ;;
    esac
    
    # Use case scoring
    case $usecase in
        0) fullpageos_score=$((fullpageos_score + 2)); dietpi_score=$((dietpi_score + 2)) ;;
        1) dietpi_score=$((dietpi_score + 2)); anthias_score=$((anthias_score + 1)) ;;
        2) anthias_score=$((anthias_score + 3)) ;;
        3) anthias_score=$((anthias_score + 3)) ;;
    esac
    
    # Remote management scoring
    case $remote in
        0) fullpageos_score=$((fullpageos_score + 2)); dietpi_score=$((dietpi_score + 1)) ;;
        1) dietpi_score=$((dietpi_score + 2)) ;;
        2) anthias_score=$((anthias_score + 3)) ;;
    esac
    
    # Performance scoring
    case $performance in
        0) fullpageos_score=$((fullpageos_score + 3)); dietpi_score=$((dietpi_score + 2)) ;;
        1) dietpi_score=$((dietpi_score + 2)); anthias_score=$((anthias_score + 1)) ;;
        2) anthias_score=$((anthias_score + 2)) ;;
    esac
    
    # Determine recommendation
    if [ $dietpi_score -gt $fullpageos_score ] && [ $dietpi_score -gt $anthias_score ]; then
        recommended="dietpi"
        recommended_name="DietPi"
        recommended_score=$dietpi_score
    elif [ $fullpageos_score -gt $anthias_score ]; then
        recommended="fullpageos"
        recommended_name="FullPageOS"
        recommended_score=$fullpageos_score
    else
        recommended="anthias"
        recommended_name="Anthias (Screenly OSE)"
        recommended_score=$anthias_score
    fi
    
    # Store all scores for display
    scores="DietPi: $dietpi_score, FullPageOS: $fullpageos_score, Anthias: $anthias_score"
}

show_recommendation() {
    print_header
    print_section "Recommendation Results"
    
    echo -e "${GREEN}Based on your answers, we recommend:${NC}"
    echo ""
    echo -e "${CYAN}🎯 $recommended_name${NC}"
    echo ""
    
    case $recommended in
        "dietpi")
            echo -e "${YELLOW}Why DietPi is recommended for you:${NC}"
            echo "• You want full control and local hosting capabilities"
            echo "• You're comfortable with command-line management"
            echo "• You prefer a complete, self-contained solution"
            echo "• You want good performance with moderate resource usage"
            echo ""
            echo -e "${BLUE}Key Benefits:${NC}"
            echo "• Complete local hosting (no external dependencies)"
            echo "• SSH access for full system control"
            echo "• Automated deployment script included"
            echo "• Optimized for Pi Zero 2W performance"
            echo "• Comprehensive management tools"
            ;;
        "fullpageos")
            echo -e "${YELLOW}Why FullPageOS is recommended for you:${NC}"
            echo "• You want the simplest possible setup"
            echo "• You prefer set-and-forget operation"
            echo "• You don't mind hosting the scoreboard externally"
            echo "• You prioritize lowest resource usage"
            echo ""
            echo -e "${BLUE}Key Benefits:${NC}"
            echo "• Minimal resource usage and fastest boot time"
            echo "• Extremely simple configuration"
            echo "• Very stable and reliable"
            echo "• Perfect for dedicated display use"
            echo "• No complex management required"
            ;;
        "anthias")
            echo -e "${YELLOW}Why Anthias is recommended for you:${NC}"
            echo "• You need professional digital signage features"
            echo "• You want web-based remote management"
            echo "• You may manage multiple displays"
            echo "• You need scheduling and automation capabilities"
            echo ""
            echo -e "${BLUE}Key Benefits:${NC}"
            echo "• Professional web-based management interface"
            echo "• Remote content management and scheduling"
            echo "• API for automation and integration"
            echo "• Multi-display support"
            echo "• Enterprise-grade features"
            ;;
    esac
    
    echo ""
    echo -e "${CYAN}Scoring Details:${NC} $scores"
    echo ""
}

show_next_steps() {
    echo -e "${GREEN}Next Steps:${NC}"
    echo ""
    echo -e "${BLUE}1.${NC} Navigate to the deployment directory:"
    echo -e "   ${CYAN}cd table-tennis-scoreboard-$recommended/${NC}"
    echo ""
    echo -e "${BLUE}2.${NC} Read the comprehensive setup guide:"
    echo -e "   ${CYAN}cat README.md${NC}"
    echo ""
    echo -e "${BLUE}3.${NC} Follow the deployment instructions in the README"
    echo ""
    
    case $recommended in
        "dietpi")
            echo -e "${BLUE}4.${NC} Run the automated deployment script:"
            echo -e "   ${CYAN}./deploy-dietpi.sh${NC}"
            ;;
        "fullpageos")
            echo -e "${BLUE}4.${NC} Configure your hosting solution first, then:"
            echo -e "   ${CYAN}# Flash FullPageOS and configure with provided templates${NC}"
            ;;
        "anthias")
            echo -e "${BLUE}4.${NC} Set up your hosting solution, then run:"
            echo -e "   ${CYAN}./scripts/setup-anthias.sh${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Alternative Options:${NC}"
    echo "If you'd like to explore other deployment options, check out:"
    
    for deployment in "${DEPLOYMENTS[@]}"; do
        IFS=':' read -r key name desc <<< "$deployment"
        if [ "$key" != "$recommended" ]; then
            echo -e "• ${GREEN}$name${NC}: $desc"
            echo -e "  ${CYAN}table-tennis-scoreboard-$key/${NC}"
        fi
    done
}

show_comparison_table() {
    print_header
    print_section "Detailed Comparison"
    
    echo -e "${CYAN}Feature Comparison Table:${NC}"
    echo ""
    printf "%-20s %-15s %-15s %-15s\n" "Feature" "DietPi" "FullPageOS" "Anthias"
    printf "%-20s %-15s %-15s %-15s\n" "$(printf '%.0s-' {1..20})" "$(printf '%.0s-' {1..15})" "$(printf '%.0s-' {1..15})" "$(printf '%.0s-' {1..15})"
    printf "%-20s %-15s %-15s %-15s\n" "Setup Complexity" "Medium" "Simple" "Medium"
    printf "%-20s %-15s %-15s %-15s\n" "Local Hosting" "✅ Yes" "❌ No" "❌ No"
    printf "%-20s %-15s %-15s %-15s\n" "Remote Management" "❌ SSH only" "❌ Limited" "✅ Web + API"
    printf "%-20s %-15s %-15s %-15s\n" "Resource Usage" "Low" "Lowest" "Medium"
    printf "%-20s %-15s %-15s %-15s\n" "Boot Time" "~30s" "~45s" "~60s"
    printf "%-20s %-15s %-15s %-15s\n" "Memory Usage" "~150MB" "~100MB" "~200MB"
    printf "%-20s %-15s %-15s %-15s\n" "Web Interface" "❌ No" "❌ No" "✅ Yes"
    printf "%-20s %-15s %-15s %-15s\n" "API Access" "❌ No" "❌ No" "✅ Yes"
    printf "%-20s %-15s %-15s %-15s\n" "Scheduling" "❌ No" "❌ No" "✅ Yes"
    printf "%-20s %-15s %-15s %-15s\n" "Multi-Display" "❌ Manual" "❌ Manual" "✅ Yes"
    printf "%-20s %-15s %-15s %-15s\n" "Best For" "Developers" "Simple Use" "Enterprise"
    echo ""
}

show_help() {
    print_header
    print_section "Help and Support"
    
    echo -e "${CYAN}Getting Help:${NC}"
    echo ""
    echo -e "${BLUE}📖 Documentation:${NC}"
    echo "• Each deployment directory contains comprehensive README files"
    echo "• Configuration templates with detailed comments"
    echo "• Troubleshooting guides for common issues"
    echo ""
    echo -e "${BLUE}🔧 Management Scripts:${NC}"
    echo "• DietPi: manage-scoreboard.sh"
    echo "• Anthias: manage-anthias.sh"
    echo "• FullPageOS: File-based configuration"
    echo ""
    echo -e "${BLUE}🐛 Troubleshooting:${NC}"
    echo "• Check the troubleshooting section in each README"
    echo "• Review system logs for error messages"
    echo "• Verify network connectivity and display settings"
    echo ""
    echo -e "${BLUE}💬 Community Support:${NC}"
    echo "• GitHub Issues: Report bugs and request features"
    echo "• Discussions: Ask questions and share experiences"
    echo ""
    echo -e "${BLUE}🔄 Migration:${NC}"
    echo "• Use migrate-to-kiosk-os.sh to transfer between deployments"
    echo "• Backup configurations before switching"
}

main_menu() {
    while true; do
        print_header
        print_section "Main Menu"
        
        echo -e "${GREEN}1.${NC} Start Deployment Questionnaire"
        echo -e "${GREEN}2.${NC} View Deployment Overview"
        echo -e "${GREEN}3.${NC} Show Detailed Comparison"
        echo -e "${GREEN}4.${NC} Help and Support"
        echo -e "${GREEN}5.${NC} Exit"
        echo ""
        
        echo -n "Select an option (1-5): "
        read -r choice
        
        case $choice in
            1)
                run_questionnaire
                calculate_recommendation
                show_recommendation
                show_next_steps
                echo ""
                echo -e "Press ${GREEN}Enter${NC} to return to main menu..."
                read -r
                ;;
            2)
                show_deployment_overview
                echo -e "Press ${GREEN}Enter${NC} to return to main menu..."
                read -r
                ;;
            3)
                show_comparison_table
                echo -e "Press ${GREEN}Enter${NC} to return to main menu..."
                read -r
                ;;
            4)
                show_help
                echo -e "Press ${GREEN}Enter${NC} to return to main menu..."
                read -r
                ;;
            5)
                echo ""
                echo -e "${GREEN}Thank you for using the Table Tennis Scoreboard Deployment Selector!${NC}"
                echo ""
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please enter a number between 1 and 5."
                sleep 2
                ;;
        esac
    done
}

# Check if running in interactive mode
if [ -t 0 ]; then
    show_welcome
    main_menu
else
    echo "This script requires interactive input. Please run it in a terminal."
    exit 1
fi