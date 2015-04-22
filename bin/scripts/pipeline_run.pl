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

# This script will be called by the pipeline_executor.pl along with a proper input file made by
# input_file_maker.pl. This will create the various input required be bpipe along with monitoring
# of runs and gathering of fastq images.

#Modules to be imported
use strict;
use warnings;
use Cwd;
use Getopt::Std;
use File::Copy;
use File::Basename;
use Tie::File;

#Processing of commandline options
my %opts;
getopt('ih', \%opts);
if (defined $opts{'h'}) { &usage(0);}
unless(defined $opts{'i'} && -e $opts{'i'}){ &usage(1);}

my ($config_hash_ref, $input_arr_ref) = &process_config($opts{'i'});
my @directories_created = &create_dirs($config_hash_ref, $input_arr_ref);
chdir(${$config_hash_ref}{WORK_DIR});
#foreach(@directories_created){print "$_\n";}
&launch_runs($config_hash_ref,@directories_created);
chdir(${$config_hash_ref}{WORK_DIR});
&monitor_runs(${$config_hash_ref}{WORK_DIR}, @directories_created);
chdir(${$config_hash_ref}{WORK_DIR});
&fastqc_integrator(${$config_hash_ref}{WORK_DIR},"2_Initial_FastQC");
chdir(${$config_hash_ref}{WORK_DIR});
&fastqc_integrator(${$config_hash_ref}{WORK_DIR},"4_Post_Trimmomatic_FastQC");
chdir(${$config_hash_ref}{WORK_DIR});
&stats_integrator(${$config_hash_ref}{WORK_DIR});

# Wil collate all the sample wise statistics
sub stats_integrator
{
    my $main_dir= shift;
    my $base = basename($main_dir);
    my @final_print_arr;
    `mkdir -p ./Stats_and_QC/Stats`;
    foreach my $dirname(<*>)
    {
        if (-e "$dirname/${dirname}_Summary.xls" && $dirname !~/Stats_and_QC/)
        {
            copy("$dirname/${dirname}_Summary.xls", "./Stats_and_QC/Stats/${dirname}_Summary.xls");
        }
    }
    chdir("${main_dir}/Stats_and_QC/Stats");
    my @stat_file_names = <*_Summary.xls>;
    open(STATS_OUTPUT,">${base}_Integrated_Stats.xls") or die "Cannot make the file";
    if (scalar(@stat_file_names)>1)
    {
        my $first_file = shift(@stat_file_names);
        my @temparr;
        tie @temparr, 'Tie::File', $first_file or die "Cannot open file";
        foreach my $line(@temparr)
        {
            chomp($line);
            push(@final_print_arr,$line);
        }
        untie @temparr;
        foreach my $other_file_names(@stat_file_names)
        {
            my @temparr2;
            tie @temparr2, 'Tie::File', $other_file_names or die "Cannot open file";
            my $counter=0;
            foreach my $line(@temparr2)
            {
                my ($one,$two)=split(/\t/,$line);
                if(defined $two)
                {
                $final_print_arr[$counter].="\t$two";
                }
                else
                {
                $final_print_arr[$counter].="\t";
                }
                $counter++;
            }
            untie @temparr2;
        }
    }
    foreach(@final_print_arr)
    {
        print STATS_OUTPUT "$_\n";
    }
    close(STATS_OUTPUT);
}


