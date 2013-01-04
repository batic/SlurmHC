# -*- perl -*-

# t/003_basic.t - check sub module SlurmHC::Basic

use Test::More 'no_plan';

#try to: use SlurmHC
BEGIN { use_ok( 'SlurmHC::Basic' ); }

#construct new SlurmHC object and check if it is really a SlurmHC
my $object = SlurmHC::Basic;
isa_ok ($object, 'SlurmHC::Basic');

#try running VERSION
is $object->VERSION(), 0.01, "Check for version.";

#try getting n_cpu
is $object->n_cpu, 4, "Are there exactly 4 cpus?"; 

#try running load_average
is $object->load_average, 0, "Is load average below 1.5*n_cpu?";

#try running load_average
is $object->load_average( (load_max=>2) ), 1, "Is load average below 0.55*n_cpu?";
