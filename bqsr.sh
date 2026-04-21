#!/bin/bash
#SBATCH --job-name=bqsr
#SBATCH --output=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/err/bqsr_err/%A_%a.out
#SBATCH --error=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/err/bqsr_err/%A_%a.err
#SBATCH --time=36:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=10


### This file performs base quality score recalibiration, a preprocessing step before variant calling, this step prepares BAM file for variant calling ###
### Steps already complete before running this file: Alignment (aligment_wes.sh) and Read Group assignment (haplo.sh) ###
source ~/.bash_profile
conda activate bioinfo_tools

inbam=$1
sample=$(basename "$inbam" .rg.bam)

# Create Directories for each smaple
BASEOUT=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/bqsr_output
OUTDIR=$BASEOUT/$sample

mkdir -p "$OUTDIR"
echo "=============================================="
echo " Running BQSR for sample: $sample"
echo " Input BAM: $inbam"
echo " Output directory: $OUTDIR"
echo "=============================================="
echo ""

# Build out references
REF=/home/groups/CEDAR/lindley/genome/GRCh38/no_chr/Homo_sapiens.GRCh38.dna.primary_assembly.fa
DBSNP=/home/groups/CEDAR/lindley/genome/GRCh38/wes_resources/Homo_sapiens_assembly38.dbsnp138.nochr.vcf.gz
MILLS=/home/groups/CEDAR/lindley/genome/GRCh38/wes_resources/Mills_and_1000G_gold_standard.indels.hg38.nochr.vcf.gz
KNOWN_INDELS=/home/groups/CEDAR/lindley/genome/GRCh38/wes_resources/Homo_sapiens_assembly38.known_indels.nochr.vcf.gz

# BaseRecalibrator
echo "[STEP 1] Running BaseRecalibrator..."
gatk BaseRecalibrator \
    -I $inbam \
    -R "$REF" \
    --known-sites "$DBSNP" \
    --known-sites "$MILLS" \
    --known-sites "$KNOWN_INDELS" \
    -O "$OUTDIR/${sample}.recal.table"
echo "[STEP 1 COMPLETE] BaseRecalibrator output: $OUTDIR/${sample}.recal.table"
echo ""

# ApplyBQSR
echo "[STEP 2] Applying BQSR..."
gatk ApplyBQSR \
    -R "$REF" \
    -I "$inbam" \
    --bqsr-recal-file "$OUTDIR/${sample}.recal.table" \
    -O "$OUTDIR/${sample}.recal.bam"

echo "[STEP 2 COMPLETE] Recalibrated BAM: $OUTDIR/${sample}.recal.bam"
echo ""

# Index the recalibrated BAM
echo "[STEP 3] Indexing recalibrated BAM..."
samtools index "$OUTDIR/${sample}.recal.bam"

echo "[STEP 3 COMPLETE] BAM indexed."

echo "=============================================="
echo " BQSR PIPELINE SUMMARY FOR SAMPLE: $sample"
echo "=============================================="
echo "Input BAM:"
echo "    $inbam"
echo ""
echo "Output directory:"
echo "    $OUTDIR"
echo ""
echo "Generated files:"
echo "    - Recalibration table:    ${OUTDIR}/${sample}.recal.table"
echo "    - Recalibrated BAM:       ${OUTDIR}/${sample}.recal.bam"
echo "    - BAM index (.bai):       ${OUTDIR}/${sample}.recal.bam.bai"
echo ""
echo "BQSR processing completed successfully."
echo "=============================================="