# Will gather all the fastqc images into one directory for easy viewing
sub fastqc_integrator
{
    my $main_dir= shift;
    my $subdir = shift;
    `mkdir -p ./Stats_and_QC/FastQC/${subdir}/InputFile_1 Stats_and_QC/FastQC/${subdir}/InputFile_2`;
    `mkdir -p ./Stats_and_QC/FastQC/${subdir}/InputFile_1/duplication_levels ./Stats_and_QC/FastQC/${subdir}/InputFile_1/per_base_gc_content ./Stats_and_QC/FastQC/${subdir}/InputFile_1/per_base_n_content ./Stats_and_QC/FastQC/${subdir}/InputFile_1/per_base_quality ./Stats_and_QC/FastQC/${subdir}/InputFile_1/per_base_sequence_content ./Stats_and_QC/FastQC/${subdir}/InputFile_1/per_sequence_gc_content ./Stats_and_QC/FastQC/${subdir}/InputFile_1/per_sequence_quality ./Stats_and_QC/FastQC/${subdir}/InputFile_1/sequence_length_distribution`;
`mkdir -p ./Stats_and_QC/FastQC/${subdir}/InputFile_2/duplication_levels ./Stats_and_QC/FastQC/${subdir}/InputFile_2/per_base_gc_content ./Stats_and_QC/FastQC/${subdir}/InputFile_2/per_base_n_content ./Stats_and_QC/FastQC/${subdir}/InputFile_2/per_base_quality ./Stats_and_QC/FastQC/${subdir}/InputFile_2/per_base_sequence_content ./Stats_and_QC/FastQC/${subdir}/InputFile_2/per_sequence_gc_content ./Stats_and_QC/FastQC/${subdir}/InputFile_2/per_sequence_quality ./Stats_and_QC/FastQC/${subdir}/InputFile_2/sequence_length_distribution`;

my @find_dir = qw(duplication_levels.png per_base_gc_content.png per_base_n_content.png per_base_quality.png per_base_sequence_content.png per_sequence_gc_content.png per_sequence_quality.png sequence_length_distribution.png);

foreach my $directory_name(<*>)
{
    chomp($directory_name);
    my (@first_arr, @second_arr, @total_arr);
    if(-d "$directory_name/$subdir" && $directory_name !~/Stats_and_QC/)
    {
        foreach my $filename(@find_dir){
        my @temparr = `find ./${directory_name}/${subdir} -name \"${filename}\"`;
        push(@total_arr, @temparr);
        }
    }
    foreach my $path(@total_arr)
    {
        my $basename = basename($path);
        $basename =~s/\.png//;
        $path=~s/^\./$main_dir/;
        chomp($basename);
        chomp($path);
        if ($path=~/_R1_/) {
           copy("$path", "./Stats_and_QC/FastQC/${subdir}/InputFile_1/${basename}/${directory_name}_${basename}_1.png") or die "Copy not possible for $path at ./Stats_and_QC/FastQC/${subdir}/InputFile_1/${basename}/${directory_name}_${basename}_1.png\n$!\n";
        }
        elsif ($path=~/_R2_/) {
           copy("$path", "./Stats_and_QC/FastQC/${subdir}/InputFile_2/${basename}/${directory_name}_${basename}_2.png") or die "Copy not possible for $path at ./Stats_and_QC/FastQC/${subdir}/InputFile_2/${basename}/${directory_name}_${basename}_2.png\n$!\n";
        }
    }
}
}




# This sub will monitor the runs and report sample wise and stage wise reports
sub monitor_runs
{
    my $main_dir= shift;
    my @launched_dirs = @_;
    my $number_of_runs_launched = scalar(@launched_dirs);
    my %completed_finish_count_hash;
    print "INFO: Will now monitor runs\n";
    while (scalar(keys %completed_finish_count_hash)<$number_of_runs_launched) {
        my %sample_wise_stage;
        my %stage_wise;
        foreach my $line(@launched_dirs){
            my($dir,$sample_name)=split(/:/,$line);
            if (-e "$dir\/${sample_name}_output") {
                my $fail_check = `grep 'Pipeline failed!' $dir/${sample_name}_output`;
                print $fail_check;
                if ($fail_check =~/Pipeline failed/) {
                    $sample_wise_stage{$sample_name}="Failed";
                    $stage_wise{"Failed"}++;
                    $completed_finish_count_hash{"$sample_name"}++;
                }
                else{
                    if (-d "$dir\/\.proceeds\/") {
                        chdir("$dir\/\.proceeds\/");
                        my $latest_stage = `ls|sort -nr|head -n 1`;
                        if($latest_stage =~/(\d+)_(.*)/){
                            my($number,$rest)=split(/\_/,$latest_stage,2);
                            chomp($rest);
                            $sample_wise_stage{$sample_name}="$rest";
                            $stage_wise{"$rest"}++;
                            if ($rest eq "complete") {
                                $completed_finish_count_hash{"$sample_name"}++; 
                            }
                        }
                    }
                }
            }
        }
        open(SAMPLE_WISE, ">","$main_dir/sample_wise.txt") or die "Could not fire up sample wise xls\n";
        open(STAGE_WISE, ">","$main_dir/stage_wise.txt") or die "Could not fire up stage wise xls\n";
        print SAMPLE_WISE"Sample\tStage\n";
        print STAGE_WISE"Stage\tCount\n";
        
        print "INFO: Sample Wise Report\n";
        foreach(sort{$a cmp $b}keys %sample_wise_stage){
            print "SAMPLE: $_\t$sample_wise_stage{$_}\n";
            print SAMPLE_WISE"$_\t$sample_wise_stage{$_}\n";
        }
        print "INFO: Stage Wise Report\n";
        
        foreach(sort{$a cmp $b}keys %stage_wise){
            print "STAGE: $_\t$stage_wise{$_}\n";
            print STAGE_WISE"$_\t$stage_wise{$_}\n";
        }
        close(SAMPLE_WISE);
        close(STAGE_WISE);
        sleep(10);
    }
    
}

