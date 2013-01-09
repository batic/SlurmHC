package SlurmHC;

BEGIN {
    use strict;
    use Carp qw(carp);
    use File::Spec::Functions qw(catdir catfile splitdir);
    use File::Basename 'fileparse';
    use POSIX qw(strftime);
    use Time::HiRes qw(gettimeofday tv_interval);

    use vars qw($VERSION);
    $VERSION     = '0.01';
}

sub new {
    my ($class, %parameters) = @_;

    my (@errors, @warnings, @info, %tests, %test_results, $hostname, $time_running)=undef;

    my $self = bless {
	error        => @errors,
	warnings     => @warnings,
	info         => @info,
	tests        => %tests,
	test_results => %test_results,
	hostname     => '',
	time_running => ''
    }, ref ($class) || $class;

    $hostname = `hostname`;
    chomp($hostname);

    $self->Info("SlurmHC","Started healthcheck.");

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
	    $test_results{$package}=-1; #for the moment the test result is unknown
	}
    }

}

sub VERSION { return $VERSION }

sub run {
    my $self=shift;
    shift if (scalar(@_) %2 ); #default tests should also be called with arguments !!!

    #start timing
    my $start_time=[gettimeofday]; #this will be needed for total run time

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

    my $ret=0;
    while( my ($k, $v) = each %test_results){
	$ret+=$v;
    }

    #stop timing and add elapsed time
    my $end_time = [gettimeofday];
    $time_running+= tv_interval $start_time, $end_time;

    return ($ret>0) ? 1 : 0;
}

sub Status {
    my $self=shift;
    my $test=shift;
    $test='SlurmHC::'.$test unless $test=~/^SlurmHC::/;

    #return test result; -1 means it has not been run yet
    return (defined $tests{$test}) ? $test_results{$test} : -1;
}

sub slurm_time {
    my $str=strftime "[%FT%H:%M:%S]", localtime;
    return $str;
}

sub Info {
    my ($self, $caller, $message) = @_;
    push @info, slurm_time." (I) $caller: $message";

    #replace info about running time 
    if(defined $time_running){
	@info = grep { $_ !~ qr/time elapsed testing/ } @info;
	push @info, slurm_time." (I) SlurmHC: time elapsed testing: ".$time_running." seconds.";
    }
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
    print "SlurmHC - info #######################################\n";
    print join("\n",@info)."\n" if @info;
    print "SlurmHC - warnings ###################################\n" if @warnings;
    print join("\n",@warnings)."\n\n";
    print "SlurmHC - errors #####################################\n" if @errors;
    print join("\n",@errors)."\n\n";
}

sub Mail {
    my $self;
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

