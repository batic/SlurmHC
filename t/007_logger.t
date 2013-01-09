# -*- perl -*-

# t/007_logger.t - check logging with SlurmHC::Log

use Test::More 'no_plan';
use Test::Warn;

#try to: use SlurmHC
BEGIN { use_ok( 'SlurmHC::Log' ); }

my $object=SlurmHC::Log->new( file=>"/tmp/SlurmHC.test.log", verbosity=>"all" );

isa_ok ($object, 'SlurmHC::Log');

is $object->Verbosity(), "all", "Checking verbosity.";
