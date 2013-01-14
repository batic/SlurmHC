# -*- perl -*-

# t/005_run_Nfs.t - check nfs mountpoints

use Test::Most 'no_plan';

sub check_timing{
    my $time=shift;
    return ($time>0) ? 1 : 0;
}

#try to: use SlurmHC
use_ok( 'SlurmHC::Nfs' );

#check nfs
my $a=SlurmHC::Nfs::run();
is $a->{result}, 0, "Nfs result is ok.";
like $a->{info}[0], qr/ok, mounted on/, "Nfs info is ok.";

#slightly wrong way to test, but right now it works
my $res={
    info      => [],
    warning   => [],
    error     => [],
    result    => 0,
    elapsed   => code(\&check_timing)
};

my @list=`df -t nfs | grep -v Available`;
use Data::Dumper;
foreach(@list){
    my @t=split(/\s+/,$_);
    push $res->{info}, "SlurmHC::Nfs::run: $t[0] ok, mounted on $t[5].";
}
cmp_deeply $a, $res, "All ok with results.";
