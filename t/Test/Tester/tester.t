#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.01';
$DATE = '2003/06/12';

use Test::TestUtil;
use Cwd;
use File::Spec;
use File::Glob ':glob';
use Test;

######
#
# T:
#
# use a BEGIN block so we print our plan before Module Under Test is loaded
#
BEGIN { 
   use vars qw( $T $__restore_dir__ @__restore_inc__ $__tests__);

   ########
   # Create the test plan by supplying the number of tests
   # and the todo tests
   #
   $__tests__ = 5;
   plan(tests => $__tests__);

   ########
   # Working directory is that of the script file
   #
   $__restore_dir__ = cwd();
   my ($vol, $dirs, undef) = File::Spec->splitpath( $0 );
   chdir $vol if $vol;
   chdir $dirs if $dirs;

   #######
   # Add the library of the unit under test (UUT) to @INC
   #
   @__restore_inc__ = Test::TestUtil->test_lib2inc;

}

END {

    #########
    # Restore working directory and @INC back to when enter script
    #
    @INC = @__restore_inc__;
    chdir $__restore_dir__;
}

    #######
    # Delete actual results files
    #
    my @outputs = bsd_glob( 'tester1.*' );
    unlink @outputs;

    #### 
    # File Legend
    # 
    #  0 - series is used to generate an test case test script
    #
    #  1 - this is the actual value test case
    #      thus, TestGen1 is used to produce actual test results
    #
    #  2 and above - these series are the expected test results
    # 
    #

#######
#
# ok: 1 
#
my $loaded;
print "# UUT not loaded\n";
verify( $loaded = Test::TestUtil->is_package_loaded('Test::Tester'), 
    ''); #expected results

#######
# 
# ok:  2
# 
print "# Load UUT\n";
my $errors = Test::TestUtil->load_package( 'Test::Tester' );
my $test_results = skip_verify(
    $loaded, # condition to skip test   
    $errors, # actual results
    '');  # expected results

######
# Unless results, skip rest of tests
# 
unless( $test_results ) {
   for (my $i=2; $i < $__tests__; $i++) { skip(1,0,0) };
   exit 1;
}

#######
#
#  ok:  3
#
#  Pod check 
# 

print  "No pod errors\n";
$test_results =
verify( Test::TestUtil->pod_errors( 'Test::Tester'), 
          0); # expected results);

unless($test_results ) {
    $test_results =~ s/\n/\n# /g;
    print '# ' . $test_results; 
}

#####
#  ok:  4
# 
# RUn demonstration script test case 
#
$test_results = `perl tester0.d`;
Test::TestUtil->fout('tester1.txt', $test_results);
print "# Demonstration script\n";

$test_results = 
verify( $test_results, 
    Test::TestUtil->fin('tester2.txt')); # expected results

unless( $test_results ) {
    $test_results =~ s/\n/\n# /g;
    print '# ' . $test_results; 
}

#####
#  ok:  5
# 
# Run test script test case 
#
$test_results = `perl tester0.t`;
Test::TestUtil->fout('tester1.txt', $test_results);
print "# Run test script\n";

$test_results = 
verify( Test::TestUtil->scrub_file_line($test_results), # actual results
    Test::TestUtil->scrub_file_line(Test::TestUtil->fin('tester3.txt')) ); # expected results

unless( $test_results ) {
    $test_results =~ s/\n/\n# /g;
    print '# ' . $test_results; 
}


#######
# Delete actual results files
#
@outputs = bsd_glob( 'tester1.*' );
unlink @outputs;


####
# The ok user caller to look up the stack. If nothing there,
# ok produces a warining. Thus, burying it in a subroutine eliminates
# these warning.
#
sub verify { 
   my ($actual,$expected) = @_;
   ok($actual,$expected) 
};

sub skip_verify { 
   my ($flag, $actual,$expected) = @_;
   skip($flag, $actual,$expected) 
};


__END__

=head1 NAME

tester.t - test script for Test::Tester

=head1 SYNOPSIS

 tester.t 

=head1 COPYRIGHT

copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

## end of test script file ##

