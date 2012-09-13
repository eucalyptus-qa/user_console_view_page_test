#!/usr/bin/perl
use strict;

my $SEL_SERVER_IP = "192.168.51.152";
my $SSH_PREFIX = "ssh -o BatchMode=yes -o ServerAliveInterval=3 -o ServerAliveCountMax=10 -o StrictHostKeyChecking=no root\@$SEL_SERVER_IP";

my $ui_user_list = "../share/ui-test-dir/ui-test-user-info.txt";

if( @ARGV > 0 ){
	my $ui_user_list = shift @ARGV;
};

print "\n";
print "Reading Input File\n";

read_input_file();
my $clc_ip = $ENV{'QA_CLC_IP'};
my $userconsole_port = "8888";
print "\n";

print "\n";
print "Scanning Accounts and Users for UI\n";
print "\n";
print "[UI USER LIST]\t$ui_user_list\n";
print "\n";

my $listbuf = `cat $ui_user_list`;
chomp($listbuf);

print "##############################################################\n";
print "$listbuf\n";
print "##############################################################\n";

my @userlistarray = split("\n", $listbuf);
my $num_user = @userlistarray;

if( $num_user < 1 ) {
	print "[TEST_REPORT] FAILED : NUM of USERS in the List $ui_user_list < 1\n";
	exit(1);
};


my $this_test = "view_all_page";

print "\n";
print "Running Selenium Test: $this_test";

foreach my $line (@userlistarray){

	if( $line =~ /^(\S+)\s+(\S+)\s+(\S+)/ ){

		my $account = $1;
		my $user = $2;
		my $password = $3;
		print "\n";
		print "\n";
		print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
		print "For User [ Account \'$account\', User \'$user\', Password '$password' ]\n";
		print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
		print "\n";
		print "\n";

		my $sel_cmd = "cd /root/eucalyptus_ui_test; export DISPLAY=:0;";
		$sel_cmd .= " ./runtest_view_page.py -i $clc_ip -p $userconsole_port -a $account -u $user -w $password -t $this_test";

		my $cmd = $SSH_PREFIX . " \"" . $sel_cmd . "\"";

		print "CMD: $cmd\n";
		my $output = `$cmd`;
		print "\n";
		print $output . "\n";
		print "\n";

		if( $output =~ /^Failures:\s+(\d+)/m ){
			if( $1 > 0 ){
				print "[TEST_REPORT]\tFAILED: Failures > 0\n";
			};
		};

		if( $output =~ /^Errors:\s+(\d+)/m ){
			if( $1 > 0 ){
				print "[TEST_REPORT]\tFAILED: Errors > 0\n";
			};
		};

	};
};

exit(0);

1;

########################### SUBROUTINE ###################################

# Read input values from input.txt
sub read_input_file{

	my $is_memo = 0;
	my $memo = "";

	open( INPUT, "< ../input/2b_tested.lst" ) || die $!;

	$ENV{'QA_CLC_IP'} = "";
	my $line;
	while( $line = <INPUT> ){
		chomp($line);
		if( $is_memo ){
			if( $line ne "END_MEMO" ){
				$memo .= $line . "\n";
			};
		};

        	if( $line =~ /^([\d\.]+)\t(.+)\t(.+)\t(\d+)\t(.+)\t\[(.+)\]/ ){
			my $qa_ip = $1;
			my $qa_distro = $2;
			my $qa_distro_ver = $3;
			my $qa_arch = $4;
			my $qa_source = $5;
			my $qa_roll = $6;

			my $this_roll = lc($6);
			if( $this_roll =~ /clc/ && $ENV{'QA_CLC_IP'} eq "" ){
				print "\n";
				print "IP $qa_ip [Distro $qa_distro, Version $qa_distro_ver, ARCH $qa_arch] is built from $qa_source as Eucalyptus-$qa_roll\n\n";
				$ENV{'QA_CLC_IP'} = $qa_ip;
				$ENV{'QA_DISTRO'} = $qa_distro;
				$ENV{'QA_DISTRO_VER'} = $qa_distro_ver;
				$ENV{'QA_ARCH'} = $qa_arch;
				$ENV{'QA_SOURCE'} = $qa_source;
				$ENV{'QA_ROLL'} = $qa_roll;
			};
		}elsif( $line =~ /^MEMO/ ){
			$is_memo = 1;
		}elsif( $line =~ /^END_MEMO/ ){
			$is_memo = 0;
		};
	};	

	close(INPUT);

	$ENV{'QA_MEMO'} = $memo;

	return 0;
};
