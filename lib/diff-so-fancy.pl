my $dim_magenta      = "\e[38;5;146m";
		my $remain       = bleach_text($5);
		print "@ $last_file_seen:$start_line \@${dim_magenta}${remain}\n";

sub bleach_text {
	my $str = shift();
	$str    =~ s/\e\[\d*(;\d+)*m//mg;

	return $str;
}