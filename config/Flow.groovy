load "base_dependencies.groovy"

validation = {
exec "mkdir -p .proceeds .tmp"
exec "rm -f ./.proceeds/${COMPLETED}"
exec "rm -f ./.proceeds/*_start rm -f ./.proceeds/*_end"
exec "perl ./io_validator.pl -s param_validation"

if(!new File('./.proceeds/'+VALIDATION_END).exists()){
    exec "echo ERROR: Parameter Validation Failed.Pipeline will now Exit"
    System.exit(0)}
else{
    exec "echo INFO: Parameter Validation Successful."
}
def INPUT_FASTQ_BASE_1= new File(INPUT_FASTQ_FILE_1).name
def INPUT_FASTQ_BASE_2= new File(INPUT_FASTQ_FILE_2).name
exec "mkdir -p ${INPUT_FASTQ_FILES_DIR}"
exec "touch ${INPUT_FASTQ_FILES_DIR}/${INPUT_FASTQ_BASE_1}"
exec "touch ${INPUT_FASTQ_FILES_DIR}/${INPUT_FASTQ_BASE_2}"
}


fastqc_initial = {
def INPUT_FASTQ_BASE_1= new File(INPUT_FASTQ_FILE_1).name
def INPUT_FASTQ_BASE_2= new File(INPUT_FASTQ_FILE_2).name
def INPUT_FASTQ_NO_EXT_1 = getFileNameWithoutExtension(INPUT_FASTQ_FILE_1);
def INPUT_FASTQ_NO_EXT_2 = getFileNameWithoutExtension(INPUT_FASTQ_FILE_2);

exec "perl ./io_validator.pl -s fastqc_start_initial"

if(!new File('./.proceeds/'+INITIAL_FASTQC_START).exists()){
    exec "echo ERROR: Fastqc could not start.Pipeline will now Exit"
    System.exit(0)}
else{
    exec "echo INFO: Starting Initial FASTQC"}

exec "mkdir -p ${INITIAL_FASTQC_DIR}/${SAMPLE_NAME}_1 ${INITIAL_FASTQC_DIR}/${SAMPLE_NAME}_2"

    
    exec """
        ${FASTQC_LOCATION}
        --nogroup
        -o ${INITIAL_FASTQC_DIR}/${SAMPLE_NAME}_1
        -t $NO_OF_THREADS
        ${INPUT_FASTQ_FILE_1}
        """
    exec """
        ${FASTQC_LOCATION}
        --nogroup
        -o ${INITIAL_FASTQC_DIR}/${SAMPLE_NAME}_2
        -t $NO_OF_THREADS
        ${INPUT_FASTQ_FILE_2}
      """
   
   if(new File(INITIAL_FASTQC_DIR+"/"+SAMPLE_NAME+"_1/"+INPUT_FASTQ_NO_EXT_1+"_fastqc.zip").exists() && new File(INITIAL_FASTQC_DIR+"/"+SAMPLE_NAME+"_1/"+INPUT_FASTQ_NO_EXT_1+"_fastqc.html").exists()){
    exec "unzip ${INITIAL_FASTQC_DIR}/${SAMPLE_NAME}_1/${INPUT_FASTQ_NO_EXT_1}_fastqc.zip -d ${INITIAL_FASTQC_DIR}/${SAMPLE_NAME}_1"
    }
   if(new File(INITIAL_FASTQC_DIR+"/"+SAMPLE_NAME+"_2/"+INPUT_FASTQ_NO_EXT_2+"_fastqc.zip").exists() && new File(INITIAL_FASTQC_DIR+"/"+SAMPLE_NAME+"_2/"+INPUT_FASTQ_NO_EXT_2+"_fastqc.html").exists()){
    exec "unzip ${INITIAL_FASTQC_DIR}/${SAMPLE_NAME}_2/${INPUT_FASTQ_NO_EXT_2}_fastqc.zip -d ${INITIAL_FASTQC_DIR}/${SAMPLE_NAME}_2"
    }
    
   exec "perl ./io_validator.pl -s fastqc_end -f initial"  
}

