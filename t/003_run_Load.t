# -*- perl -*-

# t/003_run_Load.t - check running SlurmHC::Load

use Test::Most 'no_plan';
use Data::Dumper;

#try to: use SlurmHC
use_ok( 'SlurmHC::Load' );

#populate results to (deeply) compare with results from tests
my $res={
    info      => [],
    warning   => [],
    error     => [],
    result    => 0
};

#following tests should not fail
push $res->{info}, re("Tested load average is ok.");

#try running load_average
my $a=SlurmHC::Load::run( );
#print Dumper($a);
push $res->{warning}, re("Using default test");
cmp_deeply $a, $res, "Is load average below 1.5*n_cpu?";
$res->{warning}=[];

my $load=4;
$a=SlurmHC::Load::run( load_max_1min=>4 );
cmp_deeply $a, $res, "Is 1min load average below $load*n_cpu?";

$a=SlurmHC::Load::run( load_max_5min=>4 );
cmp_deeply $a, $res, "Is 5min load average below $load*n_cpu?";

$a=SlurmHC::Load::run( load_max_15min=>4 );
cmp_deeply $a, $res, "Is 15min load average below $load*n_cpu?";

$a=SlurmHC::Load::run( load_max_1min=>4, load_max_5min=>4 );
cmp_deeply $a, $res, "Are 1min and 5min load averages below $load*n_cpu?";

$a=SlurmHC::Load::run( load_max_1min=>4, load_max_15min=>4 );
cmp_deeply $a, $res, "Are 1min and 15min load averages below $load*n_cpu?";

$a=SlurmHC::Load::run( load_max_5min=>4, load_max_15min=>4 );
cmp_deeply $a, $res, "Are 5min and 15min load averages below $load*n_cpu?";

$a=SlurmHC::Load::run( load_max_4min=>4, load_max_9min=>4 );
#print Dumper($a);
push $res->{warning}, re("Unavailable option");
push $res->{warning}, re("Unavailable option");
push $res->{warning}, re("Using default test");
cmp_deeply $a, $res, "Are load_max_4min and load_max_9min arguments accepted?";
$res->{warning}=[];


#now run tests that will fail



#try running with really small load limit
#try running load_average for 1min, 5min, 15min, various couples and all
#my $load=0.005;

# warning_like { is($object->run( Load => \{ load_max_1min=>$load } ), 1,
# 		  "Is 1min load average below $load*n_cpu?") } qr/above limit/, "Check for warning.";

# warning_like { is($object->run( Load => \{ load_max_5min=>$load } ), 1,
# 		  "Is 5min load average below $load*n_cpu?") } qr/above limit/, "Check for warning.";

# warning_like { is($object->run( Load => \{ load_max_15min=>$load } ), 1,
# 		  "Is 15min load average below $load*n_cpu?") } qr/above limit/, "Check for warning.";

# warnings_like { is($object->run( Load => \{ load_max_1min=>$load, load_max_5min=>$load } ), 1,
# 		   "Are 1min and 5min load averages ok?") } [ qr/above limit/, qr/above limit/ ],
#     "Check for warnings.";

# warnings_like { is($object->run( Load => \{ load_max_1min=>$load, load_max_15min=>$load } ), 1,
# 		   "Are 1min and 15min load averages ok?") } [ qr/above limit/, qr/above limit/ ],
#     "Check for warnings.";

# warnings_like { is($object->run( Load => \{ load_max_5min=>$load, load_max_15min=>$load } ), 1,
# 		   "Are 5min and 15min load averages ok?") } [ qr/above limit/, qr/above limit/ ],
#     "Check for warnings.";

# warnings_like { is($object->run( Load => \{ load_max_1min=>$load, load_max_5min=>$load, load_max_15min=>$load } ), 1,
# 		  "Are 1min, 5min and 15min load averages ok?"); } [ qr/above limit/, qr/above limit/, qr/above limit/ ],
#     "Check for warnings.";

# #try running load_average with negative value
# $load=-0.5;
# warning_like { $object->run( Load => \{ load_max_1min=>$load } ) }
#  qr/Negative limit/ , "Check for negative load max for 1min average";

# warning_like { $object->run( Load => \{ load_max_5min=>$load } ) }
#  qr/Negative limit/ , "Check for negative load max for 5min average";

# warning_like { $object->run( Load => \{ load_max_15min=>$load } ) }
# qr/Negative limit/ , "Check for negative load max for 15min average";

# warnings_like { $object->run( Load => \{ load_max_1min=>$load,
# 			      load_max_5min=>$load,
# 			      load_max_15min=>$load } ) }
# [
#  qr/Negative limit/,
#  qr/Negative limit/,
#  qr/Negative limit/,
# ] , "Check for negative load max for all averages";

