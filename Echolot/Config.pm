package Echolot::Config;

# (c) 2002 Peter Palfrader <peter@palfrader.org>
# $Id: Config.pm,v 1.16 2002/07/07 00:42:46 weasel Exp $
#

=pod

=head1 Name

Echolot::Config - echolot configuration

=head1 DESCRIPTION

Sets default configuration options and
reads configuration from the config file.

=head1 FILES

The configuration file is searched in those places in that order:

=over

=item the file pointed to by the B<ECHOLOT_CONF> environment variable

=item `pwd`/pingd.conf

=item $HOME/echolot/pingd.conf

=item $HOME/pingd.conf

=item $HOME/.pingd.conf

=item /etc/pingd.conf

=back

=cut

use strict;
use warnings;
use XML::Parser;
use XML::Dumper;
use Carp;

my $CONFIG;

my @CONFIG_FILES = 
	( $ENV{'ECHOLOT_CONF'},
	  'pingd.conf',
	  $ENV{'HOME'}.'/echolot/pingd.conf',
	  $ENV{'HOME'}.'/pingd.conf',
	  $ENV{'HOME'}.'/.pingd.conf',
	  '/etc/pingd.conf' );
	  
sub init($) {
	my ($params) = @_;

	my $DEFAULT;
	$DEFAULT = {
		recipient_delimiter         => '+',
		dev_random                  => '/dev/random',
		hash_len                    => 8,
		addresses_default_ttl       => 5, # days
		smarthost                   => 'localhost',
		mailindir                   => 'mail',
		mailerrordir                => 'mail-errors',
		fetch_new                   => 1,
		ping_new                    => 1,
		show_new                    => 1,

		thesaurus                   => 1,

		processmail                 => 60,   # process incomng mail every minute
		pinger_interval             => 5*60, # send out pings every 5 minutes
		ping_every_nth_time         => 48,   # send out pings to the same remailer every 48 calls, i.e. every 4 hours
		buildstats                  => 5*60, # build statistics every 5 minutes
		buildkeys                   => 8*60*60, # build keyring every 8 hours
		commitprospectives          => 8*60*60, # commit prospective addresses every 8 hours
		expire                      => 24*60*60, # daily
		getkeyconf                  => 24*60*60, # daily
		build_thesaurus             => 60*60, # hourly
		
		resultdir                   => 'results',
		thesaurusdir                => 'results/thesaurus',
		thesaurusindexfile          => 'results/thesaurus/index.html',
		private_resultdir           => 'results.private',
		gnupghome                   => 'gnupg',
		tmpdir                      => 'tmp',
		prospective_addresses_ttl   => 432000, # 5 days
		reliable_auto_add_min       => 3, # 3 remailes need to list new address
		commands_file               => 'commands.txt',
		pidfile                     => 'pingd.pid',
		expire_keys                 => 5*24*60*60, # 5 days
		expire_confs                => 5*24*60*60, # 5 days
		expire_pings                => 12*24*60*60, # 12 days
		expire_thesaurus            => 21*24*60*60, # 21 days
		storage                     => {
			backend                 	=> 'File',
			File                    	=> {
				basedir             		=> 'data'
			}
		},

		do_pings => {
			'cpunk-dsa' => 1,
			'cpunk-rsa' => 1,
			'cpunk-clear' => 1,
			'mix' => 1
		},

		templates => {
			'thesaurusindexfile'    => 'templates/thesaurusindex.html',
			'mlist'                 => 'templates/mlist.html',
			'mlist2'                => 'templates/mlist2.html',
			'rlist2'                => 'templates/rlist2.html',
			'rlist'                 => 'templates/rlist.html',
		},
		
		homedir                     => undef,
		my_localpart                => undef,
		my_domain                   => undef,
		sitename                    => undef,
		verbose                     => 0
	};


	my $configfile = undef;
	for my $filename ( @CONFIG_FILES ) {
		if ( defined $filename && -e $filename ) {
			$configfile = $filename;
			last;
		};
	};

	die ("no Configuration file found\n") unless defined $configfile;
	
	{
		my $parser = new XML::Parser(Style => 'Tree');
		my $tree = $parser->parsefile($configfile);
		my $dump = new XML::Dumper;
		$CONFIG = $dump->xml2pl($tree);
	}
	
	for my $key (keys %$DEFAULT) {
		$CONFIG->{$key} = $DEFAULT->{$key} unless defined $CONFIG->{$key};
	};

	$CONFIG->{'verbose'} = 1 if ($params->{'verbose'});

	for my $key (keys %$CONFIG) {
		warn ("Config option $key is not defined\n") unless defined $CONFIG->{$key};
	};
};

sub get() {
	return $CONFIG;
};

sub dump() {
	# FIXME XML::Dumper bug workaround
	# There is a bug in pl2xml that changes data passed (cf. Debian Bug #148969 and #148970
	# at http://bugs.debian.org/148969 and http://bugs.debian.org/148970
	require Data::Dumper;
	my $storedata;
	eval ( Data::Dumper->Dump( [ $CONFIG ], [ 'storedata' ] ));

	my $dump = new XML::Dumper;
	my $data = $dump->pl2xml($storedata);

	print $data;
};

1;
# vim: set ts=4 shiftwidth=4:
