#!/usr/bin/env bash
set -u

# ------------------------------------------------------------
# run_oncogene_panel_one_sample.sh
#
# Run from: WES/reports/
# Example:
#   ./run_oncogene_panel_one_sample.sh ../samples/OP001_CKDN... oncogenes40.txt
#
# Outputs to:
#   WES/reports/oncogene_panel/<SAMPLE>/
# ------------------------------------------------------------

# Anchor outputs to the directory containing THIS script (WES/reports)
REPORTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Usage
if [[ "$#" -ne 2 ]]; then
  echo "Usage: $0 <sample_dir> <gene_list>"
  echo "Example: $0 ../samples/OP001_CKDN... oncogenes40.txt"
  exit 1
fi

SAMPLEDIR="$1"
GENELIST="$2"

# Resolve sample name from folder
SAMPLE="$(basename "$SAMPLEDIR")"

# Sanity checks
if [[ ! -d "$SAMPLEDIR" ]]; then
  echo "ERROR: sample directory not found: $SAMPLEDIR" >&2
  exit 1
fi
if [[ ! -f "$GENELIST" ]]; then
  echo "ERROR: gene list not found: $GENELIST" >&2
  exit 1
fi

# Locate inputs inside the sample dir
MULTIANNO="$(ls -1 "$SAMPLEDIR"/annovar_output_PASSall.*.hg38_multianno.txt 2>/dev/null | head -n 1 || true)"
RARE_TSV="$(ls -1 "$SAMPLEDIR"/*.RARE_EXONIC_SPLICE.tsv 2>/dev/null | head -n 1 || true)"
HIGH_TSV="$(ls -1 "$SAMPLEDIR"/*.HIGHIMPACT.tsv 2>/dev/null | head -n 1 || true)"
KNOWN_TSV="$(ls -1 "$SAMPLEDIR"/*.CLINVAR_or_COSMIC.tsv 2>/dev/null | head -n 1 || true)"

if [[ -z "$MULTIANNO" ]]; then
  echo "ERROR: Could not find multianno in: $SAMPLEDIR" >&2
  echo "Expected: annovar_output_PASSall.*.hg38_multianno.txt" >&2
  exit 1
fi

# Output dirs/files
OUTBASE="${REPORTS_DIR}/oncogene_panel/${SAMPLE}"
PERGENE_DIR="${OUTBASE}/per_gene"
mkdir -p "$PERGENE_DIR"

LOG="${OUTBASE}/${SAMPLE}.oncogene_panel.log"
SUMMARY="${OUTBASE}/${SAMPLE}.oncogene_panel.summary.tsv"

echo "Writing outputs to:"
echo "  $SUMMARY"
echo "  $LOG"
echo "  $PERGENE_DIR"
echo

# ---------------- helpers ----------------
extract_gene_exact_col7 () {
  local infile="$1" gene="$2" outfile="$3"
  awk -F'\t' -v g="$gene" 'NR==1 || $7==g' "$infile" > "$outfile"
}

count_hits_no_header () {
  local file="$1"
  [[ ! -f "$file" ]] && { echo 0; return; }
  local n
  n=$(wc -l < "$file" | tr -d ' ')
  (( n <= 1 )) && echo 0 || echo $((n-1))
}

# Column indices (based on your header):
# 11 = gnomAD_exome_ALL
# 21 = cosmic70
# 26 = CLNSIG

# gnomAD completely missing
count_gnomad_missing () {
  local file="$1"
  awk -F'\t' 'NR>1 && ($11=="." || $11=="") {c++} END{print c+0}' "$file"
}

# gnomAD present but rare (<0.01)
count_gnomad_rare_present () {
  local file="$1"
  awk -F'\t' 'NR>1 && ($11!="." && $11!="" && ($11+0 < 0.01)) {c++} END{print c+0}' "$file"
}

count_cosmic_present () {
  local file="$1"
  awk -F'\t' 'NR>1 && $21 != "." && $21 != "" {c++} END{print c+0}' "$file"
}

count_clnsig_matches () {
  local file="$1" re="$2"
  awk -F'\t' -v re="$re" 'NR>1 && $26 ~ re {c++} END{print c+0}' "$file"
}

top_examples () {
  local file="$1" max="${2:-5}"
  awk -F'\t' 'NR>1{
    printf("%s:%s %s>%s | %s/%s | gnomAD=%s | COSMIC=%s | CLNSIG=%s\n",
      $1,$2,$4,$5,$6,$9,$11,($21==""?".":$21),($26==""?".":$26));
  }' "$file" | head -n "$max"
}

