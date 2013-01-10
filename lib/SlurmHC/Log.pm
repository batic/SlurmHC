package SlurmHC::Log;

BEGIN{
    use parent 'SlurmHC';

    use strict;
    use warnings;
    use FileHandle;
}

sub run{
    return 0;
}

sub new {
  my $class= shift;
  my $self = bless {
		    options => {},
		   }, ref ($class) || $class;
  $self->_init(@_);
  return $self;
}

sub _init {
  my $self=shift;
  my %arg =
    (
     file 	=> '/tmp/slurmHC.log',
     verbosity  => 'all',
     @_
    );

  $options{verbosity}="error";
  $options{verbosity}=$arg{verbosity} if $arg{verbosity}=~/all|error|info|warn|debug/;
  $options{file}="/tmp/SlurmHC.log";
  $options{file}=$arg{file} if defined $arg{file};

  # while( my($k,$v) = each %arg){
  #   print "SlurmHC::Log:$k = $v\n";
  # }

  $self->{fh} = new FileHandle ">>$options{file}";
  if (!defined $self->{fh}) {
    die "Unable to write to $options{file}";
  }
  $self->{fh}->autoflush();

}

sub Verbosity {
  my $self=shift;
  print "In Verbosity, verbosity = $options{verbosity}\n";
  return $options{verbosity};
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
    $self->{fh}->print($line.'\n') or do {
      warn("Could not write \"$line\" to $options{file}:\n@_ \n");
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
