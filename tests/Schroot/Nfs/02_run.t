# -*- perl -*-

# try connecting to running sessions and check NFS within them

use Test::Most 'no_plan';

sub check_timing{
    my $time=shift;
    return ($time>0) ? 1 : 0;
}

#try to: use SlurmHC
use_ok( 'SlurmHC' );
my $o=SlurmHC->new( file=>"logger.log", verbosity=>"debug" );

#check nfs
my ($name,$passwd, $gid, $members) = getgrnam("wheel");
my $username=getpwuid( $< );

SKIP: {
    skip "Testing chroots requires user to be in wheel, as will try su.", 1, unless $members=~/$username/;
    my $a=$o->run( 'Schroot::Nfs' => { run_dir => "/" } );
    is $a, 0, "Schroot::Session results ok.";
};
