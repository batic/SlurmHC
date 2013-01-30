package SlurmHC::Schroot::Chroot;

use strict;
use warnings;

use parent 'SlurmHC';
use SlurmHC::Utils;

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
    $self = shift if $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Schroot::Chroot');
  }

  my $arg = { run_as    => "prdatl01",
	      run_dir   => "./",
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
  my $available_opts= { run_as=>'', run_dir=>'', chroots=>'' };

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

  my @chroots;

  #first check if there is a list of chroots to check:
  if($arg->{chroots}!~/^\s*$/){
    @chroots = split /,\s*/, $arg->{chroots};
  }
  else{
    #list all available chroots
    my @tmp_chroots=split /\n+/, `schroot --list --all-chroot`;
    foreach (@tmp_chroots){
      my ($t, $chroot) = split ":", $_;
      push @chroots, $chroot;
    }
  }

  #list all available chroots
  my $available_chroots = join(",", split(/\n+/, `schroot --list --all-chroot`));

  my $number_of_tested_chroots=0;
  foreach my $chroot (@chroots) {
    if($available_chroots!~/$chroot/){
      push $results->{warning},
	(caller(0))[3].": chroot $chroot is not available!";
    }
    else{
      my $session="testing.".$chroot;
      my $syscall="su $arg->{run_as} -c 'schroot -d $arg->{run_dir} -b -p -c ".$chroot." -n ".$session." &>/dev/null || exit 1'";
      #make session
      system($syscall);
      if ($? != 0) {
	push $results->{error},
	  (caller(0))[3].": creating session $syscall exited with value ".sprintf("%d",$?>>8);
	$results->{result}=1;
      }
      else {
	push $results->{info},
	  (caller(0))[3].": creating session $session exited ok.";

	#try running something in the session
	#this will exit with 1 if schroot fails
	$syscall="su $arg->{run_as} -c 'schroot -d $arg->{run_dir} -r -p -c ".$session." -- true &>/dev/null || exit 1'";
	system($syscall);
	if ($? != 0) {
	  push $results->{error},
	    (caller(0))[3].": testing session $syscall exited with value ".sprintf("%d",$?>>8);
	  $results->{result}=1;
	}
	else {
	  push $results->{info},
	    (caller(0))[3].": testing session $session exited ok.";

	  #now end session
	  $syscall="su $arg->{run_as} -c 'schroot -d $arg->{run_dir} -e -c ".$session." &>/dev/null || exit 1'";
	  system($syscall);
	  if ($? != 0) {
	    push $results->{error},
	      (caller(0))[3].": ending session $syscall exited with value ".sprintf("%d",$?>>8);
	    $results->{result}=1;
	  }
	  else {
	    push $results->{info},
	      (caller(0))[3].": ending session $session exited ok.";
	  }
	}
      }
      $number_of_tested_chroots++;
    }
  }

  if(!$number_of_tested_chroots){
    push $results->{error},
      (caller(0))[3].": Defined chroots are unavailable and were not tested.";
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

    SlurmHC::Schroot::Chroot - Slurm healtcheck (sub)package for testing chroots available in schroot

=head1 SYNOPSIS

    use SlurmHC qw( Schroot::Chroot ); #or just
    use SlurmHC; #this way SlurmHC will auto-load all packages in @INC with same namespace

    my $a=SlurmHC::Schroot::Chroot::run( run_dir => "/", chroots => "chroot_name" );
    if($a->{result}==0){
      #all ok
    }
    #or
    my $hc=SlurmHC->new();
    my $result=$hc->run( 'Schroot::Chroot' => {run_dir => "/", chroots => "chroot_name"});
    if($result==0){
      #all ok
    }

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
