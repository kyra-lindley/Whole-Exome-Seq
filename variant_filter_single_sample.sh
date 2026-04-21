#!/bin/bash

# OP003 Variant-Level Filtering Script
# Outputs results to: OP003_variant_filter_results.txt

SAMPLE="OP010_CKDN250018138-1A_2323J5LT4_L2"

GENES=(
TP53
KRAS
SMAD4
BRCA1
BRCA2
PIK3CA
PTEN
EGFR
ERBB2
ALK
BRAF
NRAS
MET
RET
ROS1
NTRK1
NTRK2
NTRK3
FGFR1
FGFR2
FGFR3
IDH1
IDH2
APC
ATM
CHEK2
PALB2
RAD51C
NOTCH1
MLH1
ARID1A
RB1
TERT
CCND1
)



OUTFILE="OP010_variant_filter_results.txt"

echo "OP010 Variant-Level Filtering Results" > "$OUTFILE"
echo "Sample: $SAMPLE" >> "$OUTFILE"
echo "Generated on: $(date)" >> "$OUTFILE"
echo "====================================" >> "$OUTFILE"

for GENE in "${GENES[@]}"; do
  echo -e "\n========== $GENE ==========" >> "$OUTFILE"

  awk -F'\t' 'NR==1 || $9=="nonsynonymous SNV" || $9 ~ /(frameshift|stopgain|splicing)/' \
  oncogene_panel/${SAMPLE}/per_gene/${SAMPLE}.${GENE}.ALL.tsv \
  | column -ts $'\t' >> "$OUTFILE"

done

echo -e "\nDone." >> "$OUTFILE"

