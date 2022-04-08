#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

printf STDOUT "Readname\tpct_id\tpct_cov\tedit_dist\taln_len_read\n";

my %mapped_id = ();

# STDIN: sam

while (<>) {
	if (m/^@/) {
		print $_;
		next;
	}
	chomp;
	my $line = $_;
	my @F = split/\t/, $line;
	my $cigar = $F[5];
	if ($cigar eq "*") {
		next;
	}
	my $num_inserted = 0;
	while ($cigar =~ m/(\d+)I/g) {
		$num_inserted += $1;
	}
	my $num_deleted = 0;
	while ($cigar =~ m/(\d+)D/g) {
		$num_deleted += $1;
	}
	my $num_matched = 0;
	while ($cigar =~ m/(\d+)M/g) {
		$num_matched += $1;
	}
	my $num_clipped = 0;
	while ($cigar =~ m/(\d+)[SH]/g) {
		$num_clipped += $1;
	}
	my $edit_dist = "";
	for (my $i=11; $i<=$#F; $i++) {
		if ($F[$i] =~ m/NM:i:(\d+)/) {
			$edit_dist = $1;
			last;
		}
	}

	my $read_len = $num_matched + $num_inserted + $num_clipped;

	my $pct_cov = ($num_matched + $num_inserted)*100/$read_len;
	my $pct_id = 100 - $edit_dist*100/($num_matched + $num_inserted);

    printf STDOUT "%s\t%.1f\t%.1f\t%d\t%d\n", $F[0], $pct_id, $pct_cov, $edit_dist, $num_matched+$num_inserted;
}





