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
is $a->{result}, 0, "Cvmfs result is ok.";
like $a->{info}[0], qr/ok, mounted on/, "Cvmfs info is ok.";

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
    push $res->{info}, "SlurmHC::Cvmfs::run: $t[0] ok, mounted on $t[5].";
}
cmp_deeply $a, $res, "All ok with results.";
