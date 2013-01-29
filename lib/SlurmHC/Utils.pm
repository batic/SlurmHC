package SlurmHC::Utils;

use strict;
use warnings;

use parent 'SlurmHC';

sub run{
    return 0;
}

sub n_cpu {
  my @ncpu = grep(/^processor/,`cat /proc/cpuinfo`);
  return $#ncpu+1;
}

sub valid_user {
  my $user=shift;
  if(defined getpwnam($user)){
    return 0;
  }
  return 1;
}

sub user_id {
  my $user = shift;
  my $uid = getpwnam($user);
  return $uid;
}

sub file_perm{
  my $file = shift;
  my $user = shift;
  my $perms = shift;

  my $readable=0;
  my $writable=0;
  my $executable=0;

  #does file exist?
  if (-e $file){
    if($perms =~/read|r/i){
      system("su $user -c '[ -r \"$file\" ];'");
      $readable+=$?>>8;
    }

    if($perms =~/write|w/i){
      system("su $user -c '[ -w \"$file\" ];'");
      $writable+=$?>>8;
    }

    if($perms =~/exe|x/i){
      system("su $user -c '[ -x \"$file\" ];'");
      $executable+=$?>>8;
    }
    my $result = $readable + $writable + $executable;
    return $result>0 ? 1 : 0;
  }
  else{
    return 1;
  }
}

sub dir_perm{
  my $dir = shift;
  my $user = shift;
  my $perms = shift;

  my $readable=0;
  my $writable=0;

  #does directory exist?
  if (-d $dir){
    if($perms =~/read|r|list|l/i){
      system("su $user -c '[ -r \"$dir\" ];'");
      $readable+=$?>>8;
    }

    if($perms =~/write|w/i){
      system("su $user -c '[ -w \"$dir\" ];'");
      $writable+=$?>>8;
    }

    my $result = $readable + $writable;
    return $result>0 ? 1 : 0;
  }
  else{
    return 1;
  }
}

1;

#################### main pod documentation begin ###################

=encoding utf8

=head1 NAME

    SlurmHC::Utils - Slurm healtcheck utilities and misc checks

=head1 SYNOPSIS

    use SlurmHC;
    #Utils is required module

=head1 DESCRIPTION

=head1 EXAMPLE

    #!/usr/bin/perl

    use SlurmHC;

    #get number of cpus
    my $number_of_cpu=SlurmHC::Utils::n_cpu();

    #is /t/m/p.txt readable && writtable && executable by user hamlet
    my $file_permission_ok=SlurmHC::Utils::file_perm("/t/m/p.txt","hamlet","rwx")

    #is /t/m/p/ directory readable && writtable by othello
    my $dir_permission_ok=SlurmHC::Utils::dir_perm("/t/m/p","othello","rw");

    #is hamlet even a valid user?
    my $hamlet_ok=SlurmHC::Utils::valid_user("hamlet");

    #if he is, get his uid
    if($hamlet_ok){
       my $hamlet_uid=SlurmHC::Utils::user_id("hamlet");
    }

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
