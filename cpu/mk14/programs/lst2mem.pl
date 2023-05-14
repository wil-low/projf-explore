#!/usr/bin/perl

use strict;
use warnings;

my ($lst, $mem) = @ARGV;

die "Usage:\n    perl lst2mem.pl file.lst file.mem\n" if !defined($mem);

open (INF, "<$lst") or die "$!: $lst";
open (OUTF, ">$mem") or die "$!: $lst";

my $code_started = 0;

while (my $line = <INF>) {
	$line =~ s/[\n\r]//sg;
	if ($line =~ /^[0-9A-F]{4}\-[0-9A-F]/) {
		$code_started = 1;
	}
	if ($code_started) {
		if ($line !~ s/^([0-9A-F]{4}\-|     )(.{11})/$2  \/\/ $1  /s) {
			$line = "//                " . $line;
		}
	}
	else {
		$line = "//              " . $line;
	}
	print (OUTF "$line\n");
}

close (OUTF);
close (INF);
