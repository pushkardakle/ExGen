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

# This script will create the input file for the pipeline_run.pl file


use strict;
use warnings;
use Cwd;
use File::Basename;
my $main_dir = getcwd;
my $work_dir=$ARGV[0];

unless(defined $work_dir)
{
    print "The input dir is not specified...Exiting\n";
    die "USAGE: input_file_maker.pl <DIR_NAME>\n";
}

chomp($work_dir);
my $filename = basename($work_dir)."_input.txt";
print "$filename\n";
open(OUTPUT,">$main_dir\/$filename") or die "Cannot make output file\n$!\n";

chdir($work_dir);
my $dirforprint=getcwd;
my @files=<*>;

foreach(@files){print "$_\n";}

foreach my $filename(@files)
{
    if ($filename=~/(.*?)1.fastq/) {
        
        my $filesuffix=$1;
        print OUTPUT "INPUT\n";
        print OUTPUT "{\n";
        print OUTPUT "INPUT_FASTQ_FILE_1\=\"${work_dir}\/${filesuffix}1.fastq\"\n";
        print OUTPUT "INPUT_FASTQ_FILE_2\=\"${work_dir}\/${filesuffix}2.fastq\"\n";
        $filesuffix=~s/_R$//;
        print OUTPUT "SAMPLE_NAME\=\"$filesuffix\"\n";
        print OUTPUT "QUEUE_NAME=\"smp\"\n";
        print OUTPUT "\}\n";
        print OUTPUT "__INPUTEND__\n";
    }
}
close(OUTPUT);