# $Header: /home/fergal/my/cvs/Test-Tester/Makefile.PL,v 1.1 2003/03/02 23:45:49 fergal Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	AUTHOR => 'Fergal Daly <fergal@esatclear.ie>',
	NAME => 'Test::Tester',
	VERSION_FROM => './lib/Test/Tester.pm',
	INSTALLDIRS => 'perl',
);
