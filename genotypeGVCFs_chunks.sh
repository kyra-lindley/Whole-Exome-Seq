#!/bin/bash
#SBATCH --job-name=ggvcf
#SBATCH --output=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/ggvcf_%A_%a.out
#SBATCH --error=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/ggvcf_%A_%a.err
#SBATCH --time=1-00:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2
#SBATCH --array=0-49

export BASHRCSOURCED=1
set -eo pipefail

source ~/.bash_profile
source "$HOME/.conda/etc/profile.d/conda.sh" 2>/dev/null || true
conda activate bioinfo_tools

BASE=/home/exacloud/gscratch/CEDAR/lindleyk/WES
DBROOT=$BASE/gdb_workspaces
OUTROOT=$BASE/joint_chunks
TMPDIR=$BASE/tmp/ggvcf_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}

REF=/home/groups/CEDAR/lindley/genome/GRCh38/no_chr/Homo_sapiens.GRCh38.dna.primary_assembly.fa

mkdir -p "$OUTROOT" "$TMPDIR" "$BASE/logs"

DB=$(printf "%s/gdb_%04d" "$DBROOT" "$SLURM_ARRAY_TASK_ID")
OUT=$(printf "%s/joint_%04d.vcf.gz" "$OUTROOT" "$SLURM_ARRAY_TASK_ID")

[[ -d "$DB" ]] || { echo "ERROR: missing GenomicsDB workspace: $DB"; exit 3; }

echo "JobID: ${SLURM_JOB_ID}  TaskID: ${SLURM_ARRAY_TASK_ID}"
echo "DB:  $DB"
echo "OUT: $OUT"
echo "TMP: $TMPDIR"

# If rerunning, clean outputs
rm -f "$OUT" "${OUT}.tbi"

gatk --java-options "-Xmx12g -Djava.io.tmpdir=$TMPDIR" GenotypeGVCFs \
  -R "$REF" \
  -V "gendb://$DB" \
  -O "$OUT" \
  --allow-old-rms-mapping-quality-annotation-data

# Clean tmp to save space
rm -rf "$TMPDIR"

echo "Done chunk ${SLURM_ARRAY_TASK_ID}"
ls -lh "$OUT" "${OUT}.tbi"
