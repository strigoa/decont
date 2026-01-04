genomefile=$1
outdir=$2

# Generate directory for the index
mkdir -p "$outdir"

# Generate index with STAR
STAR --runThreadN 4 --runMode genomeGenerate --genomeDir "$outdir" \
 --genomeFastaFiles "$genomefile" --genomeSAindexNbases 9
