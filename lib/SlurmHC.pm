package SlurmHC;

use vars qw($VERSION);
$VERSION     = '0.01';

use strict;
use warnings;

use Carp qw(carp);
use File::Spec::Functions qw(catdir catfile splitdir);
use File::Basename 'fileparse';
use File::Find;

use POSIX qw(strftime);
use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper;

use SlurmHC::Log;
use SlurmHC::Utils;

sub new {
  my $class=shift;

  my $self = bless {
		    tests        => {},
		    logging      => {
				     file      => "/tmp/SlurmHC.log",
				     verbosity => "error"
				    },
		    log          => {},
		    hostname     => '',
		    time_running => 0,
		    test_timeout => 10,
		   }, ref ($class) || $class;

  my $arg = { %{$self->{logging}}, @_ };
  foreach (keys($arg)) {
    die ref($class) . "::new: Unknown option $_" unless defined $self->{logging}->{$_};
    $self->{logging}->{$_}=$arg->{$_};
  }

  $self->{hostname} = `hostname`;
  chomp($self->{hostname});

  $self->{time_running}=0;

  #start log
  $self->{log}=SlurmHC::Log->new( %$arg );

  return $self;
}

sub list_testmodules {
  my $namespace = 'SlurmHC';

  # Check all directories
  my (@modules, %found);
  for my $directory (@INC) {
    next unless -d (my $path = catdir $directory, split(/::|'/, $namespace));

    # List "*.pm" files from this directory (do not follow symbolic links)
    my @list;
    find({ wanted => sub { push @list, $File::Find::name if $File::Find::name=~ /^.*pm/ },
	   follow => 0
	 },
	 $path );

    for my $file (@list) {
      next if -d catfile splitdir($path), $file;

      my ($t, $class)=split(/$directory\//,$file);
      $class=~s/\//::/g;
      $class=~s/\.pm//g;

      # Module found, Log is not a test!
      push @modules, $class unless $found{$class}++ or $class=~/Log/;
    }
  }

  return @modules;
}

sub import {
  my $self=shift;

  my @packages =  map { 'SlurmHC::' . $_ } @_;
  @packages = $self->list_testmodules() unless @_;

  foreach my $package ( @packages ) {
    eval "require $package; 1";
    if ( $@ ) {
      carp "Could not require $package: $@";
    }
  }

}

sub VERSION { return $VERSION }

sub run {
  my $self=shift;
  die "Each test should be called with arguments!" if (scalar(@_) %2 ); #default tests should also be called with arguments !!!

  #start timing
  my $start_time=[gettimeofday]; #this will be needed for total run time

  my $do = { @_ };
  #this will flatten the scheduled tests!!!!
  #be careful that they are not the same!!!!
  #look into git history and unearth shift/shift
  #then construct hashref from that, but use $testname (look below)
  #for $self->{tests}->{$testname}
  #this way, even
  # run->( Disk => {}, Disk => { mount_point="/data1" } );
  #should work

  my @tests_of_this_run;

  foreach my $test (keys $do){
    my $testname=$test.".".int(rand(10000));
    my $testmodule='SlurmHC::'.$test;
    push @tests_of_this_run, $testname;
    $self->{tests}->{$testname}={
				 info      => [],
				 warning   => [],
				 error     => [],
				 result    => -1,
				 elapsed   => 0,
				};

    #check requirements
    my $ok_to_run=1;
    foreach($testmodule->required()){
      if($self->Status($_)!=0){
	$ok_to_run=0;
	$self->{log}->log("[".slurm_time()."] ".
			  "(E) Could not run $testmodule since it requires $_"
		       );
      }
    }
    if($ok_to_run==1){

      #wrap call to run the test into timeout,
      #so that the test does not hang indefinitely

      eval {
	local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
	alarm $self->{test_timeout};

	#run test
	my $hashref=$do->{$test};
	$self->{tests}->{$testname}=$testmodule->run( %$hashref );

	#append time of run
	$self->{tests}->{$testname}->{time}=slurm_time();

	alarm 0;
      };
      if ($@) {
	die "Something strange happened: $@\n" unless $@ eq "alarm\n";

	#log "timeout"
	$self->{tests}->{$testname}->{result}=-3;
	$self->{tests}->{$testname}->{elapsed}=$self->{test_timeout};
	push @{$self->{tests}->{$testname}->{error}},
	  "Test $test timeouted after $self->{test_timeout} seconds.";
	$self->{log}->log("[".slurm_time()."] (E) ".
			  "$testname timeouted after $self->{test_timeout} seconds.");
      }
    }
  }

  my $ret=0;
  foreach my $test (@tests_of_this_run){
    #"total" return is 1 (fail) if any of the tests fails
    $ret+=$self->{tests}->{$test}->{result};

    #log according to verbosity
    if($self->{logging}->{verbosity}=~/debug/){
      my $testname=$test=~s/\.\d[4]$//g;
      $self->{log}->log("[".$self->{tests}->{$test}->{time}."] (I) SlurmHC::$test took "
			.$self->{tests}->{$test}->{elapsed}." seconds."
		       ) if $self->{tests}->{$test}->{result}>=0;
    }

    #log info
    if($self->{logging}->{verbosity}=~/info|debug|all/){
      foreach (@{$self->{tests}->{$test}->{info}}){
	$self->{log}->log("[".$self->{tests}->{$test}->{time}."] (I) ".$_)
	  if $self->{tests}->{$test}->{result}>=0;
      }
    }
    #log warnings
    if($self->{logging}->{verbosity}=~/info|warn|debug|all/){
      foreach (@{$self->{tests}->{$test}->{warning}}){
	$self->{log}->log("[".$self->{tests}->{$test}->{time}."] (W) ".$_)
	  if $self->{tests}->{$test}->{result}>=0;
      }
    }
    #log errors
    if($self->{logging}->{verbosity}=~/info|warn|err|debug|all/){
      foreach (@{$self->{tests}->{$test}->{error}}){
	$self->{log}->log("[".$self->{tests}->{$test}->{time}."] (E) ".$_)
	  if $self->{tests}->{$test}->{result}>=0;
      }
    }
  }

  #stop timing and add elapsed time
  my $end_time = [gettimeofday];
  $self->{time_running} += tv_interval $start_time, $end_time;

  $self->{log}->log("[".slurm_time()."] (I) SlurmHC: test took $self->{time_running} seconds.") 
    if $self->{logging}->{verbosity}=~/info|all|debug/;

  return ($ret>0) ? 1 : 0;
}

sub Status {
  my $self=shift;
  my $status_of=shift;
  $status_of=~s/SlurmHC:://g;

  #return test result if the test is defined:
  # -1 means the test is scheduled, but has not been run yet
  # -2 means the test has not been defined/scheduled

  foreach my $test (keys $self->{tests}){
    return $self->{tests}->{$test}->{result} if $test=~/^$status_of/;
  }
  return -2;
}

sub slurm_time {
  my $str=strftime "%FT%H:%M:%S", localtime;
  return $str;
}


sub Print {
  my $self=shift;

  if($self->{logging}->{verbosity}=~/debug/){
    foreach my $test (keys $self->{tests}){
      print "dumping $test data:\n";
      print Dumper($self->{tests}->{$test});
    }
  }
  else{
    print "SlurmHC - info #######################################\n";
    foreach my $test (keys $self->{tests}){
      if(@{$self->{tests}->{$test}->{info}}){
	print join("\n",@{$self->{tests}->{$test}->{info}})."\n";
      }
    }
    print "SlurmHC - warnings ###################################\n";
    foreach my $test (keys $self->{tests}){
      if(@{$self->{tests}->{$test}->{warning}}){
	print join("\n",@{$self->{tests}->{$test}->{warning}})."\n";
      }
    }
    print "SlurmHC - errors #####################################\n";
    foreach my $test (keys $self->{tests}){
      if(@{$self->{tests}->{$test}->{error}}){
	print join("\n",@{$self->{tests}->{$test}->{error}})."\n";
      }
    }
  }
}

# sub Mail {
#   my $self;
#   $self = shift if ref $_[0] and $_[0]->can('isa') and  $_[0]->isa('SlurmHC'); 

#   my @temp = ( 'matej.batic@ijs.si', @_);  
#   my %mailto = map { $_, 1 } @temp;

#   open(my $mailx, "|-", "mailx","-s","[SlurmHC] $hostname",join(',',keys %mailto));
#   print $mailx join("\n",@info)."\n" if (@info);
#   print $mailx join("\n",@messages)."\n" if (@messages);
#   print $mailx join("\n",@errors)."\n" if (@errors);
#   close($mailx);
# }

1;
# The preceding line will help the module return a true value


#################### main pod documentation begin ###################

=encoding utf8

=head1 NAME

    SlurmHC - Slurm healtcheck tests module for signet cluster 

=head1 SYNOPSIS

    use SlurmHC;

=head1 DESCRIPTION

    SlurmHC provides utility functions to perform healthcheck of slurm cluster nodes. 

=head1 EXAMPLE

    #!/usr/bin/perl

    use SlurmHC;
    my $hc=SlurmHC->new();
    $hc->run( 
        Load => \{ load_max_15min=> 1.5 },
        Disk => \{ mount_point=>"/data0", warning_limit=>"40G", error_limit=>"20G" }
    );
    $hc->Print();


=head1 AUTHOR

    Matej Batič
    matej.batic@ijs.si


=head1 COPYRIGHT

    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

    Other modules(tests) from SlurmHC.

=cut

#################### main pod documentation end ###################

