# -*- perl -*-

# t/003_disk_space.t - check scratch disk space availability

use Test::More 'no_plan';
use Test::Warn;

#try to: use SlurmHC
BEGIN { use_ok( 'SlurmHC::Basic' ); }

#construct new SlurmHC object and check if it is really a SlurmHC
my $object = SlurmHC::Basic->new();
isa_ok ($object, 'SlurmHC::Basic');

#check /data0 with warning 40GB and error 20GB
is $object->check_disk_space( "/data0", "40G", "20G" ) , 0 ,
    "Check /data0 with warning 40GB and error 20GB.";

#check /data0 with warning 240GB and error 20GB
warning_like { is $object->check_disk_space( "/data0", "240G", "20G" ) , 0, 
	       "Check /data0 with warning 240GB and error 20GB." } qr/getting filled/,
    "Check for warning with 240G warning level.";

#check /data0 with warning 240GB and error 220GB
is  $object->check_disk_space( "/data0", "240G", "220G" ), 1, 
	       "Check /data0 with warning 240GB and error 220GB.";

$object->Print();

#$object->Mail(qw(matej.batic@ijs.si batic.matej@gmail.com));
