# -*- perl -*-

# check running SlurmHC::Load

use Test::Most 'no_plan';
use Data::Dumper;

#try to: use SlurmHC
use_ok( 'SlurmHC::Load' );

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
    elapsed   => code(\&check_timing),
};

#following tests should not fail
push $res->{info}, re("Tested load average is ok.");

#try running load_average
my $a=SlurmHC::Load->run( );
#print Dumper($a);
push $res->{warning}, re("Using default test");
cmp_deeply $a, $res, "Is load average below 1.5*n_cpu?";
$res->{warning}=[];

my $load=4;
$a=SlurmHC::Load->run( load_max_1min=>$load );
cmp_deeply $a, $res, "Is 1min load average below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_5min=>$load );
cmp_deeply $a, $res, "Is 5min load average below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_15min=>$load );
cmp_deeply $a, $res, "Is 15min load average below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_1min=>$load, load_max_5min=>$load );
cmp_deeply $a, $res, "Are 1min and 5min load averages below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_1min=>$load, load_max_15min=>$load );
cmp_deeply $a, $res, "Are 1min and 15min load averages below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_5min=>$load, load_max_15min=>$load );
cmp_deeply $a, $res, "Are 5min and 15min load averages below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_1min=>$load, load_max_5min=>$load, load_max_15min=>$load );
cmp_deeply $a, $res, "Are 1min, 5min and 15min load averages below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_4min=>$load, load_max_9min=>$load );
#print Dumper($a);
push $res->{warning}, re("Unavailable option");
push $res->{warning}, re("Unavailable option");
push $res->{warning}, re("Using default test");
cmp_deeply $a, $res, "Are load_max_4min and load_max_9min arguments accepted?";
$res->{warning}=[];

#now run tests that will fail due to really small load limit
$load=0.005;
$res->{result}=1;
$res->{info}=[];
push $res->{warning}, re("load average above limit");
push $res->{error}, re("Tested load average is too high");
$a=SlurmHC::Load->run( load_max_1min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Is 1min load average below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_5min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Is 5min load average below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_15min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Is 15min load average below $load*n_cpu?";

push $res->{warning}, re("load average above limit"); #two tests giving warnings!
$a=SlurmHC::Load->run( load_max_1min=>$load, load_max_5min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Are 1min and 5min load averages below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_1min=>$load, load_max_15min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Are 1min and 15min load averages below $load*n_cpu?";

$a=SlurmHC::Load->run( load_max_5min=>$load, load_max_15min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Are 5min and 15min load averages below $load*n_cpu?";

push $res->{warning}, re("load average above limit"); #three tests giving warnings!
$a=SlurmHC::Load->run( load_max_1min=>$load, load_max_5min=>$load, load_max_15min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Are 1min, 5min and 15min load averages below $load*n_cpu?";

$res->{result}=0;
$res->{info}=[];
$res->{warning}=[];
$res->{error}=[];
push $res->{warning}, re("load average above limit");
$a=SlurmHC::Load->run( load_max_1min=>$load, load_max_5min=>5 ); #print Dumper($a);
cmp_deeply $a, $res, "Are both 1min and 5min load averages failing? They shouldn't.";

$a=SlurmHC::Load->run( load_max_1min=>$load, load_max_15min=>5 ); #print Dumper($a);
cmp_deeply $a, $res, "Are both 1min and 15min load averages failing? They shouldn't.";

#try running load_average with negative value
$load=-0.5;
$res->{result}=0;
$res->{info}=[];
$res->{warning}=[];
$res->{error}=[];
push $res->{info}, re("Tested load average is ok.");
push $res->{warning}, re("Negative limit");
push $res->{warning}, re("Using default test");
$a=SlurmHC::Load->run( load_max_1min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Checking negative limit for 1min average.";

$a=SlurmHC::Load->run( load_max_5min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Checking negative limit for 5min average.";

$a=SlurmHC::Load->run( load_max_15min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Checking negative limit for 15min average.";

$res->{warning}=[];
push $res->{warning}, re("Negative limit");
push $res->{warning}, re("Negative limit");
push $res->{warning}, re("Negative limit");
push $res->{warning}, re("Using default test");
$a=SlurmHC::Load::run( load_max_1min=>$load, load_max_5min=>$load, load_max_15min=>$load ); #print Dumper($a);
cmp_deeply $a, $res, "Checking negative limit for all averages.";

