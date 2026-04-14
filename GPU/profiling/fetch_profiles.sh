#!/usr/bin/env bash
# fetch_profiles.sh — copy profiling report files from Euler to local machine
#
# Run this script on your LOCAL machine (not on Euler).
#
# Usage:
#   bash fetch_profiles.sh <euler_job_dir>
#
# Example:
#   bash fetch_profiles.sh ~/scratch/profiling/run1
#
# This copies all .ncu-rep and .nsys-rep files from the given Euler directory
# to a local subdirectory named after the last path component.

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <euler_path>"
    echo "  euler_path: directory on Euler containing .ncu-rep/.nsys-rep files"
    echo "  Example: $0 ~/scratch/profiling/run1"
    exit 1
fi

EULER_PATH="$1"
LOCAL_DIR="$(basename "$EULER_PATH")"

mkdir -p "$LOCAL_DIR"

echo "Fetching profiles from euler:$EULER_PATH ..."
scp "euler:${EULER_PATH}/*.ncu-rep" "$LOCAL_DIR/" 2>/dev/null && echo "  .ncu-rep files copied" || echo "  (no .ncu-rep files found)"
scp "euler:${EULER_PATH}/*.nsys-rep" "$LOCAL_DIR/" 2>/dev/null && echo "  .nsys-rep files copied" || echo "  (no .nsys-rep files found)"

echo ""
echo "Done. Files in ./$LOCAL_DIR/"
echo ""
echo "Open with:"
echo "  ncu-ui $LOCAL_DIR/*.ncu-rep"
echo "  nsys-ui $LOCAL_DIR/*.nsys-rep"
