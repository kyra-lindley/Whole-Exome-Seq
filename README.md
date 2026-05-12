# Whole-Exome-Seq

A GATK best-practices pipeline for whole exome sequencing (WES) variant calling, developed at the Langer Lab, CEDAR, Oregon Health and Science University (OHSU). Applied to human autopsy pancreas samples as part of a multi-institutional pancreas database project with emphasis on BRCA2-associated disease.

Scripts are designed to run on an HPC cluster via SLURM and follow the standard BWA-MEM → GATK HaplotypeCaller → joint genotyping → variant filtering workflow.

---

## Workflow Overview

```
Raw FASTQ
    │
    ▼
aligment_wes.sh / bwa_mem_1.sh   # BWA-MEM alignment to GRCh38
    │
    ▼
readgroups.sh                     # Picard AddOrReplaceReadGroups
    │
    ▼
bqsr.sh                           # GATK BaseRecalibrator + ApplyBQSR
    │
    ▼
htc.sh                            # GATK HaplotypeCaller → per-sample GVCF
    │
    ▼
joint_genotyping.sh / jg.sh / jg_pt2.sh         # GATK GenomicsDBImport
    │
    ▼
genotypeGVCFs_chunks.sh           # GATK GenotypeGVCFs (chunked by interval)
    │
    ▼
gather_vcfs.sh                    # Picard GatherVcfs → merged VCF
    │
    ▼
hard_filter_joint.sh              # GATK VariantFiltration (joint cohort)
variant_filter_loop.sh            # Variant filtering (loop over samples)
variant_filter_single_sample.sh   # Variant filtering (single sample)
    │
    ▼
run_oncogene_panel_one_sample.sh  # Targeted oncogene panel extraction
    │
    ▼
qc_vcf_gatk.sh / qc_table_sites.sh  # QC and site-level summary tables
```

---

## File Descriptions

| File | Description |
|------|-------------|
| `aligment_wes.sh` | BWA-MEM alignment of paired-end reads to GRCh38; includes alt-alignment removal, name sorting, adapter marking (Picard), and duplicate marking |
| `bwa_mem_1.sh` | Earlier/alternate version of BWA-MEM alignment with additional Picard MarkDuplicates step |
| `readgroups.sh` | Assigns read groups to BAM files using Picard AddOrReplaceReadGroups |
| `bqsr.sh` | Base Quality Score Recalibration (BQSR) using GATK BaseRecalibrator and ApplyBQSR against dbSNP138, Mills, and known indels; produces `.recal.bam` |
| `htc.sh` | GATK HaplotypeCaller in GVCF mode; input is `.recal.bam`, output is per-sample `.g.vcf.gz` |
| `joint_genotyping.sh` | GATK GenomicsDBImport for combining per-sample GVCFs into a genomics database |
| `jg.sh` / `jg_pt2.sh` | Alternate/split versions of the joint genotyping step |
| `genotypeGVCFs_chunks.sh` | GATK GenotypeGVCFs run in genomic chunks/intervals for parallelization |
| `gather_vcfs.sh` | Picard GatherVcfs to merge chunked VCFs into a single cohort VCF |
| `hard_filter_joint.sh` | Hard-filters joint cohort VCF using GATK VariantFiltration |
| `variant_filter_loop.sh` | Loops variant filtering across multiple samples |
| `variant_filter_single_sample.sh` | Variant filtering for a single sample |
| `run_oncogene_panel_one_sample.sh` | Extracts variants overlapping a targeted oncogene panel for a single sample |
| `qc_vcf_gatk.sh` | QC metrics for the filtered VCF |
| `qc_table_sites.sh` | Generates site-level summary tables for QC review |

---

## Dependencies

All scripts run on OHSU ARC/Exacloud HPC via SLURM. Tools are managed via conda (`bioinfo_tools` environment).

- [BWA-MEM](https://github.com/lh3/bwa)
- [SAMtools](http://www.htslib.org/)
- [Picard](https://broadinstitute.github.io/picard/)
- [GATK4](https://gatk.broadinstitute.org/)

**Reference files (GRCh38, no `chr` prefix):**
- `Homo_sapiens.GRCh38.dna.primary_assembly.fa`
- `Homo_sapiens_assembly38.dbsnp138.nochr.vcf.gz`
- `Mills_and_1000G_gold_standard.indels.hg38.nochr.vcf.gz`
- `Homo_sapiens_assembly38.known_indels.nochr.vcf.gz`

---

## Usage Notes

- Most scripts accept a BAM or FASTQ file as a positional argument (`$1`, `$2`) and derive the sample name from the filename.
- BQSR (`bqsr.sh`) expects input BAMs with read groups already assigned (`.rg.bam`) and outputs `.recal.bam`.
- HaplotypeCaller (`htc.sh`) expects `.recal.bam` as input and runs in `-ERC GVCF` mode for joint genotyping compatibility.
- Genotyping is parallelized by genomic interval chunks (`genotypeGVCFs_chunks.sh`) and merged with `gather_vcfs.sh`.
- Reference genome uses no `chr` prefix in contig names — ensure your reference and VCFs are consistent.
- Update all hardcoded paths (`REF`, `BASEOUT`, `DBSNP`, etc.) before running on a new system.

---

## Contact

Kyra Lindley — kyra.a.lindley@gmail.com  
Langer Lab, CEDAR, Oregon Health and Science University
