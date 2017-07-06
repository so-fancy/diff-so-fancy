#!/usr/bin/env perl

###########################################################################
# This will build a stand-a-lone version of diff-so-fancy using Fatpack
#
# Scott Baker - 2017-06-28
#
# Usage: perl build.pl [--output /tmp/diff-so-fancy]
###########################################################################

use strict;
use warnings;
use File::Basename;
use Cwd qw(abs_path getcwd);

my $args = argv();
my $ok   = has_fatpack();

if (!$ok) {
	printf("%sError:%s App::FatPacker must be installed to build diff-so-fancy\n",color('red_bold'),color('reset'));
	exit;
}

my $output_file = "/tmp/diff-so-fancy";
my $input_file  = "diff-so-fancy";

# Allow overriding the output file
if ($args->{output}) {
	$output_file = $args->{output};
}

my $dir  = dirname($0);
my $root = abs_path("$dir/../../");
my $cwd  = getcwd();

# Change to the root of the tree
chdir($root);
my $dsf_version = get_version($input_file);

my $cmd = "fatpack pack $input_file 2>/dev/null > $output_file";

my $exit = system($cmd);
$exit    = $exit >> 8;

rmdir("fatlib"); # fatpack leaves empty fatlib dirs so we remove them
my $size = -s $output_file;

my $good  = color("82bold");
my $bad   = color("160bold");
my $warn  = color("226bold");
my $vers  = color("230bold");
my $white = color("15bold");
my $reset = color();

if (!$exit) {
	print "${good}Success:${reset} Wrote diff-so-fancy ${vers}v$dsf_version${reset} to $output_file ($size bytes)\n";
	chmod 0755,$output_file; # Make the output executable
} else {
	print "${bad}Error  :${reset} Fatpack failed to build $output_file with exit code: ${warn}$exit${reset}\n";
	print "${white}Command: $cmd$reset\n";
}

chdir($cwd);

#############################################################################

sub argv {
	my $ret = {};

	for (my $i = 0; $i < scalar(@ARGV); $i++) {
		# If the item starts with "-" it's a key
		if ((my ($key) = $ARGV[$i] =~ /^--?([a-zA-Z_]\w*)/) && ($ARGV[$i] !~ /^-\w\w/)) {
			# If the next item does not start with "--" it's the value for this item
			if (defined($ARGV[$i + 1]) && ($ARGV[$i + 1] !~ /^--?\D/)) {
				$ret->{$key} = $ARGV[$i + 1];
			# Bareword like --verbose with no options
			} else {
				$ret->{$key}++;
			}
		}
	}

	# We're looking for a certain item
	if ($_[0]) { return $ret->{$_[0]}; }

	return $ret;
}

sub pfile {
	my $file = shift();
	if (!-r $file) { return ''; } # Make sure the file is readable

	my $ret = '';

	open(INPUT, "<", $file);
	while (<INPUT>) {
		$ret .= $_;
	}
	close INPUT;

	if (wantarray) {
		return split(/\n/,$ret);
	} else {
		return $ret;
	}
}

sub get_version {
	my $file  = shift();
	my @lines = pfile($file);

	foreach my $l (@lines) {
		if ($l =~ /\$VERSION\s+=\s+"(.+?)"/) {
			my $ver = $1;
			return $ver;
		}
	}

	return undef;
}

sub has_fatpack {
	my $out = `which fatpack 2>/dev/null`;

	return trim($out);
}

sub trim {
	my $s = shift();
	if (length($s) == 0) { return ""; }
	$s =~ s/^\s*|\s*$//g;

	return $s;
}

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173'
sub color {
	my $str = shift();

	# If we're NOT connected to a an interactive terminal don't do color
	if (-t STDOUT == 0) { return ''; }

	# No string sent in, so we just reset
	if (!length($str) || $str eq 'reset') { return "\e[0m"; }

	# Some predefined colors
	my %color_map = qw(red 160 blue 21 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
	$str =~ s/$_/$color_map{$_}/g for keys %color_map;

	# Get foreground/background and any commands
	my ($fc,$cmd) = $str =~ /^(\d+)?_?(\w+)?/g;
	my ($bc)      = $str =~ /on_?(\d+)$/g;

	# Some predefined commands
	my %cmd_map = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);
	my $cmd_num = $cmd_map{$cmd || 0};

	my $ret = '';
	if ($cmd_num)     { $ret .= "\e[${cmd_num}m"; }
	if (defined($fc)) { $ret .= "\e[38;5;${fc}m"; }
	if (defined($bc)) { $ret .= "\e[48;5;${bc}m"; }

	return $ret;
}

# vim: tabstop=4 shiftwidth=4 autoindent softtabstop=4