trimmomatic= {
   
//The comments
//HEADCROP:${TRIMMOMATIC_HEAD_CROP_LENGTH}
def INPUT_FASTQ_BASE_1= new File(INPUT_FASTQ_FILE_1).name
def INPUT_FASTQ_BASE_2= new File(INPUT_FASTQ_FILE_2).name
def INPUT_FASTQ_NO_EXT_1 = getFileNameWithoutExtension(INPUT_FASTQ_FILE_1);
def INPUT_FASTQ_NO_EXT_2 = getFileNameWithoutExtension(INPUT_FASTQ_FILE_2);

exec "perl ./io_validator.pl -s trimmomatic_start"

if(!new File('./.proceeds/'+TRIMMOMATIC_START).exists()){
    exec "echo ERROR: Trimomatic could not start.Pipeline will now Exit"
    System.exit(0)}
else{
    exec "echo INFO: Starting Trimmomatic"}

exec "mkdir -p ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_1 ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_2"
exec """
        ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
        ${TRIMMOMATIC_LOCATION}
        PE
        -threads $NO_OF_THREADS
        -phred33
        ${INPUT_FASTQ_FILE_1}
        ${INPUT_FASTQ_FILE_2}
        ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_1/${INPUT_FASTQ_NO_EXT_1}_filtered.fastq
        ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_1/${INPUT_FASTQ_NO_EXT_1}_removed.fastq
        ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_2/${INPUT_FASTQ_NO_EXT_2}_filtered.fastq
        ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_2/${INPUT_FASTQ_NO_EXT_2}_removed.fastq
        ILLUMINACLIP:${TRIMMOMATIC_ILLUMINA_ADAPTER_FILE}:${TRIMMOMATIC_SEEDMISMATCHES}:${TRIMMOMATIC_PALINDROMECLIPTHRESHOLD}:${TRIMMOMATIC_SIMPLECLIPTHRESHOLD}
        CROP:${TRIMMOMATIC_CROP_LENGTH}
        HEADCROP:${TRIMMOMATIC_HEAD_CROP_LENGTH}
        SLIDINGWINDOW:${TRIMMOMATIC_WINDOW_SIZE}:${TRIMMOMATIC_MIN_QUAL_SCORE}
        MINLEN:${TRIMMOMATIC_MINIMUM_LENGTH} 2>&1 | tee ${TRIMMOMATIC_TEMP_FILE}
    """

exec "perl ./io_validator.pl -s trimmomatic_end"

}

