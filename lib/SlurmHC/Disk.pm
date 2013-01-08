package SlurmHC::Disk;

BEGIN{
    use strict;
    use parent 'SlurmHC';
    use vars qw($VERSION);
}
    
sub run{
    my $self;
    $self = shift if ref $_[0] and $_[0]->can('isa') and  $_[0]->isa('SlurmHC::Disk'); 
    my $parent = shift;

    #by default only run 15min average test
    #if nothing else is defined
    my %arg = ( mount_point => "/data0",
		warning_limit => "30G",
		error_limit => "20G",
		@_);

    if( not -d $arg{mount_point}){
	$parent->Warning((caller(0))[3],"$arg{mount_point} does not exist!");
	return 0;
    }
    if($arg{warning_limit} !~ /\d+G/){
	$arg{warning_limit}="30G";
	$parent->Warning((caller(0))[3], 
			 "Configuration error: warning limits should be in xxG format (30G will be used).");
    }
    if($arg{error_limit} !~ /\d+G/){
	$arg{error_limit}="20G";
	$parent->Warning((caller(0))[3], 
			 "Configuration error: error limits should be in xxG format (20G will be used).");

    }

    my $warning_limit = $arg{warning_limit};
    $warning_limit =~ s/G//g;
    $warning_limit=$warning_limit*1024*1024;
    
    my $error_limit = $arg{error_limit};
    $error_limit =~ s/G//g;
    $error_limit = $error_limit*1024*1024;

    my $mount_point=$arg{mount_point};
    
    my $df_mount_point=`df $mount_point | grep $mount_point`;
    my ($fs, $blocks, $used, $avail) = split /\s+/, $df_mount_point;
    
    #finish here if available disk space is below error limit
    if($avail<$error_limit){
	# not enough mount_point space.
	$parent->Error((caller(0))[3], 
		       "$mount_point filled up: only "
		       .sprintf("%.2f",$avail/1024/1024)
		       ."G available, should be above $arg{error_limit}.");
	return 1;
    }
    
    #issue warning if below warning limit, but still return 0
    my $warning=0;
    if($avail<$warning_limit){
	# mount_point space getting low.
	$parent->Warning((caller(0))[3], 
			 "$mount_point is getting filled up: only "
			 .sprintf("%.2f",$avail/1024/1024)
			 ."G available, should be above $arg{warning_limit}.");
	$warning=1;
    }

    #all ok, issue OK info only if there is no warning
    $parent->Info((caller(0))[3], 
		  "All ok: $mount_point: "
		  .sprintf("%.2f",$avail/1024/1024)
		  ."G available.") unless $warning;

    return 0;
}

1;
