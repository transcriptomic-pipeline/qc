#!/bin/bash

# QC Module - Main Execution Script
# Performs quality control with FastQC and optional Trimmomatic trimming

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="${SCRIPT_DIR}/config/install_paths.conf"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Default parameters
INPUT_DIR=""
OUTPUT_DIR=""
SAMPLE_FILE=""
THREADS=8
PHRED=33
MINLEN=70
LEADING=3
TRAILING=3
SLIDINGWINDOW="4:20"
ADAPTER_FILE=""
RUN_FASTQC_ONLY=false
SKIP_TRIMMING=false
PAIRED_END=true

# Tool paths (will be loaded from config)
FASTQC_BIN=""
TRIMMOMATIC_BIN=""
ADAPTER_DIR=""

# Usage function
usage() {
    cat << EOF
Usage: $0 -i <input_dir> -o <output_dir> [options]

Required:
    -i, --input       Input directory containing FASTQ files
    -o, --output      Output directory for QC results
    
Optional:
    -s, --samples     Sample list file (one sample ID per line)
    -t, --threads     Number of threads (default: 8)
    -a, --adapters    Adapter file for Trimmomatic (default: auto-detect)
    --phred           Phred score encoding (33 or 64, default: 33)
    --minlen          Minimum read length after trimming (default: 70)
    --leading         Minimum quality at read start (default: 3)
    --trailing        Minimum quality at read end (default: 3)
    --slidingwindow   Sliding window quality cutoff (default: 4:20)
    --fastqc-only     Run only FastQC, skip trimming
    --skip-trim       Skip trimming even if quality issues detected
    --single-end      Process as single-end reads (default: paired-end)
    -h, --help        Show this help message

Examples:
    # Process all samples in directory (paired-end)
    $0 -i raw_data/ -o qc_results/ -t 20
    
    # Process specific samples from list
    $0 -i raw_data/ -o qc_results/ -s samples.txt -t 20
    
    # FastQC only, no trimming
    $0 -i raw_data/ -o qc_results/ --fastqc-only
    
    # Single-end reads
    $0 -i raw_data/ -o qc_results/ --single-end

EOF
    exit 1
}

# Check if tools are installed
check_installation() {
    log_info "Checking for installed tools..."
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        log_warning "Installation configuration not found"
        log_info "Tools need to be installed first"
        
        read -p "Run installation now? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            if [ -f "${SCRIPT_DIR}/install.sh" ]; then
                log_info "Running installer..."
                bash "${SCRIPT_DIR}/install.sh"
                
                # Check if installation was successful
                if [ $? -eq 0 ] && [ -f "$CONFIG_FILE" ]; then
                    log_success "Installation completed"
                else
                    log_error "Installation failed"
                    exit 1
                fi
            else
                log_error "Installer not found: ${SCRIPT_DIR}/install.sh"
                exit 1
            fi
        else
            log_error "Tools must be installed to proceed"
            exit 1
        fi
    fi
    
    # Load installation paths
    source "$CONFIG_FILE"
    
    FASTQC_BIN="${BIN_DIR}/fastqc"
    TRIMMOMATIC_BIN="${BIN_DIR}/trimmomatic"
    ADAPTER_DIR="${TRIMMOMATIC_DIR}/adapters"
    
    # Verify tools exist
    if [ ! -f "$FASTQC_BIN" ]; then
        log_error "FastQC not found at: $FASTQC_BIN"
        log_info "Please run install.sh first"
        exit 1
    fi
    
    if [ ! -f "$TRIMMOMATIC_BIN" ]; then
        log_error "Trimmomatic not found at: $TRIMMOMATIC_BIN"
        log_info "Please run install.sh first"
        exit 1
    fi
    
    log_success "Tools found and ready"
    log_info "FastQC: $FASTQC_BIN"
    log_info "Trimmomatic: $TRIMMOMATIC_BIN"
    log_info "Adapters: $ADAPTER_DIR"
}

