// This is the config file for paired end exome analysis pipeline.
// This will store all the input files and the values which will be input to the tools
// This file is divided into four major sections.
// The first section has the settings which you will have to frequnctly change
// The second section is divided by each tool. So you can go to each individual tool and change its settings
// The third section gives the folder names that will be created at each stage
// The fourth section specified what kind of validations you want for the parameters
// Please do not edit any key name (i.e. part before = on the line)
// Please provide all paramters in quotes ie. ""

// ------------------------Section 1 --------------------------------------
// ---------------------Autofilled be wrapper------------------------

// The path to first input fastq file[REQUIRED]
INPUT_FASTQ_FILE_1="<INPUT_FASTQ_FILE_1_NAME>"

// The path to second input fastq file[REQUIRED]
INPUT_FASTQ_FILE_2="<INPUT_FASTQ_FILE_2_NAME>"

// Sample Name - Please provide this sample name. This is an unique identified to differentiate the sample[REQUIRED]
// This same name will be used in creating a folder for this sample in the directory, and as the Readgroup
SAMPLE_NAME="<SAMPLE_NAME_NAME>"

//------------------------Changed by the user---------------------------------
//Number of threads - [REQUIRED]
NO_OF_THREADS="2"

// Reference settings The path where the required reference file is present
REFERENCE_BWA="/home/JohnDoe/References/human_g1k_v37.fa"
REFERENCE_STAMPY="/home/JohnDoe/References/References/hg19"
REFERENCE_GATK="/home/JohnDoe/References/References/human_g1k_v37.fa"
//Other input files
DBSNP_VCF_FILE="/home/JohnDoe/References/References/dbsnp132_20101103.vcf"

//--------------------Tool locations--------------------------------
//Please provide complete paths
FASTQC_LOCATION="/home/JohnDoe/Tools/FastQC/fastqc"
TRIMMOMATIC_LOCATION="/home/JohnDoe/Tools/Trimmomatic/trimmomatic-0.32.jar"
BWA_LOCATION="bwa"
SAMTOOLS_LOCATION="samtools"
STAMPY_LOCATION="/home/JohnDoe/Tools/stampy.py"
PICARD_SORTSAM_LOCATION="/home/JohnDoe/Tools/SortSam.jar"
PICARD_MARKDUP_LOCATION="/home/JohnDoe/Tools/MarkDuplicates.jar"
GATK_LOCATION="/home/JohnDoe/Tools/GenomeAnalysisTK.jar"
BAMSTATS_LOCATION="/home/JohnDoe/Tools/BAMStats-1.25.jar"
JAVA_LOCATION="java"
JAVA_MAX_MEM="28"

//----------------------------------------------------------------------



//-----------------------Section 2--------------------------------------

//---------------------------FASTQC--------------------------------------
// Setting for nogroup. If set to 0 the -nogroup will not be specified and if set to one it will be speficied
//FASTQC_NOGROUP="1"

//--------------------------TRIMMOMATIC----------------------------------
//ILLUMINA_CLIP
TRIMMOMATIC_ILLUMINA_ADAPTER_FILE="/home/JohnDoe/References/References/Trimmomatic-0.32/adapters/TruSeq3-PE.fa"
TRIMMOMATIC_SEEDMISMATCHES="2"
TRIMMOMATIC_PALINDROMECLIPTHRESHOLD="30"
TRIMMOMATIC_SIMPLECLIPTHRESHOLD="10"
//CROP
TRIMMOMATIC_CROP_LENGTH="99"
//HEADCROP
TRIMMOMATIC_HEAD_CROP_LENGTH="2"
//SLIDING WINDOW
TRIMMOMATIC_WINDOW_SIZE="25"
TRIMMOMATIC_MIN_QUAL_SCORE="20"
//MINIMUM LENGTH
TRIMMOMATIC_MINIMUM_LENGTH="50"


//-----------------------SORTSAM-----------------------------------------
SORTSAM_SORT_ORDER="coordinate"
SORTSAM_VALIDATION_STRINGENCY="LENIENT"
SORTSAM_CREATE_INDEX="true"