fastqc_post_trimmomatic = {
def INPUT_FASTQ_BASE_1= new File(INPUT_FASTQ_FILE_1).name
def INPUT_FASTQ_BASE_2= new File(INPUT_FASTQ_FILE_2).name
def INPUT_FASTQ_NO_EXT_1 = getFileNameWithoutExtension(INPUT_FASTQ_FILE_1);
def INPUT_FASTQ_NO_EXT_2 = getFileNameWithoutExtension(INPUT_FASTQ_FILE_2);
//def HALF_NO_OF_THREADS = NO_OF_THREADS/2 as int;
exec "perl ./io_validator.pl -s fastqc_start_post_trimmomatic"

if(!new File('./.proceeds/'+POST_TRIMMOMATIC_FASTQC_START).exists()){
    exec "echo ERROR: Fastqc could not start.Pipeline will now Exit"
    System.exit(0)}
else{
    exec "echo INFO: Starting Post Trimmomatic FASTQC"}

exec "mkdir -p ${POST_TRIMMOMATIC_FASTQC_DIR}/${SAMPLE_NAME}_1 ${POST_TRIMMOMATIC_FASTQC_DIR}/${SAMPLE_NAME}_2"

    
    exec """
        ${FASTQC_LOCATION}
        --nogroup
        -o ${POST_TRIMMOMATIC_FASTQC_DIR}/${SAMPLE_NAME}_1
        -t $NO_OF_THREADS
        ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_1/${INPUT_FASTQ_NO_EXT_1}_filtered.fastq
        """
    exec  """
        ${FASTQC_LOCATION}
        --nogroup
        -o ${POST_TRIMMOMATIC_FASTQC_DIR}/${SAMPLE_NAME}_2
        -t $NO_OF_THREADS
        ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_2/${INPUT_FASTQ_NO_EXT_2}_filtered.fastq
      """
    
   if(new File(POST_TRIMMOMATIC_FASTQC_DIR+"/"+SAMPLE_NAME+"_1/"+INPUT_FASTQ_NO_EXT_1+"_filtered_fastqc.zip").exists() && new File(POST_TRIMMOMATIC_FASTQC_DIR+"/"+SAMPLE_NAME+"_1/"+INPUT_FASTQ_NO_EXT_1+"_filtered_fastqc.html").exists()){
    exec "unzip ${POST_TRIMMOMATIC_FASTQC_DIR}/${SAMPLE_NAME}_1/${INPUT_FASTQ_NO_EXT_1}_filtered_fastqc.zip -d ${POST_TRIMMOMATIC_FASTQC_DIR}/${SAMPLE_NAME}_1"
    }
   if(new File(POST_TRIMMOMATIC_FASTQC_DIR+"/"+SAMPLE_NAME+"_2/"+INPUT_FASTQ_NO_EXT_2+"_filtered_fastqc.zip").exists() && new File(POST_TRIMMOMATIC_FASTQC_DIR+"/"+SAMPLE_NAME+"_2/"+INPUT_FASTQ_NO_EXT_2+"_filtered_fastqc.html").exists()){
    exec "unzip ${POST_TRIMMOMATIC_FASTQC_DIR}/${SAMPLE_NAME}_2/${INPUT_FASTQ_NO_EXT_2}_filtered_fastqc.zip -d ${POST_TRIMMOMATIC_FASTQC_DIR}/${SAMPLE_NAME}_2"
    }
   
   
   exec "perl ./io_validator.pl -s fastqc_end -f post_trimmomatic"  
}

bwa={

def INPUT_FASTQ_NO_EXT_1 = getFileNameWithoutExtension(INPUT_FASTQ_FILE_1);
def INPUT_FASTQ_NO_EXT_2 = getFileNameWithoutExtension(INPUT_FASTQ_FILE_2);
    exec "perl ./io_validator.pl -s bwa_start"
    if(!new File('./.proceeds/'+BWA_START).exists()){
    exec "echo ERROR: BWA could not start.Pipeline will now Exit"
    System.exit(0)}
    else{
    exec "echo INFO: Starting BWA Mapping"}
    
    exec "mkdir -p ${BWA_DIR}"
    exec """
    ${BWA_LOCATION}
    aln
    -t${NO_OF_THREADS}
    ${REFERENCE_BWA}
    ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_1/${INPUT_FASTQ_NO_EXT_1}_filtered.fastq >
    ${BWA_DIR}/${INPUT_FASTQ_NO_EXT_1}_filtered_bwa_aln.sai
    """
    exec """
    ${BWA_LOCATION}
    aln
    -t${NO_OF_THREADS}
    ${REFERENCE_BWA}
    ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_2/${INPUT_FASTQ_NO_EXT_2}_filtered.fastq >
    ${BWA_DIR}/${INPUT_FASTQ_NO_EXT_2}_filtered_bwa_aln.sai
    """
    exec """
    ${BWA_LOCATION}
    sampe
    ${REFERENCE_BWA}
    ${BWA_DIR}/${INPUT_FASTQ_NO_EXT_1}_filtered_bwa_aln.sai
    ${BWA_DIR}/${INPUT_FASTQ_NO_EXT_2}_filtered_bwa_aln.sai
    ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_1/${INPUT_FASTQ_NO_EXT_1}_filtered.fastq
    ${TRIMMOMATIC_DIR}/${SAMPLE_NAME}_2/${INPUT_FASTQ_NO_EXT_2}_filtered.fastq |
    ${SAMTOOLS_LOCATION}
    view -Sb - >
    ${BWA_DIR}/${SAMPLE_NAME}_filtered_bwa_sampe.bam
    """
    
}


