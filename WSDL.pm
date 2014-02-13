package PCS::WSDL;

use strict;
use warnings;
use 5.14.0;
use utf8;

use SOAP::Simple;
use LWP;

use Data::Dumper;
$Data::Dumper::Deparse = 1;

use constant {
    URL	    => q(https://www.pcs-isaac.co.uk/PCSWeb.asmx?WSDL),
    TESTURL => q(http://test.pcs-isaac.co.uk/PCSWeb.asmx?WSDL),
};

sub new
{
    my $class = shift;
    my $token = shift;
    my $live = shift;
    my $ua = new LWP::UserAgent;
    my $url = $live ? URL : TESTURL;
    my $response = $ua->get($url);
    my $wsdl = new SOAP::Simple(
	wsdl => $response->decoded_content,
	port => 'PCSWebSoap',
    );
    my $self = {
	wsdl	=> $wsdl,
	token	=> $token,
    };
    bless $self, $class;
}

sub AUTOLOAD
{
    my $self = shift;
    my %params = @_;
    (my $name = our $AUTOLOAD) =~ s/.*:://;
    $params{Auth}{APIToken} = $self->{token};
    my $wsdl = $self->{wsdl};
    my $result =  $wsdl->$name(%params);
    return $result->{parameters};
}

sub DESTROY {}

1;
