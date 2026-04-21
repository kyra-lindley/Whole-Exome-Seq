#!/bin/bash
#SBATCH --job-name=gdb
#SBATCH --output=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/%A_%a.out
#SBATCH --error=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/%A_%a.err
#SBATCH --time=7-00:00:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=12
#SBATCH --array=0-49



# output files input folder: /home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/jg_output
source ~/.bash_profile
conda activate bioinfo_tools

# Force a stable temp directory
export TMPDIR=/home/exacloud/gscratch/CEDAR/lindleyk/WES/tmp
export _JAVA_OPTIONS="-Djava.io.tmpdir=$TMPDIR"

REF=/home/groups/CEDAR/lindley/genome/GRCh38/no_chr/Homo_sapiens.GRCh38.dna.primary_assembly.fa
INTERVALS=/home/groups/CEDAR/lindley/genome/GRCh38/WES_agilent_region_filtered_hg38_strict.bed
OUTDB=/home/exacloud/gscratch/CEDAR/lindleyk/WES/jg_output
SAMPLE_MAP=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/HTC_output/sample_map.txt

echo "Running GenomicsDBImport..."

gatk --java-options "-Xmx40g" GenomicsDBImport \
    --genomicsdb-workspace-path $OUTDB \
    --batch-size 20 \
    --reader-threads 4 \
    -L $INTERVALS \
    --sample-name-map $SAMPLE_MAP

echo "GenomicsDBImport complete."