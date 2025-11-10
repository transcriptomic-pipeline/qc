#!/bin/bash

# QC Module Installation Script with Custom Directory Support
# Allows user-specified installation location

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Download URLs
FASTQC_URL="https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip"
TRIMMOMATIC_URL="http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.39.zip"

# Default installation directory (will be overridden by user input)
DEFAULT_INSTALL_DIR="${HOME}/transcriptomic_analysis/softwares"
INSTALL_BASE_DIR=""
FASTQC_DIR=""
TRIMMOMATIC_DIR=""
BIN_DIR=""

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif [ -f /etc/redhat-release ]; then
        DISTRO="redhat"
    else
        DISTRO="unknown"
    fi
    echo "$DISTRO"
}

# Prompt for installation directory
prompt_install_directory() {
    echo ""
    echo "========================================"
    echo "  Installation Directory Selection"
    echo "========================================"
    echo ""
    log_info "Choose installation directory for QC tools"
    echo ""
    echo "Recommended options:"
    echo "  1) ${HOME}/transcriptomic_analysis/softwares (recommended for user-specific installation)"
    echo "  2) /opt/qc-tools (system-wide, requires sudo)"
    echo "  3) Custom directory"
    echo ""
    read -p "Enter choice [1-3] (default: 1): " DIR_CHOICE
    
    case "${DIR_CHOICE:-1}" in
        1)
            INSTALL_BASE_DIR="${HOME}/transcriptomic_analysis/softwares"
            ;;
        2)
            INSTALL_BASE_DIR="/opt/qc-tools"
            log_warning "System-wide installation requires sudo privileges"
            ;;
        3)
            read -p "Enter custom installation directory: " CUSTOM_DIR
            INSTALL_BASE_DIR="${CUSTOM_DIR}"
            ;;
        *)
            log_warning "Invalid choice. Using default: ${DEFAULT_INSTALL_DIR}"
            INSTALL_BASE_DIR="${DEFAULT_INSTALL_DIR}"
            ;;
    esac
    
    # Expand tilde if present
    INSTALL_BASE_DIR="${INSTALL_BASE_DIR/#\~/$HOME}"
    
    # Remove trailing slash if present
    INSTALL_BASE_DIR="${INSTALL_BASE_DIR%/}"
    
    # Set subdirectories
    FASTQC_DIR="${INSTALL_BASE_DIR}/FastQC"
    TRIMMOMATIC_DIR="${INSTALL_BASE_DIR}/Trimmomatic"
    BIN_DIR="${INSTALL_BASE_DIR}/bin"
    
    echo ""
    log_info "Installation directory: ${INSTALL_BASE_DIR}"
    
    # Check if directory exists
    if [ -d "${INSTALL_BASE_DIR}" ]; then
        log_info "Directory exists: ${INSTALL_BASE_DIR}"
        
        # Check if directory is empty
        if [ -n "$(ls -A ${INSTALL_BASE_DIR} 2>/dev/null)" ]; then
            log_warning "Directory is not empty. Existing files may be overwritten."
            read -p "Continue with this directory? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Restarting directory selection..."
                prompt_install_directory
                return
            fi
        fi
    else
        log_info "Directory does not exist. It will be created."
    fi
    
    echo ""
    log_info "Tools will be installed to:"
    echo "  FastQC:      ${FASTQC_DIR}"
    echo "  Trimmomatic: ${TRIMMOMATIC_DIR}"
    echo "  Executables: ${BIN_DIR}"
    echo ""
    
    read -p "Proceed with this directory? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "Restarting directory selection..."
        prompt_install_directory
        return
    fi
    
    # Create base directory
    log_info "Creating installation directory..."
    if mkdir -p "${INSTALL_BASE_DIR}" 2>/dev/null; then
        log_success "Created: ${INSTALL_BASE_DIR}"
    else
        log_error "Failed to create directory: ${INSTALL_BASE_DIR}"
        log_info "Checking if sudo is required..."
        
        # Try with sudo
        read -p "Try creating directory with sudo? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            if sudo mkdir -p "${INSTALL_BASE_DIR}"; then
                log_success "Created with sudo: ${INSTALL_BASE_DIR}"
                
                # Change ownership to current user
                log_info "Changing ownership to current user..."
                if sudo chown -R $(whoami):$(whoami) "${INSTALL_BASE_DIR}"; then
                    log_success "Ownership changed to $(whoami)"
                else
                    log_warning "Could not change ownership. You may need sudo for installation."
                fi
            else
                log_error "Failed to create directory even with sudo"
                log_info "Please check permissions or choose a different directory"
                prompt_install_directory
                return
            fi
        else
            log_error "Cannot proceed without creating the directory"
            prompt_install_directory
            return
        fi
    fi
    
    # Create subdirectories
    log_info "Creating subdirectories..."
    if mkdir -p "${BIN_DIR}" 2>/dev/null; then
        log_success "Subdirectories created"
    else
        log_error "Failed to create subdirectories"
        exit 1
    fi
    
    # Verify write permissions
    if [ -w "${INSTALL_BASE_DIR}" ]; then
        log_success "Write permission verified"
    else
        log_error "No write permission for ${INSTALL_BASE_DIR}"
        log_info "You may need sudo privileges for this location"
        exit 1
    fi
    
    log_success "Installation directory configured successfully"
}

