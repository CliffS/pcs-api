package PCS::Case;

use strict;
use warnings;
use 5.14.0;
use utf8;

use DateTime;
use DateTime::Format::Strptime;
use Carp;

sub new
{
    my $class = shift;
    my $result = shift;
    my $strp = new DateTime::Format::Strptime(
	pattern	    => '%d/%m/%Y %H:%M:%S',
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
    };
    bless $self, $class;
}

sub dump
{
    my $self = shift;
    foreach (sort keys %$self)
    {
	printf "%-15s: %s\n", $_, $self->{$_};
    }
    say "";
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
