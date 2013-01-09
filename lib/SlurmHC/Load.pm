package SlurmHC::Load;

BEGIN{
    use strict;
    use parent 'SlurmHC';
    use vars qw($VERSION);
}

sub n_cpu {
    my @ncpu = grep(/^processor/,`cat /proc/cpuinfo`);
    return $#ncpu+1;
}


sub run{
    my $self;
    $self = shift if ref $_[0] and $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Load');
    my $parent = shift;

    #by default only run 15min average test
    #if nothing else is defined
    my %arg = ( load_max_1min => undef,
		load_max_5min => undef,
		load_max_15min => undef,
		@_);

    #check if arguments are positive
    #undefine if not, keep only 15min average
    #talk to AF for upper limits!
    if(defined $arg{load_max_1min} and $arg{load_max_1min}<0.){
	$arg{load_max_1min}=undef;
	$parent->Warning((caller(0))[3],"Negative limit for 1min average!");
    }
    if(defined $arg{load_max_5min} and $arg{load_max_5min}<0.){
	$arg{load_max_5min}=undef;
	$parent->Warning((caller(0))[3],"Negative limit for 5min average!");
    }
    if(defined $arg{load_max_15min} and $arg{load_max_15min}<0.0){
	$arg{load_max_15min}=1.5;
	$parent->Warning((caller(0))[3],"Negative limit for 15min average!");
    }
    if(not defined $arg{load_max_1min} 
       and not defined $arg{load_max_5min} 
       and not defined $arg{load_max_15min}){
	$arg{load_max_15min}=1.5;
    }

    my $ncpu=n_cpu();

    open(LOAD, "/proc/loadavg") or do {
	$parent->Error((caller(0))[3],"Unable to get server load: $!");
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
	  $parent->Warning((caller(0))[3],
			   "1min load average above limit: $load_1 > "
			   .($arg{load_max_1min}*$ncpu));
	  $error=1;
      }
    }
    if(defined $arg{load_max_5min}){
      if ( $load_5 > $arg{load_max_5min}*$ncpu ) {
	  # load is above set limit
	  $parent->Warning((caller(0))[3],
			   "5min load average above limit: $load_5 > "
			   .($arg{load_max_5min}*$ncpu));
	  $error+=2;
      }
    }
    if(defined $arg{load_max_15min}){
	if ( $load_15 > $arg{load_max_15min}*$ncpu ) {
	    # load is above set limit
	    $parent->Warning((caller(0))[3],
			     "15min load average above limit: $load_15 > "
			     .($arg{load_max_15min}*$ncpu));
	    $error+=3;
	}
    }

    my $total_error_check=0;
    $total_error_check+=1 if defined $arg{load_max_1min};
    $total_error_check+=2 if defined $arg{load_max_5min};
    $total_error_check+=3 if defined $arg{load_max_15min};

    if($error>0){
      if($error==$total_error_check){
	  $parent->Error((caller(0))[3],
			 "Tested load average is too high.");
	  return 1;
      }
      else{
	  #warning was already issued, return with 0
	  return 0;
      }
    }
    else{
	$parent->Info((caller(0))[3],"Tested load average is ok.");
	return 0;
    }
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
        Load => \{ load_max_1min=> .005 }
    );
    and
    $hc->run(
        Load => \{ load_max_1min=> .005, load_max_5min=>1.5 } 
    );
    are different; first run will (probably - load 0.005*n_cpu is quite low) will raise error
    while the second won't.


=head1 EXAMPLE

    #!/usr/bin/perl

    use SlurmHC qw( Load );
    my $hc=SlurmHC->new();
    $hc->run(
        Load => \{ load_max_15min=> 1.5 }, 
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
