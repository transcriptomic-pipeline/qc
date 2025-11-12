# Installation Guide

## Quick Install

./install.sh


## Installation Options

Choose where to install tools:

1. `~/softwares` - User directory (recommended)
2. `/opt/qc-tools` - System-wide (requires sudo)
3. Custom directory

### Custom Directory

./install.sh --install-dir /your/custom/path


## What Gets Installed

- Java (OpenJDK 8 or 11)
- Perl 5.10+
- FastQC 0.12.1
- Trimmomatic 0.39
- wget, unzip

## Verification

fastqc --version
trimmomatic -version
source ~/.bashrc


## Troubleshooting

**Command not found:**
source ~/.bashrc


**Java not found:**
Ubuntu
sudo apt install default-jre

CentOS
sudo yum install java-1.8.0-openjdk


## Uninstall
rm -rf ~/softwares

undefined
