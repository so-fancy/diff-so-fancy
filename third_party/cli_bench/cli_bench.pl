#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

###############################################################################
# Used to benchmark optimizations to CLI scripts
#
# Usage: cli_bench [--num 50] 'cat /tmp/diff.patch | diff-so-fancy'
###############################################################################

use Time::HiRes qw(time);
use Getopt::Long;

###############################################################################
###############################################################################

my $num     = 50;
my $ignore  = 1;
my $details = 1;

my $ok = GetOptions(
	'num=i'    => \$num,
	'ignore=i' => \$ignore,
	'details!' => \$details,
);


my $cmd = trim(join(" ", @ARGV));

if (!$cmd) {
	die(usage());
}

$| = 0; # Disable output buffering

my @res;
my $out;
my $exit = 0;
for (my $i = 0; $i < ($num + $ignore); $i++) {
	my $start = time();
	$out      = `$cmd`;
	$exit     = $? >> 8;

	my $total = int((time() - $start) * 1000);
	push(@res, $total);

	print ".";
}

print "\n";

# Throw away the first X to give things time to warm up and be cached
@res = splice(@res, $ignore);

# Remove the top and bottom 10%
my $outlier = $num / 10;
@res = sort(@res);
@res = splice(@res, $outlier, $num - $outlier * 2);

my $avg = sprintf("%.1f", average(@res));

if ($details) {
	show_details(@res);
	print "\n";
}

print "Ran '$cmd' $num times with average completion time of $avg ms\n";

if ($exit != 0) {
	print $out;
}

###############################################################################
###############################################################################

sub show_details {
	my @res = @_;

	my $x   = {};
	my $max = 0;

	# Build a hash of all the times:count
	foreach my $time (@res) {
		$x->{$time}++;

		if ($x->{$time} > $max) {
			$max = $x->{$time};
		}
	}

	my $target_width = 100; # How wide we want the bar + text
	my $total        = scalar(@res);
	my $scale        = ($target_width - 15) / $max;

	print "\n";

	# Print out a basic histogram of the times
	foreach my $time (sort(keys %$x)) {
		my $count   = $x->{$time};
		my $percent = sprintf("%0.1f", ($count / $total) * 100);

		my $bar = "%" x ($count * $scale);
		print "$time ms: $bar ($percent%)\n";
	}
}

sub average {
	my $ret = 0;

	foreach (@_) {
		$ret += $_;
	}

	my $count = scalar(@_);
	$ret = $ret / $count;

	return $ret;
}

sub random_int {
	my $ret = rand() * 90 + 10;
	$ret    = int($ret);

	return $ret;
}

sub round {
	my $num = shift();

	#https://stackoverflow.com/questions/178539/how-do-you-round-a-floating-point-number-in-perl
	#my $ret = int($num + $num/abs($num * 2 || 1));

	my $ret;
	if ($num < 0) {
		$ret = int($num - 0.5);
	} else {
		$ret = int($num + 0.5);
	}

	return $ret;
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
	if (-t STDOUT == 0) { return ''; }

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

sub file_get_contents {
	my $file = shift();
	open (my $fh, "<", $file) or return undef;

	my $ret;
	while (<$fh>) { $ret .= $_; }

	return $ret;
}

sub file_put_contents {
	my ($file, $data) = @_;
	open (my $fh, ">", $file) or return undef;

	print $fh $data;
	return length($data);
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

sub usage {
	return "Usage: $0 [--num 50] 'cat /tmp/simple.diff | diff-so-fancy'\n";
}

# vim: tabstop=4 shiftwidth=4 autoindent softtabstop=4