# Check Java
check_java() {
    if command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
        log_success "Java found: ${JAVA_VERSION}"
        return 0
    else
        log_warning "Java not found"
        return 1
    fi
}

install_java() {
    log_info "Installing Java..."
    
    DISTRO=$(detect_distro)
    
    case "$DISTRO" in
        ubuntu|debian|linuxmint|mint)
            log_info "Detected Ubuntu/Mint/Debian"
            log_info "Running: sudo apt install default-jre"
            sudo apt update
            sudo apt install -y default-jre
            ;;
        centos|rhel|redhat|fedora)
            log_info "Detected CentOS/RedHat/Fedora"
            log_info "Running: sudo yum install java-1.8.0-openjdk"
            sudo yum install -y java-1.8.0-openjdk
            ;;
        *)
            log_error "Unsupported distribution: $DISTRO"
            log_info "Please install Java manually:"
            log_info "  Ubuntu/Mint: sudo apt install default-jre"
            log_info "  CentOS/RedHat: sudo yum install java-1.8.0-openjdk"
            return 1
            ;;
    esac
    
    if command_exists java; then
        log_success "Java installed successfully"
        return 0
    else
        log_error "Java installation failed"
        return 1
    fi
}

# Check Perl
check_perl() {
    if command_exists perl; then
        PERL_VERSION=$(perl -v | grep -oP '(?<=\(v)\d+\.\d+\.\d+' | head -n 1)
        log_success "Perl found: v${PERL_VERSION}"
        return 0
    else
        log_warning "Perl not found"
        return 1
    fi
}

install_perl() {
    log_info "Installing Perl..."
    
    DISTRO=$(detect_distro)
    
    case "$DISTRO" in
        ubuntu|debian|linuxmint|mint)
            sudo apt install -y perl
            ;;
        centos|rhel|redhat|fedora)
            sudo yum install -y perl
            ;;
        *)
            log_error "Unsupported distribution for automatic Perl installation"
            return 1
            ;;
    esac
    
    log_success "Perl installed"
}

# Check wget
check_wget() {
    if command_exists wget; then
        log_success "wget found"
        return 0
    else
        log_warning "wget not found"
        return 1
    fi
}

install_wget() {
    log_info "Installing wget..."
    
    DISTRO=$(detect_distro)
    
    case "$DISTRO" in
        ubuntu|debian|linuxmint|mint)
            sudo apt install -y wget
            ;;
        centos|rhel|redhat|fedora)
            sudo yum install -y wget
            ;;
    esac
    
    log_success "wget installed"
}

# Check unzip
check_unzip() {
    if command_exists unzip; then
        log_success "unzip found"
        return 0
    else
        log_warning "unzip not found"
        return 1
    fi
}

install_unzip() {
    log_info "Installing unzip..."
    
    DISTRO=$(detect_distro)
    
    case "$DISTRO" in
        ubuntu|debian|linuxmint|mint)
            sudo apt install -y unzip
            ;;
        centos|rhel|redhat|fedora)
            sudo yum install -y unzip
            ;;
    esac
    
    log_success "unzip installed"
}

# Check FastQC
check_fastqc() {
    if command_exists fastqc; then
        FASTQC_VERSION=$(fastqc --version 2>&1 | grep -oP 'FastQC v\K[\d.]+')
        log_success "FastQC found: v${FASTQC_VERSION}"
        return 0
    elif [ -f "${FASTQC_DIR}/fastqc" ]; then
        log_success "FastQC found at ${FASTQC_DIR}"
        return 0
    else
        log_warning "FastQC not found"
        return 1
    fi
}

