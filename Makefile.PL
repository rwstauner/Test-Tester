# $Header: /home/fergal/my/cvs/teng/Makefile.PL,v 1.4 2003/01/19 20:39:20 fergal Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	AUTHOR => 'Fergal Daly <fergal@esatclear.ie>',
	NAME => 'Test::Tester',
	VERSION_FROM => './lib/Test/Tester.pm',
	INSTALLDIRS => 'perl',
);