# This sub will launch the runs using bpipe
sub launch_runs
{
   my %config_hash = %{shift(@_)};
   my @launched_dirs = @_;
   foreach my $line(@launched_dirs){
        my($dir,$sample_name)=split(/:/,$line);
        chdir($dir);
        #my $scriptname = basename($config_hash{"BPIPE_SCRIPT"});
        if (-e 'bpipe_exome_script.groovy') {
            
            if (defined $config_hash{JOB_SCHEDULER}) {
                print "INFO: Launched run for ${sample_name}\n";
                `nohup $config_hash{"BPIPE_EXECUTABLE"} run -r bpipe_exome_script.groovy > ${sample_name}_output 2>&1 &`;
                sleep($config_hash{"SLEEP_TIME"});
            }
            else{
                print "INFO: Launched run for ${sample_name}\n";
                `$config_hash{"BPIPE_EXECUTABLE"} run -r bpipe_exome_script.groovy > ${sample_name}_output`
            }
        }
        else
        {
            die "WARNING: Could not find launch script for sample $sample_name\n";
        }
    }
}




# This sub will create the directories for each sample in which the analysis will be done
sub create_dirs
{
    my %config_hash = %{shift(@_)};
    my @input_arr = @{shift(@_)};
    my @return_arr;
    
    foreach my $individual_input_hash(@input_arr){
        
            chdir($config_hash{WORK_DIR});
            `mkdir -p ${$individual_input_hash}{SAMPLE_NAME}`;
            chdir("$config_hash{WORK_DIR}/${$individual_input_hash}{SAMPLE_NAME}");
            if (defined ${$individual_input_hash}{BPIPE_SCRIPT}) {
            copy(${$individual_input_hash}{BPIPE_SCRIPT},"\.\/bpipe_exome_script.groovy") or die "ERROR: Copy failed for ${$individual_input_hash}{BPIPE_SCRIPT}: $!";
            }
            else{
            copy($config_hash{"BPIPE_SCRIPT"},"\.\/bpipe_exome_script.groovy") or die "ERROR: Copy failed for $config_hash{BPIPE_SCRIPT}: $!";
            }
            if (defined ${$individual_input_hash}{VALIDATOR_SCRIPT}) {
            copy(${$individual_input_hash}{"VALIDATOR_SCRIPT"},"\.\/io_validator.pl") or die "ERROR: Copy failed for ${$individual_input_hash}{BPIPE_SCRIPT}: $!";
            }
            else{
            copy($config_hash{"VALIDATOR_SCRIPT"},"\.\/io_validator.pl") or die "ERROR: Copy failed for $config_hash{VALIDATOR_SCRIPT}: $!";
            }
            if (defined ${$individual_input_hash}{DEPENDENCIES_SCRIPT}) {
            copy(${$individual_input_hash}{"DEPENDENCIES_SCRIPT"},"\.\/base_dependencies.groovy") or die "ERROR: Copy failed for ${$individual_input_hash}{BPIPE_SCRIPT}: $!";
            }
            else{
            copy($config_hash{"DEPENDENCIES_SCRIPT"},"\.\/base_dependencies.groovy") or die "ERROR: Copy failed for $config_hash{DEPENDENCIES_SCRIPT}: $!";    
            }
            
            &change_input_file_internal(\%config_hash, $individual_input_hash, "base_dependencies.groovy");
            
            &bpipe_conf_creator(\%config_hash, $individual_input_hash);
            my $diagnostic_dir = getcwd;
            push(@return_arr,$diagnostic_dir.":".${$individual_input_hash}{SAMPLE_NAME});
    }
    return @return_arr;
} 
    
    

