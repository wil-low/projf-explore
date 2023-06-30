#!/usr/bin/perl

use strict;
use warnings;

open (INF, "$ARGV[0]") or die "$!: $ARGV[0]";

my $row_counter = 0;
my $matrix = '';

while (my $line = <INF>) {
	$line =~ s/[\n\r]//g;
	if ($line =~ /^(\d{8})$/) {
		$matrix .= $line;
		++$row_counter;
		if ($row_counter == 8) {
			#die $matrix;
			#for (my $j = 0; $j < 8; ++$j) {
			#	for (my $i = 0; $i < 8; ++$i) {
			#		print substr($matrix, $i + $j * 8, 1);
			#	}
			#	print "\n";
			#}
			for (my $i = 7; $i >= 0; --$i) {
				for (my $j = 0; $j < 8; ++$j) {
					print substr($matrix, $i + $j * 8, 1);
				}
				print "\n";
			}
			$row_counter = 0;
			$matrix = '';
		}
	}
	else {
		print "$line\n";
	}
}
close(INF);
