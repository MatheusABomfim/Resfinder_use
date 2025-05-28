# Pipeline for annotation of Antimicrobial Resistance Genes in multiple isolates

## Introduction
This pipeline evaluates isolates for antimicrobial resistance genes using ResFinder and PointFinder.

📌 Full script available on GitHub: [https://bitbucket.org/genomicepidemiology/resfinder/src/master/]

## 🔧 Installation:
Follow the instructions from the ResFinder Bitbucket repository.

## Usage Guide
1. Script Overview
The resfinder_test.sh script processes multiple files in a single run.
(Including fasta, fa, fastq and fq)

2. Directory Configuration
Before execution, set the following variables in the script:

Variable	Description
PDM_PROJECT_DIR	Path to ResFinder (include /resfinder/src)
RESFINDER_DB_PATH	Path to ResFinder database (include /resfinder/resfinder_db)
POINTFINDER_DB_PATH	Path to PointFinder database (include /resfinder/pointfinder_db)
AMOSTRAS_DIR	Directory containing input files
OUTDIR_BASE	Directory where results will be saved

3. Parameter Settings
Adjust the following parameters as needed:

Parameter	Description	Default Value
MIN_COV	- Minimum coverage threshold for ResFinder (0–1)	
THRESHOLD	- Identity threshold for ResFinder (0–1)	0.8
MIN_COV_POINT	Minimum - coverage threshold for PointFinder (0–1)	0.7
THRESHOLD_POINT	Identity - threshold for PointFinder (0–1)	0.7
ORGANISM	- Target species (must match ResFinder nomenclature, e.g., "klebsiella")	"klebsiella"

4. Execution
Make the script executable:

Using bash transform the script in an executable:
chmod +x resfinder_test.sh

Run the script:
./resfinder_test.sh

Output Files
1. summary_results.csv
A consolidated CSV file containing resistance gene/mutation data for all samples:
- I recommend evaluating this csv as if it were a spreadsheet, using tools such as excel, libre office or similar software.

Column	Description
- Sample	- Input filename (isolate name)
- Gene	- Identified resistance gene
- Mutation - Detected mutation (PointFinder)
- Resistance -	Type of resistance conferred
- Coverage	- Gene/mutation coverage (0–1)
- Identity	- Sequence identity (%) with reference
- Covered_positions	- Number of covered nucleotide positions
- Total_length	- Reference gene/mutation length
- Database	Tool used - (ResFinder or PointFinder)
- Accession	Database accession number - (ResFinder only)
- Antibiotics	- List of associated antibiotics

3. processing_log
A log file is just for tracking script execution, including errors and processing steps for debugging.

  
## Final Notes
This script simplifies batch analysis of Klebsiella isolates using ResFinder and PointFinder, but can be used for other species just by changing the variable "ORGANISM".

For questions or improvements, feel free to contact me.

Matheus A. Bomfim
https://www.linkedin.com/in/matheus-azevedo-bomfim/