# ---------------- write headers ----------------
echo -e "sample\tgene\tall_hits\tQ1_gnomad_missing\tQ1_gnomad_present_rare(<0.01)\tQ2_cosmic_present\tQ3_CLNSIG_path_or_lpath\tQ3_CLNSIG_vus_or_conflicting\tQ3_CLNSIG_benign_or_lbenign\thits_in_RARE_EXONIC_SPLICE\thits_in_HIGHIMPACT\thits_in_CLINVAR_or_COSMIC" > "$SUMMARY"

{
  echo "Sample: $SAMPLE"
  echo "Sample dir: $SAMPLEDIR"
  echo "Multianno: $MULTIANNO"
  [[ -n "$RARE_TSV"  ]] && echo "RARE:  $RARE_TSV"
  [[ -n "$HIGH_TSV"  ]] && echo "HIGH:  $HIGH_TSV"
  [[ -n "$KNOWN_TSV" ]] && echo "KNOWN: $KNOWN_TSV"
  echo "Gene list: $GENELIST"
  echo "Output base: $OUTBASE"
  echo
} > "$LOG"

# ---------------- main loop ----------------
while IFS= read -r GENE; do
  [[ -z "$GENE" ]] && continue
  GENE="${GENE//$'\r'/}"   # strip Windows CR if present

  PREFIX="${PERGENE_DIR}/${SAMPLE}.${GENE}"

  # ALL hits from multianno (baseline for Q1/Q2/Q3)
  ALL="${PREFIX}.ALL.tsv"
  extract_gene_exact_col7 "$MULTIANNO" "$GENE" "$ALL"

  N_ALL="$(count_hits_no_header "$ALL")"
  N_GNOMAD_MISSING="$(count_gnomad_missing "$ALL")"
  N_GNOMAD_RARE="$(count_gnomad_rare_present "$ALL")"
  N_COSMIC="$(count_cosmic_present "$ALL")"
  N_PL="$(count_clnsig_matches "$ALL" "(Pathogenic|Likely_pathogenic)")"
  N_VUS="$(count_clnsig_matches "$ALL" "(Uncertain_significance|Conflicting)")"
  N_BEN="$(count_clnsig_matches "$ALL" "(Benign|Likely_benign)")"

  # Optional counts in your prefiltered files
  N_RARE="NA"; N_HIGH="NA"; N_KNOWN="NA"

  if [[ -n "$RARE_TSV" ]]; then
    R="${PREFIX}.RARE_EXONIC_SPLICE.tsv"
    extract_gene_exact_col7 "$RARE_TSV" "$GENE" "$R"
    N_RARE="$(count_hits_no_header "$R")"
  fi
  if [[ -n "$HIGH_TSV" ]]; then
    H="${PREFIX}.HIGHIMPACT.tsv"
    extract_gene_exact_col7 "$HIGH_TSV" "$GENE" "$H"
    N_HIGH="$(count_hits_no_header "$H")"
  fi
  if [[ -n "$KNOWN_TSV" ]]; then
    K="${PREFIX}.CLINVAR_or_COSMIC.tsv"
    extract_gene_exact_col7 "$KNOWN_TSV" "$GENE" "$K"
    N_KNOWN="$(count_hits_no_header "$K")"
  fi

  # Summary row
  echo -e "${SAMPLE}\t${GENE}\t${N_ALL}\t${N_GNOMAD_MISSING}\t${N_GNOMAD_RARE}\t${N_COSMIC}\t${N_PL}\t${N_VUS}\t${N_BEN}\t${N_RARE}\t${N_HIGH}\t${N_KNOWN}" >> "$SUMMARY"

  # Human-readable log section
  {
    echo "----- GENE: $GENE -----"
    echo "All hits: $N_ALL"
    echo "Q1 gnomAD missing:         $N_GNOMAD_MISSING"
    echo "Q1 gnomAD present <0.01:   $N_GNOMAD_RARE"
    echo "Q2 COSMIC present:         $N_COSMIC"
    echo "Q3 CLNSIG Path/LPath:      $N_PL | VUS/Conf: $N_VUS | Ben/LBen: $N_BEN"
    echo "Prefilter counts:          RARE=$N_RARE HIGH=$N_HIGH KNOWN=$N_KNOWN"
    if [[ "$N_ALL" -gt 0 ]]; then
      echo "Examples:"
      top_examples "$ALL" 5
    fi
    echo
  } >> "$LOG"

done < "$GENELIST"

echo "DONE"
echo "Summary: $SUMMARY"
echo "Log:     $LOG"
