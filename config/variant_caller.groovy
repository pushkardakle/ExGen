load "variant_caller_dependencies.groovy"

//UNIFIED-GENOTYPER
unified_genotyper={
    exec "rm -rf ${INPUT_BAM_FILES_DIR_NAME}"
    exec "mkdir -p ${INPUT_BAM_FILES_DIR_NAME}"
    exec "mkdir -p ${UNIFIED_GENOTYPER_DIR_NAME}"
    def bamfilenames=" "
    new File(path_locations_file).eachLine { line ->
    def BASENAME = new File(line).name
    // exec "touch ${INPUT_BAM_FILES_DIR_NAME}/${LINE}"
    bamfilenames = bamfilenames + "-I " + line + " "
}
exec """
${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
${GATK_LOCATION}
-T UnifiedGenotyper
-glm ${GATK_UNIFIED_GENOTYPER_GLM}
-rf ${GATK_UNIFIED_GENOTYPER_RF}
-D ${DBSNP_VCF_FILE}
-R ${REFERENCE_GATK}${bamfilenames}-metrics ${GATK_UNIFIED_GENOTYPER_METRICS_OUTFILE_NAME}
-o ${UNIFIED_GENOTYPER_DIR_NAME}/${GATK_UNIFIED_GENOTYPER_OUTPUT_FILE_NAME}
-stand_call_conf ${GATK_UNIFIED_GENOTYPER_STAND_CALL_CONF}
-stand_emit_conf ${GATK_UNIFIED_GENOTYPER_STAND_EMIT_CONF}
-dcov ${GATK_UNIFIED_GENOTYPER_STAND_DCOV}
${GATK_UNIFIED_GENOTYPER_ANNOTS}
-L ${GATK_UNIFIED_GENOTYPER_TRUSEQ_EXOME_BED_FILE}
"""
}


//VARIANT-FILTERATION
variant_filteration={
exec "mkdir -p ${VARIANT_FILTERATION_DIR_NAME}"
exec """
${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
${GATK_LOCATION}
-T VariantFiltration
-R ${REFERENCE_GATK}
--variant ${UNIFIED_GENOTYPER_DIR_NAME}/${GATK_UNIFIED_GENOTYPER_OUTPUT_FILE_NAME}
-o ${VARIANT_FILTERATION_DIR_NAME}/${GATK_VARIANT_FILTERATION_OUTPUT_FILE_NAME}
--clusterWindowSize ${GATK_VARIANT_FILTERATION_CLUSTER_WIN_SIZE}
${GATK_VARIANT_FILTERATION_ARG_STRING}
"""
}


//SNPEFF
snpeff={
exec "mkdir -p ${SNPEFF_DIR_NAME}"
exec """
${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
${SNPEFF_LOCATION}
eff
-c ${SNPEFF_CONFIG_LOCATION}
-v
-onlyCoding true
-i vcf -o vcf
${SNPEFF_REF_NAME}
${VARIANT_FILTERATION_DIR_NAME}/${GATK_VARIANT_FILTERATION_OUTPUT_FILE_NAME} >
${SNPEFF_DIR_NAME}/${SNPEFF_OUTPUT_FILE_NAME}
"""
}


//VARIANT-ANNOT
variantannot={
exec "mkdir -p ${VARIANT_ANNOTATOR_DIR_NAME}"
exec """
${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
${GATK_LOCATION}
-T VariantAnnotator
-R ${REFERENCE_GATK}
--variant ${VARIANT_FILTERATION_DIR_NAME}/${GATK_VARIANT_FILTERATION_OUTPUT_FILE_NAME}
--snpEffFile ${SNPEFF_DIR_NAME}/${SNPEFF_OUTPUT_FILE_NAME}
-A SnpEff
-L ${GATK_UNIFIED_GENOTYPER_TRUSEQ_EXOME_BED_FILE}
-o ${VARIANT_ANNOTATOR_DIR_NAME}/${GATK_VARIANT_ANNOT_OUTPUT_FILE_NAME}
"""
}



//VARIANTEVAL
varianteval={
exec "mkdir -p ${VARIANT_EVAL_DIR_NAME}"
exec """
${JAVA_LOCATION} -Xmx${JAVA_MAX_MEM}g -jar
${GATK_LOCATION}
-T VariantEval
-R ${REFERENCE_GATK}
--dbsnp ${DBSNP_VCF_FILE}
-o ${VARIANT_EVAL_DIR_NAME}/${GATK_VARIANT_EVAL_OUTPUT_FILE_NAME}
-eval:set1 ${VARIANT_ANNOTATOR_DIR_NAME}/${GATK_VARIANT_ANNOT_OUTPUT_FILE_NAME}
"""
}

Bpipe.run {
    unified_genotyper + variant_filteration + snpeff + variantannot
}