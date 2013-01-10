#!/usr/bin/perl
#

use SlurmHC qw( Load Disk );

my $t=SlurmHC->new();

# $t->run
# ( 
#   SlurmHC::Load => { load_max_5min=>0.002 },
#   Load => { load_max_1min=>0.002 }
# );
# $t->run( Load => {} );
# $t->run( Load => { load_max_5min=>2, load_max_15min=>1.5 } );

$t->run( 
    Load => {},
    Disk => { mount_point=>"/Volumes/gajba", warning_limit=>"240G", error_limit=>"20G" } 
  );
$t->Print();


