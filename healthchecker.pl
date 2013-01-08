#!/usr/bin/perl
#

use SlurmHC qw( Load Disk );

my $t=SlurmHC->new();

# $t->run
# ( 
#   SlurmHC::Load => \{ load_max_5min=>0.002 },
#   Load => \{ load_max_1min=>0.002 }
# );
# $t->run( Load => \{} );
# $t->run( Load => \{ load_max_5min=>2, load_max_15min=>1.5 } );

$t->run( Disk => \{} );
$t->run( Disk => \{ mount_point=>"/data0", warning_limit=>"240G", error_limit=>"20G" } );
$t->run( Disk => \{ mount_point=>"/data0", warning_limit=>"240G", error_limit=>"220G" } );
$t->run( Disk => \{ mount_point=>"/data0", warning_limit=>"24", error_limit=>"20" } );

$t->Print();


