package SlurmHC;

BEGIN {
use Exporter ();
use strict;
use Carp qw(carp);
use File::Spec::Functions qw(catdir catfile splitdir);
use File::Basename 'fileparse';

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

=head1 EXAMPLE

    #!/usr/bin/perl

    use SlurmHC::Basic;
    my $hc=SlurmHC::Basic->new();
    $hc->load_average( load_max_5min=>1.5 );
    $hc->Print();
 

=head1 AUTHOR

    Matej Batič
    matej.batic@ijs.si


=head1 COPYRIGHT

    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

    SlurmHC::Basic

=cut

#################### main pod documentation end ###################



sub new {
    my ($class, %parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);

    my $self = bless {
	error   => @errors,
	warnings => @warnings,
	info => @info,
	hostname => ''
    }, ref ($class) || $class;

    $hostname = `hostname`;
    chomp($hostname);

    return $self;
}


$Exporter::Verbose = 0;


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

      # Module found
      my $class = "${namespace}::" . fileparse $file, qr/\.pm/;
      push @modules, $class unless $found{$class}++;
    }
  }

  return @modules;

}

sub import {
    my $self = shift;
    my $caller = caller;

    my @packages =  map { 'SlurmHC::' . $_ } @_;
    @packages = $self->list_testmodules() unless @_;

    foreach my $package ( @packages )
    {
	eval "require $package; 1";
	if( $@ )
	{
	    carp "Could not require $package: $@";
	}
	else{
	    print "Requred $package\n";
	}
	$package->export($caller);
    }

}

sub VERSION { return $VERSION }


sub Info {
    my $self = undef;
    $self = shift if ref $_[0] and $_[0]->can('isa') and  $_[0]->isa('SlurmHC'); 
    
    my $caller = shift;
    my $message = shift;

    push @info, "(I) ".localtime." $caller: $message";
}

sub Warning {
    my $self = undef;
    $self = shift if ref $_[0] and $_[0]->can('isa') and  $_[0]->isa('SlurmHC'); 
    
    my $caller = shift;
    my $message = shift;

    push @warnings, "(W) ".localtime." $caller: $message";
    warn("(W) ".localtime." $caller: $message");
}

sub Error {
    my $self = undef;
    $self = shift if ref $_[0] and $_[0]->can('isa') and  $_[0]->isa('SlurmHC'); 
    
    my $caller = shift;
    my $message = shift;

    push @errors, "(E) ".localtime." $caller: $message";
}

sub Print {
    print "(I)SlurmHC - info #######################################\n" if @info;
    print join("\n",@info)."\n";
    print "(W)SlurmHC - warnings ###################################\n" if @warnings;
    print join("\n",@warnings)."\n";
    print "(E)SlurmHC - errors #####################################\n" if @errors;
    print join("\n",@errors)."\n";
}	

sub Mail {
    my $self = undef;
    $self = shift if ref $_[0] and $_[0]->can('isa') and  $_[0]->isa('SlurmHC'); 
 
    my @temp = ( 'matej.batic@ijs.si', @_);  
    my %mailto = map { $_, 1 } @temp;

    
    open(my $mailx, "|-", "mailx","-s","[SlurmHC] $hostname",join(',',keys %mailto));
    print $mailx join("\n",@info)."\n" if (@info);
    print $mailx join("\n",@messages)."\n" if (@messages);
    print $mailx join("\n",@errors)."\n" if (@errors);
    close($mailx);
}

1;
# The preceding line will help the module return a true value

