package PCS::API;

use base PCS::WSDL;

use strict;
use warnings;
use 5.14.0;
use utf8;

use MIME::Base64 qw(decode_base64 encode_base64);
use File::Basename qw(basename);
use File::Spec;

use Data::Dumper;
use Carp;

use CouchDB::Lite::Boolean;
use PCS::Case;

use enum qw{NONE CASE REF INSTRUCTOR NAME POSTCODE STATUS};

sub byappointment
{
    $a->appointment <=> $b->appointment;
}

sub jobtypes
{
    my $self = shift;
    my $response = $self->Get_Job_Types;
    my $types = $response->{Get_Job_TypesResult}{JobType};
    my %jobs = map { $_->{JobTypeName} => $_->{JobTypeID}  } @$types;
    return %jobs;
}

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
	cAddress2   => $params->{address2},
	cAddress3   => $params->{town},
	cPostcode   => $params->{postcode},
	apptDate    => $appointment->strftime('%d/%m/%Y'),
	apptHour    => $appointment->hour,
	apptMin	    => $appointment->min,
	referenceNo => $params->{id},
	useAltAddress => false,
	claimCount  => 0,
    );
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
    croak "$result" unless $response[0] eq 'OK';
    return $response[1];
}

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
	open my $hand, '>raw:', $filename or croak "Can't open $filename: $!";
	print $hand decode_base64($file->{FileData});
	close $hand;
	$count++;
    }
    return $count;
}

# No return value: croaks on error.
sub cancel
{
    my $self = shift;
    my $id = shift;
    my $result = $self->Cancel_Appointment(CaseNumber => $id);
    $result = $result->{Cancel_AppointmentResult};
    croak $result->{Status} unless $result->{Status} eq 'OK';
}

sub search
{
    my $self = shift;
    my ($mode, $term, $from, $to) = @_;
    my %query = (
	Mode    => $mode,
	Term    => $term,
    );
    if ($from)
    {
	if (ref $from && $from->isa('DateTime'))
	{
	    $query{ApptFrom} = $from->strftime('%d/%m/%Y %H:%M:%S');
	}
	else {
	    $query{ApptFrom} = $from;
	}
	if ($to)
	{
	    if (ref $to && $to->isa('DateTime'))
	    {
		$query{ApptTo} = $to->strftime('%d/%m/%Y %H:%M:%S');
	    }
	    else {
		$query{ApptTo} = $to;
	    }
	}
    }
    my $result = $self->Search_Cases(Query => \%query);
    my $cases = $result->{Search_CasesResult}{SearchResults};
    my @cases;
    push @cases, new PCS::Case($_) foreach @$cases;
    return @cases;
}

sub get_case
{
    my $self = shift;
    my $id = shift;
    my @cases = $self->search(CASE, $id);
    croak "More than one case returned: $id" if @cases > 1;
    return shift @cases;
}

sub get_by_status
{
    my $self = shift;
    return $self->search(STATUS, @_);
}

sub get_complete
{
    my $self = shift;
    my $from = shift;
    my @cases = $self->get_by_status('COMPLETE', $from);
    return @cases;
}

sub get_pending
{
    my $self = shift;
    my $from = shift;
    my @cases;
    foreach (qw{TBA ALLOCATED})
    {
	push @cases, $self->get_by_status($_, $from);
    }
    return sort byappointment @cases;
}


1;
