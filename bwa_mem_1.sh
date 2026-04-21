#!/bin/bash
#SBATCH --job-name=bwa_mem_1
#SBATCH --output=/home/groups/CEDAR/archive/seq/Langer/WES/err/bwa_%A_%a.out
#SBATCH --error=/home/groups/CEDAR/archive/seq/Langer/WES/err/_%A_%a.err
#SBATCH --time=36:00:00
#SBATCH --mem=12G
#SBATCH --cpus-per-task=10
source ~/.bash_profile
conda activate bioinfo_tools
library=$(basename $1 _1_ds.fq ) # I dont want the downsampled ones
echo $library
bwa mem -t 10 \
    /home/groups/CEDAR/lindley/genome/GRCh38/no_chr/Homo_sapiens.GRCh38.dna.primary_assembly.fa \
    $1 $2 > $library.sam

# Want a print statement here to say "done step one "bwa mem" ran"
conda deactivate
source ~/.bash_profile
# remove alt alignmnets, name sort
samtools view -b -F 2048 $library.sam | samtools sort -n -@10 - -o $library.nsorted.bam
# Want a print statment here saying: "done with step two removed alt alignments"
conda activate bioinfo_tools
# ignore for now:potentially add that werid java line at 35 #
# ignore for now: potentially java temp directory in chat with chris* 
picard MarkIlluminaAdapters \
    INPUT=$library.nsorted.bam \
    METRICS=$library.metrics_markadapters
    #OUTPUT=$library.nsorted.markadapters.bam
# want print statemetn: step three done samples marked for duplicates
conda deactivate
source ~/.bash_profile
#position sorting
samtools sort -@10 $library.nsorted.bam -o $library.sorted.bam
# want a print statment" done with step four file position sorted
conda activate bioinfo_tools
# tell java to give me more memory 

java -Xms512m -Xmx12g -jar /home/exacloud/gscratch/CEDAR/lindleyk/miniconda/envs/bioinfo_tools/share/picard-2.18.29-0/picard.jar MarkDuplicates \
    I=$library.sorted.bam \
    O=$library.marked_duplicates.bam \
    M=$library.marked_dup_metrics.txt
# want a print statement: step five done,final BAM made.
#gatk MarkDuplicates \
#    -I=$library.sorted.bam \
#    -O=$library.marked_duplicates.bam \
#    -M=$library.marked_dup_metrics.txt