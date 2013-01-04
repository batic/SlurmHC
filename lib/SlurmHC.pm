package SlurmHC;

BEGIN {
    use Exporter ();
    use strict;
    use Carp qw(carp);
    
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


#################### main pod documentation begin ###################

=encoding utf8

=head1 NAME

    SlurmHC - Slurm healtcheck tests module for signet cluster 

=head1 SYNOPSIS

    use SlurmHC;

=head1 DESCRIPTION

    SlurmHC provides utility functions to perform healthcheck of slurm cluster nodes. 


=head1 USAGE
=head1 BUGS
=head1 SUPPORT

=head1 AUTHOR

    Matej Batič
    matej.batic@ijs.si


=head1 COPYRIGHT

    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

    perl.
    slurm.
    schroot.
    nfs.
    cvmfs.

=cut

#################### main pod documentation end ###################



sub new
{
    my ($class, %parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);

    my $self = bless {
	error   => @errors,
	message => @messages,
    }, ref ($class) || $class;


    return $self;
}


$Exporter::Verbose = 0;


sub import
{
    my $self = shift;
    my $caller = caller;

    foreach my $package ( @_ )
    {
	my $full_package = "SlurmHC::$package";
	eval "require $full_package; 1";
	if( $@ )
	{
	    carp "Could not require SlurmHC::$package: $@";
	}
	else{
	    print "Requred SlurmHC::$package\n";
	}
	
	$full_package->export($caller);
    }
    
}

sub VERSION { return $VERSION }


1;
# The preceding line will help the module return a true value

