#!/bin/bash
#SBATCH --job-name=qc_vcf
#SBATCH --output=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/qc_vcf_%j.out
#SBATCH --error=/home/exacloud/gscratch/CEDAR/lindleyk/WES/logs/qc_vcf_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2
# strict mode (no -u yet)
set -eo pipefail
set +u   # <- critical: disable nounset early

# (Optional but helps on systems where /etc/bashrc checks this)
export BASHRCSOURCED=1

source ~/.bash_profile
source "$HOME/.conda/etc/profile.d/conda.sh" 2>/dev/null || true
conda activate bioinfo_tools

set -u   # <- ONLY re-enable nounset after conda is fully activated

which gatk
gatk --version

VCF=/home/exacloud/gscratch/CEDAR/lindleyk/WES/filtered/joint.PASS.all.vcf.gz
QC=/home/exacloud/gscratch/CEDAR/lindleyk/WES/qc
REF=/home/groups/CEDAR/lindley/genome/GRCh38/no_chr/Homo_sapiens.GRCh38.dna.primary_assembly.fa

mkdir -p "$QC"
echo "[$(date)] Input VCF: $VCF"
ls -lh "$VCF" "${VCF}.tbi"

# -------------------------
# 1) Total variants
# -------------------------
echo "[$(date)] STEP 1: CountVariants (ALL)"
gatk CountVariants -V "$VCF" > "$QC/count_all.txt"
echo "[$(date)] STEP 1 done ✅  ALL=$(tail -n 1 $QC/count_all.txt)"

# -------------------------
# 2) SNP + INDEL counts
# -------------------------
echo "[$(date)] STEP 2A: SelectVariants SNPs"
gatk SelectVariants -V "$VCF" --select-type-to-include SNP -O "$QC/tmp.snps.vcf.gz"
echo "[$(date)] STEP 2A done ✅"

echo "[$(date)] STEP 2B: CountVariants SNPs"
gatk CountVariants -V "$QC/tmp.snps.vcf.gz" > "$QC/count_snps.txt"
echo "[$(date)] STEP 2B done ✅  SNPs=$(tail -n 1 $QC/count_snps.txt)"

echo "[$(date)] STEP 2C: SelectVariants INDELs"
gatk SelectVariants -V "$VCF" --select-type-to-include INDEL -O "$QC/tmp.indels.vcf.gz"
echo "[$(date)] STEP 2C done ✅"

echo "[$(date)] STEP 2D: CountVariants INDELs"
gatk CountVariants -V "$QC/tmp.indels.vcf.gz" > "$QC/count_indels.txt"
echo "[$(date)] STEP 2D done ✅  INDELs=$(tail -n 1 $QC/count_indels.txt)"

# -------------------------
# 3) VariantEval summary (GATK3-style tool but still present in many installs)
# If this fails (tool not found), we’ll skip it.
# -------------------------
echo "[$(date)] STEP 3: VariantEval (summary stats: Ti/Tv, counts by class, etc.)"
if gatk --list | grep -q "^VariantEval$"; then
  gatk VariantEval \
    -R "$REF" \
    -eval "$VCF" \
    -O "$QC/variant_eval.txt"
  echo "[$(date)] STEP 3 done ✅  Output: $QC/variant_eval.txt"
else
  echo "[$(date)] STEP 3 skipped ⚠️  VariantEval not available in this GATK build."
fi

# -------------------------
# 4) VariantsToTable (site-level QC table)
# -------------------------
echo "[$(date)] STEP 4: VariantsToTable (site-level fields)"
gatk VariantsToTable \
  -V "$VCF" \
  -F CHROM -F POS -F REF -F ALT -F QUAL -F FILTER \
  -F AC -F AF -F AN -F DP \
  -F QD -F FS -F SOR -F MQ -F MQRankSum -F ReadPosRankSum \
  -O "$QC/sites.table.tsv"
echo "[$(date)] STEP 4 done ✅  Output: $QC/sites.table.tsv"

# -------------------------
# 5) Genotype-level table (per-sample missingness, GT distribution)
# This produces a big table: site rows x samples (GT field only).
# For 2.3M sites x 10 samples it’s big but manageable; can gzip it.
# -------------------------
echo "[$(date)] STEP 5: VariantsToTable (genotypes: GT only; gzipped)"
gatk VariantsToTable \
  -V "$VCF" \
  -F CHROM -F POS -F REF -F ALT \
  -GF GT \
  -O "$QC/genotypes.GT.tsv"
gzip -f "$QC/genotypes.GT.tsv"
echo "[$(date)] STEP 5 done ✅  Output: $QC/genotypes.GT.tsv.gz"

# -------------------------
# 6) Quick per-sample summary from GT table (missing rate, called rate)
# Missing genotypes appear as "./." in GT.
# -------------------------
echo "[$(date)] STEP 6: Summarize missingness per sample from GT table"
zcat "$QC/genotypes.GT.tsv.gz" \
| awk 'BEGIN{FS=OFS="\t"}
NR==1{
  for(i=5;i<=NF;i++){sample[i]=$i; miss[i]=0; called[i]=0; total[i]=0}
  next
}
{
  for(i=5;i<=NF;i++){
    total[i]++
    if($i=="./." || $i=="."){miss[i]++} else {called[i]++}
  }
}
END{
  print "sample","total_sites","called_sites","missing_sites","missing_frac"
  for(i in sample){
    mf = (total[i]>0)? miss[i]/total[i] : 0
    print sample[i], total[i], called[i], miss[i], mf
  }
}' > "$QC/per_sample_missingness.tsv"
echo "[$(date)] STEP 6 done ✅  Output: $QC/per_sample_missingness.tsv"

# -------------------------
# 7) Cleanup tmp files
# -------------------------
rm -f "$QC/tmp.snps.vcf.gz" "$QC/tmp.snps.vcf.gz.tbi" \
      "$QC/tmp.indels.vcf.gz" "$QC/tmp.indels.vcf.gz.tbi"

echo "[$(date)] ALL QC STEPS COMPLETE ✅"
ls -lh "$QC"
