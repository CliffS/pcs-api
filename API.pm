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
use MIME::Base64 qw(encode_base64url encode_base64);
use Fcntl;
use Encode;

use Data::Dumper;
use Carp;

use constant URI => 'https://www.pcs-isaac.co.uk/wsPCS.asmx/';


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

sub getstring
{
    my $self = shift;
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
    $string = "?APIToken=$self->{apitoken}$string";
    return $string;
}

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
    my $string = $self->getstring(%params);
    my $url = URI . "$name$string";
    #say $url;
    my $ua = new LWP::UserAgent;
    my $response = $ua->get($url);
    #say '---  ', $response->code, " ", $response->message;
    croak $response->decoded_content unless $response->is_success;
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
    my $string = $self->getstring(%params);
    my $url = URI . "Download_Paperwork$string";
    #say $url;
    my $ua = new LWP::UserAgent;
    my $response = $ua->get($url);
    croak $response->decoded_content unless $response->is_success;
    return {
	filename    => $response->filename,
	file	    => $response->content,
    };
}

sub upload_case_paperwork
{
    my $self = shift;
    my %params = @_;
    my $filename = $params{filename};
    my $file;
    {
	local $/;
	open my $hand, $filename or croak "Open $filename: $!";
	$file = <$hand>;
	close $hand;
    }
    my $string = $self->getstring(%params);
    my $url = URI . "Upload_Case_Paperwork";
    #my $url = URI . "Upload_Case_Paperwork$string";
    say $url;
    $params{fileByte} = encode_base64($file, '');
    $string = $self->getstring(%params);
    my $ua = new LWP::UserAgent;
    #my $response = $ua->get($url);
    #return $response->decoded_content;
    my $response = $ua->post($url,
	Content => substr $string, 1
#	[
#	    APIToken => $self->{apitoken},
#	    Case_Number => $params{case_number},
#	    fileByte => encode_base64($file, ''),
#	    Filename => $filename,
#	],
##	Filename => $filename,
    );
    say Dumper $response; exit;
    say '---  ', $response->code, " ", $response->message;
    return $response->decoded_content;
}

sub upload_paperwork
{
    my $self = shift;
    my $filename = shift;
    #my $url = URI . 'upload-paperwork.aspx';
    my $url = 'https://www.pcs-isaac.co.uk/upload-paperwork.aspx';
    my $ua = new LWP::UserAgent;
    my $response = $ua->post($url,
	[
	    fileByte => [$filename],
	    FileName => $filename,
	    Content_Type => 'application/pdf',
	],
	Content_Type => 'form-data',
    );
    print $response->request->headers->as_string, "\n", $response->request->content;
    return $response->decoded_content;
}

1;
