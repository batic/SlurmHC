# -*- perl -*-

# try creating available (s)chroots

use Test::Most 'no_plan';
use Data::Dumper;

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
    #default -> test all available chroots
    # my $a=SlurmHC::Schroot::Chroot::run( run_dir => "/" );
    # is $a->{result}, 0, "Schroot::Chroot results ok.";
    # my $number_of_chroots=`schroot --list | wc -l`;
    # foreach my $i (0..$number_of_chroots-1){
    # 	like $a->{info}[$i*3], qr/creating session.*ok/, "Creating ok.";
    # 	like $a->{info}[$i*3+1], qr/testing session.*ok/, "Testing ok.";
    # 	like $a->{info}[$i*3+2], qr/ending session.*ok/, "Ending ok.";
    # }
    
    #try just one 
    $a=SlurmHC::Schroot::Chroot::run( run_dir => "/", chroots => "sl6.x86_64" ); #print Dumper($a);
    is $a->{result}, 0, "Schroot::Chroot results for just one chroot.";
    like $a->{info}[0], qr/creating session.*ok/, "Creating chroot.";
    like $a->{info}[1], qr/testing session.*ok/, "Testing chroot.";
    like $a->{info}[2], qr/ending session.*ok/, "Ending chroot.";
    is @{$a->{info}}, 3, "Number of infos for just one chroot.";

    #try non-existing one
    $a=SlurmHC::Schroot::Chroot::run( run_dir => "/", chroots => "sl6.x8664" ); #print Dumper($a);
    is $a->{result}, 1, "Schroot::Chroot test results for non existing chroot ok.";
    like $a->{warning}[0], qr/chroot.*not available/, "Warning for nonexisting chroot.";
    like $a->{error}[0], qr/Defined chroots are unavailable and were not tested/, "Error for nonexisting chroot.";
    
    
    #try many
    $a=SlurmHC::Schroot::Chroot::run( run_dir => "/", chroots => "sl6.x86_64,sl5.x86_64" ); #print Dumper($a);
    is $a->{result}, 0, "Schroot::Chroot results for two chroots.";
    foreach my $i (0..1){
	like $a->{info}[$i*3], qr/creating session.*ok/, "Creating chroot.";
	like $a->{info}[$i*3+1], qr/testing session.*ok/, "Testing chroot.";
	like $a->{info}[$i*3+2], qr/ending session.*ok/, "Ending chroot.";
    }
    is @{$a->{info}}, 6, "Number of infos for just one chroot.";

    #try with SlurmHC
    my $hc=SlurmHC->new();
    my $result=$hc->run( 'Schroot::Chroot' => {run_dir => "/", chroots => "sl6.x86_64"});
    is $result, 0, "Running with SlurmHC.";
    
};
