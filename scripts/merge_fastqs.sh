samplesdir=$1
outdir=$2
sampleid=$3

# Generate directory to store the merged files
mkdir -p "$outdir"

# Merge compressed text files with the same sample ID into a single file with cat
echo "Merging sample: $sampleid"
cat "$samplesdir/$sampleid"* > "$outdir/$sampleid.fastq.gz"
