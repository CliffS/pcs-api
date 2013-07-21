package PCS::API;

use strict;
use warnings;
use 5.14.0;
use utf8;

use XML::Simple;
use JSON::XS;
use LWP;
use URI::Escape;
use Hash::Case::Lower;

use Data::Dumper;
use Carp;

use constant URI => 'https://www.pcs-isaac.co.uk/wsPCS.asmx/';

sub getstring(%)
{
    local $_;
    tie my %params, 'Hash::Case::Lower';
    %params = @_;
    my $string = '';
    foreach (keys %params)
    {
	(my $key = $_) =~ s/^./\u$&/;
	$key =~ s/(?<=_)\w/\u$&/g;
	$string .= '&' . uri_escape($key) . '=' . uri_escape($params{$_});
    }
    return $string;
}


sub new
{
    my $class = shift;
    my $apitoken = shift;
    my $jobtype = shift;
    my $self = {
	apitoken    => $apitoken,
	jobtype	    => $jobtype,
    };
    bless $self, $class;
}

sub DESTROY { }

sub AUTOLOAD
{
    my $self = shift;
    my %params = @_;
    (my $name = our $AUTOLOAD) =~ s/.*:://;
    $name =~ s/^./\u$&/;
    $name =~ s/(?<=_)\w/\u$&/g;
    if ($name =~ /^instruct_appointment$/i)
    {
	my @optional = qw(
	Customer_Email_Address_2 
	Appointment_Address_Line_3 
	Appointment_Address_Line_4 
	Appointment_Alternate_Address_Line_1
	Appointment_Alternate_Address_Line_2
	Appointment_Alternate_Address_Line_3
	Appointment_Alternate_Address_Line_4
	Appointment_Alternate_Address_Postcode
	Appointment_Instructions 
	Appointment_Reference_Number 
	);
	my %optional = map { $_ => '' } @optional;
	$optional{Appointment_Alternate_Address} = 'No';
	%params = ( %optional, %params );
    }
    my $string = getstring %params;
    my $url = URI . "$name?APIToken=$self->{apitoken}$string";
    say $url;
    my $ua = new LWP::UserAgent;
    my $response = $ua->get($url);
    say '---  ', $response->code, " ", $response->message;
    croak $response->content unless $response->is_success;
    my $xml = new XML::Simple;
    my $content = $xml->XMLin($response->decoded_content)->{content};
    my $json = new JSON::XS;
    my $result = $json->utf8->decode($content);
    return $result;
}

sub download_paperwork
{
    my $self = shift;
    my %params = @_;
    my $string = getstring %params;
    my $url = URI . "Download_Paperwork?APIToken=$self->{apitoken}$string";
    say $url;
    my $ua = new LWP::UserAgent;
    my $response = $ua->get($url);
    say $response->code, " ", $response->message;
    return $response->content;
}

1;
