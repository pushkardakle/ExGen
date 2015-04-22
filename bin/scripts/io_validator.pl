# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script is used for verification of files created after a step and checking input before a step
# This script also gathers some required statistics post each step
# TODO: There needs to be some major refactoring in this script as the earlier idea was to have an independent
#       subroutine for all steps but major things are common and hence the refactoring        

#!/usr/bin/perl
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use Getopt::Std;
use File::Basename;


#Processing command line options
my %opts;
getopt('sf', \%opts);
unless(defined $opts{'s'}){die "ERROR:The validation script not called in the right way\n"}


#Parsing the dependencies file
my %params_glob_hash; #To store the input params in a hash
open(DEPENDENCIES,"base_dependencies.groovy") or die "ERROR:Could not locate dependencies\.groovy file\n";
foreach(<DEPENDENCIES>)
{
    if ($_=~/(.*?)=\"(.*?)\"/) {
                my $value = $2;
                chomp($value);
                $params_glob_hash{$1}=$value;    
            }
}
close(DEPENDENCIES); #closing the file handle


#Calling the appropriate subroutine depending on the call
if ($opts{'s'} eq "param_validation") {   
    &param_validation();   
}
elsif($opts{'s'} eq "fastqc_start_initial") {
    &fastqc_start_initial($opts{'f'}, %params_glob_hash);
}
elsif($opts{'s'} eq "fastqc_start_post_trimmomatic") {
    &fastqc_start_post_trimmomatic($opts{'f'}, %params_glob_hash);
}
elsif($opts{'s'} eq "fastqc_end" && defined $opts{'f'}) {
    &fastqc_end($opts{'f'}, %params_glob_hash);
}
elsif($opts{'s'} eq "trimmomatic_start") {
    &trimmomatic_start(%params_glob_hash);
}
elsif($opts{'s'} eq "trimmomatic_end") {
    &trimmomatic_end(%params_glob_hash);
}
elsif($opts{'s'} eq "bwa_start") {
    &bwa_start(%params_glob_hash);
}
elsif($opts{'s'} eq "stampy_start") {
    &stampy_start(%params_glob_hash);
}
elsif($opts{'s'} eq "sortsam_start") {
    &sortsam_start(%params_glob_hash);
}
elsif($opts{'s'} eq "sortsam_end") {
    &sortsam_end(%params_glob_hash);
}
elsif($opts{'s'} eq "markdup_start") {
    &markdup_start(%params_glob_hash);
}
elsif($opts{'s'} eq "gatk_indel_realign_start") {
    &gatk_indel_realign_start(%params_glob_hash);
}
elsif($opts{'s'} eq "gatk_baserecalibration_start") {
    &gatk_baserecalibration_start(%params_glob_hash);
}
elsif($opts{'s'} eq "statistics_samtools_start") {
    &statistics_samtools_start(%params_glob_hash);
}
elsif($opts{'s'} eq "statistics_samtools_end") {
    &statistics_samtools_end(%params_glob_hash);
}
elsif($opts{'s'} eq "statistics_analyze_covariates_start") {
    &statistics_analyze_covariates_start(%params_glob_hash);
}
elsif($opts{'s'} eq "statistics_depth_of_coverage_start") {
    &statistics_depth_of_coverage_start(%params_glob_hash);
}
elsif($opts{'s'} eq "statistics_depth_of_coverage_end") {
    &statistics_depth_of_coverage_end(%params_glob_hash);
}
elsif($opts{'s'} eq "statistics_bamstats_start") {
    &statistics_bamstats_start(%params_glob_hash);
}
elsif($opts{'s'} eq "statistics_bamstats_end") {
    &statistics_bamstats_end(%params_glob_hash);
}
else
{
    die "ERROR:The validation script not called in the right way\n"
}














#------------------------------------SUBROUTINES START----------------------------------



