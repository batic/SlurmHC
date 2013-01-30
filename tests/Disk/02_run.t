# -*- perl -*-

# check scratch disk space availability

use Test::Most 'no_plan';
use Data::Dumper;

#try to: use SlurmHC
use_ok( 'SlurmHC::Disk' );

sub check_timing{
    my $time=shift;
    return ($time>0) ? 1 : 0;
}

#populate results to (deeply) compare with results from tests
my $res={
    info      => [],
    warning   => [],
    error     => [],
    result    => 0,
    elapsed   => code(\&check_timing)
};

#following tests should not fail
push $res->{info}, re("All ok");

#try running disk space test
my $a=SlurmHC::Disk->run( ); #print Dumper($a);
cmp_deeply $a, $res, "Default Disk test should be ok.";


#check /data0 with warning 40GB and error 20GB
$a=SlurmHC::Disk->run( mount_point=>"/data0", warning_limit=>"40G", error_limit=>"20G" ); #print Dumper($a);
cmp_deeply $a, $res, "Disk test should be ok.";

#check for warning
push $res->{warning}, re("getting filled up");
$a=SlurmHC::Disk->run( mount_point=>"/data0", warning_limit=>"240G", error_limit=>"20G" ); #print Dumper($a);
cmp_deeply $a, $res, "I should get a warning, but disk space is still ok.";

#check for configuration error warning
$res->{warning}=[];
push $res->{warning}, re("Configuration error");
$a=SlurmHC::Disk->run( mount_point=>"/data0", warning_limit=>"40", error_limit=>"20G" ); #print Dumper($a);
cmp_deeply $a, $res, "I should get a warning, but disk space is still ok.";

push $res->{warning}, re("Configuration error"); #two configuration errors now
$a=SlurmHC::Disk->run( mount_point=>"/data0", warning_limit=>"40", error_limit=>"20" ); #print Dumper($a);
cmp_deeply $a, $res, "I should get a warning, but disk space is still ok.";

#check for error due to wrong mount point
$res->{info}=[];
$res->{warning}=[];
$res->{result}=1;
push $res->{error}, re("does not exist");
$a=SlurmHC::Disk->run( mount_point=>"/dataZZZ" ); #print Dumper($a);
cmp_deeply $a, $res, "/dataZZZ does not exist.";

#check for error due to not enough space
$res->{error}=[];
push $res->{error}, re("Not enough diskspace on");
$a=SlurmHC::Disk->run( mount_point=>"/data0", error_limit=>"220G" ); #print Dumper($a);
cmp_deeply $a, $res, "Not enough diskspace if 220G are needed.";

