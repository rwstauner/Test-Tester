use strict;

use Test::Builder;

use Test::Tester;

use Data::Dumper qw(Dumper);

my $test = Test::Builder->new;
$test->plan(tests => 29);

my $cap = Test::Tester->capture;

{
	my @results = run_tests(
		sub {$cap->ok(1, "run pass")},
		"run pass"
	);

	local $Test::Builder::Level = 0;

	$test->is_num(scalar (@results), 1, "run pass result count");

	my $res = $results[0];

	$test->is_num($res->{tested}, 1, "run pass tested");
	$test->is_eq($res->{expected_name}, "run pass", "run pass expected name");
	$test->is_eq($res->{name}, "run pass", "run pass name");
	$test->is_eq($res->{ok}, 1, "run pass ok");
	$test->is_eq($res->{diag}, "", "run pass diag");
}

{
	my @results = run_tests(
		sub {$cap->ok(0, "run fail")},
		"run fail"
	);

	local $Test::Builder::Level = 0;

	$test->is_num(scalar (@results), 1, "run fail result count");

	my $res = $results[0];

	$test->is_num($res->{tested}, 1, "run fail tested");
	$test->is_eq($res->{expected_name}, "run fail", "run fail expected name");
	$test->is_eq($res->{name}, "run fail", "run fail name");
	$test->is_eq($res->{ok}, 0, "run fail ok");
	$test->is_eq($res->{diag}, "", "run fail diag");
}

{
	my @results = run_tests(
		sub {$cap->diag("run diag")},
		"run diag"
	);

	local $Test::Builder::Level = 0;

	$test->is_num(scalar (@results), 1, "run diag result count");

	my $res = $results[0];

	$test->is_num($res->{tested}, 0, "run diag tested");
	$test->is_eq($res->{expected_name}, "run diag", "run diag expected name");
	$test->ok(! defined($res->{name}), "run diag name");
	$test->ok(! defined($res->{ok}), "run diag ok");
	$test->is_eq($res->{diag}, "run diag", "run diag diag");
}

{
	my @results = run_tests(
		sub {
			$cap->ok(1, "multi pass");
			$cap->diag("multi pass diag");
			$cap->ok(0, "multi fail");
			$cap->diag("multi fail diag");
		},
		"run multi"
	);

	local $Test::Builder::Level = 0;

	$test->is_num(scalar (@results), 2, "run multi result count");

	my $res_pass = $results[0];

	$test->is_num($res_pass->{tested}, 1, "run multi pass tested");
	$test->is_eq($res_pass->{expected_name}, "run multi", "run multi pass expected name");
	$test->is_eq($res_pass->{name}, "multi pass", "run multi pass name");
	$test->is_eq($res_pass->{ok}, 1, "run multi pass ok");
	$test->is_eq($res_pass->{diag}, "multi pass diag", "run multi pass diag");

	my $res_fail = $results[1];

	$test->is_num($res_fail->{tested}, 1, "run multi fail tested");
	$test->ok(! defined($res_fail->{expected_name}), "run multi fail expected name");
	$test->is_eq($res_fail->{name}, "multi fail", "run multi fail name");
	$test->is_eq($res_fail->{ok}, 0, "run multi fail ok");
	$test->is_eq($res_fail->{diag}, "multi fail diag", "run multi fail diag");
}

