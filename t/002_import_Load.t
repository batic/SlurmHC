# -*- perl -*-

# t/002_load_submodules.t - check module import sub

use Test::More 'no_plan';

#importing Load module
my @imports = qw( Load );
BEGIN { use_ok( 'SlurmHC', @imports ); }

#construct new SlurmHC object and check if it is really a SlurmHC
my $object = SlurmHC->new ();
isa_ok ($object, 'SlurmHC');

#try running VERSION
ok($object->VERSION, '0.1');
