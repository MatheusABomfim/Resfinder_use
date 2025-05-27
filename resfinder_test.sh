#!/bin/bash

# Configuration section
PDM_PROJECT_DIR="/home/linux/kleb_polpath/script/resfinder/src"
RESFINDER_DB_PATH="/home/linux/kleb_polpath/script/resfinder/resfinder_db"
POINTFINDER_DB_PATH="/home/linux/kleb_polpath/script/resfinder/pointfinder_db"
AMOSTRAS_DIR="/home/linux/kleb_polpath/script/resfinder/tests/data"
OUTDIR_BASE="/home/linux/kleb_polpath/resultados_resfinder"

# Parameters for ResFinder
MIN_COV="0.8"          # Minimum coverage for ResFinder
THRESHOLD="0.8"        # Threshold for ResFinder
MIN_COV_POINT="0.7"    # --min_cov_point (PointFinder)
THRESHOLD_POINT="0.7"  # --threshold_point (PointFinder)
ORGANISM="klebsiella"

# Tools - verify they exist
BLAST_PATH=$(which blastn) || { echo "Error: blastn not found in PATH"; exit 1; }
KMA_PATH=$(which kma) || { echo "Error: kma not found in PATH"; exit 1; }

# Set environment variables
export RESFINDER_DB_PATH POINTFINDER_DB_PATH

# Create output directory with parameters in name
RUN_DIR="${OUTDIR_BASE}/cov${MIN_COV}_thresh${THRESHOLD}"
SUMMARY_FILE="${RUN_DIR}/summary_results.csv"
LOG_FILE="${RUN_DIR}/processing_log.txt"

# Create directories
mkdir -p "$RUN_DIR" || { echo "Error: Could not create output directory"; exit 1; }

# Initialize files with ENGLISH headers
echo "Sample,Gene,Resistance,Coverage,Identity,Covered_positions,Total_length,Notes" > "$SUMMARY_FILE"
echo "ResFinder processing log - $(date)" > "$LOG_FILE"

# Function to process results files
process_results() {
    local file="$1"
    local sample="$2"
    local is_pointfinder="${3:-false}"
    
    if [ -f "$file" ]; then
        if [ "$is_pointfinder" = true ]; then
            # PointFinder format
            tail -n +2 "$file" | while IFS=$'\t' read -r gene mutation resistance coverage identity covered_positions total_length; do
                echo "${sample},${gene} (${mutation}),${resistance},${coverage},${identity},${covered_positions},${total_length},PointFinder" >> "$SUMMARY_FILE"
            done
        else
            # ResFinder format
            tail -n +2 "$file" | while IFS=$'\t' read -r gene resistance coverage identity covered_positions total_length; do
                echo "${sample},${gene},${resistance},${coverage},${identity},${covered_positions},${total_length},ResFinder" >> "$SUMMARY_FILE"
            done
        fi
    fi
}

# Main processing loop
processed_samples=0
errors=0

for sample_file in "$AMOSTRAS_DIR"/*.fa "$AMOSTRAS_DIR"/*.fq; do
    [ -e "$sample_file" ] || continue  # skip if no matching file
    
    sample=$(basename "$sample_file" | sed -E 's/\.(fa|fq)$//')
    sample_outdir="${RUN_DIR}/${sample}"
    
    echo "[$(date)] Processing sample: $sample" | tee -a "$LOG_FILE"
    mkdir -p "$sample_outdir" || { echo "Error: Could not create sample directory"; ((errors++)); continue; }
    
    cd "$PDM_PROJECT_DIR" || { echo "Error: Could not change to project directory"; ((errors++)); continue; }

    # Run ResFinder with correct input file
    if python3 -m resfinder \
        -ifa "$sample_file" \
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
        # Process ResFinder and PointFinder results
        process_results "${sample_outdir}/ResFinder_results_tab.txt" "$sample"
        process_results "${sample_outdir}/PointFinder_results.txt" "$sample" true
        
        # If no resistance genes found
        if [ ! -f "${sample_outdir}/ResFinder_results_tab.txt" ] && [ ! -f "${sample_outdir}/PointFinder_results.txt" ]; then
            echo "${sample},No resistance genes found,,,,,," >> "$SUMMARY_FILE"
        fi
        
        ((processed_samples++))
        echo "[$(date)] Successfully processed sample: $sample" | tee -a "$LOG_FILE"
    else
        echo "${sample},ERROR,,,,,Processing failed" >> "$SUMMARY_FILE"
        ((errors++))
        echo "[$(date)] Error processing sample: $sample" | tee -a "$LOG_FILE"
    fi
done

# Summary report
echo "Processing complete at $(date)" | tee -a "$LOG_FILE"
echo "---------------------------------" | tee -a "$LOG_FILE"
echo "Total samples processed: $processed_samples" | tee -a "$LOG_FILE"
echo "Total errors encountered: $errors" | tee -a "$LOG_FILE"
echo "Results directory: $RUN_DIR" | tee -a "$LOG_FILE"
echo "Summary file: $SUMMARY_FILE" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"

exit 0
