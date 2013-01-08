# -*- perl -*-

# t/004_import_Disk.t - check module import sub for Disk test package

use Test::More 'no_plan';

#importing Load module
my @imports = qw( Disk );
BEGIN { use_ok( 'SlurmHC', @imports ); }

#construct new SlurmHC object and check if it is really a SlurmHC
my $object = SlurmHC->new ();
isa_ok ($object, 'SlurmHC');

#try running VERSION
ok($object->VERSION, '0.1');
