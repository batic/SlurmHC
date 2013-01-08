#!/usr/bin/perl
#

use SlurmHC qw( Load );

print "### NEW: \n";
my $t=SlurmHC->new();

print "### RUN: \n";
$t->run( SlurmHC::Load , load_max_5min=>0.002 );

print "### PRINT: \n";
$t->Print();

print "### END\n";
