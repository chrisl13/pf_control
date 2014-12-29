#!/usr/bin/perl -w
# icinga: +epn

#
use strict;    # should never be differently :-)
use warnings;

use Nagios::Plugin;
use Net::SNMP;
use Scalar::Util qw(looks_like_number);

use Nagios::Plugin qw(%ERRORS);
use Nagios::Plugin::Functions qw(@STATUS_CODES);

sub main
{
my $VERSION = 0.1;
my $AUTHOR = 'christopher.livermore@playfish.com';
my $DEBUG   = 0;
my $TIMEOUT;

my $time_now = time();
my $max_age = 300; #5mins
my $MAX_ERROR_LEVEL=0;
my $CUSTOM_RECIPIENT="";

my $np = Nagios::Plugin->new(
    version => $VERSION,
    blurb   => "Plugin to check status of a server remotely via snmp. Status is computed locally on server and stored in a set of files.\nThe response returned by the plugin will be the most severe error level, chosen from, Error levels detected by the servers local checks, or one of the following ....:\nOK if no Errors reported\nWARN if any information returned by the server is unparseable\nCRITICAL if file doesn't exist, is out of date or can not connect via SNMP.",
    usage =>
"Usage: %s [ -d ] -H <host> -C <community> -o <oid> "
);

$np->add_arg(
    spec     => 'host|H=s',
    help     => 'Hostname / IP address to query',
    required => 1,
);

$np->add_arg(
    spec     => 'oid|o=s',
    help     => 'snmp OID. (ie, 1.3.6.1.4.1.2021.8.1.101.5)',
    required => 1,
);

$np->add_arg(
    spec     => 'community|C=s',
    help     => 'snmp community. (ie, pf_public)',
    required => 1,
);

$np->add_arg(
    spec     => 'debug|d=i',
    help     => 'Turn on debug',
    required => 0,
);

$np->getopts;

$DEBUG = $np->opts->get('debug');
$TIMEOUT = $np->opts->get('timeout') if (defined($np->opts->get('timeout')));

#-----------------
my @status_data = split("\n", getDataViaSNMP($np->opts->get('host'),$np->opts->get('community'),$np->opts->get('oid')), $np);

foreach (@status_data) {
	if ($_ =~ m/^#/) {
		#its a comment, ignore
	}
	elsif($_ =~ m/=/) {
		my @status_line = split("=", $_, 2) ;
		my $test_name = $status_line[0];
		my $test_result = $status_line[1];
		my $test_result_comment = "";
		if($test_result =~ m/:/) {
			my @result_data = split(":", $test_result,2) ;
			$test_result = $result_data[0];
			$test_result_comment = $result_data[1];
		}
		#Next block needs to error if TIMESTAMP line is NOT present also if pfcontrol_complete is NOT last line of file
		if ($test_name =~ "TIMESTAMP") {
			 if (!looks_like_number($test_result)) {
                                $np->add_message(CRITICAL, "Unknown Timestamp: ". $_ );
                                if ($ERRORS{"CRITICAL"} > $MAX_ERROR_LEVEL) {
                                        $MAX_ERROR_LEVEL = $ERRORS{"CRITICAL"};
                                }

			} else {
				if ($time_now - $test_result > $max_age) {
					print ("Stale data: " . $time_now . ":" . $test_result . "::::" . ($time_now - $test_result) . "\n") if ($DEBUG);
					$np->add_message(CRITICAL, "Stale Data: Last updated " . ($time_now - $test_result) . " seconds ago");
					$MAX_ERROR_LEVEL = $ERRORS{"CRITICAL"};
				} 
			}
		} elsif ($test_name =~ "owner_email" ) {
			$CUSTOM_RECIPIENT = $test_result;
			$np->add_perfdata( label => "email", value => $test_result);
		} else {
		# actual data, parse the results
			if (!looks_like_number($test_result)) {
				$np->add_message(CRITICAL, "Unknown Result: ". $_ );
				if ($ERRORS{"CRITICAL"} > $MAX_ERROR_LEVEL) {
					$MAX_ERROR_LEVEL = $ERRORS{"CRITICAL"};
				}
			} else {
				if ($test_result != 0) {
					if ($test_result > $ERRORS{"CRITICAL"}) { $test_result = $ERRORS{"CRITICAL"}; }
					if ($test_result > $MAX_ERROR_LEVEL) {
						$MAX_ERROR_LEVEL = $test_result;
					}
					if (length($test_result_comment) > 1) {
						$np->add_message($STATUS_CODES[$test_result], $test_name . "=" . $test_result . ":" . $test_result_comment);
					} else {
						$np->add_message($STATUS_CODES[$test_result], $test_name . "=" . $test_result);
					}
				}
			}
		}
	} else {
		#raise this as an error
		$np->add_message(CRITICAL, "Unknown Response: ". $_ );
		if ($ERRORS{"CRITICAL"} > $MAX_ERROR_LEVEL) {
			$MAX_ERROR_LEVEL = $ERRORS{"CRITICAL"};
		}
	}

} 

#Need to handle $CUSTOM_RECIPIENT);

#my ($code, $message) = $np->check_messages;
$np->nagios_exit($np->check_messages('join' => ',','join_all' => ','));
}



sub getDataViaSNMP {

    my ($host_to_check) = shift;
    my ($community) = shift;
    my ($OID_load) = shift;
    my ($np) = shift;

    my ( $session, $error ) = Net::SNMP->session(
        -hostname  => $host_to_check,
        -community => $community,
    );

# have exceeded the default message size. Might need to rethink the whole smtp approach
    $session->max_msg_size(65535);

   if (!defined($session)) {
     printf("ERROR opening session: %s.\n", $error);
     $np->add_message(WARNING, "ERROR opening session:". $error );
     $np->nagios_exit($np->check_messages('join' => ',','join_all' => ','));
     exit $ERRORS{"UNKNOWN"};
   }

    my $result = $session->get_request( -varbindlist => [$OID_load], );
#    my $error_message = $session->error();
#    print "$error_message\n";
    $session->close();

    alarm 0;

    if ( !defined($result) ) {
     $np->add_message(WARNING, " please check snmpd.conf as its missing OID ".$np->opts->get('oid') );
     $np->nagios_exit($np->check_messages('join' => ',','join_all' => ','));
     exit $ERRORS{"UNKNOWN"};
    }
    return $result->{$OID_load};

}

main;
