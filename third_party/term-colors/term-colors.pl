#!/usr/bin/perl

use strict;

my $args   = join(" ",@ARGV);
my ($perl) = $args =~ /--perl/;
my ($both) = $args =~ /--both/;

# If we want both, we set perl also
if ($both) {
	$perl = 1;
}

# Term::ANSIColor didn't get 256 color constants until 4.0
if ($perl && has_term_ansicolor(4.0)) {
	require Term::ANSIColor;
	Term::ANSIColor->import(':constants','color','uncolor');

	#print "TERM::ANSIColor constant names:\n";
	term_ansicolor();
} else {
	my $cols = 120;
	my $rows = 24;
	if (-f '/bin/stty') {
		($rows,$cols) = split(/ /,`/bin/stty size`);
	}

	my $section  = 1;
	my $grouping = 8;

	for (my $i=0;$i<256;$i++) {
		print set_bcolor($i); # Set the background color

		if (needs_white($i)) {
			print set_fcolor(15); # White
			printf("    %03d    ",$i); # Ouput the color number in white
		} else {
			print set_fcolor(0); # Black
			printf("    %03d    ",$i); # Ouput the color number in black
		}

		print set_fcolor(); # Reset both colors
		print "  "; # Seperators

		if ($i == 15 || $i == 231) {
			print set_bcolor(); # Reset
			print "\n\n";
			$section  = 0;
			$grouping = 6;
		} elsif ($section > 0 && ($section % $grouping == 0)) {
			print set_bcolor(); # Reset
			print "\n";
		}

		$section++;
	}
}

END {
	print set_fcolor(); # Reset the colors
	print "\n";
}

#################################################################################

sub has_term_ansicolor {
	my $version = shift();
	$version ||= 4;

	eval {
		# Check if we have Term::ANSIColor version 4.0
		require Term::ANSIColor;
		Term::ANSIColor->VERSION($version);
	};

	if ($@) {
		return 0;
	} else {
		return 1;
	}
}

sub set_fcolor {
	my $c = shift();

	my $ret = '';
	if (!defined($c)) { $ret = "\e[0m"; } # Reset the color
	else { $ret = "\e[38;5;${c}m"; }

	return $ret;
}

sub set_bcolor {
	my $c = shift();

	my $ret = '';
	if (!defined($c)) { $ret = "\e[0m"; } # Reset the color
	else { $ret .= "\e[48;5;${c}m"; }

	return $ret;
}

sub highlight_string {
	my $needle = shift();
	my $haystack = shift();
	my $color = shift() || 2; # Green if they don't pass in a color

	my $fc = set_fcolor($color);
	my $reset = set_fcolor();

	$haystack =~ s/$needle/$fc.$needle.$reset/e;

	return $haystack;
}

sub get_color_mapping {
	my $map = {};

	for (my $i = 0; $i < 256; $i++) {
		my $str = "\e[38;5;${i}m";
		my ($acc) = uncolor($str);

		$map->{$acc} = int($i);
	}

	return $map;
}

sub term_ansicolor {
	my @colors = get_color_names();
	my $map    = get_color_mapping();

	my $absolute = 0;
	my $group    = 0;
	my $grouping = 8;

	print "Showing Term::ANSIColor constant names\n\n";

	foreach my $name (@colors) {
		my $bg          = "on_$name";
		my $map_num     = int($map->{$name});
		my $perl_name   = sprintf("%6s",$name);
		my $ansi_number = sprintf("#%03i",$map_num);

		my $name_string = "";
		if ($both) {
			$name_string = "$perl_name / $ansi_number";
		} else {
			$name_string = "$perl_name";
		}

		if (needs_white($map_num)) {
			print color($bg) . "   " . color('bright_white') . $name_string . "   ";
		} else {
			print color($bg) . "   " . color("black") . $name_string . "   ";
		}
		print color('reset') . "  ";

		$absolute++;
		$group++;

		if ($absolute == 16 || $absolute == 232) {
			print "\n\n";
			$group    = 0;
			$grouping = 6;
		} elsif ($group % $grouping == 0) {
			print "\n";
		}
	}
}

sub get_color_names {
	my @colors    = ();
	my ($r,$g,$b) = 0;

	for (my $i = 0; $i < 16; $i++) {
		my $name = "ansi$i";
		push(@colors,$name);
	}

	for ($r = 0; $r <= 5; $r++) {
		for ($g = 0; $g <= 5; $g++) {
			for ($b = 0; $b <= 5; $b++) {
				my $name = "rgb$r$g$b";
				push(@colors,$name);
			}
		}
	}

	for (my $i = 0; $i < 24; $i++) {
		my $name = "grey$i";
		push(@colors,$name);
	}

	return @colors;
}

sub needs_white {
	my $num = shift();

	# Sorta lame, but it's a hard coded list of which background colors need a white foreground
	my @white = qw(0 1 4 5 8 232 233 234 235 236 237 238 239 240 241 242 243 16 17 18
	19 20 21 22 28 52 53 54 55 25 56 57 58 59 60 88 89 90 91 92 93 124 125 29 30 31 26
	27 61 62 64 160 196 161 126 63 94 95 100 101 127 128 129 12 130 131 23 24);

	if (grep(/\b$num\b/,@white)) {
		return 1,
	} else {
		return 0;
	}
}
