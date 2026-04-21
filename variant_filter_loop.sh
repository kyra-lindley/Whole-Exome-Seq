#!/usr/bin/env bash
#SBATCH --job-name=variant_filter
#SBATCH --partition=cedar
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=home/exacloud/gscratch/CEDAR/lindleyk/WES/reports/err/variant_filter_%j.out
#SBATCH --error=home/exacloud/gscratch/CEDAR/lindleyk/WES/reports/err/variant_filter_%j.err

set -euo pipefail

GENES=(
TP53 KRAS SMAD4 BRCA1 BRCA2 PIK3CA PTEN EGFR ERBB2 ALK BRAF NRAS MET RET ROS1
NTRK1 NTRK2 NTRK3 FGFR1 FGFR2 FGFR3 IDH1 IDH2 APC ATM CHEK2 PALB2 RAD51C
NOTCH1 MLH1 ARID1A RB1 TERT CCND1
)

cd /home/exacloud/gscratch/CEDAR/lindleyk/WES/reports


for d in oncogene_panel/*; do
  [[ -d "$d" ]] || continue
  SAMPLE="$(basename "$d")"

  [[ -d "oncogene_panel/$SAMPLE/per_gene" ]] || continue

  OUTFILE="${SAMPLE}_variant_filter_results.txt"

  echo "${SAMPLE} Variant-Level Filtering Results" > "$OUTFILE"
  echo "Sample: $SAMPLE" >> "$OUTFILE"
  echo "Generated on: $(date)" >> "$OUTFILE"
  echo "====================================" >> "$OUTFILE"

  for GENE in "${GENES[@]}"; do
    echo -e "\n========== $GENE ==========" >> "$OUTFILE"

    FILE="oncogene_panel/${SAMPLE}/per_gene/${SAMPLE}.${GENE}.ALL.tsv"
    if [[ -f "$FILE" ]]; then
      awk -F'\t' 'NR==1 || $9=="nonsynonymous SNV" || $9 ~ /(frameshift|stopgain|splicing)/' \
        "$FILE" | column -ts $'\t' >> "$OUTFILE"
    else
      echo "[missing] $FILE" >> "$OUTFILE"
    fi
  done

  echo -e "\nDone." >> "$OUTFILE"
  echo "Wrote $OUTFILE"
done
