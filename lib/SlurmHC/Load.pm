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

    print "number of args = ".(scalar(@_))."\n";
    print "arg[0] = ".@_[0]."\n";
    print "arg[1] = ".@_[1]."\n";

    print "self: $self\n";
    print "parent: $parent\n";
    
    #by default only run 15min average test
    #if nothing else is defined
    my %arg = ( load_max_1min => undef,
		load_max_5min => undef,
		load_max_15min => undef,
		@_);

    foreach my $k (keys %arg) {
	print $k." => ".$arg{$k}."\n";
    }

    #check if arguments are positive
    #undefine if not, keep only 15min average
    #talk to AF for upper limits!
    if($arg{load_max_1min}<0.){
	$arg{load_max_1min}=undef;
	$parent->Warning((caller(0))[3],"Negative limit for 1min average!");
    }
    if($arg{load_max_5min}<0.){
	$arg{load_max_5min}=undef;
	$parent->Warning((caller(0))[3],"Negative limit for 5min average!");
    }
    if($arg{load_max_15min}<0.0){
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
