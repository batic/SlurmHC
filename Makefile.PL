use ExtUtils::MakeMaker;


WriteMakefile (
    'NAME'          => 'SlurmHC',
    'ABSTRACT'      => '',
    'VERSION_FROM'  => 'lib/SlurmHC.pm',
    'LICENSE'       => 'perl',
    'AUTHOR'        => 'Matej Batič <matej.batic@ijs.si>',
    
    'PREREQ_PM' => {
	'Test::Simple' => 0.44,
	'Test::More'   => 0.88,
	'Test::Warn'   => 0,
    },
    
    META_MERGE => {
	resources => {
	    repository => 'https://github.com/batic/SlurmHC',
	}
    },
    
    );
