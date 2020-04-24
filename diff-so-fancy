#!/usr/bin/env perl

my $VERSION = "1.3.0";

#################################################################################

use 5.010;                                                  # Require Perl 5.10 for 'state' variables
use File::Spec;                                             # For catdir
use File::Basename;                                         # For dirname
use Encode;                                                 # For handling UTF8 stuff
use Cwd qw(abs_path);                                       # For realpath()
use lib dirname(abs_path(File::Spec->catdir($0))) . "/lib"; # Add the local lib/ to @INC
use DiffHighlight;

use strict;
use warnings FATAL => 'all';

my $remove_file_add_header     = 1;
my $remove_file_delete_header  = 1;
my $clean_permission_changes   = 1;
my $manually_color_lines       = 0; # Usually git/hg colorizes the lines, but for raw patches we use this
my $change_hunk_indicators     = git_config_boolean("diff-so-fancy.changeHunkIndicators","true");
my $strip_leading_indicators   = git_config_boolean("diff-so-fancy.stripLeadingSymbols","true");
my $mark_empty_lines           = git_config_boolean("diff-so-fancy.markEmptyLines","true");
my $use_unicode_dash_for_ruler = git_config_boolean("diff-so-fancy.useUnicodeRuler","true");
my $ruler_width                = git_config("diff-so-fancy.rulerWidth", undef);
my $git_strip_prefix           = git_config_boolean("diff.noprefix","false");
my $has_stdin                  = has_stdin();

