package SlurmHC::Disk;

use strict;
use warnings;

use parent 'SlurmHC';

use Time::HiRes qw(gettimeofday tv_interval);
use vars qw($VERSION);

sub run{
  #start timing
  my $start_time=[gettimeofday]; #start timing

  my $self;
  if($_[0] || ref $_[0]){
    $self = shift if $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Disk');
  }

  my $arg = { 
	     mount_point    => "/data0",
	     warning_limit  => "30G",
	     error_limit    => "20G",
	     @_ 
	    };

  #results hashref
  my $results={
	       info         => [],
	       warning      => [],
	       error        => [],
	       result       => 0,
	       elapsed      => 0,
	      };

  my $available_opts= { mount_point=>'', warning_limit=>'', error_limit=>'' };

  if(keys $arg){
    foreach(keys $arg){
      if(not defined $available_opts->{$_}){
	push $results->{warning}, (caller(0))[3]." Unavailable option \"$_\"!";
      }
    }
  }

  if( not -d $arg->{mount_point}){
    push $results->{error}, (caller(0))[3]." $arg->{mount_point} does not exist!";
    $results->{result}=1;

    #stop timing and add elapsed time
    my $end_time = [gettimeofday];
    $results->{elapsed} = tv_interval $start_time, $end_time;

    return $results;
  }
  if($arg->{warning_limit} !~ /\d+G/){
    $arg->{warning_limit}="30G";
    push $results->{warning}, 
      (caller(0))[3]." Configuration error: warning limits should be in xxG format (30G will be used).";
  }
  if($arg->{error_limit} !~ /\d+G/){
    $arg->{error_limit}="20G";
    push $results->{warning}, 
      (caller(0))[3]." Configuration error: error limits should be in xxG format (20G will be used).";
  }

  my $warning_limit = $arg->{warning_limit};
  $warning_limit =~ s/G//g;
  $warning_limit=$warning_limit*1024*1024;

  my $error_limit = $arg->{error_limit};
  $error_limit =~ s/G//g;
  $error_limit = $error_limit*1024*1024;

  my $mount_point=$arg->{mount_point};

  my $df_mount_point=`df $mount_point | grep $mount_point`;
  my ($fs, $blocks, $used, $avail) = split /\s+/, $df_mount_point;

  #finish here if available disk space is below error limit
  if($avail<$error_limit){
    # not enough mount_point space.
    push $results->{error},
      (caller(0))[3]." Not enough diskspace on $mount_point: only "
	.sprintf("%.2f",$avail/1024/1024)
	  ."G available, should be above $arg->{error_limit}.";
    $results->{result}=1;
  }
  elsif($avail<$warning_limit){
    #issue warning if below warning limit, but still return 0
    # mount_point space getting low.
    my $message= (caller(0))[3]." $mount_point is getting filled up: only "
      .sprintf("%.2f",$avail/1024/1024)
	."G available, should be above $arg->{warning_limit}.";
    push $results->{warning},$message;
  }

  #all ok, issue OK info only if there is no warning
  push $results->{info},
    (caller(0))[3]." All ok: $mount_point: "
      .sprintf("%.2f",$avail/1024/1024)
	."G available." unless $results->{result}==1;

  #stop timing and add elapsed time
  my $end_time = [gettimeofday];
  $results->{elapsed} = tv_interval $start_time, $end_time;

  return $results;
}

1;

#################### main pod documentation begin ###################

=encoding utf8

=head1 NAME

    SlurmHC::Disk - Slurm healtcheck (sub)package for testing available disk space

=head1 SYNOPSIS

    use SlurmHC qw( Disk );

=head1 DESCRIPTION

    Will check for available disk space on given "mount_point" and 
    issue warning if below "warning_limit" and error if below "error_limit".

=head1 EXAMPLE

    #!/usr/bin/perl

    use SlurmHC qw( Disk );
    my $hc=SlurmHC->new();
    $hc->run( 
        Disk => { mount_point=>"/data0", warning_limit=>"40G", error_limit=>"20G" }
    );
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