# This sub will create the configuration file for bpipe
sub bpipe_conf_creator
{
    my $config_hash_loc_ref = shift;
    my $input_hash = shift;
    my %config_hash_loc = %{$config_hash_loc_ref};
    
    
    if (defined $config_hash_loc{"JOB_SCHEDULER"}) {
          unless(-e "santabanta.config"){
            open(SCHEDULER, ">bpipe.config") or die "Could not make scheduler config\n";}
        else{
            open(SCHEDULER, ">>bpipe.config") or die "Could not make scheduler config\n";}
        print SCHEDULER "executor=\"".$config_hash_loc{"JOB_SCHEDULER"}."\"\n";
        if (defined ${$input_hash}{NODE_RUN}) {
            print SCHEDULER "lsf_request_options=\" -m \'".${$input_hash}{NODE_RUN}."\'\"\n";
        }
        
        if (defined ${$input_hash}{QUEUE_NAME}) {
            print SCHEDULER "lsf_request_options=\" -q \'".${$input_hash}{QUEUE_NAME}."\'\"\n";
        }
        
        close(SCHEDULER);
    }
    
    
    if (defined $config_hash_loc{"NOTIFICATIONS_MAIL"}) {
        
        unless(-e "bpipe.config"){
            open(NOTIFICATIONS, ">bpipe.config") or die "Could not make notifications mail\n";}
        else{
            open(NOTIFICATIONS, ">>bpipe.config") or die "Could not make notifications mail\n";}
        
        print NOTIFICATIONS "notifications \{\n";
        print NOTIFICATIONS "gmail {\n";
        print NOTIFICATIONS "to=\"$config_hash_loc{NOTIFICATIONS_MAIL}\"\n";
        print NOTIFICATIONS "username=\"notificationsbpipe\@gmail\.com\"\n";
        print NOTIFICATIONS "password=\"exomenotifications\"\n";
        if (defined $config_hash_loc{"NOTIFICATIONS_STAGES"}) {
            print NOTIFICATIONS "events=\"$config_hash_loc{NOTIFICATIONS_STAGES}\"";
        }
        else
        {
            print NOTIFICATIONS "events=\"STAGE_COMPLETED,STAGE_FAILED,FINISHED\"";
        }
        print NOTIFICATIONS "\}\n";
        print NOTIFICATIONS "}\n";
        close(NOTIFICATIONS);
    }
    
}


# Internal sub
sub change_input_file_internal
{
    my %config_hash_local = %{$_[0]};
    my $individual_input_hash = $_[1];
    my $filename = $_[2];
    my @dependencies;
    open(DEPENDENCIES_IN, $filename) or die "ERROR: Could not open file $filename for reading: $!\n";
    @dependencies = <DEPENDENCIES_IN>;
    close(DEPENDENCIES_IN);
    open(DEPENDENCIES_OUT, ">$filename") or die "ERROR: Could not open file $filename for writing: $!\n";
    foreach my $line(@dependencies)
    {
        chomp($line);
        #if ($line=~/^(INPUT_FASTQ_FILE_1|INPUT_FASTQ_FILE_2|SAMPLE_NAME|REFERENCE_BWA|REFERENCE_STAMPY|REFERENCE_GATK|DBSNP_VCF_FILE|NO_OF_THREADS)=\"\<\1_NAME\>\"/) {
        if ($line=~/^(INPUT_FASTQ_FILE_1|INPUT_FASTQ_FILE_2|SAMPLE_NAME)=\"\<\1_NAME\>\"/) {
            if (defined ${$individual_input_hash}{"$1"}) {
                print DEPENDENCIES_OUT $1."=\"".${$individual_input_hash}{"$1"}."\"\n";
            }
            #elsif(defined $config_hash_local{"$1"}){
            #    print DEPENDENCIES_OUT $1."=\"".$config_hash_local{"$1"}."\"\n";
            #}
            else{
                print "ERROR $1 is not defined\n";
            }
            
            
        }
        else
        {
            print DEPENDENCIES_OUT "$line\n";
        }
    }
}
    
    
    
