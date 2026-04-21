#!/bin/bash
#SBATCH --job-name=gd_pt2
#SBATCH --output=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/err/jg_err/pt2/%A.out
#SBATCH --error=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/err/jg_err/pt2/%A.err
#SBATCH --time=24:00:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=4

source ~/.bash_profile
conda activate bioinfo_tools

REF=/home/groups/CEDAR/lindley/genome/GRCh38/no_chr/Homo_sapiens.GRCh38.dna.primary_assembly.fa
GDB=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/jg_output
INTERVALS=/home/groups/CEDAR/lindley/genome/GRCh38/WES_agilent_region_filtered_hg38_strict.bed
OUTDIR=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/gvcf_joint
OUTVCF=$OUTDIR/joint_raw.vcf.gz

mkdir -p $OUTDIR

echo "Running GenotypeGVCFs..."

gatk --java-options "-Xmx40g" GenotypeGVCFs \
   -R $REF \
   -V gendb://$GDB \
   -L $INTERVALS \
   -O $OUTVCF

echo "GenotypeGVCFs complete."
