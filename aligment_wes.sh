#!/bin/bash
#SBATCH --job-name=wes_alignment
#SBATCH --output=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/err/bwa_err/bwa_%A_%a.out
#SBATCH --error=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/err/bwa_err/bwa_%A_%a.err
#SBATCH --time=36:00:00
#SBATCH --mem=12G
#SBATCH --cpus-per-task=10

############################
# Environment Setup
############################
source ~/.bash_profile
conda activate bioinfo_tools

############################
# Define input/output names
############################
library=$(basename $1 _1.fq.gz)


BASEOUT=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/aligned_output
OUTDIR=$BASEOUT/$library
mkdir -p $OUTDIR

echo "=============================================="
echo " Running WES Pipeline"
echo " Library: $library"
echo " Output Directory: $OUTDIR"
echo "=============================================="
echo ""

############################
# STEP 1 — BWA MEM
############################
echo "[STEP 1] Running bwa mem..."
bwa mem -t 10 \
    /home/groups/CEDAR/lindley/genome/GRCh38/no_chr/Homo_sapiens.GRCh38.dna.primary_assembly.fa \
    $1 $2 > $OUTDIR/${library}.sam

echo "[STEP 1 COMPLETE] bwa mem finished."
echo ""

conda deactivate
source ~/.bash_profile

############################
# STEP 2 — Remove alt alignments + name sort
############################
echo "[STEP 2] Removing alt alignments and name-sorting..."
samtools view -b -F 2048 $OUTDIR/${library}.sam | \
    samtools sort -n -@10 - -o $OUTDIR/${library}.nsorted.bam

echo "[STEP 2 COMPLETE] Alt alignments removed and name sorting done."
echo ""

conda activate bioinfo_tools

############################
# STEP 3 — Mark Illumina adapters
############################
echo "[STEP 3] Marking Illumina adapters with Picard..."
picard MarkIlluminaAdapters \
    INPUT=$OUTDIR/${library}.nsorted.bam \
    METRICS=$OUTDIR/${library}.metrics_markadapters

echo "[STEP 3 COMPLETE] MarkIlluminaAdapters finished."
echo ""

conda deactivate
source ~/.bash_profile

############################
# STEP 4 — Position sorting
############################
echo "[STEP 4] Position sorting BAM..."
samtools sort -@10 $OUTDIR/${library}.nsorted.bam -o $OUTDIR/${library}.sorted.bam

echo "[STEP 4 COMPLETE] BAM position-sorted."
echo ""

conda activate bioinfo_tools

############################
# STEP 5 — Mark Duplicates
############################
echo "[STEP 5] MarkDuplicates running..."
java -Xms512m -Xmx12g -jar /home/exacloud/gscratch/CEDAR/lindleyk/miniconda/envs/bioinfo_tools/share/picard-2.18.29-0/picard.jar MarkDuplicates \
    I=$OUTDIR/${library}.sorted.bam \
    O=$OUTDIR/${library}.marked_duplicates.bam \
    M=$OUTDIR/${library}.marked_dup_metrics.txt

echo "[STEP 5 COMPLETE] MarkDuplicates finished."
echo ""
echo "=============================================="
echo " Pipeline finished for: $library"
echo " All output written to: $OUTDIR"
echo "=============================================="