//-----------------------MARKDUP-----------------------------------------
MARKDUP_VALIDATION_STRINGENCY="LENIENT"
MARKDUP_CREATE_INDEX="true"
MARKDUP_METRICS_FILE="Output_Duplicate_Metrics"

//----------------------DepthofCovergae---------------------------------
GATK_DEPTH_OF_COVERAGE_TRUSEQ_EXOME_BED_FILE="{DIRNAME}/TruSeq_exome_targeted_regions.hg19.bed"

//-----------------------Section 3------------------------------------
//-----------------------Folder Names---------------------------------
INPUT_FASTQ_FILES_DIR="1_Input_Fastq_Files"
INITIAL_FASTQC_DIR="2_Initial_FastQC"
TRIMMOMATIC_DIR="3_Trimmomatic"
POST_TRIMMOMATIC_FASTQC_DIR="4_Post_Trimmomatic_FastQC"
BWA_DIR="5_BWA"
STAMPY_DIR="6_Stampy"
SORTSAM_DIR="7_SortSAM"
MARKDUP_DIR="8_MarkDup"
INDEL_REALIGN_DIR="9_Indel_Realign"
BASE_RECALIBRATION_DIR="10_Base_Recalibration"
STATISTICS_DIR="11_Statistics"
SAMTOOLS_STATS_DIR="11_1_Samtools_Statistics"
ANALYZE_COVARIATES_DIR="11_2_Analyze_Covaritates"
DEPTH_OF_COVERAGE_DIR="11_3_Depth_of_Coverage"
BAMSTATS_DIR="11_4_BamStats"

//----------------------Other PATHS------------------------------------
TRIMMOMATIC_TEMP_FILE="./.tmp/trimmomatic_temp_output.txt"
SUMMARY_FILE_NAME="Summary.xls"

//--------------------START-END FILE NAMES-------------------------------
VALIDATION_END="1_validation_end"
INITIAL_FASTQC_START="2_fastqc_initial_start"
TRIMMOMATIC_START="3_trimmomatic_start"
POST_TRIMMOMATIC_FASTQC_START="4_fastqc_post_trimmomatic_start"
BWA_START="5_bwa_start"
STAMPY_START="6_stampy_start"
SORTSAM_START="7_sortsam_start"
MARKDUP_START="8_markdup_start"
GATK_INDELREALIGN_START="9_gatk_indelrealign_start"
GATK_BASE_RECALIBRATION_START="10_gatk_base_recalibration_start"
STATISTICS_SAMTOOLS_START="11_statistics_samtools"
STATISTICS_ANALYZE_COVARIATES_START="12_statistics_analyze_covariates"
STATISTICS_DEPTH_OF_COVERAGE_START="13_statistics_depth_of_coverage"
STATISTICS_BAMSTATS_START="14_statistics_bamstats"
COMPLETED="15_complete"



//---------------------Section 4----------------------------------------
//Please put no spaces between the commas
//PAR_VAL_REQUIRED=(INPUT_FASTQ_FILE_1,INPUT_FASTQ_FILE_2,SAMPLE_NAME,REFERENCE_BWA)
//PAR_VAL_FILE_EXIST_CHECK=(INPUT_FASTQ_FILE_1,INPUT_FASTQ_FILE_2)
//PAR_VAL_NUMERIC_RANGE=(NO_OF_THREADS,TRIMMOMATIC_SEEDMISMATCHES,TRIMMOMATIC_PALINDROMECLIPTHRESHOLD,TRIMMOMATIC_SIMPLECLIPTHRESHOLD,TRIMMOMATIC_CROP_LENGTH,TRIMMOMATIC_WINDOW_SIZE,TRIMMOMATIC_MIN_QUAL_SCORE,TRIMMOMATIC_MINIMUM_LENGTH)


//--------------------Functions---------------------------------
def String getFileNameWithoutExtension(String fileName) {
        File tmpFile = new File(fileName);
        tmpFile.getName();
        int whereDot = tmpFile.getName().lastIndexOf('.');
        if (0 < whereDot && whereDot <= tmpFile.getName().length() - 2 ) {
            return tmpFile.getName().substring(0, whereDot);
            //extension = filename.substring(whereDot+1);
        }    
        return "";
    }

