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
    
    my $a=SlurmHC::Schroot::Session::run( run_dir => "/" );
    is $a->{result}, 0, "Schroot::Session results ok.";
    for(my $i=0;$i<=$#sessions;$i++){
	like $a->{info}[$i], qr/testing session.*ok/, "Testing ok.";
    }
};
