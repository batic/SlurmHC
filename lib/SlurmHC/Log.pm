package SlurmHC::Log;

use strict;
use warnings;
use FileHandle;

use parent 'SlurmHC';


sub run{
    return 0;
}

sub new {
  my $class= shift;
  my $arg = { @_ } ;

  my $self = bless {
		    options => {
				verbosity => "error",
				file      => "/tmp/SlurmHC.log"
			       },
		   }, ref ($class) || $class;

  $self->{options}{verbosity}=$arg->{verbosity} if $arg->{verbosity}=~/all|error|info|warn|debug/;
  $self->{options}{file}=$arg->{file} if defined $arg->{file};

  $self->{fh} = new FileHandle ">>$self->{options}{file}";
  if (!defined $self->{fh}) {
    die "Unable to write to $self->{options}{file}";
  }
  $self->{fh}->autoflush();

  return $self;
}

sub Verbosity {
  my $self=shift;
  print "In Verbosity, verbosity = $self->{options}{verbosity}\n";
  return $self->{options}{verbosity};
}

sub DESTROY {
  #close filehandle
  my $self = shift;
  $self->{fh}->close if defined $self->{fh};
  undef $self->{fh};
}

sub log {
  my $self = shift;
  my @log_data = @_;

  foreach my $line (@log_data){
    chomp($line);
    $self->{fh}->print($line."\n") or do {
      warn("Could not write \"$line\" to $self->{options}{file}:\n@_ \n");
      return 1;
    };
  }

  return 0;
}


1;

#################### main pod documentation begin ###################

=encoding utf8

=head1 NAME

    SlurmHC::Log - Slurm healtcheck logger

=head1 SYNOPSIS

    use SlurmHC;
    #logger is required module

=head1 DESCRIPTION

=head1 EXAMPLE

    #!/usr/bin/perl

    use SlurmHC qw( Load );
    my $hc=SlurmHC->new( logfile=>"/path/to/logfile", verbosity=>"error" );

    #possible values for verbosity: all, error, warn, info, debug

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
