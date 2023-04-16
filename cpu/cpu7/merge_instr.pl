#!/usr/bin/perl

use strict;
use warnings;

my ($instr0, $instr1) = @ARGV;

die "Usage:\n    perl merge_instr.pl <instr0> <instr1>\n" if !defined($instr1);

my $hex0 = hex($instr0);
my $hex1 = hex($instr1);

my $packed = ($hex1 << 7) + $hex0;
my $packed_hex = sprintf("%04x", $packed);

die "$instr0 + $instr1 = $packed_hex";
