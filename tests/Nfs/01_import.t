# -*- perl -*-

# t/004_import_Nfs.t - check module import sub for Nfs test package

use Test::More 'no_plan';

#importing Nfs module
use_ok( 'SlurmHC::Nfs' );
