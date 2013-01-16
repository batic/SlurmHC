package SlurmHC::Cvmfs;

use strict;
use parent 'SlurmHC';

use Time::HiRes qw(gettimeofday tv_interval);
use vars qw($VERSION);

sub required{
  my @reqs=();
  return @reqs;
}

sub run{
  #start timing
  my $start_time=[gettimeofday]; #start timing

  my $self;
  if ($_[0] || ref $_[0]) {
    $self = shift if $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Cvmfs');
  }

  my $arg = { @_ };

  my $results={
	       info      => [],
	       warning   => [],
	       error     => [],
	       result    => 0,
	       elapsed   => 0
	      };

  #check cvmfs mount points (not! inside schroot)
  my @mounts = split /\n+/, `df | grep cvmfs`;
  if (!@mounts) {
    #since we expect cvmfs mounts!
    push $results->{error}, (caller(0))[3].": No cvmfs drives mounted.";
    $results->{result}=1;
  }
  foreach (@mounts){
    my @data = split /\s+/, $_;
    my $mountdir = $data[5];
    my $mountpoint = $data[0];
    my $syscall="find $mountdir -maxdepth 3 &> /dev/null || exit 1";
    system($syscall);
    if($? != 0){
      push $results->{error},
	(caller(0))[3].": $mountpoint could not be listed on $mountdir; error ".sprintf("%d",$?>>8);
      $results->{result}=1;
    }
    else{
      push $results->{info},
	(caller(0))[3].": $mountpoint ok, mounted on $mountdir.";
    }
  }

  #stop timing and add elapsed time
  my $end_time = [gettimeofday];
  $results->{elapsed} = tv_interval $start_time, $end_time;

  return $results;
}


1;

#################### main pod documentation begin ###################

=encoding utf8

=head1 NAME

    SlurmHC::Cvmfs - Slurm healtcheck (sub)package for testing cvmfs mounts

=head1 SYNOPSIS

    use SlurmHC qw( Cvmfs ); #or just
    use SlurmHC; #this way SlurmHC will auto-load all packages in @INC with same namespace

=head1 DESCRIPTION

    The test will first list all cvmfs mounts (from `df |grep cvmfs`) and will immediately issue error if no cvmfs mountpoints are available. Hence do not use this test when you do not expect! cvmfs mounts.
    The test will then try listing mountpoint and will issue error (printed in log) in case of failure.


=head1 EXAMPLE

    #!/usr/bin/perl

    use SlurmHC qw( Nfs );
    my $hc=SlurmHC->new( logfile=>"/path/to/logfile", verbosity=>"error" );
    $hc->run( Cvmfs => \{} );
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
