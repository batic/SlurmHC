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

#try running load_average
my $a=SlurmHC::Load->run( ); #print Dumper($a);
push $res->{info}, re("Tested load average is ok.");
push $res->{warning}, re("Using default test");
cmp_deeply $a, $res, "Runing with defaults.";
$res->{warning}=[];
$res->{info}=[];

#try running with negative warning limit
$a=SlurmHC::Load->run( load_warn_1min=>-0.5 ); #print Dumper($a);
push $res->{warning}, re("Negative limit for warning 1min average.");
push $res->{warning}, re("Using default test");
push $res->{info}, re("Tested load average is ok.");
cmp_deeply $a, $res, "Runing with negative warning limit for 1min average.";
$res->{warning}=[];
$res->{info}=[];

$a=SlurmHC::Load->run( load_warn_5min=>-0.5 ); #print Dumper($a);
push $res->{warning}, re("Negative limit for warning 5min average.");
push $res->{warning}, re("Using default test");
push $res->{info}, re("Tested load average is ok.");
cmp_deeply $a, $res, "Runing with negative warning limit for 5min average.";
$res->{warning}=[];
$res->{info}=[];

$a=SlurmHC::Load->run( load_warn_15min=>-0.5 ); #print Dumper($a);
push $res->{warning}, re("Negative limit for warning 15min average.");
push $res->{warning}, re("Using default test");
push $res->{info}, re("Tested load average is ok.");
cmp_deeply $a, $res, "Runing with negative warning limit for 15min average.";
$res->{warning}=[];
$res->{info}=[];

$a=SlurmHC::Load->run( load_warn_1min=>-0.5, load_warn_5min=>-0.5 ); #print Dumper($a);
push $res->{warning}, re("Negative limit for warning 1min average.");
push $res->{warning}, re("Negative limit for warning 5min average.");
push $res->{warning}, re("Using default test");
push $res->{info}, re("Tested load average is ok.");
cmp_deeply $a, $res, "Runing with negative warning limit for 1 and 5 min average.";
$res->{warning}=[];
$res->{info}=[];

$a=SlurmHC::Load->run( load_warn_5min=>-0.5, load_warn_15min=>-0.5 ); #print Dumper($a);
push $res->{warning}, re("Negative limit for warning 5min average.");
push $res->{warning}, re("Negative limit for warning 15min average.");
push $res->{warning}, re("Using default test");
push $res->{info}, re("Tested load average is ok.");
cmp_deeply $a, $res, "Runing with negative warning limit for 5 and 15 min average.";
$res->{warning}=[];
$res->{info}=[];

$a=SlurmHC::Load->run( load_warn_1min=>-0.5, load_warn_15min=>-0.5 ); #print Dumper($a);
push $res->{warning}, re("Negative limit for warning 1min average.");
push $res->{warning}, re("Negative limit for warning 15min average.");
push $res->{warning}, re("Using default test");
push $res->{info}, re("Tested load average is ok.");
cmp_deeply $a, $res, "Runing with negative warning limit for 1 and 15 min average.";
$res->{warning}=[];
$res->{info}=[];

$a=SlurmHC::Load->run( load_warn_1min=>-0.5, load_warn_5min=>-0.5, load_warn_15min=>-0.5 ); #print Dumper($a);
push $res->{warning}, re("Negative limit for warning 1min average.");
push $res->{warning}, re("Negative limit for warning 5min average.");
push $res->{warning}, re("Negative limit for warning 15min average.");
push $res->{warning}, re("Using default test");
push $res->{info}, re("Tested load average is ok.");
cmp_deeply $a, $res, "Runing with negative warning limit for 1, 5 and 15 min average.";
$res->{warning}=[];
$res->{info}=[];



#run with small warning limit, expect a warning, but test should not fail
$a=SlurmHC::Load->run( load_warn_1min=>0.05); #print Dumper($a);
push $res->{warning}, re("Using default test");
push $res->{warning}, re("load average above warning limit");
push $res->{info}, re("Tested load average is ok.");
cmp_deeply $a, $res, "Running with very small warning limit for 1min average.";
$res->{warning}=[];
$res->{info}=[];

$a=SlurmHC::Load->run( load_warn_5min=>0.05); #print Dumper($a);
push $res->{warning}, re("Using default test");
push $res->{warning}, re("load average above warning limit");
push $res->{info}, re("Tested load average is ok.");
cmp_deeply $a, $res, "Running with very small warning limit for 5min average.";
$res->{warning}=[];
$res->{info}=[];

$a=SlurmHC::Load->run( load_warn_15min=>0.05); #print Dumper($a);
push $res->{warning}, re("Using default test");
push $res->{warning}, re("load average above warning limit");
push $res->{info}, re("Tested load average is ok.");
cmp_deeply $a, $res, "Running with very small warning limit for 15min average.";
$res->{warning}=[];
$res->{info}=[];



#run with small warning and max limit, expect a warning and fail
$a=SlurmHC::Load->run( load_warn_1min=>0.05, load_max_1min=>0.06); #print Dumper($a);
$res->{result}=1;
push $res->{warning}, re("load average above limit");
push $res->{error}, re("Tested load average is too high");
cmp_deeply $a, $res, "Running with very small warning and max limits for 1min average.";
$res->{warning}=[];
$res->{info}=[];
$res->{error}=[];


#run with small warning and large max limit, expect a warning and success
$a=SlurmHC::Load->run( load_warn_1min=>0.05, load_max_1min=>60); #print Dumper($a);
$res->{result}=0;
push $res->{warning}, re("load average above warning limit");
push $res->{info}, re("Tested load average is ok");
cmp_deeply $a, $res, "Running with very small warning and large max limits for 1min average.";
$res->{warning}=[];
$res->{info}=[];
