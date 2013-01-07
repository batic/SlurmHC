package SlurmHC::Basic;


use strict;
use parent 'SlurmHC';
use base qw(Exporter);
use vars qw(@EXPORT $VERSION);

@EXPORT = qw( n_cpu load_average check_disk_space );

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
    
    #by default only run 15min average test
    #if nothing else is defined
    my %arg = ( load_max_1min => undef,
		load_max_5min => undef,
		load_max_15min => undef, 
		@_);  

    #check if arguments are positive
    #undefine if not, keep only 15min average
    #talk to AF for upper limits!
    if($arg{load_max_1min}<0.){
	$arg{load_max_1min}=undef;
	$self->SUPER::Warning((caller(0))[3],"Negative limit for 1min average!");
    }
    if($arg{load_max_5min}<0.){
	$arg{load_max_5min}=undef;
	$self->SUPER::Warning((caller(0))[3],"Negative limit for 5min average!");
    }
    if($arg{load_max_15min}<0.0){
	$arg{load_max_15min}=1.5;
	$self->SUPER::Warning((caller(0))[3],"Negative limit for 15min average!");
    }
    if(not defined $arg{load_max_1min} 
       and not defined $arg{load_max_5min} 
       and not defined $arg{load_max_15min}){
	$arg{load_max_15min}=1.5;
    }

    my $ncpu=n_cpu();

    open(LOAD, "/proc/loadavg") or do {
	$self->SUPER::Error((caller(0))[3],"Unable to get server load: $!");
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
	  $self->SUPER::Warning((caller(0))[3],
				"1min load average above limit: $load_1 > "
				.($arg{load_max_1min}*$ncpu));
	  $error=1;
      }
    }
    if(defined $arg{load_max_5min}){
      if ( $load_5 > $arg{load_max_5min}*$ncpu ) {
	  # load is above set limit
	  $self->SUPER::Warning((caller(0))[3],
				"5min load average above limit: $load_5 > "
				.($arg{load_max_5min}*$ncpu));
	  $error+=2;
      }
    }
    if(defined $arg{load_max_15min}){
	if ( $load_15 > $arg{load_max_15min}*$ncpu ) {
	    # load is above set limit
	    $self->SUPER::Warning((caller(0))[3],
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
	  $self->SUPER::Error((caller(0))[3],
			      "Tested load average is too high.");
	  return 1;
      }
      else{
	  #warning was already issued, return with 0
	  return 0;
      }
    }
    else{
	$self->SUPER::Info((caller(0))[3],"Tested load average is ok.");
	return 0;
    }
}



=item load_average( ITEM )

Check available disk space, issue error if it is below given size.

Test: 
  check_disk_space( mount_point, size_available_warning, size_available_error )
will check mount point has at least size_available_error (GB). 

In case of available disk space below warning level (but still above error level), 
warning will be issued.

Error will be given when available disk space is below error level.

=cut


sub check_disk_space {
    my $self = undef;
    $self = shift if ref $_[0] and $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Basic'); 
    
    my $mount_point=shift;
    my $warning_limit_G=shift;
    my $error_limit_G=shift;

    $mount_point="/data0" unless $mount_point;
    $warning_limit_G="30G" unless $warning_limit_G;
    
    if($warning_limit_G !~ /\d+G/){
	$self->SUPER::Warning((caller(0))[3], "Configuration error: mount_point limits should be in xxG format (30G will be used for warning).");
	$warning_limit_G="30G";
    }
    my $warning_limit = $warning_limit_G;
    $warning_limit =~ s/G//g;
    $warning_limit=$warning_limit*1024*1024;
    
    $error_limit_G="30G" unless $error_limit_G;
    if($error_limit_G !~ /\d+G/){
	$self->SUPER::Warning((caller(0))[3], "Configuration error: mount_point limits should be in xxG format (20G will be used for hard error).");
	$error_limit_G="20G";
    }
    my $error_limit = $error_limit_G;
    $error_limit =~ s/G//g;
    $error_limit = $error_limit*1024*1024;
    
    my $df_mount_point=`df $mount_point | grep $mount_point`;
    my ($fs, $blocks, $used, $avail) = split /\s+/, $df_mount_point;

    #finish here if available disk space is below error limit
    if($avail<$error_limit){
	# not enough mount_point space.
	$self->SUPER::Error((caller(0))[3], "$mount_point filled up: only ".sprintf("%.2f",$avail/1024/1024)."G available, should be above $error_limit_G.");
	return 1;
    }
    
    #issue warning if below warning limit, but still return 0
    my $warning=0;
    if($avail<$warning_limit){
	# mount_point space getting low.
	$self->SUPER::Warning((caller(0))[3], "$mount_point is getting filled up: only ".sprintf("%.2f",$avail/1024/1024)."G available, should be above $warning_limit_G.");
	$warning=1;
    }

    #all ok, issue OK info only if there is no warning
    $self->SUPER::Info((caller(0))[3], "All ok: $mount_point: ".sprintf("%.2f",$avail/1024/1024)."G available.") unless $warning;

    return 0;

}

1;


=back

=cut

"bumble bee";
