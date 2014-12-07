#!/usr/bin/env perl
use utf8;
use strict;

# main

$main::ask = 0;
if ( $ARGV[0] && $ARGV[0] =~ /^-h|--?help$/ ) {
	&help();
	exit 1;
} elsif ( $ARGV[0] && $ARGV[0] =~ /^-v|--?ask$/ ) {
	$main::ask = 1;
}
&main();

# helpers

sub help {
	print <<EOHELP;

Script to update ports in main host and all the jails.

Usage:
  $0 --help
  $0 [-v|--ask]

Options:
  -h, --help   Print this help message.
  -v, --ask    Ask for each step.

EOHELP
}

sub main {
	&run_command('portsnap fetch', 'fetch');
	&run_command('portsnap extract', 'extract');
	&run_command('portmaster -a', 'portmaster');
	&run_command('pkg audit -F', 'pkg-audit');
	&run_command('libchk | grep -v \'^Unreferenced library\'', 'libchk');
	$main::ask and ! &ask('Proceed with jails') and return;
	&run_command('ezjail-admin update -P');
	my @jails = &jls();
	for my $jail ( @jails ) {
		&run_command("jexec $jail->[0] portmaster -a",
			sprintf('portmaster@%u:%s', @$jail));
		&run_command("jexec $jail->[0] libchk | grep -v '^Unreferenced library'",
			sprintf('libchk@%u:%s', @$jail));
		&run_command("jexec $jail->[0] pkg audit -F",
			sprintf('pkg-audit@%u:%s', @$jail));
	}
}

# optional $_[1] is the question/script title to be set.
sub run_command {
	if ( ! $main::ask || &ask($_[1] || $_[0]) ) {
		printf "\033k%s\033\\", $_[1] || $_[0]; # screen title
		system $_[0];
		print "\033k \033\\"; # unset screen title
	}
}

# ask for step to be performed, with default yes answer
sub ask {
	print $_[0] . ' [Y/n] ';
	return <STDIN> =~ /^n/i ? 0 : 1;
}

sub jls {
	open JLS, 'jls |' or die "Failed to get jls output: $!";
	<JLS>; # read header
	my @jails = ();
	while ( <JLS> ) {
		s/^\s*//;
		push @jails, [ (split /\s+/, $_)[0,2] ];
		$jails[$#jails]->[1] =~ s/\..*$//;
	}
	close JLS;
	return @jails;
}

