package Quickdox::WSDL;

use strict;
use warnings;
use 5.14.0;
use utf8;

use SOAP::Simple;
use LWP;

use Data::Dumper;

use constant {
    URL	    => q(https://api.dash-portal.co.uk/ddf/v5/ddf.asmx?WSDL),
    TESTURL => q(https://uat.dash-portal.co.uk/v5dev/ddf.asmx?WSDL),
};

sub new
{
    my $class = shift;
    my $live = shift;
    my %credentials = @_;
    my $ua = new LWP::UserAgent;
    my $url = $live ? URL : TESTURL;
    my $response = $ua->get(URL);
    my $wsdl = new SOAP::Simple(
	wsdl => $response->decoded_content,
	port => 'ServiceSoap',
    );
    my $self = {
	wsdl	=> $wsdl,
	credentials => \%credentials,
    };
    bless $self, $class;
}

sub AUTOLOAD
{
    my $self = shift;
    my %params = @_;
    (my $name = our $AUTOLOAD) =~ s/.*:://;
    my $key = $name =~ /Case$/ ? 'Auth' : 'credentials';
    $params{$key} = $self->{credentials};
    my $wsdl = $self->{wsdl};
    my $result =  $wsdl->$name(%params);
    return $result;
}

sub DESTROY {}

1;
