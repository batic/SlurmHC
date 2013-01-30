# -*- perl -*-

# check logging with SlurmHC::Log

use Test::More 'no_plan';
use Test::Warn;
use Test::Exception;

#try to: use SlurmHC
BEGIN { use_ok( 'SlurmHC::Log' ); }

#create new SlurmHC::Log
my $object=SlurmHC::Log->new( file=>"/tmp/SlurmHC.test.log", verbosity=>"all" );
isa_ok ($object, 'SlurmHC::Log');
is $object->Verbosity(), "all", "Checking verbosity.";
my $message="should be able to write this to /tmp/SlurmHC.test.log";
is $object->log($message), 0, "Checking logging to /tmp/.";

#try writing to non writtable file
SKIP: {
    skip "I am root and can write anywhere.", 1, if (getpwuid( $< ))=~/^root$/;
    dies_ok { $object=SlurmHC::Log->new( file=>"/SlurmHC.test.log", verbosity=>"all" ) } "Should not be able to write to /, so should die.";
};
