# -*- perl -*-

# t/010_import_Cvmfs.t - check module import sub for Cvmfs test package

use Test::More 'no_plan';

#importing Cvmfs module
use_ok( 'SlurmHC::Cvmfs' );
