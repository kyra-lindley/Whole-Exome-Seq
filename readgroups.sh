#!/bin/bash
#SBATCH --job-name=haplo_filtering
#SBATCH --output=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/err/readgroups_err/hf_%A_%a.out
#SBATCH --error=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/err/readgroups_err/hf_%A_%a.err
#SBATCH --time=36:00:00
#SBATCH --mem=12G
#SBATCH --cpus-per-task=10

# This script performs the Read Group assignment step of the WES pipeline.
# It takes a marked-duplicates BAM file as input, extracts the sample name,
# assigns proper read groups using GATK AddOrReplaceReadGroups, and indexes
# the resulting BAM using samtools. The output is a .rg.bam file ready for
# downstream steps such as BaseRecalibrator and HaplotypeCaller.

source ~/.bash_profile
conda activate bioinfo_tools

# Define Input files
inbam=$1

# Extract sample name without extension
sample=$(basename "$inbam" .marked_duplicates.bam)
OUTDIR=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/haplo_output

echo "=============================================="
echo " Running AddOrReplaceReadGroups"
echo " Input BAM: $inbam"
echo " Sample name: $sample"
echo " Output directory: $OUTDIR"
echo "=============================================="
echo ""

gatk AddOrReplaceReadGroups \
    -I "$inbam" \
    -O $OUTDIR/${sample}.rg.bam \
    -RGID $sample \
    -RGLB lib1 \
    -RGPL ILLUMINA \
    -RGPU unit1 \
    -RGSM $sample

echo "=============================================="
echo " AddOrReplaceReadGroups done, Running Samtools "
echo "=============================================="

samtools index $OUTDIR/${sample}.rg.bam

echo "=============================================="
echo " Samtools Done, .rg.bam file created in $OUTDIR/${sample}.rg.bam"
echo "=============================================="