stampy={
    
    exec "perl ./io_validator.pl -s stampy_start"
    if(!new File('./.proceeds/'+STAMPY_START).exists()){
    exec "echo ERROR: Stampy could not start.Pipeline will now Exit"
    System.exit(0)}
    else{
    exec "echo INFO: Starting Stampy Mapping"}
    
    
exec "mkdir -p ${STAMPY_DIR}"
exec """
    ${STAMPY_LOCATION}
    -g ${REFERENCE_STAMPY}
    -h ${REFERENCE_STAMPY}
    -t${NO_OF_THREADS}
    --readgroup=ID:${SAMPLE_NAME},SM:${SAMPLE_NAME},PL:Illumina,LB:${SAMPLE_NAME}_subset
    --bamkeepgoodreads
    -M ${BWA_DIR}/${SAMPLE_NAME}_filtered_bwa_sampe.bam
    --output=${STAMPY_DIR}/${SAMPLE_NAME}_aligned.sam
    """
  
}


picard_sortsam={
    
    exec "perl ./io_validator.pl -s sortsam_start"
    if(!new File('./.proceeds/'+SORTSAM_START).exists()){
    exec "echo ERROR: SortSAM could not start.Pipeline will now Exit"
    System.exit(0)}
    else{
    exec "echo INFO: Starting SortSAM"}
    
exec "mkdir -p ${SORTSAM_DIR}"
exec """
    ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
    ${PICARD_SORTSAM_LOCATION}
    SO=${SORTSAM_SORT_ORDER}
    INPUT=${STAMPY_DIR}/${SAMPLE_NAME}_aligned.sam
    OUTPUT=${SORTSAM_DIR}/${SAMPLE_NAME}_aligned_sorted.bam
    VALIDATION_STRINGENCY=${SORTSAM_VALIDATION_STRINGENCY}
    CREATE_INDEX=${SORTSAM_CREATE_INDEX}
    """
exec """
    ${SAMTOOLS_LOCATION}
    view -Sb ${STAMPY_DIR}/${SAMPLE_NAME}_aligned.sam >
    ${STAMPY_DIR}/${SAMPLE_NAME}_aligned.bam
"""
    exec "perl ./io_validator.pl -s sortsam_end"
}


picard_dupmark={
    
    exec "perl ./io_validator.pl -s markdup_start"
    if(!new File('./.proceeds/'+MARKDUP_START).exists()){
    exec "echo ERROR: Markdup could not start.Pipeline will now Exit"
    System.exit(0)}
    else{
    exec "echo INFO: Starting DupMarking"}
    
exec "mkdir -p ${MARKDUP_DIR}"
exec """
    ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
    ${PICARD_MARKDUP_LOCATION}
    INPUT=${SORTSAM_DIR}/${SAMPLE_NAME}_aligned_sorted.bam
    OUTPUT=${MARKDUP_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked.bam
    VALIDATION_STRINGENCY=${MARKDUP_VALIDATION_STRINGENCY}
    CREATE_INDEX=${MARKDUP_CREATE_INDEX}
    METRICS_FILE=${MARKDUP_DIR}/${MARKDUP_METRICS_FILE}
    """
    
}

