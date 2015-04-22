use strict;
use warnings;
use Cwd qw(abs_path getcwd);
use Getopt::Std;
use File::Copy;
use File::Basename;

#Processing of commandline options
my %opts=();

getopts('i:o:j:m:q:h', \%opts);
if(defined $opts{'h'}) {&usage(0);}
unless(defined $opts{'i'} && -d $opts{'i'}){&usage(1);}
unless(defined $opts{'j'}){ &usage(2);}
unless(defined $opts{'o'}){ &usage(3);}


my $current_wd = getcwd;
my $script_location = &get_pipeline_executor_path;

$opts{'i'}=~s/^\.\//$current_wd\//;
$opts{'o'}=~s/^\.\//$current_wd\//;
$script_location=~s/^\./$current_wd\//;
$opts{'i'}=~s/\/$//;
$opts{'o'}=~s/\/$//;
print "INFO: Input directory is $opts{'i'}\n";
print "INFO: Output directory is $opts{'o'}\n";
print "INFO: Jobname is $opts{'j'}\n";

unless(-d $opts{'o'})
{
    `mkdir -p $opts{'o'}`;
}

chdir($opts{'i'});
`find \`pwd\` -name "*_aligned_sorted_dupmarked_realigned_recalibrated.bam" > $opts{'o'}\/$opts{'j'}_bam_locations.txt`;
chdir($current_wd);

chdir($opts{'o'});

if (defined $opts{'m'} && ($opts{'m'} eq "lsf" || $opts{'m'} eq "sge")) {
    open(BPIPE_CONFIG, ">", "bpipe.config") or die "ERROR: Could not write bpipe config\n";
    print BPIPE_CONFIG "executor=\"$opts{'m'}\"\n";
    if (defined $opts{'q'}) {
        print BPIPE_CONFIG "queue=\"$opts{'q'}\"\n";
    }
   close(BPIPE_CONFIG);
}

copy("${script_location}\/config\/variant_caller.groovy", $opts{'o'}."\/"."variant_caller.groovy") or die "ERROR: Could not copy caller\n";
copy("${script_location}\/config\/variant_caller_dependencies.groovy", $opts{'o'}."\/"."variant_caller_dependencies.groovy") or die "ERROR: Could not copy dependencies\n";
`nohup $script_location\/bin\/bpipe-0.9.8.4.1\/bin\/bpipe run -r -p path_locations_file\=$opts{'j'}_bam_locations.txt variant_caller.groovy > $opts{'j'}_Log_Txt 2>&1 &`;
chdir($current_wd);


sub get_pipeline_executor_path
{
    my $script_dir = undef;
    if(-l __FILE__) {
      $script_dir = dirname(abs_path(readlink(__FILE__)));
    }
    else {
      $script_dir = dirname(abs_path(__FILE__));
    }
    return $script_dir;
}

sub usage
{
    my $status = shift;
    print <<EndText;
This script will call variants for a run completed till BAM generation
USAGE:
-i Directory containing the previous run/ BAM file( suffix is assumed to be _aligned_sorted_dupmarked_realigned_recalibrated.bam)
-o Directory to store the results
-m Execute in multi node environment give executor as argument(Eg -m lsf/ -m sge)
-q The queue name in case of multi node environment
-j Jobname
EndText

if($status == 1)
{
    print "ERROR: The given input directory doenst exist or it was not specified\n";
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