#!/bin/bash

# Caminho do resfinder
PDM_PROJECT_DIR="/home/linux/kleb_polpath/script/resfinder/src"

# Caminho para os bancos de dados
export RESFINDER_DB_PATH="/home/linux/kleb_polpath/script/resfinder/resfinder_db"
export POINTFINDER_DB_PATH="/home/linux/kleb_polpath/script/resfinder/pointfinder_db"

# Ferramentas necessárias
BLAST_PATH=$(which blastn)
KMA_PATH=$(which kma)

# Pastas de entrada e saída
AMOSTRAS_DIR="/home/linux/kleb_polpath/amostras_resfinder"
OUTDIR_BASE="/home/linux/kleb_polpath/resultados_resfinder"

mkdir -p "$OUTDIR_BASE"

for fasta in "$AMOSTRAS_DIR"/*.fasta; do
    sample=$(basename "$fasta" .fasta)
    sample_outdir="$OUTDIR_BASE/$sample"

    echo "Processando amostra: $sample"
    mkdir -p "$sample_outdir"
    cd "$PDM_PROJECT_DIR" || exit 1

    python3 -m resfinder \
        -ifa "$fasta" \
        -o "$sample_outdir" \
        -s klebsiella \
        --point \
        -b "$BLAST_PATH" \
        -k "$KMA_PATH"

    echo "Finalizado o processamento de: $sample"
done