install_fastqc() {
    log_info "Installing FastQC..."
    log_info "Downloading from: ${FASTQC_URL}"
    
    # Download FastQC
    cd /tmp
    if ! wget -q --show-progress "$FASTQC_URL" -O fastqc_v0.12.1.zip; then
        log_error "Failed to download FastQC"
        return 1
    fi
    
    # Extract
    unzip -q fastqc_v0.12.1.zip
    
    # Make executable
    chmod +x FastQC/fastqc
    
    # Remove old installation if exists
    rm -rf "${FASTQC_DIR}"
    
    # Move to installation directory
    mv FastQC "${FASTQC_DIR}"
    
    # Create symlink in bin directory
    ln -sf "${FASTQC_DIR}/fastqc" "${BIN_DIR}/fastqc"
    
    # Cleanup
    rm fastqc_v0.12.1.zip
    
    log_success "FastQC installed to ${FASTQC_DIR}"
    
    # Verify installation
    if "${FASTQC_DIR}/fastqc" --version >/dev/null 2>&1; then
        log_success "FastQC installation verified"
        return 0
    else
        log_error "FastQC installation verification failed"
        return 1
    fi
}

# Check Trimmomatic
check_trimmomatic() {
    if command_exists trimmomatic; then
        log_success "Trimmomatic found"
        return 0
    elif [ -f "${TRIMMOMATIC_DIR}/trimmomatic.jar" ]; then
        log_success "Trimmomatic jar found at ${TRIMMOMATIC_DIR}"
        return 0
    else
        log_warning "Trimmomatic not found"
        return 1
    fi
}

install_trimmomatic() {
    log_info "Installing Trimmomatic..."
    log_info "Downloading from: ${TRIMMOMATIC_URL}"
    
    # Create Trimmomatic directory
    mkdir -p "${TRIMMOMATIC_DIR}"
    
    # Download Trimmomatic
    cd /tmp
    if ! wget -q --show-progress "$TRIMMOMATIC_URL" -O Trimmomatic-0.39.zip; then
        log_error "Failed to download Trimmomatic"
        return 1
    fi
    
    # Extract
    unzip -q Trimmomatic-0.39.zip
    
    # Move jar and adapters
    cp Trimmomatic-0.39/trimmomatic-0.39.jar "${TRIMMOMATIC_DIR}/trimmomatic.jar"
    
    # Copy adapters
    rm -rf "${TRIMMOMATIC_DIR}/adapters"
    cp -r Trimmomatic-0.39/adapters "${TRIMMOMATIC_DIR}/"
    
    # Create wrapper script in bin directory
    cat > "${BIN_DIR}/trimmomatic" << EOF
#!/bin/bash
# Trimmomatic wrapper script
java -jar "${TRIMMOMATIC_DIR}/trimmomatic.jar" "\$@"
EOF
    chmod +x "${BIN_DIR}/trimmomatic"
    
    # Copy adapters to module config directory
    mkdir -p "${SCRIPT_DIR}/config/adapters"
    cp "${TRIMMOMATIC_DIR}/adapters/"*.fa "${SCRIPT_DIR}/config/adapters/" 2>/dev/null || true
    
    # Cleanup
    rm -rf Trimmomatic-0.39*
    
    log_success "Trimmomatic installed to ${TRIMMOMATIC_DIR}"
    log_info "Adapter files: ${TRIMMOMATIC_DIR}/adapters/"
    log_info "Adapters copied to: ${SCRIPT_DIR}/config/adapters/"
    
    # Verify installation
    if java -jar "${TRIMMOMATIC_DIR}/trimmomatic.jar" -version >/dev/null 2>&1; then
        log_success "Trimmomatic installation verified"
        return 0
    else
        log_error "Trimmomatic installation verification failed"
        return 1
    fi
}

# Update PATH in shell configuration
update_path() {
    local SHELL_RC=""
    
    # Detect shell configuration file
    if [ -n "${BASH_VERSION:-}" ]; then
        SHELL_RC="${HOME}/.bashrc"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        SHELL_RC="${HOME}/.zshrc"
    else
        SHELL_RC="${HOME}/.profile"
    fi
    
    log_info "Updating PATH in ${SHELL_RC}"
    
    # Check if PATH is already configured
    if grep -q "# QC Module - added by installer" "$SHELL_RC" 2>/dev/null; then
        log_warning "PATH already configured in ${SHELL_RC}"
        log_info "Updating existing configuration..."
        
        # Remove old configuration
        sed -i '/# QC Module - added by installer/d' "$SHELL_RC"
        sed -i "\|export PATH=\"${BIN_DIR}:\$PATH\"|d" "$SHELL_RC"
    fi
    
    # Add to PATH
    echo "" >> "$SHELL_RC"
    echo "# QC Module - added by installer" >> "$SHELL_RC"
    echo "export PATH=\"${BIN_DIR}:\$PATH\"" >> "$SHELL_RC"
    
    # Export for current session
    export PATH="${BIN_DIR}:$PATH"
    
    log_success "PATH updated"
}

