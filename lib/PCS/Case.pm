package PCS::Case;

use strict;
use warnings;
use 5.14.0;
use utf8;

use DateTime;
use DateTime::Format::Strptime;
use Carp;

=head1 NAME

PCS::Case - represents a single case in the PCS::API module

=head1 VERSION

Version v1.0.0

=cut

our $VERSION = v1.0.0;

=head1 SYNOPSIS

There is no public constructor for this class.  It is returned
exclusively by the search functions of L<PCS::API>.

    my $pcs = new PCS::API($apikey);
    my $case = $pcs->get_case($caseid);

=cut

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
	jobtype	    => $result->{JobTypeID},
	jobtype_name=> $result->{JobType},
    };
    $self->{appointment}->set_formatter($formatter);
    $self->{instructed}->set_formatter($formatter);
    bless $self, $class;
}

=head1 METHODS

The following methods are available.  None of the methods
takes a parameter.  For example:

    $caseid = $case->id;

=over

=item id

The case id returned by L<PCS::API/instruct>.

=item reference

The reference given when the case was instructed.

=item jobtype

The job type ID of the case.

=item jobtype_name

The name of the job type.

=item name

The customer name.

=item postcode

The customer's postcode.

=item instructed

A C<DateTime> object representing the date and time the
case was instructed.

=item appointment

A C<DateTime> object representing the date and time of the
original appointment.

=item status

The PCS status for the case.  See L<PCS::API/"PCS STATUSES">.

=item tracking

The Royal Mail tracking number, if available.

=item charge

The charge made by PCS for this case.

=back

The following boolean methods are all self-explanatory:

=over

=item cancelled

=item signed

=item is_pending

=item is_signed

=item is_failed

=back

=cut

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

sub is_pending
{
    my $self = shift;
    return $self->status =~ /^(TBA|ALLOCATED|PROBLEM)$/;
}

sub is_signed
{
    my $self = shift;
    return $self->status =~ /^(SIGNED|UPLOADED|COMPLETE)$/;
}

sub is_failed
{
    my $self = shift;
    return $self->status =~ /^(CANX|REFUSED)/;
}

=head1 DEGUGGING

=head2 dump

    my $case = $pcs->get_case($id);
    $case->dump;

Outputs all the fields of the case for debugging purposes.

=cut

sub dump
{
    my $self = shift;
    printf "%-15s: %s\n", $_, $self->{$_} foreach sort keys %$self;
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

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

See L<PCS::API> for copywrite and all other information.

=cut

1;
