#!/usr/bin/perl

use Modern::Perl;

use Nagios::NRPE::Client;
use Data::Dumper;
use Getopt::Std;
use File::Basename;
use Log::Log4perl;
use Dancer2;

my $default_nrpe_cfg_file       = "/etc/nagios/nrpe.cfg";
my $default_prometheus_port     = 9100;
my $default_max_check_processes = 5;
my $exename                     = basename($0);

## Configure logging
my $log4perl_conf = q(
    log4perl.rootLogger=INFO, SCREEN
    log4perl.appender.SCREEN = Log::Log4perl::Appender::Screen
    log4perl.appender.SCREEN.stderr = 0
    log4perl.appender.SCREEN.layout=PatternLayout
    log4perl.appender.SCREEN.layout.ConversionPattern=%d %C %p: %m%n
);
Log::Log4perl::init( \$log4perl_conf );
my $logger = Log::Log4perl->get_logger;

sub help_and_exit {
    print <<EOF_HELP

Run NRPE checks and export state and performance data on Prometheus /metrics endpoint

usage: $exename [-c <nrpe_cfg_file>] [-p <port] [-m <max_check_procs>]

    <nrpe_cfg_file>: file to parse for NRPE command definitions [default:$default_nrpe_cfg_file]
             <port>: port where Prometheus /metrics endpoint is exported [default:$default_prometheus_port]
  <max_check_procs>: maximum number of parallel NRPE checks to run when the /metrics endpoint is invoked [default:$default_max_check_processes]

EOF_HELP
      ;
    exit 0;
}

## Process config file and get check names
sub get_nrpe_checks {
  return qw( check_load check_cpu check_disk check_mem );
}

sub _get_nrpe_checks {
    my $cfg = shift;

    my @checks;

    open CFG, $cfg
      or die "Cound not open $cfg for reading\n";
    while ( my $line = <CFG> ) {
        chomp($line);
        if ( $line =~ /^command[(.+)]=/ ) {
            push @checks, $1;
        }
    }
    close CFG;
    return @checks;
}

# runs a given check and transforms the results to Prometheus metrics
sub nrpe_check_to_prometheus {
    my $check = shift;
    my $client = Nagios::NRPE::Client->new(
        host	=> "localhost",
        check	=> $check,
        ssl	=> 1
    );
    my $response = $client->run();
    my $nrpe_data = $response->{'buffer'};
    # process nrpe_data and return prometheus lines
    my @prom_lines;
    # ...
    return @prom_lines;
}

## Start main loop
$logger->info( "$exename starting..." );

# process CLI options
our ( $opt_c, $opt_p, $opt_m, $opt_h );
getopts("c:p:m:h");
defined($opt_h) and do { help_and_exit; };
my $nrpe_cfg_file       = $opt_c || $default_nrpe_cfg_file;
my $prometheus_port     = $opt_p || $default_prometheus_port;
my $max_check_processes = $opt_m || $default_max_check_processes;

# process config file and get NRPE check names
my @nrpe_checks = get_nrpe_checks($nrpe_cfg_file);
$logger->info( "Loaded NRPE checks: [ " .join(" ", @nrpe_checks ). " ]" );

# configure Dancer server
set port => $prometheus_port;
set content_type => 'text/plain; version=0.0.4; charset=utf-8';
set startup_info => 0;

# configure routes for Dancer
get '/metrics' => sub {
    my @lines;
    foreach my $check ( @nrpe_checks ) {
        push @lines, nrpe_check_to_prometheus( $check );
    }
};

# start Dancer HTTP server
$logger->info( "NRPE state and metrics server listening on port $prometheus_port" );
dance;

__END__

print Dumper( $response );

if(defined $response->{error}) {
  print "ERROR: Couldn't run check ".$client->check()." because of: ".$response->{reason}."\n";
} else {
  print $response->{buffer}."\n";
}
