package SlurmHC::Basic;


use strict;
use parent 'SlurmHC';
use base qw(Exporter);
use vars qw(@EXPORT $VERSION);

@EXPORT = qw( n_cpu load_average );

=encoding utf8

    =head1 NAME

    SlurmHC::Basic -- Basic tests

    =head1 SYNOPSIS

    use SlurmHC::Basic;

=head1 DESCRIPTION

    Basic tests for Slurm healthcheck: 
    - load average
    - disk space

=head2 Functions

=over 4

=item n_cpu()

    Returns number of processors.

=cut

sub n_cpu {
    my @ncpu = grep(/^processor/,`cat /proc/cpuinfo`);
    return $#ncpu+1;
}


=item load_average( ITEM )

Check the load average, issue error if load average is above that limit.

Multiple tests can be performed (up to three), for 1min, 5min or 15min 
load average, as read from /proc/loadavgr

Test: 
  load_average( load_max_5min=>5 )
will check if 5min load average is below 5*n_cpu. Additional test 
can be passed (load_max_1min=>20, load_max_5min=>5, load_max_15min=>1.5).
When called without argument, load_max_15min=>1.5 test will be evaluated.

Error will be given when (all given) tests fail.

=cut

sub load_average {
    my $self = undef;
    $self = shift if ref $_[0] and $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Basic'); 
    #how to call both
    # $object->load_average( ... )
    #and
    # SlurmHC::Basic::load_average( ... )
    #and not run into "Odd number of elements" or something similar?

    #by default only run 15min average test
    #if nothing else is defined
    my %arg = ( load_max_1min => undef,
		load_max_5min => undef,
		load_max_15min => 1.5, 
		@_);  

    #check if arguments are positive
    #undefine if not, keep only 15min average
    #talk to AF for upper limits!
    if($arg{load_max_1min}<0.){
	$arg{load_max_1min}=undef;
	warn("Removing negative limit for 1min average!\n");
    }
    if($arg{load_max_5min}<0.){
	$arg{load_max_5min}=undef;
	warn("Removing negative limit for 5min average!\n");
    }
    if($arg{load_max_15min}<0.0){
	$arg{load_max_15min}=1.5;
	warn("Changing to default limit for 15min average!\n");
    }

    my $ncpu=n_cpu();

    open(LOAD, "/proc/loadavg") or do {
	#push $self->SUPER::{error},"(E) Load: Unable to get server load: $!";
	return 1;
    };

    my $load_avg = <LOAD>;
    close LOAD;
    chop $load_avg;
    my ( $load_1, $load_5, $load_15 ) = split /\s/, $load_avg;

    my $error=0;
    if(defined $arg{load_max_1min}){
      if ( $load_1 > $arg{load_max_1min}*$ncpu ) {
	  # load is above set limit
	  print "1min load average above limit: $load_1 > ".($arg{load_max_1min}*$ncpu)."\n";
	  $error=1;
      }
    }
    if(defined $arg{load_max_5min}){
      if ( $load_5 > $arg{load_max_5min}*$ncpu ) {
	  # load is above set limit
	  print "5min load average above limit: $load_5 > ".($arg{load_max_5min}*$ncpu)."\n";
	  $error+=2;
      }
    }
    if(defined $arg{load_max_15min}){
	if ( $load_15 > $arg{load_max_15min}*$ncpu ) {
	    print "15min load average above limit: $load_15 > ".($arg{load_max_15min}*$ncpu)."\n";
	    # load is above set limit
	    # 	push $self->SUPER::{error},"(E) Load: <15min> to high: $load_15, should be below ".($arg{load_max_15min}*$ncpu);
	    $error+=3;
	}
    }
    
    my $total_error_check=0;
    $total_error_check+=1 if defined $arg{load_max_1min};
    $total_error_check+=2 if defined $arg{load_max_5min};
    $total_error_check+=3 if defined $arg{load_max_15min};
    
    if($error>0){
      if($error==$total_error_check){
	  #push $self->SUPER::{error},"(E) Load: <1min> to high: $load_1, should be below ".($arg{load_max_1min}*$ncpu);
	  return 1;
      }
      else{
	  #warning??
	  return 1;
      }
    }
    else{
	#push $self->SUPER::{message},"(I) Load: all ok, $load_avg";
      return 0;
    }
}


1;


=back

=head1 SEE ALSO

L<Test::Data>,
L<Test::Data::Scalar>,
L<Test::Data::Function>,
L<Test::Data::Hash>,
L<Test::Builder>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/test-data

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2012 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

"bumble bee";
