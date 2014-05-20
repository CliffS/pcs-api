# NAME

PCS::API - An interface into Private Client Solutions API

# VERSION

Version v1.0.0;

# SYNOPSIS

This is a full interface to the SOAP API for Private Client Solutions
(PCS), a UK document collection and delivery service.

    my $pcs = new PCS::API($apikey);
    my @jobtypes = $pcs->jobtypes;  # returns a hash of name => id
    my $jobid = $pcs->instruct(\%client, @files);

# CONSTRUCTOR

## new

    my $pcs = new PCS::API($apikey);

The only parameter is a string containing the secret API key as provided
by PCS.

# GENERAL METHODS

All the methods below act upon a PCS::API object constructed with
["new"](#new).

## jobtypes

This takes no parameters and returns a hash of the jobtypes in the
form of `jobtype =` jobtype\_id>.  The jobtype\_id is used in the
["instruct"](#instruct) method below.

    my %jobtypes = $pcs->jobtypes;
    my $id = $jobtypes{MYTYPE};

## instruct

This routine instructs PCS to send a courier to a given name
and address at a particular time.  It returns the job ID.

    my $job_id = $pcs->instruct($client, @files);

### parameters

- $client

    This is a hashref containing the following keys:

    - jobtype

        from above, required

    - reference

        This is our reference, required

    - title

        (e.g. Mr Mrs)

    - first\_name

        required

    - surname

        required

    - telephone
    - mobile
    - email
    - address1

        required

    - address2
    - town

        required

    - postcode

        formatted in the normal way, required

    - appointment

        this is a DateTime object.  The day should be Monday to Saturday,
        the hour must be between 8 and 20 inclusinve and the minutes
        must be a multiple of five.  It must be no earlier than 3 working
        hours from the time ["instruct"](#instruct) is called.

- @files

    This is an array of filenames to upload to the case.  These are the
    files that the courier will print off to take to an appointment.

- return value

    The case ID is returned.  This is the key for many of the functions
    below.

## download\_paperwork

This only downloads the paperwrk that was uploaded by the
courier, not the original uploaded paperwork.

    $items = $pcs->download_paperwork($id, $path);

- $id

    This is the case ID returned by ["instruct"](#instruct).

- $path

    This is the path to whicj the files should be downloaded.  

- return value

    This is the number of items downloaded.

## cancel

    $pcs->cancel($id);

This is used to cancel a case.  It is passed the case ID returned
from ["instruct"](#instruct).  There is no return value, the call croaks on error.

# SEARCH METHODS

All the search methods take a similar format.  They all
return eith a single case or an array of cases.
Each case is an instance of [PCS::Case](https://metacpan.org/pod/PCS::Case).  

Where an array of [PCS::Case](https://metacpan.org/pod/PCS::Case) is returned, it will be in order
of appointment time.  Most of the search functions can take an optional
start and end. These are `DateTime` objects limiting the earliest
and optionally the latest appointment times for the cases returned.

## get\_case

    my $case = $pcs->get_case($id);

This returns a single [PCS::Case](https://metacpan.org/pod/PCS::Case) for the given ID or `undef`
if not found.

## get\_by\_ref

    my @cases = $pcs->get_by_ref($reference);

This returns an array of [PCS::Case](https://metacpan.org/pod/PCS::Case) as there is no restriction
on duplicate references.

## get\_by\_postcode

    my @cases = $pcs->get_by_postcode($postcode);

This takes a formatted postcode and returns an array
of [PCS::Case](https://metacpan.org/pod/PCS::Case).

## get\_all\_cases

    my @cases = $pcs->get_all_cases([$start [,$end]]);

This returns all cases, all cases after $start (a `DateTime`)
or all cases between $start and $end inclusive.

## get\_by\_status

    my @cases = $pcs->get_by_status($status [,$start [, $end]]);

Gets all the cases in range with a particular status.  See
["PCS STATUSES"](#pcs-statuses) below for a full list of statuses.

## get\_complete

    my @cases = $pcs->get_complete([$start [, $end]]);

Gets all cases in range that are complete.  Complete means that
the paperwork has been returned and a tracking number is
available.

## get\_pending

    my @cases = $pcs->get_pending([$start [,$end]]);

Gets all pending cases (i.e. not complete, not signed and not failed).

## get\_signed

    my @cases = $pcs->get_signed([$start [,$end]]);

Gets all signed cases. This reurns all cases that have been successfully
signed.  The paperwork may not yet be available.

## get\_failed

    my @cases = $pcs->get_failed([$start [,$end]]);

Gets all failed cases, irrespective of the reason.

## get\_by\_jobtype

    my @cases = $pcs->get_by_jobtype($jobtype_id [, $start, [, $end]]);

Get all cases for a particular jobtype ID.

# PCS STATUSES

The following is a full list of the raw statuses provided by
the PCS API.

- TBA

    To be allocated - Your appointment has been successfully added to our portal
    and we are in the process of allocating a field agent to attend.  ALLOCATED
    Your appointment has been allocated to one of our field agents and will be
    attended on the specified date and time.

- SIGNED

    Your appointment has been attened by our filed agent and the client has signed
    the documentation.  UPLOADED Our field agent has uploaded scanned copies of the
    documentation that was completed on the appointment.

- COMPLETE

    Our field agent has posted the documentation and has added a Royal Mail
    tracking number for your reference.

- CANX\_AT

    The client was not in when our agent attended the appointment.

- CANX\_B4<60

    The appointment has been cancelled less than 60 minutes prior to the
    appointment time.

- CANX\_B4>60

    The appointment has been cancelled more than 60 minutes prior to the
    appointment time.

- REFUSED

    Our field agent attended your appointmetn but the customer was unwilling to
    sign or complete your documentation.

- PROBLEM

    This status is used by our internal team if they are struggling to find an
    agent to attend your appointment. You don't need to do anything, our internal
    team will contact you if we require any assistance

# EXPORTS

Nothing.

# BUGS

This is fairly untested code.  Expect bugs.

Also the calls to ["cancel"](#cancel) and ["download\_paperwork"](#download_paperwork) should
probably be calls on a single case.  Logically then, ["instruct"](#instruct)
should return a [PCS::Case](https://metacpan.org/pod/PCS::Case) rather than a case ID.

# SEE ALSO

[PCS::Case](https://metacpan.org/pod/PCS::Case) - and individual case returned by the search functions.

# AUTHOR INFORMATION

Cliff Stanford `<cliff@may.be>`

# SOURCE REPOSITORY

The source is maintained at a public Github repository at
[https://github.com/CliffS/pcs-api](https://github.com/CliffS/pcs-api).

# LICENCE AND COPYRIGHT

Copyright © 2014, Cliff Stanford `<cliff@may.be>`.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

-----------------------------------------------------------------------

# NAME

PCS::Case - represents a single case in the PCS::API module

# VERSION

Version v1.0.0

# SYNOPSIS

There is no public constructor for this class.  It is returned
exclusively by the search functions of [PCS::API](https://metacpan.org/pod/PCS::API).

    my $pcs = new PCS::API($apikey);
    my $case = $pcs->get_case($caseid);

# METHODS

The following methods are available.  None of the methods
takes a parameter.  For example:

    $caseid = $case->id;

- id

    The case id returned by ["instruct" in PCS::API](https://metacpan.org/pod/PCS::API#instruct).

- reference

    The reference given when the case was instructed.

- jobtype

    The job type ID of the case.

- jobtype\_name

    The name of the job type.

- name

    The customer name.

- postcode

    The customer's postcode.

- instructed

    A `DateTime` object representing the date and time the
    case was instructed.

- appointment

    A `DateTime` object representing the date and time of the
    original appointment.

- status

    The PCS status for the case.  See ["PCS STATUSES" in PCS::API](https://metacpan.org/pod/PCS::API#PCS-STATUSES).

- tracking

    The Royal Mail tracking number, if available.

- charge

    The charge made by PCS for this case.

The following boolean methods are all self-explanatory:

- cancelled
- signed
- is\_pending
- is\_signed
- is\_failed

# DEGUGGING

## dump

    my $case = $pcs->get_case($id);
    $case->dump;

Outputs all the fields of the case for debugging purposes.

# EXPORTS

Nothing.

# SEE ALSO

See [PCS::API](https://metacpan.org/pod/PCS::API) for copyright and all other information.
