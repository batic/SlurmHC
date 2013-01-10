# -*- perl -*-

# t/005_run_Nfs.t - check nfs mountpoints

use Test::Most 'no_plan';

#try to: use SlurmHC
use_ok( 'SlurmHC::Nfs' );

#check nfs
my $a=SlurmHC::Nfs::run();
is $a->{result}, 0, "Nfs result is ok.";
like $a->{info}[0], qr/ok, mounted on/, "Nfs info is ok.";

TODO:{
    local $TODO = 'This test might not work on any other machine.';

    #slightly wrong way to test, but right now it works
    my $res={
	info      => [],
	warning   => [],
	error     => [],
	result    => 0
    };
    push $res->{info}, "SlurmHC::Nfs::run: f9sn005:/d02 ok, mounted on /var/lib/schroot/mount/slc5.x86_64-run/net/f9sn005/d02.";
    push $res->{info}, "SlurmHC::Nfs::run: pikolit:/d0/nfs ok, mounted on /var/lib/schroot/mount/slc5.x86_64-run/net/pikolit/d0/nfs.";
    push $res->{info}, "SlurmHC::Nfs::run: pikolit:/d0/nfs ok, mounted on /net/pikolit/d0/nfs.";
    push $res->{info}, "SlurmHC::Nfs::run: pikolit:/d0/nfs ok, mounted on /var/lib/schroot/mount/sl5.x86_64-run/net/pikolit/d0/nfs.";
    push $res->{info}, "SlurmHC::Nfs::run: f9sn006:/d01 ok, mounted on /var/lib/schroot/mount/slc5.x86_64-run/net/f9sn006/d01.";
    push $res->{info}, "SlurmHC::Nfs::run: f9sn007:/d02 ok, mounted on /net/f9sn007/d02.";
    push $res->{info}, "SlurmHC::Nfs::run: f9sn007:/d02 ok, mounted on /var/lib/schroot/mount/slc5.x86_64-run/net/f9sn007/d02.";
    push $res->{info}, "SlurmHC::Nfs::run: f9sn007:/d01 ok, mounted on /var/lib/schroot/mount/slc5.x86_64-run/net/f9sn007/d01.";
    push $res->{info}, "SlurmHC::Nfs::run: f9sn007:/d01 ok, mounted on /net/f9sn007/d01.";

    cmp_deeply $a, $res, "All ok with results.";
}	   
