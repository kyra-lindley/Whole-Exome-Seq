#!/bin/bash
#SBATCH --job-name=qc_sites
#SBATCH --output=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/qc_sites_%j.out
#SBATCH --error=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/qc_sites_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1

export BASHRCSOURCED=1
set -eo pipefail

echo "[$(date)] Starting QC sites table job"
echo "JobID: ${SLURM_JOB_ID}"
echo "Node: $(hostname)"
echo

source ~/.bash_profile
source "$HOME/.conda/etc/profile.d/conda.sh" 2>/dev/null || true
conda activate bioinfo_tools
echo "[$(date)] Conda env activated"
which gatk
gatk --version
echo

VCF=/home/exacloud/gscratch/CEDAR/lindleyk/WES/filtered/joint.PASS.all.vcf.gz
OUTDIR=/home/exacloud/gscratch/CEDAR/lindleyk/WES/qc
OUT=${OUTDIR}/joint.PASS.all.sites.QC.tsv

mkdir -p "$OUTDIR"

echo "[$(date)] Input VCF: $VCF"
ls -lh "$VCF" "${VCF}.tbi"
echo

echo "[$(date)] STEP 1: VariantsToTable (site-level fields)"
gatk VariantsToTable \
  -V "$VCF" \
  -O "$OUT" \
  -F CHROM -F POS -F REF -F ALT -F QUAL -F FILTER \
  -F DP -F QD -F FS -F SOR -F MQ -F MQRankSum -F ReadPosRankSum -F ExcessHet \
  -F AC -F AF -F AN

echo "[$(date)] STEP 1 complete ✅"
ls -lh "$OUT"
echo

echo "[$(date)] STEP 2: Quick sanity preview"
head -n 3 "$OUT" || true
echo
echo "[$(date)] Rows (including header):"
wc -l "$OUT" || true

echo "[$(date)] Done ✅"
