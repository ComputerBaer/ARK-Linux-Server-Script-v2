# ARK - Linux Server Script v2
This script provides an easy way for installing and managing an [ARK: Survival Evolved](http://store.steampowered.com/app/346110/)-Server on a Linux.

## Features
* ARK-Server
  * Start / Stop
  * Install / Update / Validate
* Script
  * Auto update / Integrity checks
  * Dependency checker
  * Add your own actions
* Configuration
* Backup
* Multiple instances

## Install
To install run this command:
```
curl -sL http://git.io/vBEKB -o arkserver.sh && chmod +x arkserver.sh && ./arkserver.sh
```
Afterwards issue this command or run the included actions manually:
```
sudo ./dependencies.sh
```
