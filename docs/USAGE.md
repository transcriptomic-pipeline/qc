# Usage Guide

## Basic Usage

### Minimal Command

./run_qc.sh -i /path/to/raw_fastq -o qc_results -t 20

## Supported File Naming

The pipeline automatically detects both naming conventions:

### Paired-End
- **Illumina standard**: `sample_R1.fastq`, `sample_R2.fastq`
- **Alternative**: `sample_1.fastq`, `sample_2.fastq`
- **Compressed**: `*.fastq.gz`, `*.fq.gz`

The pipeline will display which pattern it detected:

[INFO] Detected naming pattern: _R1/_R2
[INFO] R1: sample_R1.fastq
[INFO] R2: sample_R2.fastq

### Single-End
- `sample.fastq` or `sample.fq`
- Compressed: `*.fastq.gz`, `*.fq.gz`

## Processing Modes

### 1. Process All Samples

Automatically finds and processes all paired-end samples:

./run_qc.sh -i raw_data/ -o qc_results/ -t 20

### 2. Process Specific Samples

Create `samples.txt`:

sample1
sample2
sample3

Run:
./run_qc.sh -i raw_data/ -o qc_results/ -s samples.txt -t 20

### 3. FastQC Only

Run quality assessment without trimming:

./run_qc.sh -i raw_data/ -o qc_results/ --fastqc-only -t 20

### 4. Single-End Reads

For single-end sequencing data:

./run_qc.sh -i raw_data/ -o qc_results/ --single-end -t 20

## Parameter Customization

### Quality Thresholds

./run_qc.sh -i raw_data/ -o qc_results/
--minlen 70 \ # Minimum read length
--leading 3 \ # Cut bases < Q3 from start
--trailing 3 \ # Cut bases < Q3 from end
--slidingwindow 4:20 \ # Window:average quality
-t 20

### Custom Adapters

./run_qc.sh -i raw_data/ -o qc_results/
--adapters /path/to/custom_adapters.fa
-t 20

### Phred Score

Phred+33 (default, modern Illumina)
./run_qc.sh -i raw_data/ -o qc_results/ --phred 33

Phred+64 (older Illumina)
./run_qc.sh -i raw_data/ -o qc_results/ --phred 64

## Complete Examples

### Example 1: Standard RNA-seq

./run_qc.sh
-i /home/user/DATA/raw_fastq
-o /home/user/RESULTS/qc_output
-t 20

### Example 2: Tumor/Normal Samples

cat > samples.txt << EOF
normal_patient1
normal_patient2
tumor_patient1
tumor_patient2
EOF

./run_qc.sh
-i /data/raw_fastq
-o /data/qc_results
-s samples.txt
-t 20

### Example 3: Strict Filtering

./run_qc.sh
-i raw_data/
-o qc_strict/
--minlen 100
--leading 20
--trailing 20
--slidingwindow 4:25
-t 20

### Example 4: Quick Quality Check

FastQC only (fast, for initial assessment)
./run_qc.sh
-i raw_data/
-o qc_check/
--fastqc-only
-t 20

## Output Structure

qc_results/

├── fastqc_raw/ # Raw read quality reports

├── fastqc_trimmed/ # Trimmed read quality reports

├── trimmed/

│ ├── PE/ # Paired reads (use these!)

│ └── UP/ # Unpaired reads

├── logs/ # Check for errors

│ ├── sample1_trimmomatic.log

│ ├── sample1_trimlog.txt

│ └── fastqc_*.log

└── qc_summary.txt # Processing summary

## Interpreting Results

### FastQC Reports

Open `*.html` files in browser.

**Key metrics:**
- **Per base sequence quality**: Should be mostly green (Phred > 28)
- **Adapter content**: Should be low after trimming
- **Sequence duplication**: High in RNA-seq is normal
- **Overrepresented sequences**: Check for contamination

**Compare before/after:**
- `fastqc_raw/` - Before trimming
- `fastqc_trimmed/` - After trimming (should be improved)

### Trimmomatic Logs

Check `logs/*_trimmomatic.log`:

Input Read Pairs: 10000000
Both Surviving: 9500000 (95.00%)
Forward Only Surviving: 300000 (3.00%)
Reverse Only Surviving: 150000 (1.50%)
Dropped: 50000 (0.50%)

**Quality indicators:**
- **Good**: >90% both surviving
- **Acceptable**: 70-90% both surviving
- **Poor**: <70% both surviving (review parameters)

## Best Practices

### 1. Check Quality First

./run_qc.sh -i raw_data/ -o qc_check/ --fastqc-only -t 20

Review results, then trim.

### 2. Use Appropriate Threads

Check available cores
nproc

Use 70-80% of available cores
./run_qc.sh -i raw_data/ -o qc_results/ -t 20 # For 32-core system

### 3. Check Logs

Check for errors
grep -i error qc_results/logs/*.log

Check trimming statistics
grep "Both Surviving" qc_results/logs/*_trimmomatic.log

### 4. Organize Your Data

project/

├── raw_data/ # Original FASTQ files

├── qc_results/ # QC output

├── aligned/ # Aligned reads

└── analysis/ # Downstream analysis

## Troubleshooting

### No FASTQ files found

ls -lh raw_data/

Verify file names match supported patterns

**Supported patterns:**
- `sample_R1.fastq`, `sample_R2.fastq`
- `sample_1.fastq`, `sample_2.fastq`
- Compressed: `*.fastq.gz`

### R2 file not found

The pipeline shows which pattern it expected:

[WARNING] R2 file not found for sample (expected pattern: _R1/_R2), skipping...

Ensure matching names:
- ✓ `sample_R1.fastq` → `sample_R2.fastq`
- ✗ `sample_R1.fastq` → `sample_2.fastq` (mixed patterns)

### Low surviving reads

If "Both Surviving" < 70%:
- Review raw FastQC reports
- Lower quality thresholds (try `--leading 5 --trailing 5`)
- Check if correct adapter file is used

### Java memory error

export _JAVA_OPTIONS="-Xmx8g"
./run_qc.sh -i raw_data/ -o qc_results/ -t 10

## Next Steps

After QC, use trimmed reads from `qc_results/trimmed/PE/` for:

1. **Alignment**: STAR, HISAT2
2. **Quantification**: RSEM, featureCounts, Salmon
3. **Differential Expression**: DESeq2, edgeR
4. **Variant Calling**: GATK, Mutect2

Or you can readily use our transcriptomic-pipeline (https://github.com/transcriptomic-pipeline) for downstream transcriptomic analysis.

### Example Alignment

STAR --runThreadN 20
--genomeDir genome_index/
--readFilesIn qc_results/trimmed/PE/sample1_R1_paired.fastq
qc_results/trimmed/PE/sample1_R2_paired.fastq
--outFileNamePrefix aligned/sample1_

## Getting Help

Show all options
./run_qc.sh --help

Check tool versions
fastqc --version
trimmomatic -version

For issues, check logs in `qc_results/logs/`.