# Create configuration file with installation paths
save_installation_config() {
    local CONFIG_FILE="${SCRIPT_DIR}/config/install_paths.conf"
    
    mkdir -p "${SCRIPT_DIR}/config"
    
    cat > "$CONFIG_FILE" << EOF
# QC Module Installation Configuration
# Generated on: $(date)

# Installation base directory
INSTALL_BASE_DIR="${INSTALL_BASE_DIR}"

# Tool directories
FASTQC_DIR="${FASTQC_DIR}"
TRIMMOMATIC_DIR="${TRIMMOMATIC_DIR}"
BIN_DIR="${BIN_DIR}"

# Adapter directory
ADAPTER_DIR="${TRIMMOMATIC_DIR}/adapters"
EOF
    
    log_success "Installation configuration saved to: ${CONFIG_FILE}"
}

# Test installation
test_installation() {
    log_info "Testing installation..."
    echo ""
    
    local FAILED=0
    
    # Test Java
    if java -version >/dev/null 2>&1; then
        JAVA_VER=$(java -version 2>&1 | head -n 1)
        log_success "Java: ${JAVA_VER}"
    else
        log_error "Java: FAILED"
        FAILED=1
    fi
    
    # Test Perl
    if perl -e 'exit 0' 2>/dev/null; then
        PERL_VER=$(perl -v | grep -oP '(?<=This is perl ).*?(?=built)' | xargs)
        log_success "Perl: ${PERL_VER}"
    else
        log_error "Perl: FAILED"
        FAILED=1
    fi
    
    # Test FastQC
    if "${BIN_DIR}/fastqc" --version >/dev/null 2>&1; then
        FASTQC_VER=$("${BIN_DIR}/fastqc" --version 2>&1)
        log_success "FastQC: ${FASTQC_VER}"
    else
        log_error "FastQC: FAILED"
        FAILED=1
    fi
    
    # Test Trimmomatic
    if "${BIN_DIR}/trimmomatic" -version >/dev/null 2>&1; then
        TRIM_VER=$("${BIN_DIR}/trimmomatic" -version 2>&1)
        log_success "Trimmomatic: ${TRIM_VER}"
    else
        log_error "Trimmomatic: FAILED"
        FAILED=1
    fi
    
    echo ""
    return $FAILED
}

# Display installation summary
display_summary() {
    echo ""
    echo "========================================"
    echo "  Installation Complete"
    echo "========================================"
    echo ""
    log_success "All tools installed successfully!"
    echo ""
    log_info "Installation Directory:"
    echo "  ${INSTALL_BASE_DIR}/"
    echo ""
    log_info "Installed Tools:"
    echo "  FastQC:      ${FASTQC_DIR}/"
    echo "  Trimmomatic: ${TRIMMOMATIC_DIR}/"
    echo "  Executables: ${BIN_DIR}/"
    echo ""
    log_info "Adapter Files:"
    echo "  ${TRIMMOMATIC_DIR}/adapters/"
    echo "  ${SCRIPT_DIR}/config/adapters/"
    echo ""
    log_info "Configuration:"
    echo "  ${SCRIPT_DIR}/config/install_paths.conf"
    echo ""
    log_warning "IMPORTANT: To use the tools, either:"
    echo "  1. Restart your terminal, OR"
    echo "  2. Run: source ~/.bashrc"
    echo ""
    log_info "Quick Start:"
    echo "  cd ${SCRIPT_DIR}"
    echo "  bash scripts/qc_pipeline.sh -i <input_dir> -o <output_dir> -t 8"
    echo ""
    log_info "For paired-end reads add: --paired"
    log_info "For help: bash scripts/qc_pipeline.sh -h"
    echo ""
    log_info "To uninstall, simply delete: ${INSTALL_BASE_DIR}"
    echo ""
    echo "========================================"
}

