package SlurmHC;

BEGIN {
    use strict;
    use Carp qw(carp);
    use File::Spec::Functions qw(catdir catfile splitdir);
    use File::Basename 'fileparse';
    use POSIX qw(strftime);

    use vars qw($VERSION);
    $VERSION     = '0.01';
}

sub new {
    my ($class, %parameters) = @_;

    my $self = bless {
	error   => @errors,
	warnings => @warnings,
	info => @info,
	tests => %tests,
	test_results => %test_results,
	hostname => ''
    }, ref ($class) || $class;

    $hostname = `hostname`;
    chomp($hostname);

    return $self;
}

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
	    #print "All ok with package $package\n";
	    $tests{$package}=0; #the test has not yet been run
	    $test_results{$package}=undef; #for the moment the test result is unknown
	}
    }

}

sub VERSION { return $VERSION }

sub run {
    my $self=shift;
    shift if (scalar(@_) %2 ); #default tests should also be called with arguments !!!

    my $ret=0;
    while(@_){
	my $test=shift;
	my $args=shift;
	$test='SlurmHC::'.$test unless $test=~/^SlurmHC::/;
	if( defined $tests{$test} ){
	    if( defined $$args ){
		$test_results{$test}=$test->run( %$$args );
		$tests{$test}++; #the test has been run
	    }
	    else{
		$test_results{$test}=$test->run();
		$tests{$test}++; #the test has been run
	    }
	}
    }
    
    return 0;
}

sub Status {
    my $self=shift;
    my $test=shift;

    return $test_retults{$test} if defined $tests{$test};

    #else
    return 1;
}

sub slurm_time {
    my $str=strftime "[%FT%H:%M:%S]", localtime;
    return $str;
}

sub Info {
    my ($self, $caller, $message) = @_;
    push @info, slurm_time." (I) $caller: $message";
}

sub Warning {
    my ($self, $caller, $message) = @_;
    push @warnings, slurm_time." (W) $caller: $message";
    warn("(W) ".slurm_time." $caller: $message");
}

sub Error {
    my ($self, $caller, $message) = @_;
    push @errors, slurm_time." (E) $caller: $message";
}

sub Print {
    print "SlurmHC - info #######################################\n" if @info;
    print join("\n",@info)."\n\n";
    print "SlurmHC - warnings ###################################\n" if @warnings;
    print join("\n",@warnings)."\n\n";
    print "SlurmHC - errors #####################################\n" if @errors;
    print join("\n",@errors)."\n\n";
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

    use SlurmHC;
    my $hc=SlurmHC->new();
    $hc->run( 
        Load => \{ load_max_15min=> 1.5 },
        Disk => \{ mount_point=>"/data0", warning_limit=>"40G", error_limit=>"20G" }
    );
    $hc->Print();
 

=head1 AUTHOR

    Matej Batič
    matej.batic@ijs.si


=head1 COPYRIGHT

    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO
    
    Other modules(tests) from SlurmHC.

=cut

#################### main pod documentation end ###################

