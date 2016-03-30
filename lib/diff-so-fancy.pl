#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use File::Basename;

my $remove_file_add_header    = 1;
my $remove_file_delete_header = 1;
my $clean_permission_changes  = 1;
my $change_hunk_indicators    = 1;
my $strip_leading_indicators  = 1;
my $mark_empty_lines          = 1;

#################################################################################

my $ansi_color_regex = qr/(\e\[([0-9]{1,3}(;[0-9]{1,3}){0,3})[mK])?/;
my $dim_magenta      = "\e[38;5;146m";
my $reset_color      = "\e[0m";
my $bold             = "\e[1m";

my @input = <>;
clean_up_input(\@input);

my ($file_1,$file_2,$last_file_seen);
for (my $i = 0; $i <= $#input; $i++) {
	my $line = $input[$i];

	#########################
	# Look for the filename #
	#########################
	if ($line =~ /^${ansi_color_regex}diff --(git|cc) (.*?)(\s|\e|$)/) {
		$last_file_seen = $5;
		$last_file_seen =~ s|a/||; # Remove a/
	########################################
	# Find the first file: --- a/README.md #
	########################################
	} elsif ($line =~ /^$ansi_color_regex--- (\w\/)?(.+?)(\e|$)/) {
		$file_1 = $5;

		# Find the second file on the next line: +++ b/README.md
		my $next = $input[++$i];
		$next    =~ /^$ansi_color_regex\+\+\+ (\w\/)?(.+?)(\e|$)/;
		if ($1) {
			print $1; # Print out whatever color we're using
		}
		$file_2 = $5;

		# If they're the same it's a modify
		if ($file_1 eq $file_2) {
			print "modified: $file_1\n";
		# If the first is /dev/null it's a new file
		} elsif ($file_1 eq "/dev/null") {
			print "added: $file_2\n";
		# If the second is /dev/null it's a deletion
		} elsif ($file_2 eq "/dev/null") {
			print "deleted: $file_1\n";
		# If the files aren't the same it's a rename
		} elsif ($file_1 ne $file_2) {
			print "renamed: $file_1 to $file_2\n";
		# Something we haven't thought of yet
		} else {
			print "$file_1 -> $file_2\n";
		}
	########################################
	# Check for "@@ -3,41 +3,63 @@" syntax #
	########################################
	} elsif ($change_hunk_indicators && $line =~ /^${ansi_color_regex}(@@@* .+? @@@*)(.*)/) {
		my $hunk_header  = $4;
		my $remain       = bleach_text($5);

		if ($1) {
			print $1; # Print out whatever color we're using
		}

		my ($orig_offset, $orig_count, $new_offset, $new_count) = parse_hunk_header($hunk_header);
		$last_file_seen = basename($last_file_seen);

		# Figure out the start line
		my $start_line = start_line_calc($new_offset,$new_count);
		print "@ $last_file_seen:$start_line \@${bold}${dim_magenta}${remain}\n";
	###################################
	# Remove any new file permissions #
	###################################
	} elsif ($remove_file_add_header && $line =~ /^${ansi_color_regex}.*new file mode/) {
		# Don't print the line (i.e. remove it from the output);
	######################################
	# Remove any delete file permissions #
	######################################
	} elsif ($remove_file_delete_header && $line =~ /^${ansi_color_regex}deleted file mode/) {
		# Don't print the line (i.e. remove it from the output);
	#####################################################
	# Check if we're changing the permissions of a file #
	#####################################################
	} elsif ($clean_permission_changes && $line =~ /^${ansi_color_regex}old mode (\d+)/) {
		my ($old_mode) = $4;
		my $next = $input[++$i];

		if ($1) {
			print $1; # Print out whatever color we're using
		}

		my ($new_mode) = $next =~ m/new mode (\d+)/;
		print "$last_file_seen changed file mode from $old_mode to $new_mode\n";
	#####################################
	# Just a regular line, print it out #
	#####################################
	} else {
		print $line;
	}
}

# Courtesy of github.com/git/git/blob/ab5d01a/git-add--interactive.perl#L798-L805
sub parse_hunk_header {
	my ($line) = @_;
	my ($o_ofs, $o_cnt, $n_ofs, $n_cnt) = $line =~ /^@@+(?: -(\d+)(?:,(\d+))?)+ \+(\d+)(?:,(\d+))? @@+/;
	$o_cnt = 1 unless defined $o_cnt;
	$n_cnt = 1 unless defined $n_cnt;
	return ($o_ofs, $o_cnt, $n_ofs, $n_cnt);
}

sub strip_empty_first_line {
	my $array = shift(); # Array passed in by reference

	# If the first line is just whitespace remove it
	if (defined($array->[0]) && $array->[0] =~ /^\s*$/) {
		shift(@$array); # Throw away the first line
	}

	return 1;
}

sub mark_empty_lines {
	my $array = shift(); # Array passed in by reference

	my $reset_color  = "\e\\[0?m";
	my $reset_escape = "\e\[m";
	my $invert_color = "\e\[7m";

	foreach my $line (@$array) {
		$line =~ s/^($ansi_color_regex)[+-]$reset_color\s*$/$invert_color$1 $reset_escape\n/;
	}

	return 1;
}

sub clean_up_input {
	my $input_array_ref = shift();

	# Usually the first line of a diff is whitespace so we remove that
	strip_empty_first_line($input_array_ref);

	if ($mark_empty_lines) {
		mark_empty_lines($input_array_ref);
	}

	# Remove + or - at the beginning of the lines
	if ($strip_leading_indicators) {
		strip_leading_indicators($input_array_ref);
	}


	return 1;
}

# Return git config as a hash
sub get_git_config {
	my $cmd = "git config --list";
	my @out = `$cmd`;

	my %hash;
	foreach my $line (@out) {
		my ($key,$value) = split("=",$line,2);
		$value =~ s/\s+$//;
		my @path = split(/\./,$key);

		my $last = pop @path;
		my $p = \%hash;
		$p = $p->{$_} //= {} for @path;
		$p->{$last} = $value;
	}

	return \%hash;
}

# Try and be smart about what line the diff hunk starts on
sub start_line_calc {
	my ($line_num,$diff_context) = @_;
	my $ret;

	# Git defaults to three lines of context
	my $default_context_lines = 3;
	# Three lines on either side, and the line itself = 7
	my $expected_context      = ($default_context_lines * 2 + 1);

	# The first three lines
	if ($line_num == 1 && $diff_context < $expected_context) {
		$ret = $diff_context - $default_context_lines;
	} else {
		$ret = $line_num + $default_context_lines;
	}

	if ($ret < 1) {
		$ret = 1;
	}

	return $ret;
}

# Remove + or - at the beginning of the lines
sub strip_leading_indicators {
	my $array = shift();       # Array passed in by reference
	my $columns_to_remove = 1; # Default to 1 (two-way merge)

	foreach my $line (@$array) {
		# If the line is a hunk line, check for two-way vs three-way merge
		# Two-way   = @@ -132,6 +132,9 @@
		# Three-way = @@@ -48,10 -48,10 +48,15 @@@
		if ($line =~ /^${ansi_color_regex}@@@* (.+?) @@@*/) {
			$columns_to_remove = (char_count(",",$4)) - 1;
			last;
		}
	}

	foreach my $line (@$array) {
		# Remove a number of "+", "-", or spaces equal to the indent level
		$line =~ s/^(${ansi_color_regex})[ +-]{${columns_to_remove}}/$1/;
	}

	return 1;
}

# Count the number of a given char in a string
sub char_count {
	my ($needle,$str) = @_;
	my $len = length($str);
	my $ret = 0;

	for (my $i = 0; $i < $len; $i++) {
		my $found = substr($str,$i,1);

		if ($needle eq $found) { $ret++; }
	}

	return $ret;
}

sub bleach_text {
	my $str = shift();
	$str    =~ s/\e\[\d*(;\d+)*m//mg;

	return $str;
}
