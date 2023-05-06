#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

my ($program_file, $constants_file) = @ARGV;

my %instr;
my %alias;
open (INF, "<$constants_file") or die "$!: $constants_file";
while (my $line = <INF>) {
	$line =~ s/[\r\n]//sg;
	if ($line =~ /`define\s+i_(\S+)\s(?:'h)?([0-9a-fA-F]+)/) {
		my $val = hex($2);
		$instr{$1} = $val;
		if ($line =~ /alias: (\S+)/) {
			$alias{$1} = $val;
		}
	}
}
close (INF);

#make_opcode2str();

$instr{';'} = $instr{RETURN};  # alias for RETURN

force('NOP');	# NOP forced (for alignment)
force('SKIP');	# SKIP forced (for inline strings)
force('DO');	# DO forced (for inline strings)

$instr{'S"'} = '';

%instr = (%instr, %alias);

#print Dumper(\%instr);

my @token;  # array of array refs, 0-th element is the type: 0 - ordinary token, 1 - string token (item contains token+string)
my $line_backup = '';

open (INF, "<$program_file") or die "$!: $program_file";
while (my $line = <INF>) {
	$line =~ s/[\r\n]//sg;
	$line_backup = $line;
	$line =~ s/`!.+//sg;  # remove comment
	while ($line =~ s/\s*(\S+)\s*//s) {
		my $t = $1;
		if (is_string_token($t)) {
			if ($line =~ s/([^"].+?)"//s) {
				push(@token, [1, $t, $1]);
			}
			else {
				die "String not terminated at line \n$line_backup\n";
			}
		}
		else {
			push(@token, [0, $t]);
		}
	}
}
close (INF);

#print Dumper(\@token);

my $MASK14 = 0x7fff;
my $OVER14 = 0x00ffffffffffc000;
my $OVER28 = 0x00fffffff0000000;

my $VLN_NOT_LAST = 0x4000;
my $VLN_LAST = 0x8000;

my $instr_idx = 0;
my $instr_word = 0;
my $comment = '';

my $addr = 0;
my $addr_save = $addr;

my %label;
my $insert_str = 0;

foreach my $orig_tok (@token) {
	#print "token: '$tok'\n";
	add_token($orig_tok);
}
check_add_nopf();

print "\n\n// === Labels ===\n";
foreach my $key (sort(keys(%label))) {
	print "// .$key => $label{$key}\n";
}

warn Dumper(\%label);

sub add_token {  # token
	my $array_ref = shift;
	my ($type, $orig_tok, $str) = @$array_ref;
	$str = '' if !defined($str);
	my $tok = uc($orig_tok);
	if ($type == 1) {
		if (defined($instr{$tok})) {
			my $len = length($str);
			my $aligned_len = $len;
			++$aligned_len if $len % 2;
			add_token([0, $aligned_len]);
			add_token([0, "(SKIP)"]);
			check_add_nopf();
			my $saved_addr = $addr;
			add_string($tok, $str);
			add_token([0, "(DO)"]);
			add_token([0, $saved_addr]);
			add_token([0, $len]);
		}
		else {
			die "Unknown string token '$orig_tok' at line\n$line_backup\n";
		}
	}
	elsif (defined($instr{$tok})) {
		check_align_before($tok);
		$instr_word += $instr_idx ? $instr{$tok} << 7 : $instr{$tok};
		$comment .= "$orig_tok $str";
		$addr++;
		if ($instr_idx) {
			print sprintf("%04x  // %06d: %s\n", $instr_word, $addr_save, $comment);
			$addr_save = $addr;
			$instr_word = 0;
			$comment = '';
		}
		$instr_idx = 1 - $instr_idx;
		check_align_after($tok);
	}
	elsif ($tok =~ /^[\d\+\-]+$/) {  # base 10
		check_add_nopf();
		add_number($tok, $tok);
	}
	elsif ($tok =~ /(\.|:|_\!?|\&\!?)(.+)/) {
		my $label_op = $1;
		$tok = $2;
		if ($label_op eq ':') {
			check_add_nopf();
			# label definition
			$label{$tok} = $addr;
		}
		elsif (defined($label{$tok})) {
			if ($label_op eq '.') {
				check_add_nopf();
				add_number($label{$tok}, $orig_tok);
			}
			else {
				if ($label_op eq '_') {
					add_offset($tok, $orig_tok);
					add_token([0, 'CALL']);
				}
				elsif ($label_op eq '_!') {
					add_offset($tok, $orig_tok);
					add_token([0, 'NTCALL']);
				}
				elsif ($label_op eq '&') {
					add_token(".$tok", $orig_tok);
					add_token([0, 'ACALL']);
				}
				elsif ($label_op eq '&!') {
					add_token(".$tok", $orig_tok);
					add_token([0, 'NTACALL']);
				}
			}
		}
		else {
			warn "label_op '$label_op' for unknown label '$tok'";
		}
	}
	else {
		die "Unknown token '$orig_tok' at line\n$line_backup\n";
	}
}

sub check_align_before {
	my $tok = shift;
	if ($tok =~ /(REPEAT|REPIF)/) {
		check_add_nopf();
	}
}

sub check_align_after {
	my $tok = shift;
	if ($tok =~ /(REPEAT|REPIF|CALL)/) {
		check_add_nopf();
	}
}

sub add_offset {  # number, orig_tok
	my ($tok, $orig_tok) = @_;
	check_add_nopf();
	my $offset = $addr - $label{$tok};
	my $len = vln_len($offset + 8 + 2); # forecast for max length
	my $result = $offset + $len + 2;
	warn("add_offset $offset for tok '$tok', orig_tok '$orig_tok', addr $addr, label addr $label{$tok}, len $len -> $result\n");
	add_number($result, $orig_tok);
}

sub add_number {  # number, orig_tok
	my ($tok, $orig_tok) = @_;
	my $vln = vln_str($tok);
	$addr += vln_len($tok);
	print sprintf("%s // %06d: %s\n", $vln, $addr_save, $orig_tok);
	$addr_save = $addr;
}

sub add_string {  # orig_tok, string
	my ($orig_tok, $str) = @_;
	my $len = length($str);
	for (my $i = 0; $i < $len; ++$i) {
		print sprintf("%x", ord(substr($str, $i, 1)));
		if ($i % 2) {
			print ' ';
		}
	}
	if ($len % 2) {
		print '00 ';
		++$addr;
	}
	print sprintf(" // %06d: %s %s\"\n", $addr_save, $orig_tok, $str);
	$addr += $len;
	$addr_save = $addr;
}

sub check_add_nopf {
	if ($instr_idx) {
		add_token([0, '(NOP)']);
	}
}

sub vln_len {  # number => len
	my $n = $_[0];
	my $len = 0;
	if (($n & $OVER14) == 0) {  # use 14-bit constant
		$len = 2;
	}
	elsif (($n & $OVER28) == 0) {  # use 28-bit constant
		$len = 4;
	}
	else {  # use 56-bit constant
		$len = 8;
	}
	return $len;
}

sub vln_str {  # number
	my $n = $_[0];
	my $result = '';
	if (($n & $OVER14) == 0) {  # use 14-bit constant
		$result = sprintf("%04x ", ($n & $MASK14) | $VLN_LAST);
	}
	elsif (($n & $OVER28) == 0) {  # use 28-bit constant
		$result = sprintf("%04x ", ($n & $MASK14) | $VLN_NOT_LAST);
		$result .= sprintf("%04x ", (($n >> 14) & $MASK14) | $VLN_LAST);
	}
	else {  # use 56-bit constant
		$result = sprintf("%04x ", ($n & $MASK14) | $VLN_NOT_LAST);
		$result .= sprintf("%04x ", (($n >> 14) & $MASK14) | $VLN_NOT_LAST);
		$result .= sprintf("%04x ", (($n >> 28) & $MASK14) | $VLN_NOT_LAST);
		$result .= sprintf("%04x ", (($n >> 42) & $MASK14) | $VLN_LAST);
	}
	return $result;
}

sub make_opcode2str {
	my $text = << 'EOF';
function string opcode2str (input logic [6:0] opcode);
begin
	case (opcode)
EOF
	print $text;

	foreach my $key (sort(keys(%instr))) {
		print sprintf("\t`i_%-16s: opcode2str = \"%s\";\n", $key, $key);
	}
	print sprintf("\t%-19s: opcode2str = \"%s\";\n", 'default', '???');

	$text = << 'EOF';
	endcase
end
endfunction
EOF
	print $text;
	die;
}

sub is_string_token {
	return $_[0] =~ /^(S")$/;
}

sub force {
	my $token = shift;
	$instr{"($token)"} = $instr{$token};
}