# Parse command line arguments
parse_arguments() {
    if [ $# -eq 0 ]; then
        usage
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--input)
                INPUT_DIR="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -s|--samples)
                SAMPLE_FILE="$2"
                shift 2
                ;;
            -t|--threads)
                THREADS="$2"
                shift 2
                ;;
            -a|--adapters)
                ADAPTER_FILE="$2"
                shift 2
                ;;
            --phred)
                PHRED="$2"
                shift 2
                ;;
            --minlen)
                MINLEN="$2"
                shift 2
                ;;
            --leading)
                LEADING="$2"
                shift 2
                ;;
            --trailing)
                TRAILING="$2"
                shift 2
                ;;
            --slidingwindow)
                SLIDINGWINDOW="$2"
                shift 2
                ;;
            --fastqc-only)
                RUN_FASTQC_ONLY=true
                shift
                ;;
            --skip-trim)
                SKIP_TRIMMING=true
                shift
                ;;
            --single-end)
                PAIRED_END=false
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    # Validate required arguments
    if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
        log_error "Input and output directories are required"
        usage
    fi
    
    if [ ! -d "$INPUT_DIR" ]; then
        log_error "Input directory does not exist: $INPUT_DIR"
        exit 1
    fi
}

# Auto-detect adapter file
detect_adapters() {
    if [ -n "$ADAPTER_FILE" ]; then
        log_info "Using specified adapter file: $ADAPTER_FILE"
        return
    fi
    
    if [ "$PAIRED_END" = true ]; then
        ADAPTER_FILE="${ADAPTER_DIR}/TruSeq3-PE.fa"
    else
        ADAPTER_FILE="${ADAPTER_DIR}/TruSeq3-SE.fa"
    fi
    
    # Check if adapter exists in Trimmomatic installation directory
    if [ ! -f "$ADAPTER_FILE" ]; then
        log_warning "Adapter file not found in Trimmomatic directory: $ADAPTER_FILE"
        
        # Fallback to module config directory (repo fallback adapters)
        if [ "$PAIRED_END" = true ]; then
            ADAPTER_FILE="${SCRIPT_DIR}/config/adapters/TruSeq3-PE.fa"
        else
            ADAPTER_FILE="${SCRIPT_DIR}/config/adapters/TruSeq3-SE.fa"
        fi
        
        if [ -f "$ADAPTER_FILE" ]; then
            log_info "Using fallback adapter file from module: $ADAPTER_FILE"
        else
            log_error "No adapter file found. Please run install.sh or provide adapter file with -a option"
            exit 1
        fi
    else
        log_info "Using adapter file: $ADAPTER_FILE"
    fi
}

# Create output directory structure
create_output_dirs() {
    log_info "Creating output directory structure..."
    
    mkdir -p "${OUTPUT_DIR}/fastqc_raw"
    mkdir -p "${OUTPUT_DIR}/fastqc_trimmed"
    mkdir -p "${OUTPUT_DIR}/trimmed/PE"
    mkdir -p "${OUTPUT_DIR}/trimmed/UP"
    mkdir -p "${OUTPUT_DIR}/logs"
    mkdir -p "${OUTPUT_DIR}/temp"
    
    log_success "Output directories created"
}

# Run FastQC on a set of files
run_fastqc() {
    local input_dir=$1
    local output_dir=$2
    local label=$3
    
    log_info "Running FastQC on ${label} reads..."
    
    # Find FASTQ files
    local fastq_files=$(find "${input_dir}" -name "*.fastq" -o -name "*.fq" -o -name "*.fastq.gz" -o -name "*.fq.gz" | sort)
    
    if [ -z "$fastq_files" ]; then
        log_warning "No FASTQ files found in ${input_dir}"
        return 1
    fi
    
    "$FASTQC_BIN" \
        --threads "$THREADS" \
        --outdir "$output_dir" \
        --dir "${OUTPUT_DIR}/temp" \
        --extract \
        $fastq_files \
        2>&1 | tee "${OUTPUT_DIR}/logs/fastqc_${label}.log"
    
    log_success "FastQC completed for ${label} reads"
}

# Run Trimmomatic on paired-end reads
run_trimmomatic_pe() {
    local sample_id=$1
    local r1_file=$2
    local r2_file=$3
    
    log_info "Running Trimmomatic on sample: ${sample_id}"
    
    local out_r1_paired="${OUTPUT_DIR}/trimmed/PE/${sample_id}_R1_paired.fastq"
    local out_r1_unpaired="${OUTPUT_DIR}/trimmed/UP/${sample_id}_R1_unpaired.fastq"
    local out_r2_paired="${OUTPUT_DIR}/trimmed/PE/${sample_id}_R2_paired.fastq"
    local out_r2_unpaired="${OUTPUT_DIR}/trimmed/UP/${sample_id}_R2_unpaired.fastq"
    
    "$TRIMMOMATIC_BIN" PE \
        -threads "$THREADS" \
        -phred"${PHRED}" \
        -trimlog "${OUTPUT_DIR}/logs/${sample_id}_trimlog.txt" \
        "$r1_file" "$r2_file" \
        "$out_r1_paired" "$out_r1_unpaired" \
        "$out_r2_paired" "$out_r2_unpaired" \
        ILLUMINACLIP:"${ADAPTER_FILE}":2:30:10:2:True \
        LEADING:"$LEADING" \
        TRAILING:"$TRAILING" \
        SLIDINGWINDOW:"$SLIDINGWINDOW" \
        MINLEN:"$MINLEN" \
        2>&1 | tee "${OUTPUT_DIR}/logs/${sample_id}_trimmomatic.log"
    
    log_success "Trimmomatic completed for ${sample_id}"
}

