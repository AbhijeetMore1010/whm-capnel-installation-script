#!/bin/bash
# cPanel/WHM Installation Script
# This script installs cPanel/WHM on supported Linux distributions
# Adjusted for JustFlyHost by abhijeetmore
# Licensed under the JustFlyHost Team License 2.0

# Function to display JustFlyHost.com in ASCII art
display_ascii_art() {
    if command -v toilet &> /dev/null; then
        echo ""
        toilet -f bigmono12 -F border --gay "justflyhost.com"
        sleep 3
    else
        echo "*********************************************"
        echo "*             justflyhost.com               *"
        echo "*********************************************"
        sleep 3
    fi
}

# Function for logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Error handling function
handle_error() {
    local error_message="$@"
    log "Error: $error_message"
    
    # Attempt to resolve the error automatically
    resolve_error "$error_message"
}

# Function to resolve errors automatically
resolve_error() {
    local error_message="$1"
    
    # Add logic here to resolve specific errors automatically if possible
}

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    handle_error "This script must be run as root"
fi

# Display JustFlyHost.com in ASCII art or text
display_ascii_art

# Inform user to wait for 30 minutes
echo "Please wait for approximately 30 minutes. The installation is in progress..."

# Log file
LOG_FILE="/var/log/cpanel_whm_setup.log"

# Check if log directory exists
if [ ! -d "$(dirname "$LOG_FILE")" ]; then
    handle_error "Log directory does not exist"
fi

# Update the system and install required packages based on the Linux distribution
if [ -f /etc/redhat-release ]; then
    # Red Hat or CentOS
    update_cmd="yum update -y"
    install_cmd="yum install -y"
    services_cmd="service"
elif [ -f /etc/debian_version ]; then
    # Debian or Ubuntu
    update_cmd="apt-get update -y"
    install_cmd="apt-get install -y"
    services_cmd="systemctl"
else
    handle_error "Unsupported Linux distribution"
fi

# Update the system and install required packages
log "Updating system and installing required packages..."
$update_cmd >> "$LOG_FILE" 2>&1 || handle_error "Failed to update system"
$install_cmd perl curl >> "$LOG_FILE" 2>&1 || handle_error "Failed to install Perl and curl"

# Stop and disable NetworkManager (if applicable)
if [ -f /etc/redhat-release ]; then
    log "Stopping NetworkManager service..."
    $services_cmd NetworkManager stop >> "$LOG_FILE" 2>&1 || handle_error "Failed to stop NetworkManager"
    log "Disabling NetworkManager service..."
    chkconfig NetworkManager off >> "$LOG_FILE" 2>&1 || handle_error "Failed to disable NetworkManager"
fi

# Stop and disable firewalld service (if applicable)
log "Stopping firewalld service..."
$services_cmd firewalld stop >> "$LOG_FILE" 2>&1 || handle_error "Failed to stop firewalld service"
log "Disabling firewalld service..."
$services_cmd disable firewalld >> "$LOG_FILE" 2>&1 || handle_error "Failed to disable firewalld service"

# Open ports for cPanel, WHM, and Webmail SSL services
log "Opening ports for cPanel, WHM, and Webmail SSL services..."
iptables -I INPUT -p tcp --dport 2082 -j ACCEPT >> "$LOG_FILE" 2>&1 || handle_error "Failed to open port 2082"
iptables -I INPUT -p tcp --dport 2083 -j ACCEPT >> "$LOG_FILE" 2>&1 || handle_error "Failed to open port 2083"
iptables -I INPUT -p tcp --dport 2086 -j ACCEPT >> "$LOG_FILE" 2>&1 || handle_error "Failed to open port 2086"
iptables -I INPUT -p tcp --dport 2087 -j ACCEPT >> "$LOG_FILE" 2>&1 || handle_error "Failed to open port 2087"
iptables -I INPUT -p tcp --dport 2096 -j ACCEPT >> "$LOG_FILE" 2>&1 || handle_error "Failed to open port 2096"

# Save iptables rules to a file
log "Saving iptables rules..."
iptables-save > /etc/sysconfig/iptables >> "$LOG_FILE" 2>&1 || handle_error "Failed to save iptables rules"

# Download and run cPanel installer
log "Downloading and running cPanel installer..."
cd /home && curl -o latest -L https://securedownloads.cpanel.net/latest && sh latest >> "$LOG_FILE" 2>&1 || handle_error "Failed to download and run cPanel installer"

# Enable NetworkManager service (if applicable)
if [ -f /etc/redhat-release ]; then
    log "Enabling NetworkManager service..."
    chkconfig NetworkManager on >> "$LOG_FILE" 2>&1 || handle_error "Failed to enable NetworkManager"
fi

# Get system IP address
system_ip=$(hostname -I | cut -d' ' -f1)

# Display thank you message
echo "Thanks for using this script! Thank you for choosing justflyhost.com. You can build your servers with confidence."
echo "WHM Installation URL: https://$system_ip:2087"