sub tools_validator
{
    my $level = shift;
    my %param_local_hash = @_;
    my $tools_check = 1;
    my $what_failed="NULL";
    if ($level eq "fastqc" || $level eq "all") {
        my $fastqc_usage=`$param_local_hash{FASTQC_LOCATION} -v`;
        unless($fastqc_usage=~/FastQC v\d+\.\d+\.\d+/)
        {
            $tools_check=0;
            $what_failed = "fastqc";
        }
    }
    if ($level eq "trimmomatic" || $level eq "all") {
    
        my $trimmomatic_output=`$param_local_hash{JAVA_LOCATION} -jar $param_local_hash{TRIMMOMATIC_LOCATION} 2>&1&`;
        unless($trimmomatic_output=~/Usage:/)
        {
            $tools_check=0;
            $what_failed = "trimmomatic";
        }
    }
    
     if ($level eq "bwa" || $level eq "all") {
    
        my $bwa_output=`$param_local_hash{BWA_LOCATION} 2>&1&`;
        unless($bwa_output=~/Program\:\sbwa/m)
        {
            $tools_check=0;
            $what_failed = "bwa";
        }
    }
     
     if ($level eq "samtools" || $level eq "all") {
    
        my $samtools_output=`$param_local_hash{SAMTOOLS_LOCATION} 2>&1&`;
        unless($samtools_output=~/Program\:\ssamtools/m)
        {
            $tools_check=0;
            $what_failed = "samtools";
        }
    }
     
    if ($level eq "stampy" || $level eq "all") {
    
        my $stampy_output=`$param_local_hash{STAMPY_LOCATION} 2>&1&`;
        unless($stampy_output=~/stampy\sv\d/m)
        {
            $tools_check=0;
            $what_failed = "stampy";
        }
    }
    
    if ($level eq "picard_sortsam" || $level eq "all") {
    
        my $picard_sortsam_output=`$param_local_hash{JAVA_LOCATION} -jar $param_local_hash{PICARD_SORTSAM_LOCATION} 2>&1&`;
        unless($picard_sortsam_output=~/USAGE:\sSortSam/m)
        {
            $tools_check=0;
            $what_failed = "picard_sortsam";
        }
    }
    
    if ($level eq "picard_markdup" || $level eq "all") {
    
        my $picard_markdup_output=`$param_local_hash{JAVA_LOCATION} -jar $param_local_hash{PICARD_MARKDUP_LOCATION} 2>&1&`;
        unless($picard_markdup_output=~/USAGE:\sMarkDuplicates/m)
        {
            $tools_check=0;
            $what_failed = "picard_markdup";
        }
    }
    
    if ($level eq "gatk" || $level eq "all") {
    
        my $gatk_output=`$param_local_hash{JAVA_LOCATION} -jar $param_local_hash{GATK_LOCATION} --help 2>&1&`;
        unless($gatk_output=~/The Genome Analysis Toolkit/m)
        {
            $tools_check=0;
            $what_failed = "gatk";
        }
    }
    
        if ($level eq "bamstats" || $level eq "all") {
    
        my $gatk_output=`$param_local_hash{JAVA_LOCATION} -jar $param_local_hash{BAMSTATS_LOCATION} -help 2>&1&`;
        unless($gatk_output=~/USAGE:/m)
        {
            $tools_check=0;
            $what_failed = "bamstats";
        }
    }
    
    if ($what_failed ne "NULL" && $level eq "all") {
        print "The tool for $what_failed coudnt be located\n";
    }
    
    return $tools_check;
}
    




sub statistics_bamstats_end
{
    my %param_local_hash = @_;
    open(SUMMARY_STATISTICS,">>$param_local_hash{SAMPLE_NAME}_$param_local_hash{SUMMARY_FILE_NAME}") or die "ERROR: Could not open Statistics File\n";
    open(BAMSTATS,"./".${param_local_hash{"STATISTICS_DIR"}}."/".$param_local_hash{BAMSTATS_DIR}."/"."${param_local_hash{SAMPLE_NAME}}_bamstats") or die "Could not open bamstats output\n$!\n";
      print SUMMARY_STATISTICS "\nBAMSTATS_OUTPUT\n";
    my @temparr;
    {
    local $/="\n\n";
    @temparr=<BAMSTATS>;
    }
    foreach my $entry(@temparr)
    {
        if ($entry=~/(Coverage\s\(mapped regions only\)|Mapping qualities|Read lengths)/m) {
            my $type = $1;
            my @stats = map{if($_=~/^(\d|X|Y|MT)/){my($one,$two,$three)=split(/ +/,$_); my $return = "$one\t$three\n";}}split(/\n/,$entry);
            print SUMMARY_STATISTICS "$type\n";
           foreach(@stats)
           {
            print SUMMARY_STATISTICS "$_";
           }
            print SUMMARY_STATISTICS "\n";
        }
    }
  
    close(SUMMARY_STATISTICS);
    close(BAMSTATS);
}

