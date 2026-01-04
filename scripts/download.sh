file=$1
outdir=$2
uncompress=$3
filter=$4

# Generate directory to download the file
mkdir -p "$outdir"

# Download the file from URL and place in the directory
echo "Downloading file from $file..."
wget -N -P "$outdir" "$file"

# Get name and path of the downloaded file
filename=$(basename "$file")
filepath="$outdir/$filename"

# Uncompress downloaded file? If yes, uncompress and keep the compressed
if [ "$uncompress" == "yes" ]; then
	echo "Uncompressing file $filename..."
	gunzip -f -k "$filepath"
	filepath="${filepath%.gz}"
fi

# Filter by word: removing sequences that contain the word in the header
if [ -n "$filter" ]; then
	echo "Filtering sequences that contain $filter in the header..."
	grep -v -i "$filter" "$filepath" > "${filepath}.tmp"
	mv "${filepath}.tmp" "$filepath"
fi

echo "Completed. File downloaded at: $filepath"

