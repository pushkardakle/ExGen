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

# This script will launch the ExGen pipeline for a given set of samples. This is for the first phase of analysis
# i.e. upto a realigned and recalibrated BAM file. Post this the user can use the variant_calling.pl script to do 
# call variants for all the analysed samples

use strict;
use warnings;
use Getopt::Std;
use File::Basename;
use Cwd;

# Processing of commandline options
my %opts=();
getopt('i:o:j:m:h', \%opts);
if (defined $opts{'h'}) { &usage(0);}
unless(defined $opts{'i'} && -d $opts{'i'}){ &usage(1);}
unless(defined $opts{'j'}){ &usage(2);}
unless(defined $opts{'o'}){ &usage(3);}



my $current_wd = getcwd;

# Cleaning up the paths
$opts{'i'}=~s/^\.\//$current_wd\//;
$opts{'o'}=~s/^\.\//$current_wd\//;

my $dirbasename = basename($opts{'i'});
my $script_location = &get_pipeline_executor_path;

print "INFO: Input directory is $opts{'i'}\n";
print "INFO: Output directory is $opts{'o'}\n";
print "INFO: Jobname is $opts{'j'}\n";

# Create the pipeline input file
`perl $script_location/bin/scripts/input_file_maker.pl $opts{'i'}`;


open(CONFIG, "<", "$script_location/templates/Input_template.txt") or die "ERROR: could not open the input template file at $script_location/templates/Input_template.txt";
open(OUTPUT, ">", "./$opts{'j'}_Input_Config.txt") or die "ERROR: Could not create job input file at ./$opts{'j'}_Input.txt";

# Configure bpipe for the run
foreach my $config_line(<CONFIG>){
    chomp($config_line);
    if ($config_line=~/WORK_DIR\=\"\{OUTPUT_DIR\}\"/){
        $config_line=~s/\{OUTPUT_DIR\}/$opts{'o'}/;
        print OUTPUT $config_line."\n";
    }
    elsif ($config_line=~/SLEEP_TIME/ && defined $opts{'m'}) {
        print OUTPUT $config_line."\nJOB_SCHEDULER=\"$opts{'m'}\"\n";
        print "INFO: Running in multi node mode with $opts{'m'} as job scheduler\n";
    }
    elsif($config_line=~/\{DIRNAME\}/){
        $config_line=~s/\{DIRNAME\}/$current_wd/;
        print OUTPUT $config_line."\n";
    }
    else{
        print OUTPUT $config_line."\n";
    }
}
`cat ./$opts{'j'}_Input_Config.txt ${dirbasename}_input.txt > ./$opts{'j'}_Input.txt`;

# Delete temporary files
unlink("./$opts{'j'}_Input_Config.txt");
unlink("${dirbasename}_input.txt");

# Lauch the runs
`nohup perl $script_location\/bin/scripts/pipeline_run.pl -i ${current_wd}\/$opts{'j'}_Input.txt > $opts{'j'}_Log_Txt 2>&1 &`;
print "INFO: Launched the runs. Please monitor $opts{'j'}_Log_Txt for status updates on the run\nThank you\n";

# Get the path where the current script is located
sub get_pipeline_executor_path
{
    my $script_dir = undef;
    if(-l __FILE__) {
      $script_dir = dirname(readlink(__FILE__));
    }
    else {
      $script_dir = dirname(__FILE__);
    }
    return $script_dir;
}


sub usage
{
    my $status = shift;
    print <<EndText;
This script will execute the Exome Analysis Pipeline
USAGE:
-i Directory containing the input fastq files
-o Directory to store the results
-m Execute in multi node environment give executor as argument(Eg -m lsf/ -m sge)
-j Jobname
EndText

if($status == 1)
{
    print "ERROR: The given input file doenst exist or it was not specified\n";
}
if($status == 2)
{
    print "ERROR: A jobname was not specified\n";
}
if($status == 3)
{
    print "ERROR: An output directory was not specified\n";
}
exit();
}