sub statistics_samtools_end
{
    my %param_local_hash = @_;
    open(SUMMARY_STATISTICS,">>$param_local_hash{SAMPLE_NAME}_$param_local_hash{SUMMARY_FILE_NAME}") or die "ERROR: Could not open Statistics File\n";
    open(FLAGSTATS,"./".${param_local_hash{"STATISTICS_DIR"}}."/".$param_local_hash{SAMTOOLS_STATS_DIR}."/"."${param_local_hash{SAMPLE_NAME}}_flagstat_output.txt") or die "Could not open flagstat output\n$!\n";
    open(UNREADCOUNT,"./".${param_local_hash{"STATISTICS_DIR"}}."/".$param_local_hash{SAMTOOLS_STATS_DIR}."/"."${param_local_hash{SAMPLE_NAME}}_unmapped_read_count.txt") or die "Could not open flagstat output\n$!\n";
    print SUMMARY_STATISTICS "\nFLAGSTAT_OUTPUT\n";
    foreach(<FLAGSTATS>){
        if ($_=~/(.*?)\s+\+\s+(\d+)\s+(.*)/) {
            my $statname = $3;
            my $statvalue = $1;
            $statname=~s/\(.*\)//;
            print SUMMARY_STATISTICS"$statname\t$statvalue\n";
        }
    }
    my $count = <UNREADCOUNT>;
    chomp($count);
    print SUMMARY_STATISTICS"Unmapped Read Count\t$count\n";
    close(SUMMARY_STATISTICS);
    close(UNREADCOUNT);
    close(FLAGSTATS);
}

sub statistics_depth_of_coverage_end
{
    my %param_local_hash = @_;
    open(SUMMARY_STATISTICS,">>$param_local_hash{SAMPLE_NAME}_$param_local_hash{SUMMARY_FILE_NAME}") or die "ERROR: Could not open Statistics File\n";
    open(DEPTHOFCOVERAGESUMMARY,"./".${param_local_hash{"STATISTICS_DIR"}}."/".$param_local_hash{DEPTH_OF_COVERAGE_DIR}."/"."${param_local_hash{SAMPLE_NAME}}_depth_of_coverage.cov.sample_summary") or die "Could not open gatk depthofcov output\n$!\n";

    print SUMMARY_STATISTICS "\nGATK_DEPTH_OF_COVERAGE_OUTPUT\n";

    my ($line1, $line2)=<DEPTHOFCOVERAGESUMMARY>;
    my @temparr= split(/\t/,$line2);
    print SUMMARY_STATISTICS "Mean Coverage\t$temparr[2]\n";
    print SUMMARY_STATISTICS "Granular Median Covergage\t$temparr[4]\n";
    print SUMMARY_STATISTICS "\%_bases_above_15\t$temparr[6]\n";
    close(SUMMARY_STATISTICS);
    close(DEPTHOFCOVERAGESUMMARY);
   
}




sub statistics_samtools_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/$param_local_hash{STATISTICS_SAMTOOLS_START}");
    my $proceed = 1;
    
    unless(file_exist_check("./".${param_local_hash{"BASE_RECALIBRATION_DIR"}}."/".$param_local_hash{SAMPLE_NAME}."_aligned_sorted_dupmarked_realigned_recalibrated.bam")){
        die "ERROR: Input files for Samtools Stats do not exist\n";
    }
    
    unless(tools_validator("samtools", %param_local_hash)){
        die "The Samtools executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{STATISTICS_SAMTOOLS_START}`;
    }
}





sub sortsam_end
{
   my %param_local_hash = @_;
   unlink("./".${param_local_hash{STAMPY_DIR}}."/".${param_local_hash{SAMPLE_NAME}}."_aligned.sam") or die "Could not remove stampy output file\n$!\n";
}


sub statistics_analyze_covariates_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/$param_local_hash{STATISTICS_ANALYZE_COVARIATES_START}");
    my $proceed = 1;
    
    unless(file_exist_check("./".${param_local_hash{"BASE_RECALIBRATION_DIR"}}."/".$param_local_hash{SAMPLE_NAME}."_aligned_sorted_dupmarked_realigned_recalibrated.bam") &&
           file_exist_check(${param_local_hash{"REFERENCE_GATK"}})){
        die "ERROR: Input files for GATK BASE RECALIBRATION do not exist\n";
    }
    
    unless(tools_validator("gatk", %param_local_hash)){
        die "The GATK executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{STATISTICS_ANALYZE_COVARIATES_START}`;
    }
}

