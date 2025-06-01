#!/bin/bash

# Script Name: apache_installer_by_rezawojdani.sh
# Author: Reza Wojdani
# Description: Install or update Apache HTTP Server on Ubuntu systems.
# Features: Menu-based, Logging support, Clean Uninstall, Let's Encrypt integration, Auto-renew test

LOG_FILE="/var/log/apache_installer_rezawojdani.log"
BACKUP_DIR="/root"

# --- Functions ---

log() {
    echo "[$(date '+%Y-%m-%d %H:%M')] $1" | tee -a "$LOG_FILE"
}

check_ubuntu() {
    if [[ $(grep -Ei 'ubuntu' /etc/os-release) ]]; then
        log "INFO: Operating System: Ubuntu ✅"
    else
        log "ERROR: This script is designed for Ubuntu only."
        exit 1
    fi
}

update_system() {
    log "INFO: Updating package list ..."
    sudo apt update > /dev/null 2>&1 && log "SUCCESS: System updated successfully."
}

install_from_apt() {
    if command -v apache2 &> /dev/null; then
        log "INFO: Apache already installed. Version: $(apache2 -v | grep 'version' | awk '{print $3}')"
        read -p "[?] Do you want to upgrade it? (y/n): " UPD
        if [[ "$UPD" == "y" || "$UPD" == "Y" ]]; then
            sudo apt upgrade -y apache2
            log "SUCCESS: Apache upgraded via APT."
        fi
    else
        log "INFO: Installing Apache via APT ..."
        sudo apt install -y apache2
        sudo systemctl enable apache2 --now
        log "SUCCESS: Apache installed and started via APT."
    fi
}

restart_apache() {
    if command -v apache2 &> /dev/null; then
        log "INFO: Restarting Apache service ..."
        sudo systemctl restart apache2
        log "SUCCESS: Apache restarted."
    else
        log "ERROR: Apache is not installed yet."
    fi
}

uninstall_apache() {
    if ! command -v apache2 &> /dev/null; then
        log "ERROR: Apache is not installed."
        return
    fi

    log "INFO: Starting Apache clean uninstall process."

    # Ask confirmation first time
    read -p "[!] Are you sure you want to remove Apache completely? (yes/no): " CONFIRM1
    if [[ "$CONFIRM1" != "yes" ]]; then
        log "INFO: Uninstall canceled by user."
        return
    fi

    # Ask for backup
    read -p "[?] Would you like to create a backup of Apache configs before removal? (yes/no): " BACKUP_CONFIRM
    if [[ "$BACKUP_CONFIRM" == "yes" ]]; then
        TIMESTAMP=$(date "+%Y-%m-%d_%H-%M")
        BACKUP_NAME="apache_backup_$TIMESTAMP.bak"
        sudo tar -czf "/root/$BACKUP_NAME" /etc/apache2 2>/dev/null || true
        log "SUCCESS: Backup created at /root/$BACKUP_NAME"
    fi

    # Final warning
    read -p "[!!!] FINAL WARNING: This will permanently remove Apache. Type YES to confirm: " FINAL_CONFIRM
    if [[ "$FINAL_CONFIRM" != "YES" ]]; then
        log "INFO: Uninstall canceled by user."
        return
    fi

    # Stop and disable service
    sudo systemctl stop apache2 2>/dev/null || true
    sudo systemctl disable apache2 2>/dev/null || true

    # Remove packages
    sudo apt purge -y apache2* 2>/dev/null || true
    sudo rm -rf /etc/apache2 /var/www/html /var/log/apache2 /usr/sbin/apache2 /usr/lib/apache2

    log "SUCCESS: Apache has been completely removed from your system."
}

view_log_file() {
    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE"
    else
        echo "[!] Log file does not exist yet."
    fi
}

