# QC Module v1.0.0 - Initial Release

Released: November 12, 2025

## Overview

First stable release of the QC Module - a comprehensive RNA-seq quality control pipeline using FastQC and Trimmomatic.

## Features

### Core Functionality
- ✅ Automated installation with custom directory support
- ✅ FastQC quality assessment (before and after trimming)
- ✅ Trimmomatic read trimming with configurable parameters
- ✅ Paired-end and single-end read support
- ✅ Batch processing with sample list support
- ✅ Comprehensive logging and reporting

### File Format Support
- ✅ Flexible FASTQ naming: `_R1/_R2` and `_1/_2` patterns
- ✅ Compressed files: `.fastq.gz`, `.fq.gz`
- ✅ Automatic pattern detection with user feedback

### Installation
- ✅ One-command installation
- ✅ Custom installation directory
- ✅ Automatic dependency detection and installation
- ✅ Fallback adapter files included
- ✅ Auto-cleanup of failed installations

## Tools Included

- **FastQC** v0.12.1
- **Trimmomatic** v0.40
- **Java** (OpenJDK 8 or 11)
- **Perl** 5.10+

## Installation

git clone https://github.com/transcriptomic-pipeline/qc.git
cd qc
chmod +x install.sh run_qc.sh
./install.sh

## Quick Start

./run_qc.sh -i raw_data/ -o qc_results/ -t 20

## What's New in v1.0.0

### Initial Features
- Complete automated installation system
- Robust file naming pattern detection
- Comprehensive error handling
- Detailed logging system
- Fallback adapter support
- Custom parameter configuration

### Documentation
- Complete README with examples
- Detailed installation guide
- Comprehensive usage documentation
- Troubleshooting guide

## System Requirements

- **OS**: Linux (Ubuntu 18.04+, CentOS 7+) or macOS 10.14+
- **RAM**: 4 GB minimum, 8 GB recommended
- **Storage**: 2 GB for tools + data space
- **CPU**: 2+ cores recommended

## Known Issues

None at this time.

## Upgrade Notes

This is the first release. No upgrade path needed.

## Contributors

- [Babul Pradhan, Dr. Jyoti Sharma]

## License

[License]

## Citation

If you use this pipeline, please cite:

[Citation]
