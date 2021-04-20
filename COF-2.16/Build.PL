#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Module::Build;
my $build = Module::Build->new
        (
            dist_name => 'COF',
            module_name => 'COF',
            dist_version_from => 'lib/COF/Info.pm',
	        script_files    => [ 'script/cof.pl', 'script/cof_oo_cli.pl' ],
            dist_author       => 'Franz Feregot',
            dist_abstract     => 'Coretôr Ortografic Furlan',
            requires    => {
                'File::Spec'         => 0.86,
				'Params::Validate'   => 1.06,
				'File::HomeDir'	  => 1.00,
				'Wx'                 => 0.26,
				'Wx::Perl::ListCtrl' => 0,
				'Try::Tiny'		  => 0.22,
				'Carp::Always'		  => 0.13,
				'Module::Build' => 0.40,
            }
        );
$build->create_build_script;