install_letsencrypt() {
    log "INFO: Checking for Certbot installation ..."

    # Check if certbot exists
    if command -v certbot &> /dev/null; then
        log "INFO: Certbot is already installed."
    else
        log "INFO: Installing Certbot via Snap ..."
        sudo apt install -y snapd > /dev/null 2>&1
        sudo snap install core; sudo snap refresh core > /dev/null 2>&1
        sudo snap install certbot --classic > /dev/null 2>&1
        sudo ln -s /snap/bin/certbot /usr/bin/certbot > /dev/null 2>&1
    fi

    # Check if Apache is installed
    if ! command -v apache2 &> /dev/null; then
        log "ERROR: Apache is not installed. Please install Apache first."
        return 1
    fi

    read -p "[?] Enter your domain (e.g., example.com): " DOMAIN
    read -p "[?] Enter your email for renewal notifications: " EMAIL

    log "INFO: Requesting SSL certificate for $DOMAIN ..."

    sudo certbot --apache -d "$DOMAIN" -m "$EMAIL" --agree-tos --non-interactive

    if [ $? -eq 0 ]; then
        log "SUCCESS: SSL certificate issued and configured for $DOMAIN"
        echo "[+] SSL certificate successfully installed for https://$DOMAIN" 
        echo "[+] Auto-renewal is already configured (runs twice daily)."
    else
        log "ERROR: Failed to obtain SSL certificate"
        echo "[-] There was an error requesting the SSL certificate."
        echo "[-] Make sure:"
        echo "     - You have a valid public domain pointing to this server"
        echo "     - Port 80/443 are open"
        echo "     - Apache is running"
    fi
}

remove_letsencrypt() {
    log "INFO: Removing Let's Encrypt (Certbot) and related files..."

    if command -v certbot &> /dev/null; then
        sudo snap remove certbot > /dev/null 2>&1
        sudo rm -rf /snap/certbot
        log "SUCCESS: Certbot removed successfully."
    else
        log "INFO: Certbot is not installed."
    fi

    sudo rm -rf /etc/letsencrypt /var/log/letsencrypt /var/lib/letsencrypt
    sudo find /etc/apache2 -type f -name "*.conf" -exec sed -i '/^.*SSLEngine on.*/d' {} \;
    sudo a2dissite default-ssl.conf > /dev/null 2>&1
    sudo systemctl reload apache2 > /dev/null 2>&1

    log "SUCCESS: Let's Encrypt and all related files have been removed."
}

test_letsencrypt_renewal() {
    log "INFO: Testing SSL auto-renewal ..."

    sudo certbot renew --dry-run

    if [ $? -eq 0 ]; then
        log "SUCCESS: SSL renewal test passed!"
        echo "[+] SSL renewal test successful. Auto-renewal is working correctly."
    else
        log "ERROR: SSL renewal test failed"
        echo "[-] SSL renewal test failed. Possible issues with:"
        echo "     - Apache configuration"
        echo "     - Certbot setup"
        echo "     - Domain DNS or web server accessibility"
    fi
}

main_menu() {
    clear
    echo "######################################################"
    echo "#                                                    #"
    echo "#        Apache Installer & Updater Script           #"
    echo "#                By Reza Wojdani                     #"
    echo "#                                                    #"
    echo "######################################################"
    echo ""
    echo "Select an option:"
    echo "1) Install Apache via APT"
    echo "2) Upgrade Apache (if installed)"
    echo "3) Restart Apache Service"
    echo "4) View Log File"
    echo "5) Uninstall Apache (Clean Remove)"
    echo "6) Install SSL with Let's Encrypt"
    echo "7) Remove Let's Encrypt & Certbot (Clean)"
    echo "8) Test SSL Certificate Auto-Renewal"
    echo "9) Exit"
    echo ""
}

# --- Main Script ---

check_ubuntu

while true; do
    main_menu
    read -p "[?] Enter your choice (1-9): " CHOICE

    case $CHOICE in
        1)
            update_system
            install_from_apt
            ;;
        2)
            if command -v apache2 &> /dev/null; then
                sudo apt upgrade -y apache2
                log "SUCCESS: Apache upgraded via APT."
            else
                log "ERROR: Apache is not installed."
            fi
            ;;
        3)
            restart_apache
            ;;
        4)
            view_log_file
            ;;
        5)
            uninstall_apache
            ;;
        6)
            install_letsencrypt
            ;;
        7)
            remove_lets_encrypt
            ;;
        8)
            test_letsencrypt_renewal
            ;;
        9)
            log "INFO: Exiting script. Goodbye!"
            exit 0
            ;;
        *)
            echo "[!] Invalid option. Please try again."
            sleep 1
            ;;
    esac

    echo ""
    read -p "[*] Press Enter to return to the main menu..."
done