sub statistics_depth_of_coverage_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/$param_local_hash{STATISTICS_DEPTH_OF_COVERAGE_START}");
    my $proceed = 1;
    
    unless(file_exist_check("./".${param_local_hash{"BASE_RECALIBRATION_DIR"}}."/".$param_local_hash{SAMPLE_NAME}."_aligned_sorted_dupmarked_realigned_recalibrated.bam") &&
           file_exist_check(${param_local_hash{"REFERENCE_GATK"}})){
        die "ERROR: Input files for GATK BASE RECALIBRATION do not exist\n";
    }
    
    unless(tools_validator("gatk", %param_local_hash)){
        die "The GATK executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{STATISTICS_DEPTH_OF_COVERAGE_START}`;
    }
}

sub statistics_bamstats_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/$param_local_hash{STATISTICS_BAMSTATS_START}");
    my $proceed = 1;
    
    unless(file_exist_check("./".${param_local_hash{"BASE_RECALIBRATION_DIR"}}."/".$param_local_hash{SAMPLE_NAME}."_aligned_sorted_dupmarked_realigned_recalibrated.bam")){
        die "ERROR: Input files for BAMSTATS do not exist\n";
    }
    
    unless(tools_validator("bamstats", %param_local_hash)){
        die "The BAMSTATS executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{STATISTICS_BAMSTATS_START}`;
    }
}

sub gatk_baserecalibration_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/$param_local_hash{GATK_BASE_RECALIBRATION_START}");
    my $proceed = 1;
    
    unless(file_exist_check("./".${param_local_hash{"INDEL_REALIGN_DIR"}}."/".$param_local_hash{SAMPLE_NAME}."_aligned_sorted_dupmarked_realigned.bam") &&
           file_exist_check(${param_local_hash{"REFERENCE_GATK"}})){
        die "ERROR: Input files for GATK BASE RECALIBRATION do not exist\n";
    }
    
    unless(tools_validator("gatk", %param_local_hash)){
        die "The GATK executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{GATK_BASE_RECALIBRATION_START}`;
    }
}


sub gatk_indel_realign_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/$param_local_hash{GATK_INDELREALIGN_START}");
    my $proceed = 1;
    
    unless(file_exist_check("./".${param_local_hash{"MARKDUP_DIR"}}."/".$param_local_hash{SAMPLE_NAME}."_aligned_sorted_dupmarked.bam") &&
           file_exist_check(${param_local_hash{"REFERENCE_GATK"}})){
        die "ERROR: Input files for GATK INDEL REALIGN does not exist\n";
    }
    
    unless(tools_validator("gatk", %param_local_hash)){
        die "The GATK executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{GATK_INDELREALIGN_START}`;
    }
}





sub markdup_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/$param_local_hash{MARKDUP_START}");
    my $proceed = 1;

    unless(file_exist_check("./".${param_local_hash{"SORTSAM_DIR"}}."/".$param_local_hash{SAMPLE_NAME}."_aligned_sorted.bam")){
        die "ERROR: Input files for MarkDup do not exist\n";
    }
    
    unless(tools_validator("picard_markdup", %param_local_hash)){
        die "The Picard MarkDup executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{MARKDUP_START}`;
    }
}


sub sortsam_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/$param_local_hash{SORTSAM_START}");
    my $proceed = 1;

    unless(file_exist_check("./".${param_local_hash{"STAMPY_DIR"}}."/".$param_local_hash{SAMPLE_NAME}."_aligned.sam")){
        die "ERROR: Input files for SortSAM do not exist\n";
    }
    
    unless(tools_validator("picard_sortsam", %param_local_hash)){
        die "The Picard SortSAM executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{SORTSAM_START}`;
    }
}

sub bwa_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/$param_local_hash{BWA_START}");
    my $proceed = 1;
    my ($tempfilename1, $tempfilename2) ;
    ($tempfilename1 = basename($param_local_hash{"INPUT_FASTQ_FILE_1"})) =~ s/\.[^.]+$//;
    ($tempfilename2 = basename($param_local_hash{"INPUT_FASTQ_FILE_2"})) =~ s/\.[^.]+$//;
    unless(file_exist_check("./".${param_local_hash{"TRIMMOMATIC_DIR"}}."/".${param_local_hash{"SAMPLE_NAME"}}."_1/${tempfilename1}_filtered.fastq") &&
           file_exist_check("./".${param_local_hash{"TRIMMOMATIC_DIR"}}."/".${param_local_hash{"SAMPLE_NAME"}}."_2/${tempfilename2}_filtered.fastq") &&
           file_exist_check(${param_local_hash{"REFERENCE_BWA"}}."\.bwt")){
        die "ERROR: Input files for BWA do not exist\n";
    }
    
    unless(tools_validator("bwa", %param_local_hash)){
        die "The BWA executable could not be located/isnt of the right version\n";
    }
    
    unless(tools_validator("samtools", %param_local_hash)){
        die "The SAMTOOLS executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{BWA_START}`;
    }
}


