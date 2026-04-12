#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

my $raw   = 0;
my $plain = $ENV{AR_PLAIN} || 0;
GetOptions(
	'raw'   => \$raw,
	'plain' => \$plain,
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

		if ($plain) {
			$l = bleach_text($l);
		}

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
		} elsif ($p eq "2") {
			$ret .= "[DIM]";
		} elsif ($p eq "3") {
			$ret .= "[ITALIC]";
		} elsif ($p eq "4") {
			$ret .= "[UNDERLINE]";
		} elsif ($p eq "5") {
			$ret .= "[BLINK]";
		} elsif ($p eq "7") {
			$ret .= "[REVERSE]";
		} elsif ($p eq "27") {
			$ret .= "[NOTREV]";
		# Foreground color
		} elsif ($p eq "38") { # Foreground either 8 or 24bit
			my $next  = $parts[$count + 1]; # 5 = 8bit, 2 = 24bit

			if ($next == 5) {
				my $color  = $parts[$count + 2];
				$count    += 2;

				$ret .= sprintf("[COLOR%03d]",$color);
			} elsif ($next == 2) {
				my $red    = $parts[$count + 2];
				my $green  = $parts[$count + 3];
				my $blue   = $parts[$count + 4];
				$count    += 4;

				$ret .= sprintf("[COLOR(%d,%d,%d)]", $red, $green, $blue);
			} else {
				$ret .= sprintf("[COLOR???]");
			}
		# Background color
		} elsif ($p eq "48") { # Background either 8 or 24bit
			my $next = $parts[$count + 1]; # 5 = 8bit, 2 = 24bit

			if ($next == 5) {
				my $color  = $parts[$count + 2];
				$count    += 2;

				$ret .= sprintf("[BACKG%03d]",$color);
			} elsif ($next == 2) {
				my $red    = $parts[$count + 2];
				my $green  = $parts[$count + 3];
				my $blue   = $parts[$count + 4];
				$count    += 4;

				$ret .= sprintf("[BACKG(%d,%d,%d)]", $red, $green, $blue);
			} else {
				$ret .= sprintf("[BACKG???]");
			}
		# Basic foreground colors
		} elsif ($p >= 30 and $p <= 37) {
			my $color = $p - 30;
			$color = $basic_mapping[$color];
			$ret .= "[$color]";
		# Basic background colors
		} elsif ($p >= 40 and $p <= 47) {
			my $color = $p - 40;
			$color = $basic_mapping[$color];
			$ret .= "[BG-$color]";
		# Basic bright foreground colors
		} elsif ($p >= 90 and $p <= 97) {
			my $color = $p - 90;
			$color = $basic_mapping[$color];
			$ret .= "[BRT-$color]";
		# Basic bright background colors
		} elsif ($p >= 100 and $p <= 107) {
			my $color = $p - 100;
			$color = $basic_mapping[$color];
			$ret .= "[BRTBG-$color]";
		} else {
			$ret .= "[UKN: $p]";
		}
	}

	# Append the ANSI color string to end of the human readable one
	$ret .= $raw;

	return $ret;
}

# Remove all ANSI codes from a string
sub bleach_text {
	my $str = shift();
	$str    =~ s/\e\[\d*(;\d+)*m//mg;

	return $str;
}

# Creates methods k() and kd() to print, and print & die respectively
BEGIN {
    if (!defined(&trim)) {
        *trim = sub {
            my ($s) = (@_, $_); # Passed in var, or default to $_
            if (length($s) == 0) { return ""; }
            $s =~ s/^\s*//;
            $s =~ s/\s*$//;

            return $s;
        }
    }

    if (eval { require Dump::Krumo }) {
        Dump::Krumo->import(qw/k kd/);
    } else {
        require Data::Dumper;
        *k  = sub { print Data::Dumper::Dumper(\@_) };
        *kd = sub { print Data::Dumper::Dumper(\@_); die; };
    }
}

# vim: tabstop=4 shiftwidth=4 autoindent softtabstop=4
