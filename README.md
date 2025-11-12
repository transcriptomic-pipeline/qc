# qc
Quality assessment and control using FastQC and Trimmomatic
# QC Module - RNA-seq Quality Control Pipeline

A comprehensive quality control pipeline for RNA-seq data using FastQC and Trimmomatic.

## Quick Start

chmod +x install.sh run_qc.sh
./run_qc.sh -i /path/to/raw_fastq -o qc_results -t 8

## Features

- Automated installation with dependency checking
- Process all samples or specific samples from a list
- Paired-end and single-end support
- FastQC analysis before and after trimming
- Comprehensive logging
- User-defined installation directory
- **Fallback adapter files** - Works even without installation using repo adapters

## Installation

./install.sh


The pipeline will prompt you to choose an installation directory. See [docs/INSTALLATION.md](docs/INSTALLATION.md) for details.

## Usage Examples

Process all samples:
./run_qc.sh -i raw_data/ -o qc_results/ -t 20

Process specific samples:
./run_qc.sh -i raw_data/ -o qc_results/ -s samples.txt -t 20


FastQC only:
./run_qc.sh -i raw_data/ -o qc_results/ --fastqc-only -t 20


See [docs/USAGE.md](docs/USAGE.md) for complete documentation.

## Requirements

- Linux (Ubuntu 18.04+, CentOS 7+) or macOS 10.14+
- 4 GB RAM minimum, 8 GB recommended
- Java, Perl, FastQC, Trimmomatic (auto-installed)

## Output

qc_results/
├── fastqc_raw/ # Quality reports for raw reads

├── fastqc_trimmed/ # Quality reports for trimmed reads

├── trimmed/PE/ # Trimmed paired-end reads

├── logs/ # Processing logs

└── qc_summary.txt # Summary report


## Options

-i, --input Input directory with FASTQ files
-o, --output Output directory
-s, --samples Sample list file
-t, --threads Number of threads (default: 8)
--minlen Minimum read length (default: 70)
--fastqc-only Run only FastQC
--single-end Process single-end reads
-h, --help Show help

## Citation

- FastQC: Andrews S. (2010)
- Trimmomatic: Bolger et al. (2014) Bioinformatics, btu170
