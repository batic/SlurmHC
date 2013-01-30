# -*- perl -*-

# check SlurmHC module for status of (given) test

use Test::More 'no_plan';

#try to: use SlurmHC
BEGIN { use_ok( 'SlurmHC', qw( Disk ) ); }

#construct new SlurmHC object and check if it is really a SlurmHC
my $object = SlurmHC->new ();
isa_ok ($object, 'SlurmHC');

#check status, should be "wrong"
is $object->Status("Disk"), -2, "Disk check status: test not yet defined.";

#try running
is $object->run( Disk => { mount_point=>"/data0", warning_limit=>"1G", error_limit=>"1G" } ) , 0 ,
    "Check /data0 with warning 1GB and error 1GB.";

#check status, should be ok
is $object->Status("Disk"), 0, "Disk check status.";
