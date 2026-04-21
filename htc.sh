#!/bin/bash
#SBATCH --job-name=htc
#SBATCH --output=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/err/HTC_err/%A_%a.out
#SBATCH --error=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/err/HTC_err/%A_%a.err
#SBATCH --time=36:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=10


### This file performs GATK Haplotype Caller ###
### Steps already complete before running this file: Alignment (aligment_wes.sh), Read Group assignment (haplo.sh), and base quality score recalibiration (bqsr.sh) ###
### Input file must be the recalibrated bam: sample.recal.bam ###

source ~/.bash_profile
conda activate bioinfo_tools

# Variables
inbam=$1
sample=$(basename "$inbam" .recal.bam)
REF=/home/groups/CEDAR/lindley/genome/GRCh38/no_chr/Homo_sapiens.GRCh38.dna.primary_assembly.fa

BASEOUT=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/HTC_output
OUTDIR=$BASEOUT/$sample
mkdir -p "$OUTDIR"

echo "=============================================="
echo " Running HaplotypeCaller for sample: $sample"
echo " Input BAM: $inbam"
echo " Output directory: $OUTDIR"
echo "=============================================="

gatk HaplotypeCaller \
    -R "$REF" \
    -I "$inbam" \
    -O "$OUTDIR/${sample}.g.vcf.gz" \
    -ERC GVCF

echo "=============================================="
echo " HaplotypeCaller completed for sample: $sample"
echo " Generated files:"
echo "    $OUTDIR/${sample}.g.vcf.gz"
echo "    $OUTDIR/${sample}.g.vcf.gz.tbi"
echo "=============================================="
