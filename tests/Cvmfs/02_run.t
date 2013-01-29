# -*- perl -*-

# t/011_run_Cvmfs.t - check cvmfs

use Test::Most 'no_plan';

sub check_timing{
    my $time=shift;
    return ($time>0) ? 1 : 0;
}

#try to: use SlurmHC
use_ok( 'SlurmHC::Cvmfs' );

#check cvmfs as function
my $a=SlurmHC::Cvmfs::run();
is $a->{result}, 0, "Cvmfs (without mount_points) result is ok.";
like $a->{info}[0], qr/ok/, "Cvmfs (without mount_points) info is ok.";

#slightly wrong way to test, but right now it works
my $res={
    info      => [],
    warning   => [],
    error     => [],
    result    => 0,
    elapsed   => code(\&check_timing)
};

my @list=`df | grep cvmfs`;
use Data::Dumper;
foreach(@list){
    my @t=split(/\s+/,$_);
    push $res->{info}, "SlurmHC::Cvmfs::run: $t[5] ok";
}
cmp_deeply $a, $res, "All ok with results.";


$a=SlurmHC::Cvmfs::run( 
    mount_points=>"
             /cvmfs.local/atlas.cern.ch,
             /cvmfs.local/atlas-condb.cern.ch,
             /cvmfs.local/atlas-nightlies.cern.ch,
             /cvmfs.local/belle.cern.ch"
    );
is $a->{result}, 0, "Cvmfs (with 4 mount_points) result is ok."; #print Dumper($a);
like $a->{info}[0], qr/ok/, "Cvmfs (with mount_points) info[0] is ok.";
like $a->{info}[1], qr/ok/, "Cvmfs (with mount_points) info[1] is ok.";
like $a->{info}[2], qr/ok/, "Cvmfs (with mount_points) info[2] is ok.";
like $a->{info}[3], qr/ok/, "Cvmfs (with mount_points) info[3] is ok.";
