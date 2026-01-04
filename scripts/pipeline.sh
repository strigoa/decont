#Download all the files specified in data/filenames
for url in $(cat data/urls)
do
    bash scripts/download.sh $url data
done

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes "small nuclear"

# Index the contaminants file
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx

# Merge the samples into a single file
for sid in $(ls data/*.fastq.gz | xargs -n 1 basename | cut -d'-' -f1 | sort | uniq) 
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

# Run cutadapt for all merged files
mkdir -p out/trimmed
mkdir -p log/cutadapt
for mergedsample in $(ls out/merged/*.fastq.gz | xargs -n 1 basename | cut -d'.' -f1 | sort | uniq) 
do
	echo "Running cutadapt for sample $mergedsample..."
	cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
	-o out/trimmed/${mergedsample}.trimmed.fastq.gz \
	out/merged/${mergedsample}.fastq.gz > log/cutadapt/${mergedsample}.log
done

# Run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
    sid=$(basename "$fname" .trimmed.fastq.gz)
    mkdir -p out/star/$sid
    echo "Running STAR alignement for sample $sid..."
    STAR --runThreadN 4 --genomeDir res/contaminants_idx \
    --outReadsUnmapped Fastx --readFilesIn "$fname" \
    --readFilesCommand gunzip -c --outFileNamePrefix out/star/$sid/
done 

# Create a log file containing information from cutadapt (reads with adapters and total basepairs processed) and STAR (percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci) logs
echo "Creating a summary log file from cutadapt and STAR..."
summarylog="log/pipeline.log"
echo "Date pipeline run: $(date)" >> $summarylog
echo >> $summarylog
for sample in $(ls out/star/)
do
    echo "Summary for sample $sample" >> $summarylog
    echo "Cutadapt information: " >> $summarylog
    grep -E "Reads with adapters|Total basepairs processed"\
    log/cutadapt/${sample}.log >> $summarylog
    echo >> $summarylog
    echo "STAR information: " >> $summarylog
    grep -E "Uniquely mapped reads %|% of reads mapped to multiple loci|\
    % of reads mapped to too many loci" out/star/${sample}/Log.final.out >> $summarylog
    echo >> $summarylog
done
echo "-------------------------------------------------------------" >> $summarylog
echo >> $summarylog

