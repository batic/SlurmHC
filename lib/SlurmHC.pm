package SlurmHC;

use vars qw($VERSION);
$VERSION     = '0.01';

use strict;
use warnings;

use Carp qw(carp);
use File::Spec::Functions qw(catdir catfile splitdir);
use File::Basename 'fileparse';
use POSIX qw(strftime);
use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper;

use SlurmHC::Log;

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
		   }, ref ($class) || $class;

  my $arg = { %{$self->{logging}}, @_ };
  foreach (keys($arg)) {
    die ref($class) . "::new: Unknown option $_" unless defined $self->{logging}->{$_};
    $self->{logging}->{$_}=$arg->{$_};
  }

  $self->{hostname} = `hostname`;
  chomp($self->{hostname});

  $self->{time_running}=0;

  use Data::Dumper;
  print Dumper($self);

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

    # List "*.pm" files in directory
    opendir(my $dir, $path);
    for my $file (grep /\.pm$/, readdir $dir) {
      next if -d catfile splitdir($path), $file;

      # Module found, Log is not test!
      my $class = "${namespace}::" . fileparse $file, qr/\.pm/;
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

  foreach my $test (keys $do){
    my $testname=$test.".".int(rand(10000));
    my $testmodule='SlurmHC::'.$test;
    $self->{tests}->{$testname}={
				 info      => [],
				 warning   => [],
				 error     => [],
				 result    => -1,
				 elapsed   => 0,
				};

    my $hashref=$do->{$test};
    $self->{tests}->{$testname}=$testmodule->run( %$hashref );

    #append time of run
    $self->{tests}->{$testname}->{time}=slurm_time();
  }

  my $ret=0;
  foreach my $test (keys $do){
    #"total" return is 1 (fail) if any of the tests fails
    $ret+=$self->{tests}->{$test}->{result};

    #log according to verbosity
    if($self->{logging}->{verbosity}=~/debug/){
      my $testname=$test=~s/\.\d[4]$//g;
      $self->{log}->log("[".$self->{tests}->{$test}->{time}."] (I) SlurmHC::$test took "
			.$self->{tests}->{$test}->{elapsed}." seconds."
		       );
    }

    #log info
    if($self->{logging}->{verbosity}=~/info|debug|all/){
      foreach (@{$self->{tests}->{$test}->{info}}){
	$self->{log}->log("[".$self->{tests}->{$test}->{time}."] (I) ".$_);
      }
    }
    #log warnings
    if($self->{logging}->{verbosity}=~/info|warn|debug|all/){
      foreach (@{$self->{tests}->{$test}->{warning}}){
	$self->{log}->log("[".$self->{tests}->{$test}->{time}."] (W) ".$_);
      }
    }
    #log errors
    if($self->{logging}->{verbosity}=~/info|warn|err|debug|all/){
      foreach (@{$self->{tests}->{$test}->{error}}){
	$self->{log}->log("[".$self->{tests}->{$test}->{time}."] (E) ".$_);
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

  #return test result if the test is defined:
  # -1 means the test is scheduled, but has not been run yet
  # -2 means the test has not been defined/scheduled
  foreach my $test (keys $self->{tests}){
    return $self->{tests}->{$test}->{result} if $test=~/$status_of/;
  }
  return -2;
}

sub slurm_time {
  my $str=strftime "%FT%H:%M:%S", localtime;
  return $str;
}

# sub Info {
#   my ($self, $caller, $message) = @_;
#   my $inf=slurm_time." (I) $caller: $message";
#   push @info, $inf;

#   $log->log($inf) if $options{verbosity} =~ /all|info|debug/;

#   #replace info about running time 
#   if (defined $self{time_running}) {
#     @info = grep { $_ !~ qr/time elapsed testing/ } @info;
#     push @info, slurm_time." (I) SlurmHC: time elapsed testing: ".$self{time_running}." seconds.";
#     $log->log(slurm_time." (I) SlurmHC: time elapsed testing: ".$self{time_running}." seconds.") if $options{verbosity} =~ /debug/;
#   }
# }

# sub Warning {
#   my ($self, $caller, $message) = @_;
#   my $warn=slurm_time." (I) $caller: $message";
#   push @warnings, $warn;
#   warn("(W) ".$warn);
#   $log->log($warn) if $options{verbosity} =~ /all|warn|debug/;
# }

# sub Error {
#   my ($self, $caller, $message) = @_;
#   my $err=slurm_time." (E) $caller: $message";
#   push @errors, $err;
#   $log->log($err) if $options{verbosity} =~ /all|err|debug/;
# }

sub Print {
  my $self=shift;

  foreach my $test (keys $self->{tests}){
    print "test name = $test\n";
    if($self->{tests}->{$test}->{info}){
      print "SlurmHC - info #######################################\n";
      #print Dumper($self->{tests}->{$test});
      print join("\n",@{$self->{tests}->{$test}->{info}})."\n"
    }
  }
#   print "SlurmHC - warnings ###################################\n" if @warnings;
#   print join("\n",@warnings)."\n\n" if @warnings;
#   print "SlurmHC - errors #####################################\n" if @errors;
#   print join("\n",@errors)."\n\n" if @errors;
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