sub stampy_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/$param_local_hash{STAMPY_START}");
    my $proceed = 1;
   
    unless(file_exist_check("./".${param_local_hash{"BWA_DIR"}}."/".$param_local_hash{SAMPLE_NAME}."_filtered_bwa_sampe.bam") &&
           file_exist_check(${param_local_hash{"REFERENCE_STAMPY"}}."\.sthash") &&
           file_exist_check(${param_local_hash{"REFERENCE_STAMPY"}}."\.stidx")){
        die "ERROR: Input files for Stampy does not exist\n";
    }
    
    unless(tools_validator("stampy", %param_local_hash)){
        die "The Stampy executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{STAMPY_START}`;
    }
}



sub trimmomatic_end
{
    my %param_local_hash = @_;
    
    
    open(TRIMMOMATIC_LOG,"$param_local_hash{TRIMMOMATIC_TEMP_FILE}") or die "ERROR: Could not open Trimmomatic Log File\n";
    open(SUMMARY_STATISTICS,">>$param_local_hash{SAMPLE_NAME}_$param_local_hash{SUMMARY_FILE_NAME}") or die "ERROR: Could not open Statistics File\n";
    print SUMMARY_STATISTICS "\nTrimmomatic Statstics\n";
    my @temp_trimmomatic = <TRIMMOMATIC_LOG>;
    foreach my $logline(@temp_trimmomatic)
    {
        if ($logline =~/Input Read Pairs: (.*) Both Surviving: (.*) Forward Only Surviving: (.*) Reverse Only Surviving: (.*) Dropped: (.*)/) {
            print SUMMARY_STATISTICS "Input Read Pairs\t$1\n";
            print SUMMARY_STATISTICS "Both Surviving\t$2\n";
            print SUMMARY_STATISTICS "Forward Only Surviving\t$3\n";
            print SUMMARY_STATISTICS "Reverse Only Surviving\t$4\n";
            print SUMMARY_STATISTICS "Dropped\t$5\n";
        }
        
    }
    
    close(TRIMMOMATIC_LOG);
    close(SUMMARY_STATISTICS);
}





