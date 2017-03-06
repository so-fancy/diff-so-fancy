my $VERSION = "0.12.0";

#################################################################################

my $git_strip_prefix           = git_config_boolean("diff.noprefix","false");
my $has_stdin                  = has_stdin();

# We only process ARGV if we don't have STDIN
if (!$has_stdin) {
	my $args = argv();

	if ($args->{v} || $args->{version}) {
		die(version());
	}

	if (!%$args) {
		print usage(); exit;
		die(usage());
	}
}
		if ($git_strip_prefix) {
			my $file_dir = $4 || "";
			$file_1 = $file_dir . $5;
		} else {
			$file_1 = $5;
		}
		if ($git_strip_prefix) {
			my $file_dir = $4 || "";
			$file_2 = $file_dir . $5;
		} else {
			$file_2 = $5;
		}

		$in_hunk        = 1;
		my $hunk_header = $4;
		my $remain      = bleach_text($5);

		# The number of colums to remove (1 or 2) is based on how many commas in the hunk header
		$columns_to_remove   = (char_count(",",$hunk_header)) - 1;
		# On single line removes there is NO comma in the hunk so we force one
		$columns_to_remove ||= 1;
		return boolean($default_value);

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

# Output the command line usage for d-s-f
sub usage {
	my $out = "Usage:

  # One off fanciness
  git diff --color | diff-so-fancy

  # Configure git to use d-s-f for all diff operations
  git config --global core.pager \"diff-so-fancy | less --tabs=4 -RFX\"

  # Create a git alias to run d-s-f on demand
  git config --global alias.dsf '!f() { [ -z \"\$GIT_PREFIX\" ] || cd \"\$GIT_PREFIX\" && git diff --color \"\$@\" | diff-so-fancy  | less --tabs=4 -RFX; }; f'\n\n";

	return $out;
}

# Output the current version string
sub version {
	my $ret  = "Diff-so-fancy: https://github.com/so-fancy/diff-so-fancy\n";
	$ret    .= "Version      : $VERSION\n\n";

	return $ret;
}