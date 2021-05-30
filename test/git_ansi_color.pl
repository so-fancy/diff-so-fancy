#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

###############################################################################
###############################################################################

compare_color("\e[1;91m"               , git_ansi_color("brightred bold")    , "brightred bold");
compare_color("\e[1;31m"               , git_ansi_color("red bold")          , "red bold");
compare_color("\e[1;32m"               , git_ansi_color("green bold")        , "green bold");
compare_color("\e[33m"                 , git_ansi_color("yellow")            , "yellow");
compare_color("\e[1;7;32m"             , git_ansi_color("green bold reverse"), "green bold reverse");
compare_color("\e[1;35m"               , git_ansi_color("magenta bold")      , "magenta bold");
compare_color("\e[1;38;5;146m"         , git_ansi_color("146 bold")          , "146 bold");
compare_color("\e[1;38;5;146;48;5;22m" , git_ansi_color("146 bold 22")       , "146 bold 22");
compare_color("\e[1;34;40m"            , git_ansi_color("blue black bold")   , "blue black gold");
compare_color("\e[93m"                 , git_ansi_color("11")                , "11");
compare_color("\e[7;31m"               , git_ansi_color("red reverse")       , "red reverse");
compare_color("\e[1;31;48;5;52m"       , git_ansi_color("red bold 52")       , "red bold 52");
compare_color("\e[92;48;5;20m"         , git_ansi_color("10 20")             , "10 20");
compare_color("\e[30;47m"              , git_ansi_color("0 7")               , "0 7");
compare_color("\e[94;105m"             , git_ansi_color("12 13")             , "12 13");
compare_color("\e[1;38;5;254;48;5;255m", git_ansi_color("254 bold 255")      , "254 bold 255");
compare_color("\e[1;38;5;238;42m"      , git_ansi_color("238 bold green")    , "238 bold green");
compare_color("\e[1;38;5;238;42m"      , git_ansi_color("238 green bold")    , "238 green bold");

###############################################################################
###############################################################################

sub compare_color {
	my ($one, $two, $desc) = @_;

	if ($one ne $two) {
		#k($one, $two);
		#printf("No match for %-20s %s / %s\n", $desc, ansi_to_human($one), ansi_to_human($two));
		printf("%-20s %sFAIL%s  %s ne %s\n", $desc, color('red'), color(), ansi_to_human($one), ansi_to_human($two));
	} else {
		printf("%-20s %sOK%s\n", $desc, color('green'), color());
	}
}

