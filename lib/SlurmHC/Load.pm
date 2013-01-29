package SlurmHC::Load;

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
  if($_[0] || ref $_[0]){
    $self = shift if $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Load');
  }

  my $arg = { @_ };

  #results hashref
  my $results={
	       info      => [],
	       warning   => [],
	       error     => [],
	       result    => 0,
	       elapsed   => 0,
	      };

  my $available_limits= { load_warn_1min=>'', load_warn_5min=>'', load_warn_15min=>'',
			  load_max_1min=>'', load_max_5min=>'', load_max_15min=>'' };

  if (keys $arg) {
    foreach (keys $arg) {
      if (not defined $available_limits->{$_}) {
	push $results->{warning}, (caller(0))[3]." Unavailable option \"$_\"!";
      }
    }
  }

  #check if arguments are positive
  #undefine if not, keep only 15min average, defaulting it to 1.5
  if (defined $arg->{load_warn_1min} and $arg->{load_warn_1min}<0.) {
    $arg->{load_warn_1min}=undef;
    push $results->{warning}, (caller(0))[3]." Negative limit for warning 1min average.";
  }
  if (defined $arg->{load_warn_5min} and $arg->{load_warn_5min}<0.) {
    $arg->{load_warn_5min}=undef;
    push $results->{warning}, (caller(0))[3]." Negative limit for warning 5min average.";
  }
  if (defined $arg->{load_warn_15min} and $arg->{load_warn_15min}<0.0) {
    $arg->{load_warn_15min}=undef;
    push $results->{warning}, (caller(0))[3]." Negative limit for warning 15min average.";
  }
  if (defined $arg->{load_max_1min} and $arg->{load_max_1min}<0.) {
    $arg->{load_max_1min}=undef;
    push $results->{warning}, (caller(0))[3]." Negative limit for 1min average.";
  }
  if (defined $arg->{load_max_5min} and $arg->{load_max_5min}<0.) {
    $arg->{load_max_5min}=undef;
    push $results->{warning}, (caller(0))[3]." Negative limit for 5min average.";
  }
  if (defined $arg->{load_max_15min} and $arg->{load_max_15min}<0.0) {
    $arg->{load_max_15min}=undef;
    push $results->{warning}, (caller(0))[3]." Negative limit for 15min average.";
  }
  if (not defined $arg->{load_max_1min}
      and not defined $arg->{load_max_5min}
      and not defined $arg->{load_max_15min}) {
    $arg->{load_max_15min}=1.5;
    push $results->{warning},
      (caller(0))[3]." Using default test: 15min average with load_max_15min=$arg->{load_max_15min}.";
  }


  my $ncpu=SlurmHC::Utils::n_cpu();

  open(LOAD, "/proc/loadavg") or do {
    push $results->{error}, (caller(0))[3]."Unable to get server load: $!";
    $results->{result}=1;

    #stop timing and add elapsed time
    my $end_time = [gettimeofday];
    $results->{elapsed} = tv_interval $start_time, $end_time;

    return $results;
  };

  my $load_avg = <LOAD>;
  close LOAD;
  chop $load_avg;
  my ( $load_1, $load_5, $load_15 ) = split /\s/, $load_avg;
  my $loads={ load_1min=>$load_1, load_5min=>$load_5, load_15min=>$load_15 };

  foreach my $load (qw/1min 5min 15min/){
    my $load_warning="load_warn_".$load;
    my $load_limit="load_max_".$load;
    my $load_value=$loads->{"load_".$load};

    if(defined $arg->{$load_warning})
    {
      if(defined $arg->{$load_limit})
	{
	  #both warn and max are defined:
	  if ( $load_value > $arg->{$load_warning}*$ncpu ){
	    if ( $load_value < $arg->{$load_limit}*$ncpu ){
	      # load is above warning limit, but below error limit
	      push $results->{warning},
		(caller(0))[3]." $load load average above warning limit: $load_value > "
		  .($arg->{$load_warning}*$ncpu);
	    }
	    else
	      {
		# load is above max limit
		push $results->{warning},
		  (caller(0))[3]." $load load average above limit: $load_value > "
		    .($arg->{$load_limit}*$ncpu);
		$results->{result}+=1;
	      }
	  }
	}
      else
	{
	  #only warn is defined
	  if ( $load_value > $arg->{$load_warning}*$ncpu )
	    {
	      push $results->{warning},
		(caller(0))[3]." $load load average above warning limit: $load_value > "
		  .($arg->{$load_warning}*$ncpu);
	    }
	}
    }
  else
    {
      if(defined $arg->{$load_limit})
	{
	  #only max is defined
	  if ( $load_value > $arg->{$load_limit}*$ncpu )
	    {
	      push $results->{warning},
		(caller(0))[3]." $load load average above limit: $load_value > "
		  .($arg->{$load_limit}*$ncpu);
		$results->{result}+=1;
	    }
	}
    }
  }

  my $error=$results->{result};

  my $total_error_check=0;
  $total_error_check++ if defined $arg->{load_max_1min};
  $total_error_check++ if defined $arg->{load_max_5min};
  $total_error_check++ if defined $arg->{load_max_15min};

  if ($error>0) {
    if ($error==$total_error_check) {
      push $results->{error},
	(caller(0))[3]." Tested load average is too high.";
      $results->{result}=1;
    } else {
      #warning was already issued, return with 0
      $results->{result}=0;
    }
  } else {
    push $results->{info}, (caller(0))[3]." Tested load average is ok.";
    $results->{result}=0;
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

    SlurmHC::Load - Slurm healtcheck (sub)package for testing machine load

=head1 SYNOPSIS

    use SlurmHC qw( Load );

=head1 DESCRIPTION

    Will parse /proc/loadavg for load check.
    The average load(s) will be checked with respect to n_cpu()*limit, issuing warning
    when given load is above limit and issuing error when all loads are above limits.

    In this sense checks
    $hc->run(
        Load => { load_max_1min=> .005 }
    );
    and
    $hc->run(
        Load => { load_max_1min=> .005, load_max_5min=>1.5 }
    );
    are different; first run will (probably - load 0.005*n_cpu is quite low) will raise error
    while the second won't.


=head1 EXAMPLE

    #!/usr/bin/perl

    use SlurmHC qw( Load );
    my $hc=SlurmHC->new();
    $hc->run(
        Load => { load_max_15min=> 1.5 },
    )
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