# Run Trimmomatic on single-end reads
run_trimmomatic_se() {
    local sample_id=$1
    local input_file=$2
    
    log_info "Running Trimmomatic on sample: ${sample_id}"
    
    local out_file="${OUTPUT_DIR}/trimmed/${sample_id}_trimmed.fastq"
    
    "$TRIMMOMATIC_BIN" SE \
        -threads "$THREADS" \
        -phred"${PHRED}" \
        -trimlog "${OUTPUT_DIR}/logs/${sample_id}_trimlog.txt" \
        "$input_file" \
        "$out_file" \
        ILLUMINACLIP:"${ADAPTER_FILE}":2:30:10 \
        LEADING:"$LEADING" \
        TRAILING:"$TRAILING" \
        SLIDINGWINDOW:"$SLIDINGWINDOW" \
        MINLEN:"$MINLEN" \
        2>&1 | tee "${OUTPUT_DIR}/logs/${sample_id}_trimmomatic.log"
    
    log_success "Trimmomatic completed for ${sample_id}"
}

# Detect R2 file based on R1 file pattern
find_r2_file() {
    local r1_file=$1
    local r2_file=""
    
    # Try different patterns to find R2
    if [[ "$r1_file" =~ _R1\. ]] || [[ "$r1_file" =~ _R1_ ]]; then
        r2_file=$(echo "$r1_file" | sed 's/_R1/_R2/g')
    elif [[ "$r1_file" =~ _1\. ]] || [[ "$r1_file" =~ _1_ ]]; then
        r2_file=$(echo "$r1_file" | sed 's/_1\./_2./g' | sed 's/_1_/_2_/g')
    fi
    
    echo "$r2_file"
}

# Detect naming pattern
detect_pattern() {
    local filename=$1
    
    if [[ "$filename" =~ _R1 ]]; then
        echo "_R1/_R2"
    elif [[ "$filename" =~ _1\. ]] || [[ "$filename" =~ _1_ ]]; then
        echo "_1/_2"
    else
        echo "unknown"
    fi
}

