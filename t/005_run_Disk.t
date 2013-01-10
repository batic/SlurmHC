# -*- perl -*-

# t/005_run_Disk.t - check scratch disk space availability

use Test::Most 'no_plan';
use Data::Dumper;

#try to: use SlurmHC
use_ok( 'SlurmHC::Disk' );

#populate results to (deeply) compare with results from tests
my $res={
    info      => [],
    warning   => [],
    error     => [],
    result    => 0
};

#following tests should not fail
push $res->{info}, re("All ok");

#try running disk space test
my $a=SlurmHC::Disk::run( ); #print Dumper($a);
cmp_deeply $a, $res, "Default Disk test should be ok.";


#check /data0 with warning 40GB and error 20GB
$a=SlurmHC::Disk::run( mount_point=>"/data0", warning_limit=>"40G", error_limit=>"20G" ); #print Dumper($a);
cmp_deeply $a, $res, "Disk test should be ok.";

#check for warning
push $res->{warning}, re("getting filled up");
$a=SlurmHC::Disk::run( mount_point=>"/data0", warning_limit=>"240G", error_limit=>"20G" ); #print Dumper($a);
cmp_deeply $a, $res, "I should get a warning, but disk space is still ok.";


# is $object->run( Disk => \{  } ) , 0 ,
#     "Check /data0 with warning 40GB and error 20GB.";

# #check /data0 with warning 240GB and error 20GB
# warning_like { is $object->run( Disk => \{ mount_point=>"/data0", warning_limit=>"240G", error_limit=>"20G" } ) , 0,
#     "Check /data0 with warning 240GB and error 20GB." } qr/getting filled up/,
#     "Check for warning with 240G warning limit.";

# #check /data0 with warning 240GB and error 220GB
# is $object->run(
#     Disk => \{ mount_point=>"/data0", warning_limit=>"240G", error_limit=>"220G" } ), 1,
#     "Check /data0 with warning 240GB and error 220GB.";

# warnings_like { is $object->run( Disk => \{ mount_point=>"/data0", warning_limit=>"40", error_limit=>"20" } ), 0, "Check /data0 with defaults because of config error." }
# [
#   qr/Configuration error/,
#   qr/Configuration error/
# ],
#     "Check /data0 with warning 40 and error 20 - expecting a warning in config.";
