use strict;

use Test::Builder;

use Test::Tester;

use Data::Dumper qw(Dumper);

my $test = Test::Builder->new;
$test->plan(tests => 2);

my $cap;

$cap = Test::Tester->capture;

local $Test::Builder::Level = 0;
{
	my $cur = $cap->current_test;
	$test->is_num($cur, 0, "current test");

	eval {$cap->current_test(2)};
	$test->ok($@, "can't set test_num");
}
