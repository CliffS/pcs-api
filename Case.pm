package PCS::Case;

use strict;
use warnings;
use 5.14.0;
use utf8;

use DateTime;
use DateTime::Format::Strptime;
use Carp;
use Data::Dumper;

sub new
{
    my $class = shift;
    my $result = shift;
    # print Dumper $result; exit;
    my $strp = new DateTime::Format::Strptime(
	pattern	    => '%d/%m/%Y %H:%M:%S',
	locale	    => 'en_GB',
	time_zone   => 'Europe/London',
	on_error    => 'croak',
    );
    my $formatter = new DateTime::Format::Strptime(
	pattern   => '%e %b %Y at %H:%M',
	locale	    => 'en_GB',
	time_zone   => 'Europe/London',
	on_error    => 'croak',
    );	
    my $self = {
	id	    => $result->{CaseNo},
	name	    => $result->{CustomerName},
	status	    => $result->{Status},
	reference   => $result->{Reference},
	postcode    => $result->{Postcode},
	instructor  => $result->{Instructor},
	appointment => $strp->parse_datetime($result->{ApptDate}),
	instructed  => $strp->parse_datetime($result->{InstructionDate}),
	cost	    => $result->{Charge},
	tracking    => $result->{TrackingNo},
    };
    $self->{appointment}->set_formatter($formatter);
    $self->{instructed}->set_formatter($formatter);
    bless $self, $class;
}

sub cancelled
{
    my $self = shift;
    return $self->{status} =~ /^(CANX|REFUSED)/;
}

sub signed
{
    my $self = shift;
    return $self->{status} =~ /^(SIGNED|UPLOADED|COMPLETE)$/;
}

sub dump
{
    my $self = shift;
    printf "%-15s: %s\n", $_, $self->{$_} foreach sort keys %$self;
    say "";
}

sub jobtype
{
    my $self = shift;
    return rand 2 > 1 ? 53 : 150;
}

sub AUTOLOAD
{
    my $self = shift;
    (my $field = our $AUTOLOAD) =~ s/.*:://;
    croak "Unknown field: $field" unless exists $self->{$field};
    return $self->{$field};
}

sub DESTROY {}

1;
