#!/bin/bash

# Store working directory
WORKINGDIR=$(pwd)

# Create temporary directory
TMPDIR=$(mktemp -d)

if [ ! -e $TMPDIR ]; then
	>&2 echo "Failed to create temp directory"
	exit 1
fi

trap "exit 1" HUP INT PIPE QUIT TERM
trap 'rm -rf "$TMPDIR"' EXIT


# Copy presentation to temporary directory
cp "$1" "$TMPDIR"

# Change directory into the temporary directory
cd "$TMPDIR"

# Extract media files from the presentation
unzip * ppt/media/media*.m4a

# Convert all media files to WAV
find ppt/media/ -name 'media*.m4a' -exec ffmpeg -i "{}" "{}.wav" \;

# Generate beep sound
ffmpeg -f lavfi -i "sine=frequency=500:duration=0.1" beep.wav


# Concatenate all media files and insert beep in between
ffmpeg -f concat -safe 0 -i <(
	find ppt/media/ -name "media*.m4a.wav" -printf "file '$PWD/%p'\n" |
	sort -V |
	awk -v P="$(pwd)" '{printf $0"\nfile \x27%s/beep.wav\x27\n",P}'
) -c copy output.wav

# Change directory back to the working directory
cd "$WORKINGDIR"

# Copy the result from the temporary directory
cp "$TMPDIR"/output.wav "$2"
