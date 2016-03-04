use File::Basename;
my $change_hunk_indicators    = 1;
	if ($line =~ /^${ansi_sequence_regex}diff --(git|cc) (.*?)(\e|$)/) {
		$last_file_seen = $5;
	########################################
	# Check for "@@ -3,41 +3,63 @@" syntax #
	########################################
	} elsif ($change_hunk_indicators && $line =~ /^${ansi_sequence_regex}@@@* (.+?) @@@*(.*)/) {
		my $file_str     = $4;
		my $remain       = $5;

		if ($1) {
			print $1; # Print out whatever color we're using
		}

		my ($start_line) = $file_str =~ m/(.+?),/;
		$start_line      = abs($start_line + 0);

		$last_file_seen = basename($last_file_seen);

		# Plus three line for context
		print "@ $last_file_seen:" . ($start_line + 3) . " \@${remain}\n";
		#print $line;
	} elsif ($remove_file_add_header && $line =~ /^${ansi_sequence_regex}.*new file mode/) {