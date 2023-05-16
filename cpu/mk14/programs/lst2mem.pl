#!/usr/bin/perl

use strict;
use warnings;

my ($lst) = @ARGV;

die "Usage:\n    perl lst2mem.pl file.lst\n" if !defined($lst);

open (INF, "<$lst") or die "$!: $lst";

my $mem = $lst;
$mem =~ s/\.\w+$/.mem/;
open (OUTF, ">$mem") or die "$!: $lst";

my $code_started = 0;
my $rf_start = '';
my $rf_end = '';

while (my $line = <INF>) {
	$line =~ s/[\n\r]//sg;
	if ($line =~ /^[0-9A-F]{4}\-[0-9A-F]/) {
		$code_started = 1;
	}
	if ($code_started) {
		if ($line =~ /^([0-9A-F]{4}).+?\s\.[rR][fF]\s/) {
			$rf_start = $1;
			#warn $rf_start;
		}
		if ($rf_start and $line =~ /^([0-9A-F]{4})/) {
			if ($1 ne $rf_start) {
				$rf_end = $1;
				#warn $rf_end;
				my $start = hex($rf_start);
				my $len = hex($rf_end) - hex($rf_start);
				my $i = 0;
				for (; $i < int($len / 4); ++$i) {
					print (OUTF sprintf("00 00 00 00  // %04X-                                  (zero fill)\n", $start + $i * 4));
				}
				if ($len % 4) {
					print (OUTF ("00 " x ($len % 4)));
					print (OUTF ("   " x (4 - $len % 4)) . sprintf(" // %04X-                                  (zero fill)\n", $start + $i * 4));
				}
				$rf_start = ''; $rf_end = '';
			}
		}
		if ($line =~ /^([0-9A-F]{4}\-|     )(.{11})(.+)/) {
			print (OUTF "$2  \/\/ $1  $3\n");
		}
		else {
			print (OUTF "//                $line\n");
		}
	}
	else {
		print (OUTF "//              $line\n");
	}
}

close (OUTF);
close (INF);
