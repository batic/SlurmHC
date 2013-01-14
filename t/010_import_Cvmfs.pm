# -*- perl -*-

# t/010_import_Cvmfs.t - check module import sub for Nfs test package

use Test::More 'no_plan';

#importing Nfs module
use_ok( 'SlurmHC::Cvmfs' );