gatk_indel_realign={
        exec "perl ./io_validator.pl -s gatk_indel_realign_start"
    if(!new File('./.proceeds/'+GATK_INDELREALIGN_START).exists()){
    exec "echo ERROR: Indel Realign could not start.Pipeline will now Exit"
    System.exit(0)}
    else{
    exec "echo INFO: Starting Indel Realigner"}
    
    exec "mkdir -p ${INDEL_REALIGN_DIR}"
    exec """
    ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
    ${GATK_LOCATION}
    -T RealignerTargetCreator
    -nt ${NO_OF_THREADS}
    -R ${REFERENCE_GATK}
    -I ${MARKDUP_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked.bam
    -o ${INDEL_REALIGN_DIR}/${SAMPLE_NAME}_IndelRealigner.intervals
    """
    exec """
    ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
    ${GATK_LOCATION}
    -T IndelRealigner
    -R ${REFERENCE_GATK}
    -I ${MARKDUP_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked.bam
    -targetIntervals ${INDEL_REALIGN_DIR}/${SAMPLE_NAME}_IndelRealigner.intervals
    -o ${INDEL_REALIGN_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked_realigned.bam
    """
    
}

gatk_base_recalibration={
        exec "perl ./io_validator.pl -s gatk_baserecalibration_start"
    if(!new File('./.proceeds/'+GATK_BASE_RECALIBRATION_START).exists()){
    exec "echo ERROR: Base Recalibration could not start.Pipeline will now Exit"
    System.exit(0)}
    else{
    exec "echo INFO: Starting Base Recalibration"}
    
    exec "mkdir -p ${BASE_RECALIBRATION_DIR}"
    exec """
    ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
    ${GATK_LOCATION}
    -T BaseRecalibrator
    -R ${REFERENCE_GATK}
    -I ${INDEL_REALIGN_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked_realigned.bam
    -knownSites ${DBSNP_VCF_FILE}
    -o ${BASE_RECALIBRATION_DIR}/${SAMPLE_NAME}_recal_data.table
    """
    exec """
    ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
    ${GATK_LOCATION}
    -T PrintReads
    -R ${REFERENCE_GATK}
    -I ${INDEL_REALIGN_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked_realigned.bam
    -BQSR ${BASE_RECALIBRATION_DIR}/${SAMPLE_NAME}_recal_data.table
    -o  ${BASE_RECALIBRATION_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked_realigned_recalibrated.bam
    """
}

statistics_samtools={
    exec "perl ./io_validator.pl -s statistics_samtools_start"
    if(!new File('./.proceeds/'+STATISTICS_SAMTOOLS_START).exists()){
    exec "echo ERROR: Statistics Statistics Samtools could not start.Pipeline will now Exit"
    System.exit(0)}
    else{
    exec "echo INFO: Starting Statistics Samtools"}
    exec "mkdir -p ${STATISTICS_DIR}/${SAMTOOLS_STATS_DIR}"
    exec """
    ${SAMTOOLS_LOCATION}
    flagstat
    ${BASE_RECALIBRATION_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked_realigned_recalibrated.bam
    > ${STATISTICS_DIR}/${SAMTOOLS_STATS_DIR}/${SAMPLE_NAME}_flagstat_output.txt 2>&1
    """
    
    exec """
    ${SAMTOOLS_LOCATION}
    view
    -c -f 4
    ${BASE_RECALIBRATION_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked_realigned_recalibrated.bam
    > ${STATISTICS_DIR}/${SAMTOOLS_STATS_DIR}/${SAMPLE_NAME}_unmapped_read_count.txt 2>&1
    """
    exec "perl ./io_validator.pl -s statistics_samtools_end"
}


