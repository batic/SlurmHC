#!/usr/bin/perl

use Test::Harness;
use File::Find;

@tdirs = map ( glob(), "tests/" )
  or die "$0: Can't find any tests in tests/\n";

find( sub { /\.t\z/ and push @tests, $File::Find::name }, @tdirs );

@tests = sort { lc $a cmp lc $b } @tests
  or die "$0: Can't find any tests in @tdirs\n";

# Run the tests, using code from ExtUtils::testlib and ExtUtils::Command::MM

warn "$0: Found " . scalar(@tests) . " .t files for test harness.\n";

unshift @INC, qw( blib/arch blib/lib );
$Test::Harness::verbose = $ENV{TEST_VERBOSE} || 0;
Test::Harness::runtests( @tests );
