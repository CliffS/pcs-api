package PCS::API;

use parent PCS::WSDL;

use strict;
use warnings FATAL => 'all';
use 5.14.0;
use utf8;

use MIME::Base64 qw(decode_base64 encode_base64);
use File::Basename qw(basename);
use File::Spec;
use Storable qw(freeze);

use Carp;

use Attribute::Boolean;
use PCS::Case;

=head1 NAME

PCS::API - An interface into Private Client Solutions API

=head1 VERSION

Version v1.0.0;

=cut

our $VERSION = v1.0.0;   # Don't forget the pod above

=head1 SYNOPSYS

This is a full interface to the SOAP API for Private Client Solutions
(PCS), a UK document collection and delivery service.

    my $pcs = new PCS::API($apikey);
    my @jobtypes = $pcs->jobtypes;  # returns a hash of name => id
    my $jobid = $pcs->instruct(\%client, @files);

=cut

use enum qw{NONE CASE REF INSTRUCTOR NAME POSTCODE STATUS};

sub byappointment
{
    $a->appointment <=> $b->appointment;
}

=head1 CONSTRUCTOR

=head2 new

    my $pcs = new PCS::API($apikey);

The only parameter is a string containing the secret API key as provided
by PCS.

=head1 GENERAL METHODS

All the methods below act upon a PCS::API object constructed with
L</new>.

=head2 jobtypes

This takes no parameters and returns a hash of the jobtypes in the
form of C<jobtype => jobtype_id>.  The jobtype_id is used in the
L</instruct> method below.

    my %jobtypes = $pcs->jobtypes;
    my $id = $jobtypes{MYTYPE};

=cut

sub jobtypes
{
    my $self = shift;
    my $response = $self->Get_Job_Types;
    my $types = $response->{Get_Job_TypesResult}{JobType};
    my %jobs = map { $_->{JobTypeName} => $_->{JobTypeID}  } @$types;
    return %jobs;
}

=head2 instruct

This routine instructs PCS to send a courier to a given name
and address at a particular time.  It returns the job ID.

    my $job_id = $pcs->instruct($client, @files);

=head3 parameters

=over

=item $client

This is a hashref containing the following keys:

=over

=item jobtype

from above, required

=item reference

This is our reference, required

=item title

(e.g. Mr Mrs)

=item first_name

required

=item surname

required

=item telephone

=item mobile

=item email

=item address1

required

=item address2

=item town

required

=item postcode

formatted in the normal way, required

=item appointment

this is a DateTime object.  The day should be Monday to Saturday,
the hour must be between 8 and 20 inclusinve and the minutes
must be a multiple of five.  It must be no earlier than 3 working
hours from the time L</instruct> is called.

=back

=item @files

This is an array of filenames to upload to the case.  These are the
files that the courier will print off to take to an appointment.

=item return value

The case ID is returned.  This is the key for many of the functions
below.

=back

=cut

# Returns ID
sub instruct
{
    my $self = shift;
    local $_;
    my ($params, @files) = @_;
    my $appointment = $params->{appointment};
    my %details = (
	JobTypeID   => $params->{jobtype},
	cTitle	    => $params->{title},
	cFirstName  => $params->{first_name},
	cLastName   => $params->{surname},
	cPhone1	    => $params->{telephone},
	cPhone2	    => $params->{mobile},
	cEmail1	    => $params->{email},
	cAddress1   => $params->{address1},
	cAddress2   => $params->{address2} || $params->{town},
	cAddress3   => $params->{address2} ? $params->{town} : undef,
	cPostcode   => $params->{postcode},
	apptDate    => $appointment->strftime('%d/%m/%Y'),
	apptHour    => $appointment->hour,
	apptMin	    => $appointment->min,
	referenceNo => $params->{reference},
	useAltAddress => false,
	claimCount  => 0,
    );
    $details{specialInstruction} = $params->{comment} if $params->{comment};
    my @attachments;
    foreach my $file (@files)
    {
	open my $hand, '<raw:', $file or croak "Can't open $file: $!";
	local $/;
	my $contents = <$hand>;
	my %attachment = (
	    FileName	=> basename($file),
	    FileData	=> encode_base64($contents, ''),
	);
	push @attachments, \%attachment;
    }
    my @instruction = (
	Details	    => \%details,
	Attachments => { CaseFile => \@attachments },
    );
    my $result = $self->Instruct_Appointment(@instruction);
    my @response = split /:/, $result->{Instruct_AppointmentResult};
    croak "@response" unless $response[0] eq 'OK';
    return $self->get_case($response[1]);
}

