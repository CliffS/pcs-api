#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# all_pod_coverage_ok();

plan tests => 2;

pod_coverage_ok('PCS::API',
    {
	also_private => [
	    qr/^byappointment$/,
	    qr/^search$/,
	],
	trustme => []
    }
);

pod_coverage_ok('PCS::Case',
    {
	also_private => [
	    qr/^new$/,
	],
    }
);

