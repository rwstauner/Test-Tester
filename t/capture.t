use strict;

use Test::Builder;

use Test::Tester;

use Data::Dumper qw(Dumper);

my $Test = Test::Builder->new;
$Test->plan(tests => 3);

my $cap;

$cap = Test::Tester->capture;

local $Test::Builder::Level = 0;
{
	my $cur = $cap->current_test;
	$Test->is_num($cur, 0, "current test");

	eval {$cap->current_test(2)};
	$Test->ok($@, "can't set test_num");
}

{
	$cap->ok(1, "a test");

	my @res = $cap->details;

	$Test->is_num(scalar @res, 1, "res count");
}
