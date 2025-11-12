# qc
Quality assessment and control using FastQC and Trimmomatic
# QC Module - RNA-seq Quality Control Pipeline

A comprehensive quality control pipeline for RNA-seq data using FastQC and Trimmomatic.

## Features

- **Automated installation** - One-command setup with dependency checking
- **Flexible file naming** - Supports both `_R1/_R2` and `_1/_2` naming conventions
- **Custom installation directory** - Install tools anywhere you choose
- **Paired-end and single-end support** - Automatic detection and processing
- **Quality assessment** - FastQC analysis before and after trimming
- **Comprehensive logging** - Detailed logs for all operations
- **Fallback adapter files** - Works even without full installation
- **Robust error handling** - Auto-cleanup and recovery from failed installations

## Quick Start

### 1. Clone the Repository

git clone https://github.com/transcriptomic-pipeline/qc.git
cd qc

### 2. Make Scripts Executable

chmod +x install.sh run_qc.sh

### 3. Run QC Pipeline

The pipeline will automatically detect missing tools and prompt for installation:

./run_qc.sh -i /path/to/raw_fastq -o qc_results -t 8

## Installation

### Automatic Installation (Recommended)

The QC pipeline automatically detects missing tools:

./run_qc.sh -i input_dir -o output_dir

### Manual Installation

./install.sh

Choose your installation directory:
- `~/softwares` (recommended for single-user)
- `/opt/qc-tools` (system-wide, requires sudo)
- Custom directory

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for detailed instructions.

## Usage

### Process All Samples

Automatically detects all paired-end samples:

./run_qc.sh -i raw_data/ -o qc_results/ -t 20

**Supported file naming:**
- `sample_R1.fastq` / `sample_R2.fastq`
- `sample_1.fastq` / `sample_2.fastq`
- Compressed: `*.fastq.gz`

### Process Specific Samples

Create a sample list file (see [examples/samples.txt](examples/samples.txt)):

./run_qc.sh -i raw_data/ -o qc_results/ -s samples.txt -t 20

### FastQC Only (No Trimming)

./run_qc.sh -i raw_data/ -o qc_results/ --fastqc-only -t 20

### Single-End Reads

./run_qc.sh -i raw_data/ -o qc_results/ --single-end -t 20

### Custom Parameters

./run_qc.sh -i raw_data/ -o qc_results/
--minlen 70
--leading 3
--trailing 3
--slidingwindow 4:20
-t 20

See [docs/USAGE.md](docs/USAGE.md) for complete usage documentation.

## Requirements

### System Requirements
- **Operating System**: Linux (Ubuntu 18.04+, CentOS 7+) or macOS 10.14+
- **Memory**: 4 GB minimum, 8 GB recommended
- **Storage**: 2 GB for tools, plus space for your data

### Dependencies (auto-installed)
- Java (OpenJDK 8 or 11)
- Perl 5.10+
- FastQC 0.12.1
- Trimmomatic 0.40
- wget, unzip

## Output Structure

qc_results/

├── fastqc_raw/ # FastQC reports for raw reads

├── fastqc_trimmed/ # FastQC reports for trimmed reads

├── trimmed/

│ ├── PE/ # Paired-end trimmed reads (use for analysis)

│ └── UP/ # Unpaired trimmed reads

├── logs/ # Processing logs

└── qc_summary.txt # Summary report

## Command-Line Options

Required:
-i, --input Input directory containing FASTQ files
-o, --output Output directory for QC results

Optional:
-s, --samples Sample list file (one sample ID per line)
-t, --threads Number of threads (default: 8)
-a, --adapters Adapter file for Trimmomatic
--phred Phred score encoding (33 or 64, default: 33)
--minlen Minimum read length after trimming (default: 70)
--leading Minimum quality at read start (default: 3)
--trailing Minimum quality at read end (default: 3)
--slidingwindow Sliding window quality cutoff (default: 4:20)
--fastqc-only Run only FastQC, skip trimming
--single-end Process as single-end reads
-h, --help Show help message

## Examples

### Example 1: Standard RNA-seq QC

./run_qc.sh
-i /home/user/DATA/raw_fastq
-o /home/user/RESULTS/qc_output
-t 20

### Example 2: Process Tumor/Normal Samples

cat > samples.txt << EOF
normal_sample1
normal_sample2
tumor_sample1
tumor_sample2
EOF

./run_qc.sh
-i /data/raw_fastq
-o /data/qc_results
-s samples.txt
-t 20

### Example 3: Strict Quality Filtering

./run_qc.sh
-i raw_data/
-o qc_strict/
--minlen 100
--leading 20
--trailing 20
--slidingwindow 4:25
-t 20

## Troubleshooting

### Command Not Found After Installation

source ~/.bashrc

### Permission Denied

chmod +x install.sh run_qc.sh

### No Files Found

The pipeline supports these naming patterns:
- `sample_R1.fastq`, `sample_R2.fastq`
- `sample_1.fastq`, `sample_2.fastq`
- Compressed: `*.fastq.gz`

Check your file naming matches one of these patterns.

## Citation

If you use this pipeline, please cite:

- **FastQC**: Andrews S. (2010). FastQC: a quality control tool for high throughput sequence data. Available online at: http://www.bioinformatics.babraham.ac.uk/projects/fastqc
- **Trimmomatic**: Bolger, A. M., Lohse, M., & Usadel, B. (2014). Trimmomatic: A flexible trimmer for Illumina Sequence Data. Bioinformatics, btu170.

## Contact

[email]

## Cite the pipeline

If you have used this pipeline in your work, please cite this pipeline.

[Citation]

This pipeline was developed for RNA-seq quality control in bioinformatics downstream workflows.
