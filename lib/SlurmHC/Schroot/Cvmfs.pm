package SlurmHC::Schroot::Cvmfs;

use strict;
use parent 'SlurmHC';

use Time::HiRes qw(gettimeofday tv_interval);
use vars qw($VERSION);

sub required{
  my @reqs=( qw/SlurmHC::Cvmfs SlurmHC::SlurmHC::Cvmfs/ );
  return @reqs;
}

sub run{
  #start timing
  my $start_time=[gettimeofday]; #start timing

  my $self;
  if ($_[0] || ref $_[0]) {
    $self = shift if $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Schroot::Cvmfs');
  }

  my $results={
	       info      => [],
	       warning   => [],
	       error     => [],
	       result    => 0,
	       elapsed   => 0
	      };

  my $arg = { run_as    => "prdatl01",
	      run_dir   => "./",
	      @_ };

  #check for unavailable/unparsable options
  my $available_opts= { run_as=>'', run_dir=>'' };

  if(keys $arg){
    foreach(keys $arg){
      if(not defined $available_opts->{$_}){
	push $results->{warning}, (caller(0))[3]." Unavailable option \"$_\"!";
      }
    }
  }

  if( not defined getpwnam($arg->{run_as})){
    push $results->{error}, (caller(0))[3]." User $arg->{run_as} does not exist!";
    $results->{result}=1;

    #stop timing and add elapsed time
    my $end_time = [gettimeofday];
    $results->{elapsed} = tv_interval $start_time, $end_time;

    return $results;
  }

  #list all available sessions and try connecting to them
  my @sessions = split /\n+/, `schroot --list --all-session`;

  foreach (@sessions) {
    my ($t, $session) = split ":", $_;

    #cvmfs inside chroot is bind to /cvmfs
    my $syscall="su $arg->{run_as} -c 'schroot -d $arg->{run_dir} -r -c $session -- find /cvmfs/ -maxdepth 3 &> /dev/null || exit 1'";
    system($syscall);
    if($? != 0){
      push $results->{error},
	(caller(0))[3].": /cvmfs/ could not be listed in session $session; exit value ".sprintf("%d",$?>>8);
      $results->{result}=1;

      #stop timing and add elapsed time
      my $end_time = [gettimeofday];
      $results->{elapsed} = tv_interval $start_time, $end_time;

      return $results;
    }
    else{
      push $results->{info},
	(caller(0))[3].": all ok with /cvmfs/ in session $session.";
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

    SlurmHC::Schroot::Cvmfs - Slurm healtcheck (sub)package for testing nfs mounts within chroot sessions

=head1 SYNOPSIS

    use SlurmHC qw( Schroot::Cvmfs );

=head1 DESCRIPTION

    The test will first list all nfs mounts (from `df -t nfs`) from within available chroot sessions and will immediately issue error if no nfs mountpoints are available. Hence do not use this test when you do not expect! mounted nfs drives.
    The test will then try listing mountpoint and will issue error (printed in log) in case of failure.


=head1 EXAMPLE



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
