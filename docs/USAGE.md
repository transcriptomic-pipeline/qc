# Usage Guide

## Basic Usage

./run_qc.sh -i /path/to/raw_fastq -o qc_results -t 20

## Input Files

**Paired-end naming:**
- sample_R1.fastq / sample_R2.fastq
- sample_1.fastq / sample_2.fastq
- Compressed: *.fastq.gz

**Single-end naming:**
- sample.fastq or sample.fq

## Processing Modes

### All Samples
./run_qc.sh -i raw_data/ -o qc_results/ -t 20


### Specific Samples

Create samples.txt:
sample1
sample2
sample3

Run:
./run_qc.sh -i raw_data/ -o qc_results/ -s samples.txt -t 20


### FastQC Only
./run_qc.sh -i raw_data/ -o qc_results/ --fastqc-only -t 20


### Single-End
./run_qc.sh -i raw_data/ -o qc_results/ --single-end -t 20


## Custom Parameters
./run_qc.sh -i raw_data/ -o qc_results/
--minlen 70
--leading 3
--trailing 3
--slidingwindow 4:20
-t 20


## Output

- `fastqc_raw/` - Raw quality reports
- `fastqc_trimmed/` - Trimmed quality reports
- `trimmed/PE/` - Use these for downstream analysis
- `logs/` - Check for errors

## Best Practices

1. Run FastQC first: `--fastqc-only`
2. Use 70-80% of available cores
3. Check logs: `grep -i error qc_results/logs/*.log`

## Troubleshooting

**No FASTQ files found:**
Check file naming matches patterns above

**R2 file not found:**
Ensure R1/R2 have matching prefixes

**Low surviving reads:**
Review FastQC reports and adjust parameters