=head2 download_paperwork

This only downloads the paperwrk that was uploaded by the
courier, not the original uploaded paperwork.

    $items = $pcs->download_paperwork($id, $path);

=item $id

This is the case ID returned by L</instruct>.

=item $path

This is the path to whicj the files should be downloaded.  

=item return value

This is the number of items downloaded.

=back

=cut

# Returns the number of files downloaded
sub download_paperwork
{
    my $self = shift;
    my $id = shift // croak 'No ID';
    my $path = shift;
    croak "Not a directory: $path" unless -d $path;
    my $result = $self->Download_Paperwork(CaseNumber => $id);
    my @files = @{$result->{Download_PaperworkResult}{Paperwork}};
    my $count = 0;
    foreach my $file (@files)
    {
	next unless $file->{PaperworkType} eq 'ATTACHED';
	my $filename = File::Spec->catfile($path, $file->{FileName});
	$filename =~ s/\.\w*$/\L$&/;
	open my $hand, '>raw:', $filename or croak "Can't open $filename: $!";
	print $hand decode_base64($file->{FileData});
	close $hand;
	$count++;
    }
    return $count;
}

=head2 cancel

    $pcs->cancel($id);

This is used to cancel a case.  It is passed the case ID returned
from L</instruct>.  There is no return value, the call croaks on error.

=cut

# No return value: croaks on error.
sub cancel
{
    my $self = shift;
    my $id = shift;
    my $result = $self->Cancel_Appointment(CaseNumber => $id);
    $result = $result->{Cancel_AppointmentResult};
    croak $result->{Status} unless $result->{Status} eq 'OK';
}

=head1 SEARCH METHODS

All the search methods take a similar format.  They all
return eith a single case or an array of cases.
Each case is an instance of L<PCS::Case>.  

Where an array of L<PCS::Case> is returned, it will be in order
of appointment time.  Most of the search functions can take an optional
start and end. These are C<DateTime> objects limiting the earliest
and optionally the latest appointment times for the cases returned.

=cut

sub search
{
    my $self = shift;
    my ($mode, $term, $from, $to) = @_;
    my %query = (
	Mode    => $mode,
	Term    => $term,
    );
# Code removed as it doesn't work at the PCS end
#    if ($from)
#    {
#	$query{ApptFrom} = $from->strftime('%d/%m/%Y %H:%M:%S');
#	$query{ApptTo} = $to->strftime('%d/%m/%Y %H:%M:%S') if $to;
#    }
    state %cache;
    my @cases;
    $term //= '-';
    if (exists $cache{$mode}{$term})
    {
	@cases = @{$cache{$mode}{$term}};
    }
    else {
	my $result = $self->Search_Cases(Query => \%query);
	my $cases = $result->{Search_CasesResult}{SearchResults};
	push @cases, new PCS::Case($_) foreach @$cases;
	my @cache = @cases;
	$cache{$mode}{$term} = \@cache;
    }
    my $count = @cases;
    if ($from)
    {
	@cases = grep { $_->appointment >= $from } @cases;
	@cases = grep { $_->appointment <= $to } @cases if $to;
    }
    return @cases;
}

=head2 get_case

    my $case = $pcs->get_case($id);

This returns a single L<PCS::Case> for the given ID or C<undef>
if not found.

=cut

sub get_case
{
    my $self = shift;
    my $id = shift;
    my @cases = $self->search(CASE, $id);
    croak "More than one case returned: $id" if @cases > 1;
    return shift @cases;
}

=head2 get_by_ref

    my @cases = $pcs->get_by_ref($reference);

This returns an array of L<PCS::Case> as there is no restriction
on duplicate references.

=cut

sub get_by_ref
{
    my $self = shift;
    my $ref = shift;
    my @cases = $self->search(REF, $ref, @_);
    return sort byappointment @cases;
}

=head2 get_by_postcode

    my @cases = $pcs->get_by_postcode($postcode);

This takes a formatted postcode and returns an array
of L<PCS::Case>.

=cut

sub get_by_postcode
{
    my $self = shift;
    my $postcode = shift;
    my @cases = $self->search(POSTCODE, $postcode, @_);
    return sort byappointment @cases;
}

=head2 get_all_cases

    my @cases = $pcs->get_all_cases([$start [,$end]]);

