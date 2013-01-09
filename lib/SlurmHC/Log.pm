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

  my %arg =
    (
     file 	=> '/var/log/slurmHC.log',
     verbosity => 'all',
     @_
    );

  $arg{verbosity}="error" unless defined $arg{verbosity} and $arg{verbosity}=~/all|error|info|warn|debug/;
  $arg{file}="/tmp/SlurmHC.log" unless defined $arg{file};

  my $self = bless {
		    arg => %arg,
		   }, ref ($class) || $class;

  while( my($k,$v) = each %arg){
    print "SlurmHC::Log:$k = $v\n";
  }

  $self->{fh} = new FileHandle ">>$arg{file}";
  die "Unable to write to $arg{file}" if (!defined $self->{fh});
  $self->{fh}->autoflush();

  return $self;
}

sub Verbosity {
  my $self=shift;
  return $arg{verbosity};
}

sub DESTROY {
  #close filehandle
  my $self = shift;
  $self->{fh}->close;
  undef $self->{fh};
}

sub log {
  my $self = shift;
  my @log_data = @_;

  foreach my $line (@log_data){
    $self->{fh}->print($line);
  }
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
