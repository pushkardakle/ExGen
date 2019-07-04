# ExGen[Archived]

**ExGen** is a [bpipe](https://github.com/ssadedin/bpipe) and Perl based whole Exome and Genome analysis pipeline. The pipeline was designed primarily to take advantage of a multi-node HPC environment though it also supports single node environments. The pipeline can be used for 

**Major features of the pipeline are:-**

-  Easy single command launch for any number of input samples
- Customizable mail notifications on completion of pipeline/ individual stages
- Monitoring of the run with sample and stage wise status
- Out of the box support for running on HPC environment with multiple job managers eg. lsf, torque etc supported
-  Inbuilt validation of tools, parameters and input files
-  Customizable tool flow and easy resume from any intermediate step in case of failure
-  Integrated collection of relevant statistics from every stage and collation into a single excel file for easy comprison and summarization
-  All fastqc images are collected into a single directory for easy comparison of pre and post QC 
-  Analysis of time taken per module/tool
-  Logging of all the executed commands for easy traceback of parameters

**Limitations:-**

- Currently supports only paired end Illumina data out of the box. Though pipeline can be easily edited to single end mode, different toolbase etc.

**TODO:-**

- Reduction of consumed disk space with compression of BAM files using CRAM or alternate toolkit
-  Relevant plots for the collected statistics
-  Creation of a dockerised container with all the dependencies
-  Add test cases for multi node/single node use case scenarios


