# -*- perl -*-

# t/003_basic.t - check sub module SlurmHC::Basic

use Test::More 'no_plan';
use Test::Warn;

#try to: use SlurmHC
BEGIN { use_ok( 'SlurmHC::Basic' ); }

#construct new SlurmHC object and check if it is really a SlurmHC
my $object = SlurmHC::Basic->new();
isa_ok ($object, 'SlurmHC::Basic');

#try running VERSION
is $object->VERSION(), 0.01, "Check for version.";

#try getting n_cpu
is $object->n_cpu, 4, "Are there exactly 4 cpus?"; 

#try running load_average
is $object->load_average, 0, "Is load average below 1.5*n_cpu?";

#try running load_average for 1min, 5min, 15min, various couples and all
my $load=0.005;
warning_like { is($object->load_average( load_max_1min=>$load ), 1, 
		  "Is 1min load average below $load*n_cpu?") } qr/above limit/, "Check for warning.";

warning_like { is($object->load_average( load_max_5min=>$load ), 1, 
		  "Is 5min load average below $load*n_cpu?") } qr/above limit/, "Check for warning.";

warning_like { is($object->load_average( load_max_15min=>$load ), 1, 
		  "Is 15min load average below $load*n_cpu?") } qr/above limit/, "Check for warning.";

warnings_like { is($object->load_average( load_max_1min=>$load, load_max_5min=>$load ), 1, 
		   "Are 1min and 5min load averages ok?") } [ qr/above limit/, qr/above limit/ ], 
    "Check for warnings.";

warnings_like { is($object->load_average( load_max_1min=>$load, load_max_15min=>$load ), 1, 
		   "Are 1min and 15min load averages ok?") } [ qr/above limit/, qr/above limit/ ], 
    "Check for warnings.";

warnings_like { is($object->load_average( load_max_5min=>$load, load_max_15min=>$load ), 1, 
		   "Are 5min and 15min load averages ok?") } [ qr/above limit/, qr/above limit/ ], 
    "Check for warnings.";

warnings_like { is($object->load_average( load_max_1min=>$load, load_max_5min=>$load, load_max_15min=>$load ), 1, 
		   "Are 1min, 5min and 15min load averages ok?"); } [ qr/above limit/, qr/above limit/, qr/above limit/ ], 
    "Check for warnings.";

#try running load_average with negative value
$load=-0.5;
warning_like { $object->load_average( load_max_1min=>$load ) } 
 qr/Negative limit/ , "Check for negative load max for 1min average";

warning_like { $object->load_average( load_max_5min=>$load ) } 
 qr/Negative limit/ , "Check for negative load max for 5min average";

warning_like { $object->load_average( load_max_15min=>$load ) } 
qr/Negative limit/ , "Check for negative load max for 15min average";

warnings_like { $object->load_average( load_max_1min=>$load, 
				       load_max_5min=>$load, 
				       load_max_15min=>$load ) } 
[
 qr/Negative limit/,
 qr/Negative limit/,
 qr/Negative limit/,
] , "Check for negative load max for all averages";

