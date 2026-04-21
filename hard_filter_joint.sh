#!/bin/bash
#SBATCH --job-name=hardfilter
#SBATCH --output=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/hardfilter_%j.out
#SBATCH --error=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/hardfilter_%j.err
#SBATCH --time=06:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=2

export BASHRCSOURCED=1
set -eo pipefail

########################################
# Environment setup
########################################
echo "[$(date)] Starting hard filter job"
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

########################################
# Inputs/Outputs
########################################
VCF=/home/exacloud/gscratch/CEDAR/lindleyk/WES/joint_all.vcf.gz
OUTDIR=/home/exacloud/gscratch/CEDAR/lindleyk/WES/filtered
mkdir -p "$OUTDIR"

echo "[$(date)] Input VCF: $VCF"
ls -lh "$VCF" "${VCF}.tbi"
echo

########################################
# Step 0: Quick sanity check
########################################
echo "[$(date)] STEP 0: CountVariants on input VCF"
gatk CountVariants -V "$VCF"
echo "[$(date)] STEP 0 complete ✅"
echo

########################################
# Step 1: Split SNPs and INDELs
########################################
echo "[$(date)] STEP 1A: SelectVariants (SNPs)"
gatk --java-options "-Xmx18g" SelectVariants \
  -V "$VCF" \
  --select-type-to-include SNP \
  -O "$OUTDIR/joint.snps.vcf.gz"
echo "[$(date)] STEP 1A complete ✅"
ls -lh "$OUTDIR/joint.snps.vcf.gz" "$OUTDIR/joint.snps.vcf.gz.tbi"
echo

echo "[$(date)] STEP 1B: SelectVariants (INDELs)"
gatk --java-options "-Xmx18g" SelectVariants \
  -V "$VCF" \
  --select-type-to-include INDEL \
  -O "$OUTDIR/joint.indels.vcf.gz"
echo "[$(date)] STEP 1B complete ✅"
ls -lh "$OUTDIR/joint.indels.vcf.gz" "$OUTDIR/joint.indels.vcf.gz.tbi"
echo

########################################
# Step 2: Hard filter SNPs
########################################
echo "[$(date)] STEP 2: VariantFiltration (SNPs)"
gatk --java-options "-Xmx18g" VariantFiltration \
  -V "$OUTDIR/joint.snps.vcf.gz" \
  -O "$OUTDIR/joint.snps.filtered.vcf.gz" \
  --filter-name "QD2"        --filter-expression "QD < 2.0" \
  --filter-name "FS60"       --filter-expression "FS > 60.0" \
  --filter-name "SOR3"       --filter-expression "SOR > 3.0" \
  --filter-name "MQ40"       --filter-expression "MQ < 40.0" \
  --filter-name "MQRS-12.5"  --filter-expression "MQRankSum < -12.5" \
  --filter-name "RPRS-8"     --filter-expression "ReadPosRankSum < -8.0"

echo "[$(date)] STEP 2 complete ✅"
ls -lh "$OUTDIR/joint.snps.filtered.vcf.gz" "$OUTDIR/joint.snps.filtered.vcf.gz.tbi"
echo

########################################
# Step 3: Hard filter INDELs
########################################
echo "[$(date)] STEP 3: VariantFiltration (INDELs)"
gatk --java-options "-Xmx18g" VariantFiltration \
  -V "$OUTDIR/joint.indels.vcf.gz" \
  -O "$OUTDIR/joint.indels.filtered.vcf.gz" \
  --filter-name "QD2"        --filter-expression "QD < 2.0" \
  --filter-name "FS200"      --filter-expression "FS > 200.0" \
  --filter-name "SOR10"      --filter-expression "SOR > 10.0" \
  --filter-name "RPRS-20"    --filter-expression "ReadPosRankSum < -20.0"

echo "[$(date)] STEP 3 complete ✅"
ls -lh "$OUTDIR/joint.indels.filtered.vcf.gz" "$OUTDIR/joint.indels.filtered.vcf.gz.tbi"
echo

########################################
# Step 4: Keep PASS only
########################################
echo "[$(date)] STEP 4A: SelectVariants PASS-only (SNPs)"
gatk --java-options "-Xmx18g" SelectVariants \
  -V "$OUTDIR/joint.snps.filtered.vcf.gz" \
  --exclude-filtered true \
  -O "$OUTDIR/joint.snps.PASS.vcf.gz"
echo "[$(date)] STEP 4A complete ✅"
ls -lh "$OUTDIR/joint.snps.PASS.vcf.gz" "$OUTDIR/joint.snps.PASS.vcf.gz.tbi"
echo

echo "[$(date)] STEP 4B: SelectVariants PASS-only (INDELs)"
gatk --java-options "-Xmx18g" SelectVariants \
  -V "$OUTDIR/joint.indels.filtered.vcf.gz" \
  --exclude-filtered true \
  -O "$OUTDIR/joint.indels.PASS.vcf.gz"
echo "[$(date)] STEP 4B complete ✅"
ls -lh "$OUTDIR/joint.indels.PASS.vcf.gz" "$OUTDIR/joint.indels.PASS.vcf.gz.tbi"
echo

########################################
# Step 5: Gather PASS VCFs + index
########################################
echo "[$(date)] STEP 5: GatherVcfs (PASS SNPs + PASS INDELs)"
gatk --java-options "-Xmx18g" GatherVcfs \
  -I "$OUTDIR/joint.snps.PASS.vcf.gz" \
  -I "$OUTDIR/joint.indels.PASS.vcf.gz" \
  -O "$OUTDIR/joint.PASS.all.vcf.gz"
echo "[$(date)] STEP 5 complete ✅"
ls -lh "$OUTDIR/joint.PASS.all.vcf.gz" || true
echo

echo "[$(date)] STEP 5B: IndexFeatureFile (final PASS VCF)"
gatk IndexFeatureFile -I "$OUTDIR/joint.PASS.all.vcf.gz"
echo "[$(date)] STEP 5B complete ✅"
ls -lh "$OUTDIR/joint.PASS.all.vcf.gz" "$OUTDIR/joint.PASS.all.vcf.gz.tbi"
echo

########################################
# Step 6: QC counts
########################################
echo "[$(date)] STEP 6: CountVariants on final PASS VCF"
gatk CountVariants -V "$OUTDIR/joint.PASS.all.vcf.gz"
echo "[$(date)] STEP 6 complete ✅"
echo

########################################
# Done
########################################
echo "[$(date)] ALL DONE ✅ Outputs located in: $OUTDIR"
du -sh "$OUTDIR" || true
