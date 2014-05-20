use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PCS::API',
    AUTHOR           => q{Cliff Stanford <cliff@may.be>},
    VERSION_FROM     => 'lib/PCS/API.pm',
    ABSTRACT_FROM    => 'lib/PCS/API.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
	'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
	'Test::More' => 0,
    },
    PREREQ_PM => {
	'MIME::Base64'	    => 3.13,
	'File::Basename'    => 2.82,
	'File::Spec'	    => 3.33,
	Storable	    => 2.27,
	DateTime	    => 0.74,
	'DateTime::Format::Strptime' => 1.51,
	Carp		    => 0,
	'SOAP::Simple'	    => 0.00_03,
	LWP		    => 6.04,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PCS-API-*' },
);
