#!/bin/bash
#SBATCH --job-name=gdb
#SBATCH --output=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/gdb_%A_%a.out
#SBATCH --error=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/gdb_%A_%a.err
#SBATCH --time=2-00:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=4
#SBATCH --array=0-49


export BASHRCSOURCED=1
set -eo pipefail

source ~/.bash_profile
source "$HOME/.conda/etc/profile.d/conda.sh" 2>/dev/null || true
conda activate bioinfo_tools

# Fail fast if gatk isn't available
which gatk
gatk --version

BASE=/home/exacloud/gscratch/CEDAR/lindleyk/WES
CHUNKDIR=$BASE/interval_chunks
OUTROOT=$BASE/gdb_workspaces
TMPDIR=$BASE/tmp/gdb_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}

REF=/home/groups/CEDAR/lindley/genome/GRCh38/no_chr/Homo_sapiens.GRCh38.dna.primary_assembly.fa
SAMPLE_MAP=/home/groups/CEDAR/lindley/WES_ANALYSIS/output_from_pipeline/HTC_output/sample_map.txt

mkdir -p "$TMPDIR" "$OUTROOT" "$BASE/logs"

INTERVALS=$(printf "%s/chunk_%04d.bed" "$CHUNKDIR" "$SLURM_ARRAY_TASK_ID")
OUTDB=$(printf "%s/gdb_%04d" "$OUTROOT" "$SLURM_ARRAY_TASK_ID")

# Sanity checks (will stop immediately with a clear error)
[[ -s "$INTERVALS" ]] || { echo "ERROR: missing intervals file: $INTERVALS"; exit 3; }
[[ -s "$SAMPLE_MAP" ]] || { echo "ERROR: missing sample map: $SAMPLE_MAP"; exit 4; }

echo "JobID: ${SLURM_JOB_ID}  TaskID: ${SLURM_ARRAY_TASK_ID}"
echo "Intervals: $INTERVALS ($(wc -l < "$INTERVALS") lines)"
echo "Workspace: $OUTDB"
echo "TMPDIR: $TMPDIR"
echo "Samples: $(wc -l < "$SAMPLE_MAP")"
df -h "$BASE" || true

# Start clean for this chunk
rm -rf "$OUTDB"

gatk --java-options "-Xmx18g -Djava.io.tmpdir=$TMPDIR" GenomicsDBImport \
  --genomicsdb-workspace-path "$OUTDB" \
  --tmp-dir "$TMPDIR" \
  --batch-size 10 \
  --reader-threads "${SLURM_CPUS_PER_TASK}" \
  --genomicsdb-shared-posixfs-optimizations true \
  --merge-input-intervals true \
  -L "$INTERVALS" \
  --sample-name-map "$SAMPLE_MAP"




echo "GenomicsDBImport complete for chunk ${SLURM_ARRAY_TASK_ID}."
du -sh "$OUTDB" || true
