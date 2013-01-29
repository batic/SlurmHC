# -*- perl -*-

# t/013_run_Schroot-Chroot.t - try creating available (s)chroots

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
    skip "Testing chroots requires user to be in wheel, as will try su.", 10, unless $members=~/$username/;
    my $a=SlurmHC::Schroot::Chroot::run( run_dir => "/" );
    is $a->{result}, 0, "Schroot::Chroot results ok.";
    like $a->{info}[0], qr/creating session.*ok/, "Creating ok.";
    like $a->{info}[1], qr/testing session.*ok/, "Testing ok.";
    like $a->{info}[2], qr/ending session.*ok/, "Ending ok.";
    like $a->{info}[3], qr/creating session.*ok/, "Creating ok.";
    like $a->{info}[4], qr/testing session.*ok/, "Testing ok.";
    like $a->{info}[5], qr/ending session.*ok/, "Ending ok.";
    like $a->{info}[6], qr/creating session.*ok/, "Creating ok.";
    like $a->{info}[7], qr/testing session.*ok/, "Testing ok.";
    like $a->{info}[8], qr/ending session.*ok/, "Ending ok.";
};
