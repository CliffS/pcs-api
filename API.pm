package PCS::API;

use strict;
use warnings;
use 5.14.0;
use utf8;

use XML::Simple;
use JSON::XS;
use LWP;

use Data::Dumper;

use constant URI => 'https://www.pcs-isaac.co.uk/wsPCS.asmx/';

sub getstring(%)
{
    local $_;
    my %params = @_;
    my $string = '';
    foreach (keys %params)
    {
	(my $key = $_) =~ s/^./\u$&/;
	$key =~ s/(?<=_)\w/\u$&/g;
	$string .= "&$key=$params{$_}";
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
    my $string = getstring %params;
    my $url = URI . "$name?APIToken=$self->{apitoken}$string";
    say $url;
    my $ua = new LWP::UserAgent;
    my $response = $ua->get($url);
    say $response->code, " ", $response->message;
    my $xml = new XML::Simple;
    my $content = $xml->XMLin($response->decoded_content)->{content};
    my $json = new JSON::XS;
    my $result = $json->utf8->pretty->canonical->decode($content);
    return $result;
}

1;
