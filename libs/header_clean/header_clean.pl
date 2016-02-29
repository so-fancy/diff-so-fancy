#!/usr/bin/perl

use strict;
use warnings;

my $ansi_sequence_regex = qr/(\e\[([0-9]{1,3}(;[0-9]{1,3}){0,3})[mK])?/;

my ($f1,$f2);
while (my $l = <>) {
	# Find the first file: --- a/README.md
	if ($l =~ /^$ansi_sequence_regex--- (a\/)?(.+?)(\e|$)/) {
		$f1 = $5;
	# Find the second file: +++ b/README.md
	} elsif ($l =~ /^$ansi_sequence_regex\+\+\+ (b\/)?(.+?)(\e|$)/) {
		if ($1) {
			print $1; # Print out whatever color we're using
		}
		$f2 = $5;

		# If they're the same it's a modify
		if ($f1 eq $f2) {
			print "modified: $f1\n";
		# If the first is /dev/null it's a new file
		} elsif ($f1 eq "/dev/null") {
			print "added: $f2\n";
		# If the second is /dev/null it's a deletion
		} elsif ($f2 eq "/dev/null") {
			print "deleted: $f1\n";
		# If the files aren't the same it's a rename
		} elsif ($f1 ne $f2) {
			print "renamed: $f1 to $f2\n";
		# Something we haven't thought of yet
		} else {
			print "$f1 -> $f2\n";
		}

		# Reset the vars
		my ($f1,$f2);
	# Just a regular line, print it out
	} else {
		print $l;
	}
}
