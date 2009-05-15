use 5.008001;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME              => 'Perldoc-Config',
	VERSION_FROM      => 'lib/Perldoc/Config.pm',
	PREREQ_PM         => {
		'Data::Dumper'          => 0,
		'File::Basename'        => 0,
		'File::Find'            => 0,
		'File::Spec::Functions' => 0,
		'File::Temp'            => 0,
		'FindBin'               => 0,
		'Getopt::Long'          => 0,
		'Module::CoreList'      => 0,
		'Perl::Tidy'            => 0,
		'Shell'                 => 0,
		'Storable'              => 0,
		'Template'              => 0,
		'Test::More'            => 0,
		'Text::Template'        => 0,
		'Pod::Simple::Search'   => 0,
		'Pod::Functions'        => 0,
		'Pod::Escapes'          => 0,
		'Pod::ParseLink'        => 0,
		'Pod::POM'              => 0,
		'Pod::POM::View::HTML'  => 0,
		'Pod::POM::View::Text'  => 0,
	},
	ABSTRACT_FROM  => 'lib/Perldoc/Config.pm',
	AUTHOR         => 'Gabor Szabo <szabgab@gmail.com>',
);

