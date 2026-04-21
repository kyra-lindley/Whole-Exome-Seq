#!/bin/bash
#SBATCH --job-name=gather_vcfs
#SBATCH --output=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/gather_%j.out
#SBATCH --error=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/gather_%j.err
#SBATCH --time=06:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2

export BASHRCSOURCED=1
set -eo pipefail

source ~/.bash_profile
source "$HOME/.conda/etc/profile.d/conda.sh" 2>/dev/null || true
conda activate bioinfo_tools

LIST=/home/exacloud/gscratch/CEDAR/lindleyk/WES/joint_chunks/vcfs.list
OUT=/home/exacloud/gscratch/CEDAR/lindleyk/WES/joint_all.vcf.gz

gatk --java-options "-Xmx12g" GatherVcfs \
  -I "$LIST" \
  -O "$OUT"

ls -lh "$OUT" "${OUT}.tbi"
EOF