# This sub will create changes required in the configuration file for bpipe
sub process_config
{
    #Variables
    my $filename = shift;
    my @config_file_contents;
    my %return_config_hash;
    my @return_input_arr;
    my $alternative_work_dir="$ENV{HOME}/Exome_Pipeline_Run";
    
    
    #Opening the config file
    open(CONFIGFILE,$filename) or die "ERROR: Specified config file doesnt exist";
    {
    local $/="__CONFIGEND__"; #Splitting it by __CONFIGEND__ to seperate config and inputs
    @config_file_contents = <CONFIGFILE>;
    }
    
    #Getting individual configs
    foreach my $ind_conf(split(/\n/,$config_file_contents[0])){
    if($ind_conf!~/^\#/ && $ind_conf=~/(.*?)\=\"(.*)\"/){
        $return_config_hash{$1}=$2;}
    }
    
    #Validation of individual configs
    #Validation of required input files
    unless(defined $return_config_hash{"BPIPE_SCRIPT"} && defined $return_config_hash{"VALIDATOR_SCRIPT"} && $return_config_hash{"DEPENDENCIES_SCRIPT"} && -e $return_config_hash{"BPIPE_SCRIPT"} && -e $return_config_hash{"VALIDATOR_SCRIPT"} && -e $return_config_hash{"DEPENDENCIES_SCRIPT"})
    {
        die "ERROR: Required  params not given\n";
    }
    
    #Validation of work direcotry
    if (defined $return_config_hash{WORK_DIR}) {
        unless (-d $return_config_hash{WORK_DIR}) {
            print "INFO: The specified output direcotry does not exist. Creating one\n";
            `mkdir -p $return_config_hash{WORK_DIR}`;
        }
        print "INFO: Setting the working dir as $return_config_hash{WORK_DIR}\n";
        
    }
    else{
        `mkdir -p $alternative_work_dir`;
         print "INFO: Setting the working dir as $alternative_work_dir\n";
         $return_config_hash{WORK_DIR} =  $alternative_work_dir;
    }
    
    
    #Getting the input details
    foreach my $ind_input(split(/__INPUTEND__/,$config_file_contents[1])){
        my %temp_input_hash;
        foreach my $input_line(split(/\n/,$ind_input))
        {
            if ($input_line!~/^#/ && $input_line=~/(.*?)\=\"(.*)\"/)
            {
                $temp_input_hash{$1}=$2;
            }
        }
        #checking the inputs
        unless(defined $temp_input_hash{"INPUT_FASTQ_FILE_1"} && defined $temp_input_hash{"INPUT_FASTQ_FILE_2"} && $temp_input_hash{"SAMPLE_NAME"} && -e $temp_input_hash{"INPUT_FASTQ_FILE_1"} && -e $temp_input_hash{"INPUT_FASTQ_FILE_2"})
        {
            #warn "Required input for given for the saple  . Skipping it\n";
        }
        else
        {
            push(@return_input_arr, \%temp_input_hash);
        }
    }
    return(\%return_config_hash, \@return_input_arr);
}





sub usage
{
    my $status = shift;
    print <<EndText;
This script will take a wrapper_input.txt file as an input
USAGE:
-i PATH to wrapper input file
-h Help
EndText

if($status == 1)
{
    print "ERROR: The given input file doenst exist or it was not specified\n";
}
exit();
}

