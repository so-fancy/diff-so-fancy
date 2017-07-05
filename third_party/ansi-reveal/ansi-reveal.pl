#!/usr/bin/env perl

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
		$l =~ s/(\e\[.*?m)/dump_ansi($1)/eg;

		## Basic reset
		#$l =~ s/(\e\[0?m)/${reset}[RESET]/g;

		## Bold text
		#$l =~ s/(\e\[1m)/${reset}[BOLD]/g;

		## Inverted text
		#$l =~ s/(\e\[7m)/${reset}. "[INVRT]$1"/eg;
		#$l =~ s/(\e\[7;(\d+)m)/${reset}. "[INVRT" . sprintf("%03d",($2-30)) . "]$1"/eg;

		## Basic 16 color ANSI
		##$l =~ s/(\e\[(3[0-7])m)/${reset}. "[BASIC" . sprintf("%03d",($2-30)) . "]$1"/eg;
		#$l =~ s/(\e\[(3[0-7])m)/dump_ansi($1)/eg;
		##$l =~ s/(\e\[1;(3[0-7])m)/${reset}. "[BRIGH" . sprintf("%03d",($2-30)) . "]$1"/eg;
		#$l =~ s/(\e\[1;(3[0-7])m)/dump_ansi($1)/eg;

		## 256 Color/Background
		#$l =~ s/(\e\[38;0?5;(\d+)m)/${reset}. "[COLOR" . sprintf("%03d",$2) . "]$1"/eg;
		#$l =~ s/(\e\[48;0?5;(\d+)m)/${reset}. "[BACKG" . sprintf("%03d",$2) . "]$1"/eg;

		#$l =~ s/(\e\[1;(3[0-7]);48;5;(\d+)m)/${reset}. "[FGBG" . sprintf("%02d:%02d",($2-30),($3)) . "]$1"/eg;
		#$l =~ s/(\e\[1;38;5;(.*?)m)/${reset} . dump_ansi($1) . "$1"/eg;

		## 24bit Color/Background
		#$l =~ s/(\e\[38;2;(\d+);(\d+);(\d+)m)/${reset} . sprintf("[RGB#%02X%02X%02X",$2,$3,$4) . "]$1"/eg;
		#$l =~ s/(\e\[48;2;(\d+);(\d+);(\d+)m)/${reset} . sprintf("[RGBBG#%02X%02X%02X",$2,$3,$4) . "]$1"/eg;

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

sub dump_ansi {
	my $str   = shift();
	if ($str !~ /^\e/) {
		return "";
	}

	my $raw   = $str;
	my $human = $str =~ s/\e/ESC/rg;

	# Remove the ANSI control chars, we just want the payload
	$str =~ s/^\e\[//g;
	$str =~ s/m$//g;

	# Make the [HUMAN] text reset and white to make it easier to see
	my $ret  = "\e[0m";
	$ret    .= "\e[38;5;15m";

	my @parts = split(";",$str);

	#k(\@parts);

	my @basic_mapping = qw(BLACK RED GREEN YELLW BLUE MAGNT CYAN WHITE);

	if (!@parts) {
		$ret .= "[RESET]";
	}

	for (my $count = 0; $count < @parts; $count++) {
		my $p = $parts[$count];

		#print "[$count = '$p']\n";
		if ($p eq "1") {
			$ret .= "[BOLD]";
		} elsif ($p eq "0" || $p eq "") {
			$ret .= "[RESET]";
		} elsif ($p eq "38") {
			my $next  = $parts[$count + 1];
			my $color = $parts[$count + 2];

			$count += 2;

			$ret .= sprintf("[COLOR%03d]",$color);
		} elsif ($p eq "48") {
			my $next  = $parts[++$count];
			my $color = $parts[++$count];

			$count += 2;

			$ret .= sprintf("[BACKG%03d]",$color);
		} elsif ($p >= 30 and $p <= 37) {
			my $color = $p - 30;
			$color = $basic_mapping[$color];
			$ret .= "[$color]";
			#$ret .= sprintf("[BASIC%03d]",$color);
		} else {
			$ret .= "[UKN: $p]";
		}
	}

	# Append the ANSI color string to end of the human readable one
	$ret .= $raw;

	return $ret;
}

BEGIN {
	if (eval { require Data::Dump::Color }) {
		*k = sub { Data::Dump::Color::dd($_[0]) };
	} else {
		require Data::Dumper;
		*k = sub { print Data::Dumper::Dumper($_[0]) };
	}
}

# vim: tabstop=4 shiftwidth=4 autoindent softtabstop=4
