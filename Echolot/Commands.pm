package Echolot::Commands;

# (c) 2002 Peter Palfrader <peter@palfrader.org>
# $Id: Commands.pm,v 1.11 2002/09/11 03:10:27 weasel Exp $
#

=pod

=head1 Name

Echolot::Commands - manage commands like add key, set ttl etc.

=head1 DESCRIPTION

This package provides functions for sending out and receiving pings.

=cut

use strict;
use Carp qw{cluck};
use Fcntl ':flock'; # import LOCK_* constants
#use Fcntl ':seek'; # import SEEK_* constants
use POSIX; # import SEEK_* constants (older perls don't have SEEK_ in Fcntl)
use English;

sub addCommand($) {
	my ($command) = @_;

	my $filename = Echolot::Config::get()->{'commands_file'};
	open(FH, ">>$filename" ) or
		cluck("Cannot open $filename for appending $!"),
		return 0;
	flock(FH, LOCK_EX) or
		cluck("Cannot get exclusive lock on $filename: $!"),
		return 0;
	
	print FH $command,"\n";
	
	flock(FH, LOCK_UN) or
		cluck("Cannot unlock $filename: $!");
	close(FH) or
		cluck("Cannot close $filename: $!");
};

sub processCommands($) {
	my $filename = Echolot::Config::get()->{'commands_file'};

	(-e $filename) or
		return 1;
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks)= stat $filename;
	($size > 0) or
		return 1;
	
	open(FH, "+<$filename" ) or
		cluck("Cannot open $filename for reading: $!"),
		return 0;
	flock(FH, LOCK_EX) or
		cluck("Cannot get exclusive lock on $filename: $!"),
		return 0;
	

	while (<FH>) {
		chomp;
		my ($command, @args) = split;

		if ($command eq 'add') {
			Echolot::Globals::get()->{'storage'}->add_address(@args);
		} elsif ($command eq 'set') {
			Echolot::Globals::get()->{'storage'}->set_stuff(@args);
		} elsif ($command eq 'getkeyconf') {
			Echolot::Globals::get()->{'scheduler'}->schedule('getkeyconf', 0, time(), \@args );
		} elsif ($command eq 'sendpings') {
			Echolot::Globals::get()->{'scheduler'}->schedule('ping', 0, time(), \@args );
		} elsif ($command eq 'buildstats') {
			Echolot::Globals::get()->{'scheduler'}->schedule('buildstats', 0, time() );
		} elsif ($command eq 'buildkeys') {
			Echolot::Globals::get()->{'scheduler'}->schedule('buildkeys', 0, time() );
		} elsif ($command eq 'buildthesaurus') {
			Echolot::Globals::get()->{'scheduler'}->schedule('buildthesaurus', 0, time() );
		} elsif ($command eq 'delete') {
			Echolot::Globals::get()->{'storage'}->delete_remailer(@args);
		} elsif ($command eq 'setremailercaps') {
			my $addr = shift @args;
			my $conf = join(' ', @args);
			Echolot::Conf::set_caps_manually($addr, $conf);
		} elsif ($command eq 'deleteremailercaps') {
			Echolot::Globals::get()->{'storage'}->delete_remailercaps(@args);
		} else {
			warn("Unkown command: $_\n");
		};
	};

	seek(FH, 0, SEEK_SET) or
		cluck("Cannot seek to start $filename $!"),
		return 0;
	truncate(FH, 0) or
		cluck("Cannot truncate $filename to zero length: $!"),
		return 0;
	flock(FH, LOCK_UN) or
		cluck("Cannot unlock $filename: $!");
	close(FH) or
		cluck("Cannot close $filename: $!");
};

1;
# vim: set ts=4 shiftwidth=4:
