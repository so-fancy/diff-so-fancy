#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $raw = 0;
GetOptions(
	'raw' => \$raw,
);

if ($raw) {
	output_raw();
} else {
	output_human();
}

###############################################

sub output_human {
	my $reset = "\e[0m";

	while (my $l = <>) {
		# Basic reset
		$l =~ s/(\e\[0?m)/${reset}[RESET]/g;

		# Bold text
		$l =~ s/(\e\[1m)/${reset}[BOLD]/g;

		# Inverted text
		$l =~ s/(\e\[7m)/${reset}. "[INVRT]$1"/eg;
		$l =~ s/(\e\[7;(\d+)m)/${reset}. "[INVRT" . sprintf("%03d",($2-30)) . "]$1"/eg;

		# Basic 16 color ANSI
		$l =~ s/(\e\[(3[0-7])m)/${reset}. "[BASIC" . sprintf("%03d",($2-30)) . "]$1"/eg;
		$l =~ s/(\e\[1;(3[0-7])m)/${reset}. "[BRIGH" . sprintf("%03d",($2-30)) . "]$1"/eg;

		# 256 Color/Background
		$l =~ s/(\e\[38;0?5;(\d+)m)/${reset}. "[COLOR" . sprintf("%03d",$2) . "]$1"/eg;
		$l =~ s/(\e\[48;0?5;(\d+)m)/${reset}. "[BACKG" . sprintf("%03d",$2) . "]$1"/eg;

		$l =~ s/(\e\[1;(3[0-7]);48;5;(\d+)m)/${reset}. "[FGBG" . sprintf("%02d:%02d",($2-30),($3)) . "]$1"/eg;

		# 24bit Color/Background
		$l =~ s/(\e\[38;2;(\d+);(\d+);(\d+)m)/${reset} . sprintf("[RGB#%02X%02X%02X",$2,$3,$4) . "]$1"/eg;
		$l =~ s/(\e\[48;2;(\d+);(\d+);(\d+)m)/${reset} . sprintf("[RGBBG#%02X%02X%02X",$2,$3,$4) . "]$1"/eg;

		print $l;
	}
}

###############################################

sub output_raw {
	while (<>) {
		s/\e/\\e/g;
		print;
	}
}