sub param_validation
{
    open(DEPENDENCIES,"base_dependencies.groovy") or die "ERROR: Could not locate dependencies\.groovy file\n";
    
    my $proceed=1;
    my %params_hash;
    my @required_check;
    my @file_exist_check;
    my @numeric_with_range_check;
    foreach(<DEPENDENCIES>)
    {
        if ($_!~/^\/\//)
        {
            if ($_=~/(.*?)=\"(.*?)\"/) {
                my $value = $2;
                chomp($value);
                $params_hash{$1}=$value;    
            }
        }
        elsif($_=~/^\/\/PAR_VAL_(.*?)=\((.*?)\)/)
        {
            my $val_par_name = $1;
            my $val_pars=$2;
            if ($val_par_name=~/REQUIRED/ && defined $val_pars) {
                @required_check=split(/\,/,$val_pars);
            }
            elsif ($val_par_name=~/FILE_EXIST_CHECK/ && defined $val_pars) {
                @file_exist_check=split(/\,/,$val_pars);
            }
            elsif ($val_par_name=~/NUMERIC_RANGE/ && defined $val_pars) {
                @numeric_with_range_check=split(/\,/,$val_pars);
            }
        }
           
    }
    
    unlink("./.proceeds/$params_hash{VALIDATION_END}");
    
    foreach my $paramter(@required_check)
    {
        unless(defined $params_hash{$paramter})
        {
            die "The required parameter $paramter is not specified\n";
        }
    }
    
    foreach my $paramter(@file_exist_check)
    {
        unless(-e $params_hash{$paramter})
        {
            die "The file $params_hash{$paramter} specified for $paramter does not exist\n";
        }
    }
    
    foreach my $paramter(@numeric_with_range_check)
    {
        
        if ($paramter=~/(.*?)\[(\d*)\:(\d*)\]/) {
            my ($temp_param, $min, $max)= ($1,$2,$3);
            unless(looks_like_number($params_hash{$temp_param}) && $params_hash{$temp_param}>=$min && $params_hash{$temp_param}<=$max)
            {
                die "The value given for $temp_param in not a number or not within range. Given value $params_hash{$temp_param}\n Allowed range Min: $min Max: $max\n";
            }
        }
        elsif(!looks_like_number($params_hash{$paramter}))
        {
            die "The value given for $paramter in not a number. Given value $params_hash{$paramter}\n";
        }
        
    }
    #unless(tools_validator("all", %params_hash)){
    #    $proceed=0;
    #}
    unless($proceed==0)
    {
        `touch ./.proceeds/$params_hash{VALIDATION_END}`;
    }
    close(DEPENDENCIES);
}









sub trimmomatic_start
{
    my %param_local_hash = @_;
    unlink("./.proceeds/.$param_local_hash{TRIMMOMATIC_START}");
    my $proceed=1;
    unless(file_exist_check("./".$param_local_hash{"INPUT_FASTQ_FILES_DIR"}."/".basename($param_local_hash{"INPUT_FASTQ_FILE_1"})) &&
           file_exist_check("./".$param_local_hash{"INPUT_FASTQ_FILES_DIR"}."/".basename($param_local_hash{"INPUT_FASTQ_FILE_2"}))){
        die "ERROR: Input files for Trimmomatic do not exist\n";
    }
    
    unless(tools_validator("trimmomatic", %param_local_hash)){
        die "The trimmomatic executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0)
    {
        `touch ./.proceeds/$param_local_hash{TRIMMOMATIC_START}`;
    }
}




sub fastqc_end
{
    my $stage = shift;
    my %param_local_hash = @_;
    
    my $proceed=1;
    my $dirname;
    my $suffix;
    my $fastqc_folder_name_1 = basename($param_local_hash{"INPUT_FASTQ_FILE_1"}, ".fastq");
    my $fastqc_folder_name_2 = basename($param_local_hash{"INPUT_FASTQ_FILE_2"}, ".fastq");
    my %fastqc1_hash;
    my %fastqc2_hash;
    my @records1;
    my @records2;
    my @summary1;
    my @summary2;
    if ($stage eq "initial") {
        $dirname=$param_local_hash{"INITIAL_FASTQC_DIR"};
        $suffix="";
    }
    elsif($stage eq "post_trimmomatic"){
        $dirname=$param_local_hash{"POST_TRIMMOMATIC_FASTQC_DIR"};
        $suffix="_filtered";
    }
    
    {
    local $/=">>END_MODULE";
    open(FASTQC_FILE_1_RECORDS, "./".$dirname."/".$param_local_hash{"SAMPLE_NAME"}."_1/${fastqc_folder_name_1}".$suffix."_fastqc/fastqc_data.txt") or die "ERROR: Fastqc output files not found\n";
    open(FASTQC_FILE_2_RECORDS, "./".$dirname."/".$param_local_hash{"SAMPLE_NAME"}."_2/${fastqc_folder_name_2}".$suffix."_fastqc/fastqc_data.txt") or die "ERROR: Fastqc output files not found\n";
    @records1=<FASTQC_FILE_1_RECORDS>;
    @records2=<FASTQC_FILE_2_RECORDS>;
    close(FASTQC_FILE_1_RECORDS);
    close(FASTQC_FILE_2_RECORDS);
    }
    
    open(FASTQC_FILE_1_SUMMARY, "./".$dirname."/".$param_local_hash{"SAMPLE_NAME"}."_1/${fastqc_folder_name_1}".$suffix."_fastqc/summary.txt") or die "ERROR: Fastqc output files not found\n";
    open(FASTQC_FILE_2_SUMMARY, "./".$dirname."/".$param_local_hash{"SAMPLE_NAME"}."_2/${fastqc_folder_name_2}".$suffix."_fastqc/summary.txt") or die "ERROR: Fastqc output files not found\n";
    @summary1=<FASTQC_FILE_1_SUMMARY>;
    @summary2=<FASTQC_FILE_2_SUMMARY>;
    close(FASTQC_FILE_1_SUMMARY);
    close(FASTQC_FILE_2_SUMMARY);
    
    %fastqc1_hash=&fastqc_statistics_internal(\@records1,\@summary1);
    %fastqc2_hash=&fastqc_statistics_internal(\@records2,\@summary2);
    
    if ($stage eq "initial") {
    &fastqc_print_internal($param_local_hash{"SAMPLE_NAME"}, "First_Input_FASTQC",$param_local_hash{"SUMMARY_FILE_NAME"}, %fastqc1_hash);
    &fastqc_print_internal($param_local_hash{"SAMPLE_NAME"}, "Second_Input_FASTQC", $param_local_hash{"SUMMARY_FILE_NAME"}, %fastqc2_hash);
    
    }
    elsif ($stage eq "post_trimmomatic") {
    &fastqc_print_internal($param_local_hash{"SAMPLE_NAME"}, "Post_Trimmomatic_FASTQC_1", $param_local_hash{"SUMMARY_FILE_NAME"}, %fastqc1_hash);
    &fastqc_print_internal($param_local_hash{"SAMPLE_NAME"}, "Post_Trimmomatic_FASTQC_2", $param_local_hash{"SUMMARY_FILE_NAME"}, %fastqc2_hash);
    
    }
    
    
}




sub fastqc_print_internal
{
    my $local_sample_name = shift;
    my $print_statement=shift;
    my $summary_file_name = shift;
    my %print_hash = @_;
    my @print_order = ("Basic Statistics","Total Sequences","Filtered Sequences","Sequence length","\%GC", "Per base sequence quality", "Count of bases with lower quartile below 20.0", "Positions of bases lower quartile below 20.0", "Count of bases with 10th percentile below 20.0", "Positions of bases with 10th percentile below 20.0", "Per sequence quality scores", "Number of sequences with qual score under 20", "Per base GC content", "Per sequence GC content" , "Per base N content" , "Sequence Length Distribution" , "Sequence Duplication Levels" , "Overrepresented sequences" , "Kmer Content");
    
    if ($print_statement eq "First_Input_FASTQC") {
        open(STATISTICS_PRINT,">${local_sample_name}_${summary_file_name}") or die "Could not write statistics file\n";
        print STATISTICS_PRINT "STATISTIC\tVALUE\-${local_sample_name}\n";
    }
    else
    {
        open(STATISTICS_PRINT,">>${local_sample_name}_${summary_file_name}") or die "Could not write statistics file\n";
    }
        print STATISTICS_PRINT "\n$print_statement\n";
        foreach my $stat_name(@print_order)
        {
            if (defined $print_hash{$stat_name}) {
                $print_hash{$stat_name}=~s/\t//;
                print STATISTICS_PRINT "$stat_name\t$print_hash{$stat_name}\n";
            }
            else
            {
                print "$stat_name\n";
                warn "There was an error in your fastqc file\n";
            }
            
        }
        close(STATISTICS_PRINT);
}
    





sub fastqc_statistics_internal
{
    my @internal_records = @{$_[0]};
    my @internal_summary = @{$_[1]};
    my %internal_hash;
    foreach my $record(@internal_records)
    {
        if ($record =~/Basic Statistics/m) {
            my @temp_arr = split(/\n/,$record);
            foreach my $line(@temp_arr)
            {
                if ($line=~/^Total Sequences\t(.*)/) {
                    $internal_hash{"Total Sequences"}=$1;
                }
                elsif ($line=~/^Filtered Sequences\t(.*)/) {
                    $internal_hash{"Filtered Sequences"}=$1;
                }
                elsif ($line=~/^Sequence length\t(.*)/) {
                    $internal_hash{"Sequence length"}=$1;
                }
                elsif ($line=~/^\%GC\t(.*)/) {
                    $internal_hash{"\%GC"}=$1;
                }
                
            }
        }
        elsif($record =~/Per base sequence quality/m)
        {
            my @temp_arr = split(/\n/,$record);
            my $positions_with_10th_quartile_under_20="";
            my $positions_with_10th_quartile_under_20_count=0;
            my $positions_with_lower_quartile_under_20="";
            my $positions_with_lower_quartile_under_20_count=0;
            foreach my $line(@temp_arr)
            {
                if($line=~/^(\d+)/)
                {
                    my @temparr2 = split(/\t/,$line);
                    if ($temparr2[5]<20.0 && $temparr2[5]>0) {
                        $positions_with_10th_quartile_under_20.="$temparr2[0] \, ";
                        $positions_with_10th_quartile_under_20_count++;
                    }
                    if ($temparr2[3]<20.0 && $temparr2[3]>0) {
                        $positions_with_lower_quartile_under_20.="$temparr2[0] \, ";
                        $positions_with_lower_quartile_under_20_count++;
                    }
                    
                }
            }
            if ($positions_with_10th_quartile_under_20 eq "") {
                $positions_with_10th_quartile_under_20 = "NA";
            }
            else
            {
                $positions_with_10th_quartile_under_20=~s/, $//;
            }
            if ($positions_with_lower_quartile_under_20 eq "") {
                $positions_with_lower_quartile_under_20 = "NA";
            }
            else
            {
                $positions_with_lower_quartile_under_20=~s/, $//;
            }
            
            $internal_hash{"Count of bases with 10th percentile below 20.0"}="$positions_with_10th_quartile_under_20_count";
            $internal_hash{"Positions of bases with 10th percentile below 20.0"}="$positions_with_10th_quartile_under_20";
            $internal_hash{"Count of bases with lower quartile below 20.0"}="$positions_with_lower_quartile_under_20_count";
            $internal_hash{"Positions of bases lower quartile below 20.0"}="$positions_with_lower_quartile_under_20";
        }
        elsif($record =~/Per sequence quality scores/m)
        {
            my @temp_arr = split(/\n/,$record);
            my $number_of_sequnces_under_20=0;
            foreach my $line(@temp_arr)
            {
                if ($line=~/^(\d+)\t(.*)/) {
                    if ($1<20.0) {
                        $number_of_sequnces_under_20+=$2;
                        
                    }
                }
                
            }
            $internal_hash{"Number of sequences with qual score under 20"}=int($number_of_sequnces_under_20);
            
        }
        
    }
    
    foreach my $summary(@internal_summary)
    {
        my($value, $key) = split(/\t/,$summary);
        $internal_hash{$key}=$value;
    }
    
    return %internal_hash;
}




    






sub fastqc_start_initial
{
    my $fastqc_stage=shift;
    my %param_local_hash = @_;
    my $proceed = 1;
    unlink("./.proceeds/$param_local_hash{INITIAL_FASTQC_START}");
    
    
    unless(file_exist_check("./".$param_local_hash{"INPUT_FASTQ_FILES_DIR"}."/".basename($param_local_hash{"INPUT_FASTQ_FILE_1"})) &&
           file_exist_check("./".$param_local_hash{"INPUT_FASTQ_FILES_DIR"}."/".basename($param_local_hash{"INPUT_FASTQ_FILE_2"}))){
        die "ERROR: Input files for Initial FASTQC do not exist\n";
    }
    
    unless(tools_validator("fastqc", %param_local_hash)){
        die "The fastqc executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0){
        `touch ./.proceeds/$param_local_hash{INITIAL_FASTQC_START}`;
    }
}



sub fastqc_start_post_trimmomatic
{
    my $fastqc_stage=shift;
    my %param_local_hash = @_;
    my $proceed = 1;
    unlink("./.proceeds/$param_local_hash{POST_TRIMMOMATIC_FASTQC_START}");
    my ($tempfilename1, $tempfilename2) ;
    
    ($tempfilename1 = basename($param_local_hash{"INPUT_FASTQ_FILE_1"})) =~ s/\.[^.]+$//;
    ($tempfilename2 = basename($param_local_hash{"INPUT_FASTQ_FILE_2"})) =~ s/\.[^.]+$//;
    
    my $google = "./".${param_local_hash{"TRIMMOMATIC_DIR"}}."/".${param_local_hash{"SAMPLE_NAME"}}."_1/${tempfilename1}_filtered.fastq";
    print "$google\n";
    
    unless(file_exist_check("./".${param_local_hash{"TRIMMOMATIC_DIR"}}."/".${param_local_hash{"SAMPLE_NAME"}}."_1/${tempfilename1}_filtered.fastq") &&
           file_exist_check("./".${param_local_hash{"TRIMMOMATIC_DIR"}}."/".${param_local_hash{"SAMPLE_NAME"}}."_2/${tempfilename2}_filtered.fastq")){
        die "ERROR: Input files for Post Trimmomatic FASTQC do not exist\n";
    }
    
    unless(tools_validator("fastqc", %param_local_hash)){
        die "The fastqc executable could not be located/isnt of the right version\n";
    }
    
    unless($proceed==0){
        `touch ./.proceeds/$param_local_hash{POST_TRIMMOMATIC_FASTQC_START}`;
    }
}
    








sub file_exist_check
{
    my $filename = shift;
    my $exists = 0;
    if (-e $filename) {
        $exists = 1;
    }
    return $exists;
}