This returns all cases, all cases after $start (a C<DateTime>)
or all cases between $start and $end inclusive.

=cut

sub get_all_cases
{
    my $self = shift;
    my @cases = $self->search(NONE, undef, @_);
    return sort byappointment @cases;
}

=head2 get_by_status

    my @cases = $pcs->get_by_status($status [,$start [, $end]]);

Gets all the cases in range with a particular status.  See
L</PCS STATUSES> below for a full list of statuses.

=cut

sub get_by_status
{
    my $self = shift;
    return $self->search(STATUS, @_);
}

=head2 get_complete

    my @cases = $pcs->get_complete([$start [, $end]]);

Gets all cases in range that are complete.  Complete means that
the paperwork has been returned and a tracking number is
available.

=cut

sub get_complete
{
    my $self = shift;
    my @cases = $self->get_by_status('COMPLETE', @_);
    return @cases;
}

=head2 get_pending

    my @cases = $pcs->get_pending([$start [,$end]]);

Gets all pending cases (i.e. not complete, not signed and not failed).

=cut

sub get_pending
{
    my $self = shift;
    my @cases;
    foreach (qw{TBA ALLOCATED PROBLEM})
    {
	push @cases, $self->get_by_status($_, @_);
    }
    return sort byappointment @cases;
}

=head2 get_signed

    my @cases = $pcs->get_signed([$start [,$end]]);

Gets all signed cases. This reurns all cases that have been successfully
signed.  The paperwork may not yet be available.

=cut

sub get_signed
{
    my $self = shift;
    my @cases;
    foreach (qw{SIGNED UPLOADED COMPLETE})
    {
	push @cases, $self->get_by_status($_, @_);
    }
    return sort byappointment @cases;
}

=head2 get_failed

    my @cases = $pcs->get_failed([$start [,$end]]);

Gets all failed cases, irrespective of the reason.

=cut

sub get_failed
{
    my $self = shift;
    my @cases;
    foreach (qw{CANX_AT CANX_B4<60 CANX_B4>60 REFUSED})
    {
	local $_ = $_;
	s/_/ /g;
	push @cases, $self->get_by_status($_, @_);
    }
    return sort byappointment @cases;
}

=head2 get_by_jobtype

    my @cases = $pcs->get_by_jobtype($jobtype_id [, $start, [, $end]]);

Get all cases for a particular jobtype ID.

=cut

sub get_by_jobtype
{
    my $self = shift;
    my $jobtype = shift;
    my @cases = $self->get_all_cases(@_);
    @cases = grep { $_->jobtype == $jobtype } @cases;
    return @cases;
}

=head1 PCS STATUSES

The following is a full list of the raw statuses provided by
the PCS API.

=over

=item TBA

To be allocated - Your appointment has been successfully added to our portal
and we are in the process of allocating a field agent to attend.  ALLOCATED
Your appointment has been allocated to one of our field agents and will be
attended on the specified date and time.

=item SIGNED

Your appointment has been attened by our filed agent and the client has signed
the documentation.  UPLOADED Our field agent has uploaded scanned copies of the
documentation that was completed on the appointment.

=item COMPLETE

Our field agent has posted the documentation and has added a Royal Mail
tracking number for your reference.

=item CANX_AT

The client was not in when our agent attended the appointment.

=item CANX_B4<60

The appointment has been cancelled less than 60 minutes prior to the
appointment time.

=item CANX_B4>60

The appointment has been cancelled more than 60 minutes prior to the
appointment time.

=item REFUSED

Our field agent attended your appointmetn but the customer was unwilling to
sign or complete your documentation.

=item PROBLEM

This status is used by our internal team if they are struggling to find an
agent to attend your appointment. You don't need to do anything, our internal
team will contact you if we require any assistance

=back

=head1 EXPORTS

Nothing.

=head1 BUGS

This is fairly untested code.  Expect bugs.

Also the calls to L</cancel> and L</download_paperwork> should
probably be calls on a single case.  Logically then, L</instruct>
should return a L<PCS::Case> rather than a case ID.

SEE ALSO

L<PCS::Case> - and individual case returned by the search functions.

=head1 AUTHOR INFORMATION

Cliff Stanford C<< <cliff@may.be> >>

=head1 SOURCE REPOSITORY

The source is maintained at a public Github repository at
L<https://github.com/CliffS/pcs-api>.

=head1 LICENCE AND COPYWRITE

Copyright © 2014, Cliff Stanford C<< <cliff@may.be> >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

1;
