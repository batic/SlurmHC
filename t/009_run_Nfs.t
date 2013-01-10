# -*- perl -*-

# t/005_run_Nfs.t - check nfs mountpoints

use Test::More 'no_plan';
use Test::Warn;

#try to: use SlurmHC
BEGIN { use_ok( 'SlurmHC', qw( Nfs ) ); }

#construct new SlurmHC object and check if it is really a SlurmHC
my $object = SlurmHC->new( logfile=>"./logger.log", verbosity=>"debug" );
isa_ok ($object, 'SlurmHC');

#check /data0 with warning 40GB and error 20GB
is $object->run( Nfs => \{} ) , 0 ,
    "Check Nfs, hopefully no problems no so the test will pass.";
