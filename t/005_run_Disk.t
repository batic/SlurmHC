# -*- perl -*-

# t/003_disk_space.t - check scratch disk space availability

use Test::More 'no_plan';
use Test::Warn;

#try to: use SlurmHC
BEGIN { use_ok( 'SlurmHC', qw( Disk ) ); }

#construct new SlurmHC object and check if it is really a SlurmHC
my $object = SlurmHC->new();
isa_ok ($object, 'SlurmHC');

#check /data0 with warning 40GB and error 20GB
is $object->run( Disk => \{ mount_point=>"/data0", warning_limit=>"40G", error_limit=>"20G" } ) , 0 ,
    "Check /data0 with warning 40GB and error 20GB.";

#check /data0 with warning 240GB and error 20GB
warning_like { is $object->run( Disk => \{ mount_point=>"/data0", warning_limit=>"240G", error_limit=>"20G" } ) , 0,
    "Check /data0 with warning 240GB and error 20GB." } qr/getting filled up/,
    "Check for warning with 240G warning limit.";

#check /data0 with warning 240GB and error 220GB
is $object->run( 
    Disk => \{ mount_point=>"/data0", warning_limit=>"240G", error_limit=>"220G" } ), 1,
    "Check /data0 with warning 240GB and error 220GB.";

warnings_like { is $object->run( Disk => \{ mount_point=>"/data0", warning_limit=>"40", error_limit=>"20" } ), 0, "Check /data0 with defaults because of config error." } 
[ 
  qr/Configuration error/,
  qr/Configuration error/
],
    "Check /data0 with warning 40 and error 20 - expecting a warning in config.";
