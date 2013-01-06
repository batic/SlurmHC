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
    my $self = shift;
    #how to call both
    # $object->load_average( ... )
    #and
    # SlurmHC::Basic::load_average( ... )
    #and not run into "Odd number of elements" or something similar?
    #(talk to JJJ)

    # load_max defaults to 1.5*n_cpu
    my %defaults = ( load_max => 1.55 );
    my %arg = (%defaults, @_);  # replace defaults with arguments (if there are)

    #have load_max_1min, load_max_15min, load_max_5min
    #check if all undef, define 1.5 to load_max_15min
    #check that input values are positive!
    # (and not too large???)
    #perform given checks
    #use named arguments like
    # load_average( load_max_1min=>20, load_max_5min=>5, load_max_15min=>1,5)
    #and raise error when (???) all of them are above?
    #(talk to AF)

    my $load_max=$arg{load_max};

    if($load_max<0.5 || $load_max>3){
 	$load_max=1.5; 
    }
   
    my $ncpu=n_cpu();

    open(LOAD, "/proc/loadavg") or do { 
 	#push $self->SUPER::{error},"(E) Load: unable to get server load: $!";
 	return 1;
    };

    my $load_avg = <LOAD>;
    close LOAD;
    chop $load_avg;
    my ( $load_1, $load_5, $load_15 ) = split /\s/, $load_avg;

    if ( $load_15 > $load_max*$ncpu ) {
 	# to high load.
# 	push $self->SUPER::{error},"(E) Load: <15min> to high: $load_15, should be below ".($load_max*$ncpu);
 	return 1;
    }
     else{
# 	push $self->SUPER::{message},"(I) Load: all ok, $load_avg";
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