statistics_analyze_covariates={
    exec "perl ./io_validator.pl -s statistics_analyze_covariates_start"
    if(!new File('./.proceeds/'+STATISTICS_ANALYZE_COVARIATES_START).exists()){
    exec "echo ERROR: Statistics Analyze Covariates could not start.Pipeline will now Exit"
    System.exit(0)}
    else{
    exec "echo INFO: Starting Statistics Analyze Covariates"}
    
    exec "mkdir -p ${STATISTICS_DIR}/${ANALYZE_COVARIATES_DIR}"
    exec """
    ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
    ${GATK_LOCATION}
    -T BaseRecalibrator
    -R ${REFERENCE_GATK}
    -I ${BASE_RECALIBRATION_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked_realigned_recalibrated.bam
    -knownSites ${DBSNP_VCF_FILE}
    -o ${STATISTICS_DIR}/${ANALYZE_COVARIATES_DIR}/${SAMPLE_NAME}_post_recal_data.table
    """
    exec """
    ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
    ${GATK_LOCATION}
    -T AnalyzeCovariates
    -R ${REFERENCE_GATK}
    -before ${BASE_RECALIBRATION_DIR}/${SAMPLE_NAME}_recal_data.table
    -after ${STATISTICS_DIR}/${ANALYZE_COVARIATES_DIR}/${SAMPLE_NAME}_post_recal_data.table
    -csv ${STATISTICS_DIR}/${ANALYZE_COVARIATES_DIR}/${SAMPLE_NAME}_analyze_covariates.csv
    -plots ${STATISTICS_DIR}/${ANALYZE_COVARIATES_DIR}/${SAMPLE_NAME}_analyze_covariates.pdf
    """
}

statistics_depth_of_coverage={
    exec "perl ./io_validator.pl -s statistics_depth_of_coverage_start"
    if(!new File('./.proceeds/'+STATISTICS_DEPTH_OF_COVERAGE_START).exists()){
    exec "echo ERROR: Statistics Depth of coverage could not start.Pipeline will now Exit"
    System.exit(0)}
    else{
    exec "echo INFO: Starting Statistics Depth of coverage"}
    
    exec "mkdir -p ${STATISTICS_DIR}/${DEPTH_OF_COVERAGE_DIR}"
    exec """
    ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
    ${GATK_LOCATION}
    -T DepthOfCoverage
    -R ${REFERENCE_GATK}
    -L ${GATK_DEPTH_OF_COVERAGE_TRUSEQ_EXOME_BED_FILE}
    -I ${BASE_RECALIBRATION_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked_realigned_recalibrated.bam
    -o ${STATISTICS_DIR}/${DEPTH_OF_COVERAGE_DIR}/${SAMPLE_NAME}_depth_of_coverage.cov
    """
    exec "perl ./io_validator.pl -s statistics_depth_of_coverage_end"
}

statistics_bamstats={
    exec "perl ./io_validator.pl -s statistics_bamstats_start"
    if(!new File('./.proceeds/'+STATISTICS_BAMSTATS_START).exists()){
    exec "echo ERROR: Statistics Bamstats could not start.Pipeline will now Exit"
    System.exit(0)}
    else{
    exec "echo INFO: Starting Statistics Bamstats"}
    
    exec "mkdir -p ${STATISTICS_DIR}/${BAMSTATS_DIR}"
    exec """
    ${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
    ${BAMSTATS_LOCATION}
    -dlmq
    -i ${BASE_RECALIBRATION_DIR}/${SAMPLE_NAME}_aligned_sorted_dupmarked_realigned_recalibrated.bam
    -o ${STATISTICS_DIR}/${BAMSTATS_DIR}/${SAMPLE_NAME}_bamstats
    """
    exec "perl ./io_validator.pl -s statistics_bamstats_end"

}

complete={
    exec "touch ./.proceeds/${COMPLETED}"
}




Bpipe.run {
validation + fastqc_initial + trimmomatic + fastqc_post_trimmomatic + bwa + stampy + picard_sortsam + picard_dupmark + gatk_indel_realign + gatk_base_recalibration + statistics_samtools + statistics_depth_of_coverage + statistics_bamstats + complete
//validation + fastqc_initial + trimmomatic + fastqc_post_trimmomatic + complete
//validation + fastqc_initial + complete
//validation + complete
//validation + statistics_depth_of_coverage + statistics_bamstats + complete
}
