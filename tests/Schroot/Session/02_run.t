# -*- perl -*-

# try connecting to running sessions

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
    my @sessions = split /\n+/, `schroot --list --all-session`;
    
    skip "Testing chroots requires user to be in wheel, as will try su.", $#sessions+2, unless $members=~/$username/;
    
    #default test of all sessions
    my $a=SlurmHC::Schroot::Session::run( run_dir => "/" );
    is $a->{result}, 0, "Schroot::Session results ok.";
    for(my $i=0;$i<=$#sessions;$i++){
	like $a->{info}[$i], qr/testing session.*ok/, "Testing ok.";
    }

    #test just one session (that is currently running)
    my ($t,$test_session)=split(/:/, $sessions[0]);
    $a=SlurmHC::Schroot::Session::run( run_dir => "/" , sessions=> $test_session );
    is $a->{result}, 0, "Schroot::Session testing currently running session.";
    like $a->{info}[0], qr/testing session.*ok/, "Testing ok.";
    is @{$a->{info}}, 1, "Number of infos.";
    
    #test non-existing session
    $a=SlurmHC::Schroot::Session::run( run_dir => "/" , sessions=> "parZeErrors" );
    is $a->{result}, 1, "Schroot::Session testing non-existing session.";
    like $a->{warning}[0], qr/session.*not available/, "Warning message for non-existing session.";
    like $a->{error}[0], qr/Defined sessions are unavailable and were not tested./, "Error message for non-existing session.";

    
};
