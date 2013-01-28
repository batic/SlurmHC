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
my $a=SlurmHC::Nfs::run();#print Dumper($a);
is $a->{result}, 0, "Nfs result from default test is ok.";
like $a->{info}[0], qr/ok/, "Nfs info is ok.";

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
    push $res->{info}, "SlurmHC::Nfs::run: listing $t[5] ok";
}
cmp_deeply $a, $res, "All ok with results from default test.";

#check nfs
$a=SlurmHC::Nfs::run( 
      mount_points => "/var/lib/schroot/mount/slc5.x86_64-run/net/pikolit/d0/nfs,/net/f9sn005/d02"
    );#print Dumper($a);
is $a->{result}, 0, "Nfs result from mount_points is ok.";
like $a->{info}[0], qr/ok/, "Nfs info from mount_points test is ok.";


#check nfs
$a=SlurmHC::Nfs::run( 
    exports => "f9sn007:/d02,f9sn007:/d01"
    );#print Dumper($a);
is $a->{result}, 0, "Nfs result from exports test is ok.";
like $a->{info}[0], qr/ok/, "Nfs info from exports test is ok.";


#check nfs
$a=SlurmHC::Nfs::run( 
    exports => "f9sn007:/d02,f9sn007:/d01",
    mount_points => "/var/lib/schroot/mount/slc5.x86_64-run/net/f9sn007/d01"
    );#print Dumper($a);
is $a->{result}, 0, "Nfs result from both exports and mount_points is ok.";
like $a->{info}[0], qr/ok/, "Nfs info from both exports and mount_points is ok.";
like $a->{info}[1], qr/ok/, "Nfs info from both exports and mount_points is ok.";
like $a->{info}[2], qr/ok/, "Nfs info from both exports and mount_points is ok.";
