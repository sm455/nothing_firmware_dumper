#!/usr/bin/env bash

[[ $# -eq 0 ]] && { echo "Usage: extract.sh <rom_name>"; exit 1; }

ROM_NAME=$1
WORK_DIR="./working/${ROM_NAME}"
TEMP_FOLDER="./temp_${ROM_NAME}"
mkdir -p "$WORK_DIR"
mkdir -p "$TEMP_FOLDER"

log_msg() {
    echo "[$(date '+%H:%M:%S')] $1"
}

log_msg "Starting ROM extraction: $ROM_NAME"

# Download tools
log_msg "Downloading tools..."
if [[ -f "fsck.erofs" ]]; then
    log_msg "✓ fsck.erofs already exists, skipping download"
else
    if wget -q -O "fsck.erofs" "https://github.com/sm455/nothing_firmware_extractor/raw/refs/heads/main/fsck.erofs" && chmod +x fsck.erofs; then
        log_msg "✓ Downloaded: fsck.erofs"
    else
        log_msg "✗ Failed: fsck.erofs"
    fi
fi

# Download archives
log_msg "Downloading archives..."
for ext in image-logical.7z.{001,002,003} image-firmware.7z; do
    if wget -q -O "${ROM_NAME}-${ext}" "https://github.com/spike0en/nothing_archive/releases/download/${ROM_NAME}/${ROM_NAME}-${ext}"; then
        log_msg "✓ Downloaded: ${ext}"
    else
        log_msg "✗ Failed: ${ext}"
    fi
done

# Extract archives
log_msg "Extracting archives..."
# Extract image-logical to temp folder
if 7z x "${ROM_NAME}-image-logical.7z.001" -o"$TEMP_FOLDER" > /dev/null 2>&1; then
    log_msg "✓ Extracted: image-logical.7z"
else
    log_msg "✗ Failed: image-logical.7z"
fi

# Extract firmware to working directory
if 7z x "${ROM_NAME}-image-firmware.7z" -o"$WORK_DIR" > /dev/null 2>&1; then
    log_msg "✓ Extracted: image-firmware.7z"
else
    log_msg "✗ Failed: image-firmware.7z"
fi

# Extract partitions
log_msg "Processing partitions..."
PARTITIONS=(system product system_ext vendor)

for partition in "${PARTITIONS[@]}"; do
    partition_file="$TEMP_FOLDER/${partition}.img"
    [[ -f "$partition_file" ]] || continue
    if ./fsck.erofs --extract="$WORK_DIR/${partition}" "$partition_file" > /dev/null 2>&1; then
        rm -f "$partition_file"
        log_msg "✓ Extracted: ${partition}"
    else
        log_msg "✗ Failed: ${partition}"
    fi
done

# Cleanup temp folder
log_msg "Cleaning up temporary files..."
rm -rf "$TEMP_FOLDER"

log_msg "Complete!"
