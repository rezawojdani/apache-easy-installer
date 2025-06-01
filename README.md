# Apache Installer Script by "Rezawojdani"
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/rezawojdani/apache-easy-installer/blob/main/LICENSE) 

A simple and clean bash script for installing, updating, and managing the Apache HTTP Server on Ubuntu systems.

## ✅ Features
- Install Apache via APT
- Upgrade Apache
- Restart Service
- Clean Uninstall (with backup option)
- Let's Encrypt SSL Installation
- Remove Let's Encrypt
- Test SSL Auto-Renewal
- Logging support
- Menu-based interface

## 📄 Backup Location
All backups are stored in:
    /root/apache_backup_DATE-TIME.bak
    
## 🔧 How to Use

You can run this script on any Ubuntu server with bash installed. Here's how:

### ✅ Option 1: Download and Run Directly

```bash
# Download the script
wget https://raw.githubusercontent.com/rezawojdani/apache-easy-installer/main/apache_easy_installer.sh 

# Make it executable
chmod +x apache_easy_installer.sh

# Run the script (preferably as root)
  If you don't have root access, first log in to the root environment : sudo -i
  Or run the commands with sudo :
sudo ./apache_easy_installer.sh
```


### ✅ Option 2: Clone the Repository (Optional)

```bash

git clone https://github.com/rezawojdani/apache-easy-installer.git 
cd apache-easy-installer
chmod +x apache_easy_installer.sh
sudo ./apache_easy_installer.sh
```

### ⚠️ Requirements 

    Operating System: Ubuntu 20.04+ or newer LTS versions
    Internet access for downloading packages
    Root access recommended
    
### MIT License 

- See LICENSE for details
