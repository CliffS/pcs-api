#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PCS::API' ) || print "Bail out!\n";
}

diag( "Testing PCS::API $PCS::API::VERSION, Perl $], $^X" );
