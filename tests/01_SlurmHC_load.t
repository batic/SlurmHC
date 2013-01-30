# -*- perl -*-

# check SlurmHC module loading 

use Test::More 'no_plan';

#try to: use SlurmHC
use_ok( 'SlurmHC' );

#construct new SlurmHC object and check if it is really a SlurmHC
my $object = SlurmHC->new ();
isa_ok ($object, 'SlurmHC');

#try running VERSION
ok($object->VERSION, '0.1');