my $ansi_color_regex = qr/(\e\[([0-9]{1,3}(;[0-9]{1,3}){0,10})[mK])?/;
my $reset_color      = color("reset");
my $bold             = color("bold");
my $meta_color       = "";

my ($file_1,$file_2);
my $args              = argv(); # Hashref of all the ARGV stuff
my $last_file_seen    = "";
my $last_file_mode    = "";
my $i                 = 0;
my $in_hunk           = 0;
my $columns_to_remove = 0;
my $is_mercurial      = 0;
my $color_forced      = 0; # Has the color been forced on/off

# We try and be smart about whether we need to do line coloring, but
# this is an option to force it on/off
if ($args->{color_on}) {
	$manually_color_lines = 1;
	$color_forced         = 1;
} elsif ($args->{color_off}) {
	$manually_color_lines = 0;
	$color_forced         = 1;
}

# We only process ARGV if we don't have STDIN
if (!$has_stdin) {
	if ($args->{v} || $args->{version}) {
		die(version());
	} elsif ($args->{'set-defaults'}) {
		my $ok = set_defaults();
	} elsif ($args->{colors}) {
		# We print this to STDOUT so we can redirect to bash to auto-set the colors
		print get_default_colors();
		exit;
	} elsif (!%$args || $args->{help} || $args->{h}) {
		my $first = check_first_run();

		if (!$first) {
			die(usage());
		}
	} else {
		die("Missing input on STDIN\n");
	}
} else {
	# Check to see if were using default settings
	check_first_run();

	my @lines;
	local $DiffHighlight::line_cb = sub {
		push(@lines,@_);

		my $last_line = $lines[-1];

		# Buffer X lines before we try and output anything
		# Also make sure we're sending enough data to d-s-f to do it's magic.
		# Certain things require a look-ahead line or two to function so
		# we make sure we don't break on those sections prematurely
		if (@lines > 24 && ($last_line !~ /^${ansi_color_regex}(---|index|old mode|similarity index|rename (from|to))/)) {
			do_dsf_stuff(\@lines);
			@lines = ();
		}
	};

	my $line_count = 0;
	while (my $line = <STDIN>) {
		# If the very first line of the diff doesn't start with ANSI color we're assuming
		# it's a raw patch file, and we have to color the added/removed lines ourself
		if (!$color_forced && $line_count == 0 && starts_with_ansi($line)) {
			$manually_color_lines = 1;
		}

		my $ok = DiffHighlight::handle_line($line);
		$line_count++;
	}

	DiffHighlight::flush();
	do_dsf_stuff(\@lines);
}

#################################################################################

sub do_dsf_stuff {
	my $input = shift();

	#print STDERR "START -------------------------------------------------\n";
	#print STDERR join("",@$input);
	#print STDERR "END ---------------------------------------------------\n";

	while (my $line = shift(@$input)) {
		######################################################
		# Pre-process the line before we do any other markup #
		######################################################

		# If the first line of the input is a blank line, skip that
		if ($i == 0 && $line =~ /^\s*$/) {
			next;
		}

		######################
		# End pre-processing #
		######################

		#######################################################################

		####################################################################
		# Look for git index and replace it horizontal line (header later) #
		####################################################################
		if ($line =~ /^${ansi_color_regex}index /) {
			# Print the line color and then the actual line
			$meta_color = $1 || get_config_color("meta");

			# Get the next line without incrementing counter while loop
			my $next = $input->[0] || "";
			my ($file_1,$file_2);

			# The line immediately after the "index" line should be the --- file line
			# If it's not it's an empty file add/delete
			if ($next !~ /^$ansi_color_regex(---|Binary files)/) {

				# We fake out the file names since it's a raw add/delete
				if ($last_file_mode eq "add") {
					$file_1 = "/dev/null";
					$file_2 = $last_file_seen;
				} elsif ($last_file_mode eq "delete") {
					$file_1 = $last_file_seen;
					$file_2 = "/dev/null";
				}
			}

			if ($file_1 && $file_2) {
				print horizontal_rule($meta_color);
				print $meta_color . file_change_string($file_1,$file_2) . "\n";
				print horizontal_rule($meta_color);
			}
		#########################
		# Look for the filename #
		#########################
		#                                            $4              $5
		} elsif ($line =~ /^${ansi_color_regex}diff (-r|--git|--cc) (.*?)(\e| b\/|$)/) {

			# Mercurial looks like: diff -r 82e55d328c8c hello.c
			if ($4 eq "-r") {
				$is_mercurial = 1;
				$meta_color ||= get_config_color("meta");
			# Git looks like: diff --git a/diff-so-fancy b/diff-so-fancy
			} else {
				$last_file_seen = $5;
			}

			$last_file_seen =~ s|^\w/||; # Remove a/ (and handle diff.mnemonicPrefix).
			$in_hunk = 0;
		########################################
		# Find the first file: --- a/README.md #
		########################################
		} elsif (!$in_hunk && $line =~ /^$ansi_color_regex--- (\w\/)?(.+?)(\e|\t|$)/) {
			$meta_color ||= get_config_color("meta");

			if ($git_strip_prefix) {
				my $file_dir = $4 || "";
				$file_1 = $file_dir . $5;
			} else {
				$file_1 = $5;
			}

			# Find the second file on the next line: +++ b/README.md
			my $next = shift(@$input);
			$next    =~ /^$ansi_color_regex\+\+\+ (\w\/)?(.+?)(\e|\t|$)/;
			if ($1) {
				print $1; # Print out whatever color we're using
			}
			if ($git_strip_prefix) {
				my $file_dir = $4 || "";
				$file_2 = $file_dir . $5;
			} else {
				$file_2 = $5;
			}

			if ($file_2 ne "/dev/null") {
				$last_file_seen = $file_2;
			}

			# Print out the top horizontal line of the header
			print $reset_color;
			print horizontal_rule($meta_color);

			# Mercurial coloring is slightly different so we need to hard reset colors
			if ($is_mercurial) {
				print $reset_color;
			}

			print $meta_color;
			print file_change_string($file_1,$file_2) . "\n";

			# Print out the bottom horizontal line of the header
			print horizontal_rule($meta_color);
		########################################
		# Check for "@@ -3,41 +3,63 @@" syntax #
		########################################
		} elsif (!$change_hunk_indicators && $line =~ /^${ansi_color_regex}(@@@* .+? @@@*)(.*)/) {
			$in_hunk = 1;

			print $line;
		} elsif ($change_hunk_indicators && $line =~ /^${ansi_color_regex}(@@@* .+? @@@*)(.*)/) {
			$in_hunk = 1;

			my $hunk_header = $4;
			my $remain      = bleach_text($5);

			# The number of colums to remove (1 or 2) is based on how many commas in the hunk header
			$columns_to_remove   = (char_count(",",$hunk_header)) - 1;
			# On single line removes there is NO comma in the hunk so we force one
			if ($columns_to_remove <= 0) {
				$columns_to_remove = 1;
			}

			if ($1) {
				print $1; # Print out whatever color we're using
			}

			my ($orig_offset, $orig_count, $new_offset, $new_count) = parse_hunk_header($hunk_header);
			#$last_file_seen = basename($last_file_seen);

			# Figure out the start line
			my $start_line = start_line_calc($new_offset,$new_count);

			# Last function has it's own color
			my $last_function_color = "";
			if ($remain) {
				$last_function_color = get_config_color("last_function");
			}

			# Check to see if we have the color for the fragment from git
			if ($5 =~ /\e\[\d/) {
				#print "Has ANSI color for fragment\n";
			} else {
				# We don't have the ANSI sequence so we shell out to get it
				#print "No ANSI color for fragment\n";
				my $frag_color = get_config_color("fragment");
				print $frag_color;
			}

			print "@ $last_file_seen:$start_line \@${bold}${last_function_color}${remain}${reset_color}\n";
		###################################
		# Remove any new file permissions #
		###################################
		} elsif ($remove_file_add_header && $line =~ /^${ansi_color_regex}.*new file mode/) {
			# Don't print the line (i.e. remove it from the output);
			$last_file_mode = "add";
		######################################
		# Remove any delete file permissions #
		######################################
		} elsif ($remove_file_delete_header && $line =~ /^${ansi_color_regex}deleted file mode/) {
			# Don't print the line (i.e. remove it from the output);
			$last_file_mode = "delete";
		################################
		# Look for binary file changes #
		################################
		} elsif ($line =~ /^Binary files (\w\/)?(.+?) and (\w\/)?(.+?) differ/) {
			my $change = file_change_string($2,$4);
			print horizontal_rule($meta_color);
			print "$meta_color$change (binary)\n";
			print horizontal_rule($meta_color);
		#####################################################
		# Check if we're changing the permissions of a file #
		#####################################################
		} elsif ($clean_permission_changes && $line =~ /^${ansi_color_regex}old mode (\d+)/) {
			my ($old_mode) = $4;
			my $next = shift(@$input);

			if ($1) {
				print $1; # Print out whatever color we're using
			}

			my ($new_mode) = $next =~ m/new mode (\d+)/;
			print "$last_file_seen changed file mode from $old_mode to $new_mode\n";

		###############
		# File rename #
		###############
		} elsif ($line =~ /^${ansi_color_regex}similarity index (\d+)%/) {
			my $simil = $4;

			# If it's a move with content change we ignore this and the next two lines
			if ($simil != 100) {
				shift(@$input);
				shift(@$input);
				next;
			}

			my $next    = shift(@$input);
			my ($file1) = $next =~ /rename from (.+)/;

			$next       = shift(@$input);
			my ($file2) = $next =~ /rename to (.+)/;

			if ($file1 && $file2) {
				# We may not have extracted this yet, so we pull from the config if not
				$meta_color ||= get_config_color("meta");

				my $change = file_change_string($file1,$file2);

				print horizontal_rule($meta_color);
				print $meta_color . $change . "\n";
				print horizontal_rule($meta_color);
			}

			$i += 3; # We've consumed three lines
			next;
		#####################################
		# Just a regular line, print it out #
		#####################################
		} else {
			# Mark empty line with a red/green box indicating addition/removal
			if ($mark_empty_lines) {
				$line = mark_empty_line($line);
			}

			# Remove the correct number of leading " " or "+" or "-"
			if ($strip_leading_indicators) {
				$line = strip_leading_indicators($line,$columns_to_remove);
			}
			print $line;
		}

		$i++;
	}
}

######################################################################################################
# End regular code, begin functions
######################################################################################################

# Courtesy of github.com/git/git/blob/ab5d01a/git-add--interactive.perl#L798-L805
sub parse_hunk_header {
	my ($line) = @_;
	my ($o_ofs, $o_cnt, $n_ofs, $n_cnt) = $line =~ /^\@\@+(?: -(\d+)(?:,(\d+))?)+ \+(\d+)(?:,(\d+))? \@\@+/;
	$o_cnt = 1 unless defined $o_cnt;
	$n_cnt = 1 unless defined $n_cnt;
	return ($o_ofs, $o_cnt, $n_ofs, $n_cnt);
}

# Mark the first char of an empty line
sub mark_empty_line {
	my $line = shift();

	my $reset_color  = "\e\\[0?m";
	my $reset_escape = "\e\[m";
	my $invert_color = "\e\[7m";
	my $add_color    = $DiffHighlight::NEW_HIGHLIGHT[1];
	my $del_color    = $DiffHighlight::OLD_HIGHLIGHT[1];

	# This captures lines that do not have any ANSI in them (raw vanilla diff)
	if ($line eq "+\n") {
		$line = $invert_color . $add_color . " " . color('reset') . "\n";
	# This captures lines that do not have any ANSI in them (raw vanilla diff)
	} elsif ($line eq "-\n") {
		$line = $invert_color . $del_color . " " . color('reset') . "\n";
	# This handles everything else
	} else {
		$line =~ s/^($ansi_color_regex)[+-]$reset_color\s*$/$invert_color$1 $reset_escape\n/;
	}

	return $line;
}

# String to boolean
sub boolean {
	my $str = shift();
	$str    = trim($str);

	if ($str eq "" || $str =~ /^(no|false|0)$/i) {
		return 0;
	} else {
		return 1;
	}
}

# Memoize getting the git config
{
	my $static_config;

	sub git_config_raw {
		if ($static_config) {
			# If we already have the config return that
			return $static_config;
		}

		my $cmd = "git config --list";
		my @out = `$cmd`;

		$static_config = \@out;

		return \@out;
	}
}

# Fetch a textual item from the git config
sub git_config {
	my $search_key    = lc($_[0] || "");
	my $default_value = lc($_[1] || "");

	my $out = git_config_raw();

	# If we're in a unit test, use the default (don't read the users config)
	if (in_unit_test()) {
		return $default_value;
	}

	my $raw = {};
	foreach my $line (@$out) {
		if ($line =~ /=/) {
			my ($key,$value) = split("=",$line,2);
			$value =~ s/\s+$//;
			$raw->{$key} = $value;
		}
	}

	# If we're given a search key return that, else return the hash
	if ($search_key) {
		return $raw->{$search_key} || $default_value;
	} else {
		return $raw;
	}
}

# Fetch a boolean item from the git config
sub git_config_boolean {
	my $search_key    = lc($_[0] || "");
	my $default_value = lc($_[1] || 0); # Default to false

	# If we're in a unit test, use the default (don't read the users config)
	if (in_unit_test()) {
		return boolean($default_value);
	}

	my $result = git_config($search_key,$default_value);
	my $ret    = boolean($result);

	return $ret;
}

# Check if we're inside of BATS
sub in_unit_test {
	if ($ENV{BATS_CWD}) {
		return 1;
	} else {
		return 0;
	}
}

sub get_less_charset {
	my @less_char_vars = ("LESSCHARSET", "LESSCHARDEF", "LC_ALL", "LC_CTYPE", "LANG");
	foreach (@less_char_vars) {
		return $ENV{$_} if defined $ENV{$_};
	}

	return "";
}

sub should_print_unicode {
	if (-t STDOUT) {
		# Always print unicode chars if we're not piping stuff, e.g. to less(1)
		return 1;
	}

	# Otherwise, assume we're piping to less(1)
	my $less_charset = get_less_charset();
	if ($less_charset =~ /utf-?8/i) {
		return 1;
	}

	return 0;
}

# Try and be smart about what line the diff hunk starts on
sub start_line_calc {
	my ($line_num,$diff_context) = @_;
	my $ret;

	if ($line_num == 0 && $diff_context == 0) {
		return 1;
	}

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
	my $line              = shift(); # Array passed in by reference
	my $columns_to_remove = shift(); # Don't remove any lines by default

	if ($columns_to_remove == 0) {
		return $line; # Nothing to do
	}

	$line =~ s/^(${ansi_color_regex})([ +-]){${columns_to_remove}}/$1/;

	if ($manually_color_lines) {
		if (defined($5) && $5 eq "+") {
			my $add_line_color = get_config_color("add_line");
			$line              = $add_line_color . $line . $reset_color;
		} elsif (defined($5) && $5 eq "-") {
			my $remove_line_color = get_config_color("remove_line");
			$line                 = $remove_line_color . $line . $reset_color;
		}
	}

	return $line;
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

# Remove all ANSI codes from a string
sub bleach_text {
	my $str = shift();
	$str    =~ s/\e\[\d*(;\d+)*m//mg;

	return $str;
}

# Remove all trailing and leading spaces
sub trim {
	my $s = shift();
	if (!$s) { return ""; }
	$s =~ s/^\s*|\s*$//g;

	return $s;
}

# Print a line of em-dash or line-drawing chars the full width of the screen
sub horizontal_rule {
	my $color = $_[0] || "";
	my $width = get_terminal_width();

	# em-dash http://www.fileformat.info/info/unicode/char/2014/index.htm
	#my $dash = "\x{2014}";
	# BOX DRAWINGS LIGHT HORIZONTAL http://www.fileformat.info/info/unicode/char/2500/index.htm
	my $dash;
	if ($use_unicode_dash_for_ruler && should_print_unicode()) {
		$dash = Encode::encode('UTF-8', "\x{2500}");
	} else {
		$dash = "-";
	}

	# Draw the line
	my $ret = $color . ($dash x $width) . "$reset_color\n";

	return $ret;
}

sub file_change_string {
	my $file_1 = shift();
	my $file_2 = shift();

	# If they're the same it's a modify
	if ($file_1 eq $file_2) {
		return "modified: $file_1";
	# If the first is /dev/null it's a new file
	} elsif ($file_1 eq "/dev/null") {
		my $add_color = $DiffHighlight::NEW_HIGHLIGHT[1];
		return "added: $add_color$file_2$reset_color";
	# If the second is /dev/null it's a deletion
	} elsif ($file_2 eq "/dev/null") {
		my $del_color = $DiffHighlight::OLD_HIGHLIGHT[1];
		return "deleted: $del_color$file_1$reset_color";
	# If the files aren't the same it's a rename
	} elsif ($file_1 ne $file_2) {
		my ($old, $new) = DiffHighlight::highlight_pair($file_1,$file_2,{only_diff => 1});
		$old = trim($old);
		$new = trim($new);

		# highlight_pair resets the colors, but we want it to be the meta color
		$old =~ s/(\e0?\[m)/$1$meta_color/g;
		$new =~ s/(\e0?\[m)/$1$meta_color/g;

		return "renamed: $old to $new";
	# Something we haven't thought of yet
	} else {
		return "$file_1 -> $file_2";
	}
}

# Check to see if STDIN is connected to an interactive terminal
sub has_stdin {
	my $i   = -t STDIN;
	my $ret = int(!$i);

	return $ret;
}

# We use this instead of Getopt::Long because it's faster and we're not parsing any
# crazy arguments
# Borrowed from: https://www.perturb.org/display/1153_Perl_Quick_extract_variables_from_ARGV.html
sub argv {
	my $ret = {};

	for (my $i = 0; $i < scalar(@ARGV); $i++) {

		# If the item starts with "-" it's a key
		if ((my ($key) = $ARGV[$i] =~ /^--?([a-zA-Z_-]*\w)$/) && ($ARGV[$i] !~ /^-\w\w/)) {
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

# Output the command line usage for d-s-f
sub usage {
	my $out = color("white_bold") . version() . color("reset") . "\n";

	$out .= "Usage:

git diff --color | diff-so-fancy         # Use d-s-f on one diff
cat diff.txt | diff-so-fancy             # Use d-s-f on a diff/patch file
diff -u one.txt two.txt | diff-so-fancy  # Use d-s-f on unified diff output

diff-so-fancy --colors                   # View the commands to set the recommended colors
diff-so-fancy --set-defaults             # Configure git-diff to use diff-so-fancy and suggested colors

# Configure git to use d-s-f for *all* diff operations
git config --global core.pager \"diff-so-fancy | less --tabs=4 -RFX\"\n";

	return $out;
}

sub get_default_colors {
	my $out  = "# Recommended default colors for diff-so-fancy\n";
	$out    .= "# --------------------------------------------\n";
	$out    .= 'git config --global color.ui true

git config --global color.diff-highlight.oldNormal    "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"

git config --global color.diff.meta       "yellow"
git config --global color.diff.frag       "magenta bold"
git config --global color.diff.commit     "yellow bold"
git config --global color.diff.old        "red bold"
git config --global color.diff.new        "green bold"
git config --global color.diff.whitespace "red reverse"
';

	return $out;
}

# Output the current version string
sub version {
	my $ret  = "Diff-so-fancy: https://github.com/so-fancy/diff-so-fancy\n";
	$ret    .= "Version      : $VERSION\n";

	return $ret;
}

sub is_windows {
	if ($^O eq 'MSWin32' or $^O eq 'dos' or $^O eq 'os2' or $^O eq 'cygwin' or $^O eq 'msys') {
		return 1;
	} else {
		return 0;
	}
}

# Return value is whether this is the first time they've run d-s-f
sub check_first_run {
	my $ret = 0;

	# If first-run is not set, or it's set to "true"
	my $first_run     = git_config_boolean('diff-so-fancy.first-run');
	# See if they're previously set SOME diff-highlight colors
	my $has_dh_colors = git_config_boolean('color.diff-highlight.oldnormal') || git_config_boolean('color.diff-highlight.newnormal');

	#$first_run = 1; $has_dh_colors = 0;

	if (!$first_run || $has_dh_colors) {
		return 0;
	} else {
		print "This appears to be the first time you've run diff-so-fancy, please note\n";
		print "that the default git colors are not ideal. Diff-so-fancy recommends the\n";
		print "following colors.\n\n";

		print get_default_colors();

		# Set the first run flag to false
		my $cmd = 'git config --global diff-so-fancy.first-run false';
		system($cmd);

		exit;
	}

	return 1;
}

sub set_defaults {
	my $color_config = get_default_colors();
	my $git_config   = 'git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"';
	my $first_cmd    = 'git config --global diff-so-fancy.first-run false';

	my @cmds = split(/\n/,$color_config);
	push(@cmds,$git_config);
	push(@cmds,$first_cmd);

	# Remove all comments from the commands
	foreach my $x (@cmds) {
		$x =~ s/#.*//g;
	}

	# Remove any empty commands
	@cmds = grep($_,@cmds);

	foreach my $cmd (@cmds) {
		system($cmd);
		my $exit = ($? >> 8);

		if ($exit != 0) {
			die("Error running: '$cmd' (error #18941)\n");
		}
	}

	return 1;
}

# Borrowed from: https://www.perturb.org/display/1167_Perl_ANSI_colors.html
# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
	my $str = shift();

	# No string sent in, so we just reset
	if (!length($str) || $str eq 'reset') { return "\e[0m"; }

	# Some predefined colors
	my %color_map = qw(red 160 blue 21 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
	$str =~ s|([A-Za-z]+)|$color_map{$1} // $1|eg;

	# Get foreground/background and any commands
	my ($fc,$cmd) = $str =~ /(\d+)?_?(\w+)?/g;
	my ($bc)      = $str =~ /on_?(\d+)/g;

	# Some predefined commands
	my %cmd_map = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);
	my $cmd_num = $cmd_map{$cmd // 0};

	my $ret = '';
	if ($cmd_num)     { $ret .= "\e[${cmd_num}m"; }
	if (defined($fc)) { $ret .= "\e[38;5;${fc}m"; }
	if (defined($bc)) { $ret .= "\e[48;5;${bc}m"; }

	return $ret;
}

# Get colors used for various output sections (memoized)
{
	my $static_config;

	sub get_config_color {
		my $str = shift();

		my $ret = "";
		if ($static_config->{$str}) {
			return $static_config->{$str};
		}

		#print color(15) . "Shelling out for color: '$str'\n" . color('reset');

		if ($str eq "meta") {
			# Default ANSI yellow
			$ret = DiffHighlight::color_config('color.diff.meta', color(11));
		} elsif ($str eq "reset") {
			$ret = color("reset");
		} elsif ($str eq "add_line") {
			# Default ANSI green
			$ret = DiffHighlight::color_config('color.diff.new', color('bold') . color(2));
		} elsif ($str eq "remove_line") {
			# Default ANSI red
			$ret = DiffHighlight::color_config('color.diff.old', color('bold') . color(1));
		} elsif ($str eq "fragment") {
			$ret = DiffHighlight::color_config('color.diff.frag', color('13_bold'));
		} elsif ($str eq "last_function") {
			$ret = DiffHighlight::color_config('color.diff.func', color('bold') . color(146));
		}

		# Cache (memoize) the entry for later
		$static_config->{$str} = $ret;

		return $ret;
	}
}

sub starts_with_ansi {
	my $str = shift();

	if ($str =~ /^$ansi_color_regex/) {
		return 1;
	} else {
		return 0;
	}
}

sub get_terminal_width {
	# Make width static so we only calculate it once
	state $width;

	if ($width) {
		return $width;
	}

	# If there is a ruler width in the config we use that
	if ($ruler_width) {
		$width = $ruler_width;
	# Otherwise we check the terminal width using tput
	} else {
		my $tput = `tput cols`;

		if ($tput) {
			$width = int($tput);

			if (is_windows()) {
				$width--;
			}
		} else {
			print color('orange') . "Warning: `tput cols` did not return numeric input" . color('reset') . "\n";
			$width = 80;
		}
	}

	return $width;
}

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
