package PCS::WSDL;

use strict;
use warnings;
use 5.14.0;
use utf8;

use SOAP::Simple;
use LWP;
use Carp;

use constant {
    URL	    => q(https://www.pcs-isaac.co.uk/PCSWeb.asmx?WSDL),
    TESTURL => q(http://test.pcs-isaac.co.uk/PCSWeb.asmx?WSDL),
};

sub new
{
    my $class = shift;
    my $token = shift;
    my $live = shift;
    my $ua = new LWP::UserAgent( ssl_opts => { verify_hostname => 0 } );
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
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
    our $AUTOLOAD;
    { # Only allow to be called by subclasses (protected)
	my $caller = caller . '::ISA';
	no strict 'refs';
	croak "Unknown method $AUTOLOAD" unless grep {__PACKAGE__} @$caller;
    }
    my %params = @_;
    (my $name = $AUTOLOAD) =~ s/.*:://;
    $params{Auth}{APIToken} = $self->{token};
    my $wsdl = $self->{wsdl};
    my $result =  $wsdl->$name(%params);
    return $result->{parameters};
}

sub DESTROY {}

1;
