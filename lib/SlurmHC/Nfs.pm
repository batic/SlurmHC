package SlurmHC::Nfs;

BEGIN{
    use strict;
    use parent 'SlurmHC';
    use vars qw($VERSION);
}

sub n_cpu {
    my @ncpu = grep(/^processor/,`cat /proc/cpuinfo`);
    return $#ncpu+1;
}


sub run{
    my $self;
    $self = shift if ref $_[0] and $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Nfs');
    my $parent = shift;


    #list all mounted nfs points
    my @mounts = split /\n+/, `df -t nfs | grep -v Available`;
    if(!@mounts){
      #since we expect at least "some" nfs mounts
      $parent->Error((caller(0))[3],"No nfs drives mounted.");
      return 1;
    }
    my $return_val=0;
    foreach (@mounts){
      my @data = split /\s+/, $_;
      my $mountdir = $data[5];
      my $mountpoint = $data[0];
      my $syscall="ls -l $mountdir/ &>/dev/null || exit 1";
      system($syscall);
      if($? != 0){
	$parent->Error((caller(0))[3],"$mountpoint could not be listed on $mountdir; error ".sprintf("%d",$?>>8));
	$return_val=1;
      }
      else{
	$parent->Info((caller(0))[3],"$mountpoint ok, mounted on $mountdir.");
      }
    }

    return $return_val;
}


1;

#################### main pod documentation begin ###################

=encoding utf8

=head1 NAME

    SlurmHC::Nfs - Slurm healtcheck (sub)package for testing nfs mounts

=head1 SYNOPSIS

    use SlurmHC qw( Nfs );

=head1 DESCRIPTION

    The test will first list all nfs mounts (from `df -t nfs`) and will immediately issue error if no nfs mountpoints are available. Hence do not use this test when you do not expect! mounted nfs drives.
    The test will then try listing mountpoint and will issue error (printed in log) in case of failure.


=head1 EXAMPLE

    #!/usr/bin/perl

    use SlurmHC qw( Nfs );
    my $hc=SlurmHC->new( logfile=>"/path/to/logfile", verbosity=>"error" );
    $hc->run( Nfs => \{} );
    $hc->Print();

=head1 AUTHOR

    Matej Batič
    matej.batic@ijs.si


=head1 COPYRIGHT

    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

    SlurmHC.

=cut

#################### main pod documentation end ###################
