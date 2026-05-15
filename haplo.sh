#!/bin/bash
#SBATCH --job-name=readgroups
#SBATCH --time=36:00:00
#SBATCH --mem=12G
#SBATCH --cpus-per-task=10

# This script performs Read Group assignment.
# Input: .marked_duplicates.bam from alignment.sh
# Output: .rg.bam ready for bqsr.sh

source ~/.bash_profile
conda activate bioinfo_tools

inbam=$1
sample=$(basename "$inbam" .marked_duplicates.bam | grep -oP 'OP\d+')

OUTDIR=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/haplo_output
mkdir -p "$OUTDIR"

echo "=============================================="
echo " Running AddOrReplaceReadGroups"
echo " Input BAM: $inbam"
echo " Sample name: $sample"
echo " Output directory: $OUTDIR"
echo "=============================================="

gatk AddOrReplaceReadGroups \
    -I "$inbam" \
    -O "$OUTDIR/${sample}.rg.bam" \
    -RGID $sample \
    -RGLB lib1 \
    -RGPL ILLUMINA \
    -RGPU unit1 \
    -RGSM $sample

echo "[STEP 1 COMPLETE] AddOrReplaceReadGroups done."

samtools index "$OUTDIR/${sample}.rg.bam"

echo "[STEP 2 COMPLETE] BAM indexed."
echo " Output: $OUTDIR/${sample}.rg.bam"
echo "=============================================="
