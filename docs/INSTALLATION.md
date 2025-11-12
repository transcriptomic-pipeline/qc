# Installation Guide

## Quick Install

### Automatic (Recommended)

Run the QC pipeline, and it will prompt for installation if tools are missing:

./run_qc.sh -i input_dir -o output_dir

### Manual

./install.sh


## Installation Options

When you run `install.sh`, you'll choose an installation directory:

1. /home/user/softwares (recommended)

2. /opt/qc-tools (system-wide, requires sudo)

3. Custom directory

### Option 1: User Directory (Recommended)

./install.sh

Choose option 1

- Installs to `~/softwares`
- No sudo required
- Easy to manage and uninstall

### Option 2: System-Wide
./install.sh

- Installs to `/opt/qc-tools`
- Requires sudo privileges
- Shared across all users

### Option 3: Custom Directory

./install.sh

Choose option 3
Enter: /path/to/your/directory

Or use command-line:
./install.sh --install-dir /path/to/your/directory


## What Gets Installed

- **Java** (OpenJDK 8 or 11) - Required for FastQC and Trimmomatic
- **Perl** 5.10+ - Required for data processing
- **FastQC** 0.12.1 - Quality assessment tool
- **Trimmomatic** 0.40 - Read trimming tool
- **wget, unzip** - Download and extraction utilities

## Adapter Files

The repository includes fallback Illumina adapter files in `config/adapters/`. During Trimmomatic installation, these will be replaced with the official adapter files from Trimmomatic 0.40.

**Adapter priority:**
1. Official Trimmomatic adapters (after installation)
2. Fallback adapters from repository (if Trimmomatic not installed)
3. Custom adapter file (specified with `-a` option)

## Installation Process

The installer will:

1. **Check dependencies** - Verify Java, Perl, wget, unzip
2. **Install missing tools** - Prompt to install each missing tool
3. **Download QC tools** - FastQC 0.12.1 and Trimmomatic 0.40
4. **Configure environment** - Add tools to PATH in ~/.bashrc
5. **Verify installation** - Test that all tools work correctly
6. **Save configuration** - Create config/install_paths.conf

## Verification

After installation:

fastqc --version
trimmomatic -version
java -version

Restart terminal or:
source ~/.bashrc

## System Requirements

### Operating Systems
- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RedHat 7+
- macOS 10.14+

### Hardware
- CPU: 2+ cores recommended
- RAM: 4 GB minimum, 8 GB recommended
- Storage: 2 GB for tools

### Dependencies (auto-installed)
- Java (OpenJDK 8 or 11)
- Perl 5.10+
- wget
- unzip

## Installation Structure

~/softwares/ # Or your chosen directory

├── bin/

│ ├── fastqc # FastQC executable

│ └── trimmomatic # Trimmomatic wrapper

├── FastQC/

│ └── fastqc # FastQC program

└── Trimmomatic/

├── trimmomatic.jar # Trimmomatic JAR

└── adapters/ # Adapter sequences

## Troubleshooting

### Command not found

source ~/.bashrc

### Permission denied

chmod +x install.sh run_qc.sh

### Java not found

Ubuntu/Debian
sudo apt install default-jre

CentOS/RedHat
sudo yum install java-1.8.0-openjdk

### Installation fails

If installation fails:

1. Check error messages in terminal
2. Verify you have write permissions to installation directory
3. Try a different installation directory
4. Remove broken installation and retry:

rm -rf ~/softwares # Or your installation directory
./install.sh

### Trimmomatic verification failed

If you see "Trimmomatic installation verification failed":

1. Check that Java is installed: `java -version`
2. Remove the broken installation:
rm -rf ~/softwares/Trimmomatic
rm -f ~/softwares/bin/trimmomatic

3. Run installer again

The installer includes auto-cleanup that removes broken installations automatically.

## Uninstallation

To completely remove:

Remove installed tools
rm -rf ~/softwares # Or your installation directory

Remove PATH modification (optional)
Edit ~/.bashrc and remove these lines:
QC Module - added by installer
export PATH="$HOME/softwares/bin:$PATH"

## Installing on HPC/Cluster

For HPC systems, install to your home directory:

./install.sh --install-dir ~/tools/qc-module

Then use in job scripts:

#!/bin/bash
#SBATCH --job-name=qc
#SBATCH --cpus-per-task=8

export PATH="$HOME/tools/qc-module/bin:$PATH"
./run_qc.sh -i raw_data/ -o qc_results/ -t 8

## Next Steps

After successful installation:

1. Read the [Usage Guide](USAGE.md)
2. Try the examples in `examples/` directory
3. Run QC on your data
