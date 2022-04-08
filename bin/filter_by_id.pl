#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $include_file = "";
my $fastq_file_in = "";
my $fastq_file_out = "";

my $excluding = 0;

GetOptions(
	'include=s' => \$include_file,
    'v' => \$excluding,
)
or print_usage();

sub print_usage
{
	print "USAGE: $0 -include=[file_containing_read_names_being_included]\n";
	exit();
}

my %read = ();	# read names for filtering out

open(my $fh, "<", "$include_file") or die "Can't open: $!";
while(<$fh>) {
	chomp;
	$read{$_} = 1;
}
close($fh);

while (<>) {
	chomp;
	my $name_line = $_;
	my $seq = <>;
	my $plus = <>;
	my $qual = <>;
	
	$name_line =~ m/^@([^ ]+)/;
	my $name = $1;
    if ($excluding) {
    	if (!exists($read{$name})) {
	    	print "$name_line\n" . $seq . $plus . $qual;
    	}
    } else {
        if (exists($read{$name})) {
	    	print "$name_line\n" . $seq . $plus . $qual;
        }
    }
}

