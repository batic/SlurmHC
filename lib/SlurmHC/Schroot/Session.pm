package SlurmHC::Schroot::Session;

use strict;
use warnings;

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
    $self = shift if $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Schroot::Session');
  }

  my $arg = { run_as    => "prdatl01",
	      run_dir   => "./",
	      sessions  => "",
	      @_ };

  #results hashref
  my $results={
	       info      => [],
	       warning   => [],
	       error     => [],
	       result    => 0,
	       elapsed   => 0,
	      };


  #check for unavailable/unparsable options
  my $available_opts= { run_as=>'', run_dir=>'' , sessions=>'' };

  if(keys $arg){
    foreach(keys $arg){
      if(not defined $available_opts->{$_}){
	push $results->{warning}, (caller(0))[3]." Unavailable option \"$_\"!";
      }
    }
  }

  if( not SlurmHC::Utils::valid_user($arg->{run_as} ) ){
    push $results->{error}, (caller(0))[3]." User $arg->{run_as} does not exist!";
    $results->{result}=1;

    #stop timing and add elapsed time
    my $end_time = [gettimeofday];
    $results->{elapsed} = tv_interval $start_time, $end_time;

    return $results;
  }

  my @sessions;

  #first check if there is a list of sessions to check:
  if($arg->{sessions}!~/^\s*$/){
    @sessions = split /,\s*/, $arg->{sessions};
  }
  else{
    #list all available sessions
    my @tmp_sessions=split /\n+/, `schroot --list --all-session`;
    foreach (@tmp_sessions){
      my ($t, $session) = split ":", $_;
      push @sessions, $session;
    }
  }

  #list all available sessions
  my $available_sessions = join(",", split(/\n+/, `schroot --list --all-session`));

  my $number_of_tested_sessions=0;
  foreach my $session (@sessions) {
    if($available_sessions!~/$session/){
      push $results->{warning},
	(caller(0))[3].": session $session is not available!";
    }
    else{
      #try running something in the session
      #this will exit with 1 if schroot fails
      my $syscall="su $arg->{run_as} -c 'schroot -d $arg->{run_dir} -r -p -c ".$session." -- true &>/dev/null || exit 1'";
      system($syscall);
      if ($? != 0) {
	push $results->{error},
	  (caller(0))[3].": testing session $syscall exited with value ".sprintf("%d",$?>>8);
	$results->{result}=1;
      }
      else {
	push $results->{info},
	  (caller(0))[3].": testing session $session exited ok.";
      }
      $number_of_tested_sessions++;
    }
  }

  if(!$number_of_tested_sessions && $available_sessions!~/^\s*$/){
    push $results->{error},
      (caller(0))[3].": Defined sessions are unavailable and were not tested.";
    $results->{result}=1;
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

    SlurmHC::Schroot::Session - Slurm healtcheck (sub)package for testing chroots available in schroot

=head1 SYNOPSIS

    use SlurmHC qw( Schroot::Session ); #or just
    use SlurmHC; #this way SlurmHC will auto-load all packages in @INC with same namespace

=head1 DESCRIPTION



=head1 EXAMPLE

    #!/usr/bin/perl


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