# Process samples from file
process_samples_from_file() {
    log_info "Processing samples from file: $SAMPLE_FILE"
    
    if [ ! -f "$SAMPLE_FILE" ]; then
        log_error "Sample file not found: $SAMPLE_FILE"
        exit 1
    fi
    
    local sample_count=0
    
    while IFS= read -r sample_id; do
        # Skip empty lines and comments
        [[ -z "$sample_id" || "$sample_id" =~ ^#.*$ ]] && continue
        
        sample_count=$((sample_count + 1))
        
        echo ""
        log_info "========================================="
        log_info "Processing sample ${sample_count}: ${sample_id}"
        log_info "========================================="
        
        if [ "$PAIRED_END" = true ]; then
            # Look for paired-end files with flexible patterns
            local r1_file=$(find "$INPUT_DIR" -type f \( -name "${sample_id}*_R1*.fastq" -o -name "${sample_id}*_R1*.fq" -o -name "${sample_id}*_R1*.fastq.gz" -o -name "${sample_id}*_R1*.fq.gz" -o -name "${sample_id}*_1.fastq" -o -name "${sample_id}*_1.fq" -o -name "${sample_id}*_1.fastq.gz" -o -name "${sample_id}*_1.fq.gz" \) | head -n 1)
            
            if [ -z "$r1_file" ] || [ ! -f "$r1_file" ]; then
                log_error "R1 file not found for sample: ${sample_id}"
                continue
            fi
            
            # Find corresponding R2 file
            local r2_file=$(find_r2_file "$r1_file")
            local pattern=$(detect_pattern "$r1_file")
            
            if [ ! -f "$r2_file" ]; then
                log_error "R2 file not found for sample: ${sample_id} (expected pattern: ${pattern})"
                continue
            fi
            
            log_info "Detected naming pattern: ${pattern}"
            log_info "R1: $r1_file"
            log_info "R2: $r2_file"
            
            # Run Trimmomatic
            if [ "$RUN_FASTQC_ONLY" = false ]; then
                run_trimmomatic_pe "$sample_id" "$r1_file" "$r2_file"
            fi
        else
            # Look for single-end files
            local input_file=$(find "$INPUT_DIR" -type f \( -name "${sample_id}*.fastq" -o -name "${sample_id}*.fq" -o -name "${sample_id}*.fastq.gz" -o -name "${sample_id}*.fq.gz" \) | head -n 1)
            
            if [ -z "$input_file" ] || [ ! -f "$input_file" ]; then
                log_error "Input file not found for sample: ${sample_id}"
                continue
            fi
            
            log_info "Input: $input_file"
            
            # Run Trimmomatic
            if [ "$RUN_FASTQC_ONLY" = false ]; then
                run_trimmomatic_se "$sample_id" "$input_file"
            fi
        fi
        
    done < "$SAMPLE_FILE"
    
    log_success "Processed ${sample_count} samples"
}

# Process all samples in directory
process_all_samples() {
    log_info "Processing all samples in directory: $INPUT_DIR"
    
    if [ "$PAIRED_END" = true ]; then
        # Find all R1 files (supports both _R1 and _1 patterns)
        local r1_files=$(find "$INPUT_DIR" -type f \( -name "*_R1*.fastq" -o -name "*_R1*.fq" -o -name "*_R1*.fastq.gz" -o -name "*_R1*.fq.gz" -o -name "*_1.fastq" -o -name "*_1.fq" -o -name "*_1.fastq.gz" -o -name "*_1.fq.gz" \) | sort)
        
        if [ -z "$r1_files" ]; then
            log_error "No paired-end FASTQ files found in $INPUT_DIR"
            log_info "Looking for files with patterns: *_R1*.fastq, *_R1*.fq, *_1.fastq, *_1.fq (and .gz versions)"
            exit 1
        fi
        
        local sample_count=0
        
        for r1_file in $r1_files; do
            sample_count=$((sample_count + 1))
            
            # Extract sample ID
            local basename=$(basename "$r1_file")
            local sample_id=$(echo "$basename" | sed -E 's/_(R1|1).*//g')
            
            # Find corresponding R2 file
            local r2_file=$(find_r2_file "$r1_file")
            local pattern=$(detect_pattern "$r1_file")
            
            if [ ! -f "$r2_file" ]; then
                log_warning "R2 file not found for $r1_file (expected pattern: ${pattern}), skipping..."
                continue
            fi
            
            echo ""
            log_info "========================================="
            log_info "Processing sample ${sample_count}: ${sample_id}"
            log_info "========================================="
            log_info "Detected naming pattern: ${pattern}"
            log_info "R1: $r1_file"
            log_info "R2: $r2_file"
            
            # Run Trimmomatic
            if [ "$RUN_FASTQC_ONLY" = false ]; then
                run_trimmomatic_pe "$sample_id" "$r1_file" "$r2_file"
            fi
        done
        
        log_success "Processed ${sample_count} samples"
    else
        # Find all single-end files
        local input_files=$(find "$INPUT_DIR" -type f \( -name "*.fastq" -o -name "*.fq" -o -name "*.fastq.gz" -o -name "*.fq.gz" \) | sort)
        
        if [ -z "$input_files" ]; then
            log_error "No FASTQ files found in $INPUT_DIR"
            exit 1
        fi
        
        local sample_count=0
        
        for input_file in $input_files; do
            sample_count=$((sample_count + 1))
            
            # Extract sample ID
            local basename=$(basename "$input_file")
            local sample_id=$(echo "$basename" | sed -E 's/\.(fastq|fq)(\.gz)?$//g')
            
            echo ""
            log_info "========================================="
            log_info "Processing sample ${sample_count}: ${sample_id}"
            log_info "========================================="
            log_info "Input: $input_file"
            
            # Run Trimmomatic
            if [ "$RUN_FASTQC_ONLY" = false ]; then
                run_trimmomatic_se "$sample_id" "$input_file"
            fi
        done
        
        log_success "Processed ${sample_count} samples"
    fi
}

# Generate summary report
generate_summary() {
    log_info "Generating summary report..."
    
    local summary_file="${OUTPUT_DIR}/qc_summary.txt"
    
    cat > "$summary_file" << EOF
========================================
QC Module Summary Report
========================================
Date: $(date)
Input Directory: ${INPUT_DIR}
Output Directory: ${OUTPUT_DIR}

Parameters:
  Threads: ${THREADS}
  Phred Score: ${PHRED}
  Min Length: ${MINLEN}
  Leading Quality: ${LEADING}
  Trailing Quality: ${TRAILING}
  Sliding Window: ${SLIDINGWINDOW}
  Adapter File: ${ADAPTER_FILE}

Processing Mode: $([ "$PAIRED_END" = true ] && echo "Paired-end" || echo "Single-end")

FastQC Results:
  Raw reads: ${OUTPUT_DIR}/fastqc_raw/
  Trimmed reads: ${OUTPUT_DIR}/fastqc_trimmed/

Trimmed Reads:
  Paired: ${OUTPUT_DIR}/trimmed/PE/
  Unpaired: ${OUTPUT_DIR}/trimmed/UP/

Logs:
  ${OUTPUT_DIR}/logs/

========================================
EOF
    
    log_success "Summary report: $summary_file"
}

# Display final summary
display_final_summary() {
    echo ""
    echo "========================================"
    echo "  QC Processing Complete"
    echo "========================================"
    echo ""
    log_success "All QC steps completed successfully!"
    echo ""
    log_info "Results Directory: ${OUTPUT_DIR}"
    echo ""
    log_info "Output Structure:"
    echo "  FastQC (raw):     ${OUTPUT_DIR}/fastqc_raw/"
    echo "  FastQC (trimmed): ${OUTPUT_DIR}/fastqc_trimmed/"
    echo "  Trimmed PE:       ${OUTPUT_DIR}/trimmed/PE/"
    echo "  Trimmed UP:       ${OUTPUT_DIR}/trimmed/UP/"
    echo "  Logs:             ${OUTPUT_DIR}/logs/"
    echo "  Summary:          ${OUTPUT_DIR}/qc_summary.txt"
    echo ""
    log_info "Next Steps:"
    echo "  - Review FastQC reports in ${OUTPUT_DIR}/fastqc_*/fastqc_report.html"
    echo "  - Check processing logs in ${OUTPUT_DIR}/logs/"
    echo "  - Use trimmed reads from ${OUTPUT_DIR}/trimmed/PE/ for downstream analysis"
    echo ""
    echo "========================================"
}

# Main execution
main() {
    echo "========================================"
    echo "  QC Module - Quality Control Pipeline"
    echo "========================================"
    echo ""
    
    # Parse arguments
    parse_arguments "$@"
    
    # Check installation
    check_installation
    
    # Detect adapters
    detect_adapters
    
    # Create output directories
    create_output_dirs
    
    # Log start time
    local start_time=$(date +%s)
    log_info "Started at: $(date)"
    
    # Step 1: Run FastQC on raw reads
    echo ""
    log_info "Step 1: Running FastQC on raw reads..."
    run_fastqc "$INPUT_DIR" "${OUTPUT_DIR}/fastqc_raw" "raw"
    
    # Step 2: Process samples (trimming)
    if [ "$RUN_FASTQC_ONLY" = false ]; then
        echo ""
        log_info "Step 2: Running Trimmomatic..."
        
        if [ -n "$SAMPLE_FILE" ]; then
            process_samples_from_file
        else
            process_all_samples
        fi
        
        # Step 3: Run FastQC on trimmed reads
        echo ""
        log_info "Step 3: Running FastQC on trimmed reads..."
        run_fastqc "${OUTPUT_DIR}/trimmed/PE" "${OUTPUT_DIR}/fastqc_trimmed" "trimmed"
    else
        log_info "FastQC-only mode. Skipping trimming."
    fi
    
    # Generate summary
    echo ""
    generate_summary
    
    # Calculate runtime
    local end_time=$(date +%s)
    local runtime=$((end_time - start_time))
    local hours=$((runtime / 3600))
    local minutes=$(((runtime % 3600) / 60))
    local seconds=$((runtime % 60))
    
    log_info "Completed at: $(date)"
    log_info "Total runtime: ${hours}h ${minutes}m ${seconds}s"
    
    # Display final summary
    display_final_summary
}

# Run main function with all arguments
main "$@"