# Main installation workflow
main() {
    echo "========================================"
    echo "  QC Module Installation"
    echo "========================================"
    echo ""
    echo "This script will install:"
    echo "  - Java (OpenJDK)"
    echo "  - FastQC v0.12.1"
    echo "  - Trimmomatic v0.39"
    echo "  - Perl (if needed)"
    echo ""
    
    # Detect OS
    DISTRO=$(detect_distro)
    log_info "Detected distribution: ${DISTRO}"
    
    # Prompt for installation directory (if not set via command line)
    if [ -z "$INSTALL_BASE_DIR" ]; then
        prompt_install_directory
    fi
    
    # Check and install system dependencies
    echo ""
    log_info "Step 1: Checking system dependencies..."
    echo ""
    
    # Perl
    if ! check_perl; then
        read -p "Install Perl? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_perl || log_warning "Perl installation had issues"
        fi
    fi
    
    # wget
    if ! check_wget; then
        read -p "Install wget? (needed for downloads) [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_wget || log_warning "wget installation had issues"
        fi
    fi
    
    # unzip
    if ! check_unzip; then
        read -p "Install unzip? (needed for extraction) [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_unzip || log_warning "unzip installation had issues"
        fi
    fi
    
    # Java (required)
    echo ""
    if ! check_java; then
        read -p "Install Java? (REQUIRED for FastQC and Trimmomatic) [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_java || {
                log_error "Java installation failed. Cannot proceed."
                exit 1
            }
        else
            log_error "Java is required. Exiting."
            exit 1
        fi
    fi
    
    # Install QC tools
    echo ""
    log_info "Step 2: Installing QC tools to ${INSTALL_BASE_DIR}..."
    echo ""
    
    # FastQC
    if ! check_fastqc; then
        read -p "Install FastQC? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_fastqc || log_error "FastQC installation failed"
        fi
    fi
    
    echo ""
    
    # Trimmomatic
    if ! check_trimmomatic; then
        read -p "Install Trimmomatic? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_trimmomatic || log_error "Trimmomatic installation failed"
        fi
    fi
    
    # Update PATH
    echo ""
    log_info "Step 3: Configuring environment..."
    update_path
    
    # Make scripts executable
    chmod +x "${SCRIPT_DIR}/scripts/"*.sh 2>/dev/null || true
    chmod +x "${SCRIPT_DIR}/scripts/"*.pl 2>/dev/null || true
    log_success "Scripts configured"
    
    # Save configuration
    save_installation_config
    
    # Test installation
    echo ""
    log_info "Step 4: Testing installation..."
    if test_installation; then
        display_summary
        exit 0
    else
        echo ""
        log_warning "Installation completed with some failures."
        log_info "Please check the error messages above."
        exit 1
    fi
}

# Parse command line arguments
SKIP_PROMPT=false
CUSTOM_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --install-dir)
            CUSTOM_DIR="$2"
            SKIP_PROMPT=true
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --install-dir <path>   Specify installation directory (skips prompt)"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0"
            echo "  $0 --install-dir /home/user/transcriptomic_analysis/softwares"
            echo "  $0 --install-dir /opt/qc-tools"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# If directory specified via command line, use it
if [ "$SKIP_PROMPT" = true ]; then
    INSTALL_BASE_DIR="${CUSTOM_DIR/#\~/$HOME}"
    INSTALL_BASE_DIR="${INSTALL_BASE_DIR%/}"  # Remove trailing slash
    FASTQC_DIR="${INSTALL_BASE_DIR}/FastQC"
    TRIMMOMATIC_DIR="${INSTALL_BASE_DIR}/Trimmomatic"
    BIN_DIR="${INSTALL_BASE_DIR}/bin"
    
    log_info "Using specified installation directory: ${INSTALL_BASE_DIR}"
    
    # Create directory if it doesn't exist
    if [ ! -d "${INSTALL_BASE_DIR}" ]; then
        log_info "Directory does not exist. Creating..."
        if mkdir -p "${INSTALL_BASE_DIR}" 2>/dev/null; then
            log_success "Created: ${INSTALL_BASE_DIR}"
        else
            log_error "Failed to create directory: ${INSTALL_BASE_DIR}"
            log_info "Trying with sudo..."
            if sudo mkdir -p "${INSTALL_BASE_DIR}" && sudo chown -R $(whoami):$(whoami) "${INSTALL_BASE_DIR}"; then
                log_success "Created with sudo and ownership changed"
            else
                log_error "Failed to create directory. Please check permissions."
                exit 1
            fi
        fi
    else
        log_info "Directory already exists: ${INSTALL_BASE_DIR}"
    fi
    
    # Create subdirectories
    mkdir -p "${BIN_DIR}" || {
        log_error "Failed to create subdirectories"
        exit 1
    }
    
    # Verify write permissions
    if [ ! -w "${INSTALL_BASE_DIR}" ]; then
        log_error "No write permission for ${INSTALL_BASE_DIR}"
        exit 1
    fi
    
    log_success "Installation directory configured"
fi

# Run main installation
main
