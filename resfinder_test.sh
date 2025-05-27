#!/bin/bash

# Configuration section
PDM_PROJECT_DIR="/resfinder/src"
RESFINDER_DB_PATH="/resfinder/resfinder_db"
POINTFINDER_DB_PATH="/pointfinder_db"
AMOSTRAS_DIR="resfinder/tests/data/"
OUTDIR_BASE=""

# File extensions to process
EXTENSIONS=("fasta" "fa" "fastq" "fq")

# Parameters
MIN_COV="0.6"
THRESHOLD="0.6"
MIN_COV_POINT="0.6"
THRESHOLD_POINT="0.6"
ORGANISM="klebsiella"

# Tools
BLAST_PATH=$(which blastn) || { echo "Error: blastn not found in PATH"; exit 1; }
KMA_PATH=$(which kma) || { echo "Error: kma not found in PATH"; exit 1; }

export RESFINDER_DB_PATH POINTFINDER_DB_PATH

# Create output directory
RUN_DIR="${OUTDIR_BASE}/cov${MIN_COV}_thresh${THRESHOLD}"
SUMMARY_FILE="${RUN_DIR}/summary_results.csv"
LOG_FILE="${RUN_DIR}/processing_log.txt"

mkdir -p "$RUN_DIR" || { echo "Error: Could not create output directory"; exit 1; }

# Initialize CSV with proper headers
echo "Sample,Gene,Mutation,Resistance,Coverage,Identity,Covered_positions,Total_length,Database,Accession,Antibiotics" > "$SUMMARY_FILE"
echo "ResFinder processing log - $(date)" > "$LOG_FILE"

# Function to clean and format resistance field
clean_resistance() {
    echo "$1" | tr '\t' ' ' | sed 's/  */ /g' | tr ',' ';'
}

# Function to process ResFinder results
process_resfinder() {
    local file="$1"
    local sample="$2"
    
    if [ -f "$file" ]; then
        tail -n +2 "$file" | while IFS=$'\t' read -r gene _ _ coverage identity covered_positions total_length accession _ resistance; do
            cleaned_resistance=$(clean_resistance "$resistance")
            echo "${sample},${gene},,${cleaned_resistance},${coverage},${identity},${covered_positions},${total_length},ResFinder,${accession},${cleaned_resistance}" >> "$SUMMARY_FILE"
        done
    fi
}

# Function to process PointFinder results
process_pointfinder() {
    local file="$1"
    local sample="$2"
    
    if [ -f "$file" ]; then
        tail -n +2 "$file" | while IFS=$'\t' read -r gene mutation _ resistance coverage identity covered_positions total_length; do
            cleaned_resistance=$(clean_resistance "$resistance")
            echo "${sample},${gene},${mutation},${cleaned_resistance},${coverage},${identity},${covered_positions},${total_length},PointFinder,," >> "$SUMMARY_FILE"
        done
    fi
}

# Main processing
processed_samples=0
errors=0

for ext in "${EXTENSIONS[@]}"; do
    for input_file in "$AMOSTRAS_DIR"/*."$ext"; do
        [ -e "$input_file" ] || continue

        sample=$(basename "$input_file")
        sample="${sample%.*}"
        sample_outdir="${RUN_DIR}/${sample}"

        echo "[$(date)] Processing sample: $sample" | tee -a "$LOG_FILE"
        mkdir -p "$sample_outdir" || { echo "Error: Could not create sample directory"; ((errors++)); continue; }

        cd "$PDM_PROJECT_DIR" || { echo "Error: Could not change to project directory"; ((errors++)); continue; }

        if python3 -m resfinder \
            -ifa "$input_file" \
            -o "$sample_outdir" \
            -s "$ORGANISM" \
            -b "$BLAST_PATH" \
            -k "$KMA_PATH" \
            -acq \
            --point \
            -u \
            --min_cov "$MIN_COV" \
            --threshold "$THRESHOLD" \
            --min_cov_point "$MIN_COV_POINT" \
            --threshold_point "$THRESHOLD_POINT" \
            2>> "$LOG_FILE"
        then
            process_resfinder "${sample_outdir}/ResFinder_results_tab.txt" "$sample"
            process_pointfinder "${sample_outdir}/PointFinder_results.txt" "$sample"

            if [ ! -f "${sample_outdir}/ResFinder_results_tab.txt" ] && [ ! -f "${sample_outdir}/PointFinder_results.txt" ]; then
                echo "${sample},,,,,,,,No resistance found,," >> "$SUMMARY_FILE"
            fi

            ((processed_samples++))
            echo "[$(date)] Successfully processed sample: $sample" | tee -a "$LOG_FILE"
        else
            echo "${sample},ERROR,,,,,,,Processing failed,," >> "$SUMMARY_FILE"
            ((errors++))
            echo "[$(date)] Error processing sample: $sample" | tee -a "$LOG_FILE"
        fi
    done
done

# Final report
echo "Processing complete at $(date)" | tee -a "$LOG_FILE"
echo "---------------------------------" | tee -a "$LOG_FILE"
echo "Total samples processed: $processed_samples" | tee -a "$LOG_FILE"
echo "Total errors encountered: $errors" | tee -a "$LOG_FILE"
echo "Results directory: $RUN_DIR" | tee -a "$LOG_FILE"
echo "Summary file: $SUMMARY_FILE" | tee -a "$LOG_FILE"

exit 0
