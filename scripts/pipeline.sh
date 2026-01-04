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

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in



