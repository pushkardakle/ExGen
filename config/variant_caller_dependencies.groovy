// This is the config file for variant calling in exome analysis.
// This will store all the input files and the values which will be input to the tools
// Please do not edit any key name (i.e. part before = on the line)
// Please provide all paramters in quotes ie. ""

//DIRECTORY NAMES
INPUT_BAM_FILES_DIR_NAME="1_Input_BAM_Files"
UNIFIED_GENOTYPER_DIR_NAME="2_Unified_Genotyper"
VARIANT_FILTERATION_DIR_NAME="3_Variant_Filter"
SNPEFF_DIR_NAME="4_Snpeff"
VARIANT_ANNOTATOR_DIR_NAME="5_Variant_Annotator"
VARIANT_EVAL_DIR_NAME="6_Variant_Eval"


//EXECUTABLE SETTINGS
JAVA_LOCATION="java7"
GATK_LOCATION="/opt/apps/GenomeAnalysisTK-2.7-2-g6bda569/GenomeAnalysisTK.jar"
SNPEFF_LOCATION="/opt/apps/snpEff_2_0_5/snpEff.jar"
JAVA_MAX_MEM="28"


//OUTPUT_FILE_NAMES
GATK_UNIFIED_GENOTYPER_METRICS_OUTFILE_NAME="unified_genotyper_metrics.txt"
GATK_VARIANT_FILTERATION_OUTPUT_FILE_NAME="unified_genotyper_filtered.vcf"
SNPEFF_OUTPUT_FILE_NAME="unified_genotyper_filtered_snpeff.vcf"
GATK_VARIANT_ANNOT_OUTPUT_FILE_NAME="unified_genotyper_filtered_snpeff_annot.vcf"
GATK_VARIANT_EVAL_OUTPUT_FILE_NAME="variant_eval_report.txt"

//UNIFIED GENOTYPER
GATK_UNIFIED_GENOTYPER_GLM="BOTH"
GATK_UNIFIED_GENOTYPER_RF="BadCigar"
DBSNP_VCF_FILE="/home/JohnDoe/dbsnp_version_138_from_dbsnp.vcf"
REFERENCE_GATK="/home/JohnDoe/human_g1k_v37.fa"
GATK_UNIFIED_GENOTYPER_OUTPUT_FILE_NAME="unified_genotyper.vcf"
GATK_UNIFIED_GENOTYPER_STAND_CALL_CONF="50.0"
GATK_UNIFIED_GENOTYPER_STAND_EMIT_CONF="10.0"
GATK_UNIFIED_GENOTYPER_STAND_DCOV="400"
GATK_UNIFIED_GENOTYPER_ANNOTS="-A AlleleBalance -A BaseCounts -A ClippingRankSumTest -A GCContent -A HardyWeinberg -A HomopolymerRun -A LikelihoodRankSumTest -A LowMQ -A NBaseCount"
GATK_UNIFIED_GENOTYPER_TRUSEQ_EXOME_BED_FILE="/home/JohnDoe/TruSeq_exome_targeted_regions.hg19.bed"


//SNPEFF
SNPEFF_CONFIG_LOCATION="/home/JohnDoe/Tools/snpeff/snpEff.config"
SNPEFF_REF_NAME="GRCh37.64"


//VARIANTFILTERATION
GATK_VARIANT_FILTERATION_CLUSTER_WIN_SIZE="10"
GATK_VARIANT_FILTERATION_ARG_STRING='--filterExpression "MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)" --filterName "HARD_TO_VALIDATE" --filterExpression "DP < 5 " --filterName "LowCoverage" --filterExpression "QUAL < 30.0 " --filterName "VeryLowQual" --filterExpression "QUAL > 30.0 && QUAL < 50.0 " --filterName "LowQual" --filterExpression "QD < 1.5 " --filterName "LowQD"'
