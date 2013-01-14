#!/usr/bin/perl
#

use SlurmHC;# qw( Load Disk );

my $t=SlurmHC->new( 
    file      => "logger.log", 
    verbosity => "debug" 
    );

$t->run( 
    Load => {},
    Disk => { mount_point=>"/data0", warning_limit=>"40G", error_limit=>"20G" },
    Nfs  => {}
  );
$t->Print();