# Convert an ANSI sequence to something printable
sub ansi_to_human {
	my $str = shift();

	$str =~ s/\e\[/[/g;
	$str =~ s/m\b/]/g;

	return $str;
}

# Alternate (unused) method to parse git config colors
sub git_ansi_color2 {
	my $str   = shift();
	my @parts = split(' ', $str);

	if (!@parts) {
		return '';
	}

	my %map = qw(
		black 30 red 31 green 32 yellow 33 blue 34 magenta 35 cyan 36 white 37
		bold 1 reverse 7
	);

	k(\@parts);

	my @ret;
	my $first = 1;
	foreach my $item (@parts) {
		my $val = $map{$item};

		if (!$val) {
			if (!$first && $item > 10) {
				$val = $item + 10;
			}
			push(@ret, (38,5,$val));
		} else {
			# Background color
			if (!$first && $val > 10) {
				$val += 10;
				$first = 0;
			}
			push(@ret, $val);
		}

		if ($val > 10) {
			$first = 0;
		}
	}

	my $ret = "\e[" . join(";", @ret) . "m";

	print ansi_to_human($ret);

	return $ret;
}

# https://www.git-scm.com/book/en/v2/Customizing-Git-Git-Configuration#_colors_in_git
sub git_ansi_color {
	my $str   = shift();
	my @parts = split(' ', $str);

	if (!@parts) {
		return '';
	}
	my $colors = {
		'black'   => 0,
		'red'     => 1,
		'green'   => 2,
		'yellow'  => 3,
		'blue'    => 4,
		'magenta' => 5,
		'cyan'    => 6,
		'white'   => 7,
	};

	my @ansi_part = ();

	if (grep { /bold/ } @parts) {
		push(@ansi_part, "1");
		@parts = grep { !/bold/ } @parts; # Remove from array
	}

	if (grep { /reverse/ } @parts) {
		push(@ansi_part, "7");
		@parts = grep { !/reverse/ } @parts; # Remove from array
	}

	my $fg  = $parts[0] // "";
	my $bg  = $parts[1] // "";

	#############################################

	# It's an numeric value, so it's an 8 bit color
	if (is_numeric($fg)) {
		if ($fg < 8) {
			push(@ansi_part, $fg + 30);
		} elsif ($fg < 16) {
			push(@ansi_part, $fg + 82);
		} else {
			push(@ansi_part, "38;5;$fg");
		}
	# It's a simple 16 color OG ansi
	} elsif ($fg) {
		my $bright    = $fg =~ s/bright//;
		my $color_num = $colors->{$fg} + 30;

		if ($bright) { $color_num += 60; } # Set bold

		push(@ansi_part, $color_num);
	}

	#############################################

	# It's an numeric value, so it's an 8 bit color
	if (is_numeric($bg)) {
		if ($bg < 8) {
			push(@ansi_part, $bg + 40);
		} elsif ($bg < 16) {
			push(@ansi_part, $bg + 92);
		} else {
			push(@ansi_part, "48;5;$bg");
		}
	# It's a simple 16 color OG ansi
	} elsif ($bg) {
		my $bright    = $bg =~ s/bright//;
		my $color_num = $colors->{$bg} + 40;

		if ($bright) { $color_num += 60; } # Set bold

		push(@ansi_part, $color_num);
	}

	#############################################

	my $ansi_str = join(";", @ansi_part);
	my $ret      = "\e[" . $ansi_str . "m";

	return $ret;
}

sub is_numeric {
	my $s = shift();

	if ($s =~ /^\d+$/) {
		return 1;
	}

	return 0;
}

sub trim {
	my $s = shift();
	if (!defined($s) || length($s) == 0) { return ""; }
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;

	return $s;
}

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
	my $str = shift();

	# If we're NOT connected to a an interactive terminal don't do color
	#if (-t STDOUT == 0) { return ''; }

	# No string sent in, so we just reset
	if (!length($str) || $str eq 'reset') { return "\e[0m"; }

	# Some predefined colors
	my %color_map = qw(red 160 blue 27 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
	$str =~ s|([A-Za-z]+)|$color_map{$1} // $1|eg;

	# Get foreground/background and any commands
	my ($fc,$cmd) = $str =~ /^(\d{1,3})?_?(\w+)?$/g;
	my ($bc)      = $str =~ /on_(\d{1,3})$/g;

	# Some predefined commands
	my %cmd_map = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);
	my $cmd_num = $cmd_map{$cmd // 0};

	my $ret = '';
	if ($cmd_num)     { $ret .= "\e[${cmd_num}m"; }
	if (defined($fc)) { $ret .= "\e[38;5;${fc}m"; }
	if (defined($bc)) { $ret .= "\e[48;5;${bc}m"; }

	return $ret;
}

# Debug print variable using either Data::Dump::Color (preferred) or Data::Dumper
# Creates methods k() and kd() to print, and print & die respectively
BEGIN {
	if (eval { require Data::Dump::Color }) {
		*k = sub { Data::Dump::Color::dd(@_) };
	} else {
		require Data::Dumper;
		*k = sub { print Data::Dumper::Dumper(\@_) };
	}

	sub kd {
		k(@_);

		printf("Died at %2\$s line #%3\$s\n",caller());
		exit(15);
	}
}

# vim: tabstop=4 shiftwidth=4 autoindent softtabstop=4
