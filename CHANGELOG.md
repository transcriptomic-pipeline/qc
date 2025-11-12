# Changelog

All notable changes to the QC Module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-12

### Added
- Initial release of QC Module
- Automated installation system with custom directory support
- FastQC v0.12.1 integration for quality assessment
- Trimmomatic v0.40 integration for read trimming
- Support for both `_R1/_R2` and `_1/_2` file naming patterns
- Automatic file pattern detection with user feedback
- Paired-end and single-end read processing
- Batch processing with sample list support
- Comprehensive logging system
- Detailed error messages and troubleshooting
- Fallback adapter files from repository
- Auto-cleanup of failed installations
- PATH configuration in shell RC files
- Complete documentation (README, INSTALLATION, USAGE)
- Example files and sample lists

### Features
- Custom installation directory selection
- Configurable quality thresholds
- FastQC-only mode (skip trimming)
- Thread control for parallel processing
- Phred score encoding support (33/64)
- Custom adapter file support
- Comprehensive output directory structure
- Summary report generation

### Documentation
- Complete README.md with quick start
- Detailed INSTALLATION.md guide
- Comprehensive USAGE.md with examples
- Troubleshooting sections
- Citation information

### Tools
- FastQC 0.12.1
- Trimmomatic 0.40
- Java (OpenJDK 8/11)
- Perl 5.10+

[1.0.0]: https://github.com/transcriptomic-pipeline/qc/releases/tag/qc_v1.0.0
