#!/bin/perl -w 

##################################################################################################
use warnings;
use strict;

###################################
## --- Source Perl Modules    ---##
###################################
use Data::Dumper;
use POSIX qw(strftime);
use FileHandle;
use Time::Local;
use File::Copy;
use File::Copy "cp";
use Net::FTP;
use List::Util 'first';
use List::MoreUtils 'none';

use File::chdir;
use File::Copy qw(copy);
use File::Copy qw(move);

use Time::Piece;
use Time::Seconds;
use feature qw(say);

###################################
## --- Source Custom Modules  ---##
###################################
## BEGIN { unshift @INC, "H:/EDP/MyPerl/FedLineAdvantage/perl/lib" }
BEGIN { unshift @INC, "C:/Users/BUAdmin/MyPerl/FedLineAdvantage/perl/lib" }

use SendTools qw(&SendEmailPS &SendEmailMIME &SendEmailStuffer RoboCopyFile);
use GenWirePayments qw(&GenFEDWirePmt);

###################################
$| = 1;			# --- autoflush stdout to print right away
###################################

###################################
=begin DateTimePiece
###################################
my $time = Time::Piece->new;
my $my_date = $time - ONE_DAY;

say $my_date->mday . "-" . $my_date->monname . "-" . $my_date->year;
## my $testdate = $my_date->mday . "." . $my_date->mon . "." . $my_date->year;
my $testdate = $my_date->mon . $my_date->mday .  $my_date->year;

my $prev_day = localtime($my_date);

print "Today:|$time|\n";
print "Yesterday |$my_date|\n";
print "prev_day |$prev_day|\n";
print "testdate |$testdate|\n";
## print "processing_date |$processing_date|\n";
###################################
=end DateTimePiece
=cut
###################################


###################################
## --- Date Variables	      ---##
###################################
my $processing_date = strftime "%d.%m.%Y", localtime;
## $processing_date = "17.05.2022";
my $filedate = strftime "%m%d%Y_%H%M%S", localtime;

print "Processing Date:|$processing_date|\n";
print "File Date:|$filedate|\n";

###################################
## --- Directory Path	      ---##
###################################
my $archive_file;

###################################
## =begin PROD_PATH
###################################
my $fed_input_path = 'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\In';
my $fed_output_path = 'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Out';
my $fed_log_path = 'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Log';
my $fed_template_path = 'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Template';
my $fed_archive_path = 'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Archive';
my $rc_srctemplate_path = 'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Template';
my $rc_source_path = 'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Out';
my $rc_upload_path = '/\\ehny20-2\FILESHARES\Shared Data\FedLineAdvantage\Upload';
my $rc_template_path = '/\\ehny20-2\FILESHARES\Shared Data\FedLineAdvantage\Template';
###################################
## =end PROD_PATH
## =cut
###################################
#
###################################
## --- Input Files	      ---##
###################################
my $calypso_payments_filename = 'calypso_payments.txt';
my $calypso_payments = $fed_input_path . "\\$calypso_payments_filename";

my $fed_switch_filename = 'fed_repayment_switch.txt';
my $fed_switch = $fed_input_path . "\\$fed_switch_filename";

my $fed_cpty_filename = 'fed_cpty_repayment_list.txt';
my $fed_cpty = $fed_input_path . "\\$fed_cpty_filename";

my $fed_holidays_filename = 'fed_holidays.csv';
my $fed_holidays = $fed_input_path . "\\$fed_holidays_filename";

###################################
## --- Output Files	      ---##
###################################
my $fed_interest_filename = 'FED_Interest2Transfer_' . $filedate . ".csv";
my $fed_interest = $fed_output_path . "\\$fed_interest_filename";

my $fed_wirepayments_filename = 'FED_Pmts_' . $filedate . ".txt";
my $fed_wirepayments = $fed_output_path . "\\$fed_wirepayments_filename";

my $calypso_payments_template_filename = 'calypso_payments_TEMPLATE_' . $filedate . ".csv";
my $calypso_payments_template = $fed_template_path . "\\$calypso_payments_template_filename";

###################################
## --- Log Files	      ---##
###################################
my $ignored_log_filename = 'calypso_payments_ignored_' . $filedate . ".csv";
my $ignored_log = $fed_log_path . "\\$ignored_log_filename";

my $processed_log_filename = 'calypso_payments_processed_log_' . $filedate . ".txt";
my $processed_log = $fed_log_path . "\\$processed_log_filename";

my $missing_data_log_filename = 'calypso_missing_data_' . $filedate . ".csv";
my $missing_data_log = $fed_log_path . "\\$missing_data_log_filename";

###################################
## --- Set Email Variables   --- ##
###################################
## my $Email_Distribution_List = "'MLNYBackOfficeEH_NY\@erstegroup.com', 'MLInterITEH_NY\@erstegroup.com'"; # PROD
my $Email_Distribution_List = "'erwin.ortega\@erstegroup.com', 'john.ferrante\@erstegroup.com'"; ## TEST
## my $Email_Distribution_List = "'Dinesh.Patadia\@erstegroup.com', 'erwin.ortega\@erstegroup.com'"; ## DEV
print "$Email_Distribution_List\n";
###################################
my $Email_Type = 'Notification::';
## my $Email_RunType = 'MANUAL';
my $Email_RunType = 'Daily';
my $Email_Sender = 'MLInterITEH_NY@erstegroup.com';
my $Email_Subject = "$Email_Type $Email_RunType FedLineAdvantage Batch Repayments";
my $Email_Body = "Hi,\n
The FED Batch Repayments file is ready for upload.\n
You can find it in the shared drive under S:\\FEDLineAdvantage\\Out\n";
my $Email_Server = '10.252.50.50';


			##################################################
			##						##
			##################################################
			##						##
			## 	P R E - P R O C E S S I N G		##
			##						##
			##################################################
			## - only proceed if the file date is current	##
			##################################################
			
###################################
## --- Read Holdays File     --- ##
###################################  
open my $HOLIDAYS_FH, '<', $fed_holidays or die $!;
###################################
my(@FED_Holidays);
my $holiday_flag = "N";
my $holiday = "01.01.1999";
my $holiday_name = " ";
my $eval_date = $processing_date;
$eval_date =~ s/\.//g;

HOLIDAY_FILE: while (<$HOLIDAYS_FH>) {
	chomp;
	($holiday,$holiday_name)= split /\,/; 
	$holiday =~ s/\.//g;
	print "$holiday,$holiday_name\n";
	if ($eval_date =~ m/$holiday/) {	
		$holiday_flag = "Y";
		last;
	}
}  ## end while HOLIDAY_FILE

die "\n|$processing_date|$holiday|$holiday_name| is a holiday. Exiting program.|$!|\n" if ($holiday_flag =~ m/Y/);	
close($HOLIDAYS_FH);

print "\n|$processing_date| is a business day. Proceeding..\n";

###################################
			
###################################
## --- Archive Log Files     --- ##
## You can't move files if   --- ##
## they are open  	     --- ##
###################################
## chdir($fed_output_path);
## my @logfiles = glob("$fed_log_path/calypso*.*");
my @logfiles = glob("$fed_log_path/calypso*");
for $archive_file (@logfiles) {
	## copy($archive_file, $fed_archive_path) or warn "Copy failed: $!";
	## print "Log file: |$archive_file|\n";
	move($archive_file, $fed_archive_path) or warn "Move failed: $!";
}

###################################
open my $CALYPSO_FH, '<', $calypso_payments or die $!;
open my $PROCESSED_FH, '>', $processed_log or die $!;

###################################
## --- Check Calypso Date    --- ##
###################################
my $calypso_date = "31.12.1999";
my ($wait_time,$wait_limit) = (900,7200);
## my ($wait_time,$wait_limit) = (60,120);
my $wait_mins = $wait_time/60;
my $wait_total = $wait_limit/60;
###################################
$Email_Type = 'ALERT::';
$Email_Subject = "$Email_Type $Email_RunType FED Batch Repayments";
$Email_Body = "Hi,\n\n The Calypso payments file has NOT been delivered. The process will wait and check again in |$wait_mins| minutes.\n";
###################################
my ($calypso_file) = do { local( $/ ) ; <$CALYPSO_FH> } ; close($CALYPSO_FH);
$calypso_file =~ m/\d{2,2}.\d{2,2}.\d{4,4}/;
$calypso_date = $&;
print "CHECK...Processing_date is:|$processing_date|\n";
print "CHECK...Calypso_date is:|$calypso_date|\n";



###################################
while ( $calypso_date ne $processing_date ) {
	print "WHILE...wait_limit is:|$wait_limit|\n";
	if ( $wait_limit == 0 ) {
		$Email_Body = "Hi,\n\n The Calypso payments file was NOT delivered after waiting for |$wait_total} minutes.\n
		Exiting program.  FileDate:|$calypso_date| IS NOT EQUAL to the ProcessDate:|$processing_date|\n";
		print $PROCESSED_FH "$Email_Body";
		&SendEmailPS ( $Email_Type,$Email_Sender,$Email_Distribution_List,$Email_Subject,$Email_Body,$PROCESSED_FH,$calypso_payments,$Email_Server);
		print "DIE...Calypso_date is:|$calypso_date|\n";
		die "$Email_Body";
	}

	print "$Email_Body";
	print $PROCESSED_FH "$Email_Body";
	&SendEmailPS ( $Email_Type,$Email_Sender,$Email_Distribution_List,$Email_Subject,$Email_Body,$PROCESSED_FH,$calypso_payments,$Email_Server) if  $calypso_date ne $processing_date ;
	sleep $wait_time;
	$wait_limit = $wait_limit - $wait_time;

	open $CALYPSO_FH, '<', $calypso_payments or die $!;
	$calypso_file = do { local( $/ ) ; <$CALYPSO_FH> } ; close($CALYPSO_FH);
	$calypso_file =~ m/\d{2,2}.\d{2,2}.\d{4,4}/;
	$calypso_date = $&;
	## my ($yyyy,$mm,$dd,$chk_MidasHr) = split /\-/, $chk_MidasDate;
	## $chk_MidasDate = qq($yyyy) . "-" . qq($mm) . "-" . qq($dd);
	## $chk_MidasHr =~ s/\.*$//g;
	print "WHILE...Calypso_date is:|$calypso_date|\n";
} # end while loop
###################################


			##################################################
			##						##
			##################################################
			##						##
			## 	M A I N  P R O C E S S I N G		##
			##						##
			##################################################
			##						##
			##################################################
			
print "\n-----------------------------------------------------------\n";
print "\n-----------------------------------------------------------\n";
print "PROCEEDING to Main Process...Calypso_date is:|$calypso_date|\n";
sleep 10; 

		##############################################################
		##############################################################
		##--- 		FILES ARCHIVE PROCESS			 ---## 
		##############################################################
		##############################################################


###################################
## --- Archive Input File    --- ##
###################################
my $transferfile;
my @inputfiles = glob("$fed_input_path/calypso*.txt");
for $archive_file (@inputfiles) {
	## $transferfile = 'calpyso_payments_' . $filedate . ".txt";
	$transferfile = $archive_file . "_". $filedate . ".txt";
	## print "Input file: |$archive_file|$transferfile|\n";
	copy($archive_file, $transferfile) or warn "Copy failed: $!";
	move($transferfile, $fed_archive_path) or warn "Copy failed: $!";
}
###################################
## --- Archive Output File   --- ##
###################################
## my @outputfiles = glob("$fed_output_path/fed*.*");
my @outputfiles = glob("$fed_output_path/FED*");
for $archive_file (@outputfiles) {
	## copy($archive_file, $fed_archive_path) or die "warn failed: $!";
	## print "Output file: |$archive_file|\n";
	move($archive_file, $fed_archive_path) or warn "Move failed: $!";
}
###################################
## --- Archive Log Files    --- ##
###################################
## chdir($fed_output_path);
## my @logfiles = glob("$fed_log_path/calypso*.*");
## my @logfiles = glob("$fed_log_path/calypso*");
## for $archive_file (@logfiles) {
	## copy($archive_file, $fed_archive_path) or warn "Copy failed: $!";
	## print "Log file: |$archive_file|\n";
	## move($archive_file, $fed_archive_path) or warn "Move failed: $!";
## }

###################################
###################################
$| = 1;			# --- autoflush stdout to print right away
###################################
###################################

###################################
## --- Read Calypso File     --- ##
###################################
open $CALYPSO_FH, '<', $calypso_payments or die $!;
my(@Calypso_Payments,@fields);

CALYPSO_FILE: while (<$CALYPSO_FH>) {
	chomp;
        @fields = split /\;/;   # --- semi colon delimiter
	## next CALYPSO_FILE if ( @fields =~ /Transfer/ );
        push @Calypso_Payments,[@fields];
}  ## end while CALYPSO_FILE
close($CALYPSO_FH);

my $Calypso_Payments_Cnt = scalar(@Calypso_Payments);
print "\n-------------------------------------------------------\n";
print "|$Calypso_Payments_Cnt| calypso records found for processing...\n";

if( $Calypso_Payments_Cnt < 2 ) {
	$Email_Type = 'Alert::';
	$Email_Subject = "$Email_Type $Email_RunType FED Batch Repayments";
	$Email_Body = "Hi,\n\n The Calypso import file is EMPTY!!! Please investigate. \n\n";
	close($CALYPSO_FH);
	&SendEmailPS ( $Email_Type,$Email_Sender,$Email_Distribution_List,$Email_Subject,$Email_Body,$PROCESSED_FH,$calypso_payments,$Email_Server);
	print $PROCESSED_FH "$Calypso_Payments_Cnt NO Calypso payment records found...\n"; 
	die "\nNO CALYPSO RECORDS TO PROCESS HERE! EXITING Program...\n";
}

###################################
## --- Open File Handles      ---##
###################################
###################################
open my $FEDSWITCH_FH, '<', $fed_switch or die $!;
open my $FEDCPTY_FH, '<', $fed_cpty or die $!;
open my $FEDINTEREST_FH, '>', $fed_interest or die $!;
open my $FEDPAY_FH, '>', $fed_wirepayments or die $!;
open my $CALYPSO_PAY_TEMPLATE_FH, '>', $calypso_payments_template or die $!;
open my $IGNORED_FH, '>', $ignored_log or die $!;
open my $MISSING_FH, '>', $missing_data_log or die $!;

###################################
## --- Print File Headers    --- ##
###################################
## open my $IGNORED_FH, '>', $ignored_log or die $!;
## print $IGNORED_FH "TradeId,Instrument,Cust_Name,Calypso_CustNbr,Bene_AccNo,TotalPayment,Principal,Interest_Amount\n";
## print $MISSING_FH "TradeId,Instrument,Cust_Name,Calypso_CustNbr,Bene_AccNo,TotalPayment,Principal,Interest_Amount\n";
## print $FEDINTEREST_FH "TradeId,Instrument,Cust_Name,Calypso_CustNbr,TotalPayment,Principal,Interest_Amount\n";
#
print $IGNORED_FH "TradeId,Instrument,Cust_Name,Calypso_CustNbr,Bene_AccNo,Bene_Address_2,TotalPayment,Principal,Interest_Amount\n";
print $MISSING_FH "TradeId,Instrument,Cust_Name,Calypso_CustNbr,Bene_AccNo,Bene_Address_2,TotalPayment,Principal,Interest_Amount\n";
print $FEDINTEREST_FH "TradeId,Instrument,Cust_Name,Calypso_CustNbr,Bene_Address_2,TotalPayment,Principal,Interest_Amount\n";
print $CALYPSO_PAY_TEMPLATE_FH "File_Date,Principal,Interest,Sender_ABA,Sender_ShortName,Sender_Ref,Receiver_ABA,Receiver_ShortName,Transfer_Type,Bene_CustNo,Bene_AccType,Bene_AccNo,Bene_Name,Bene_Address_1,Bene_Ref,Originator,TradeId,Instrument,Bene_Address_2,Bene_Address_3,Rec_Nostro\n";  

###################################
## --- Read FED SWITCH File  --- ##
###################################
my ($cpty_switch) = do { local( $/ ) ; <$FEDSWITCH_FH> } ; close($FEDSWITCH_FH);
print "\nCPTY SWITCH is: |$cpty_switch|\n";
print $PROCESSED_FH "\nCPTY SWITCH is: |$cpty_switch|\n";
## exit;

###################################
## --- Read FED Cpty File    --- ##
###################################
my(@FED_Cpty);

CPTY_FILE: while (<$FEDCPTY_FH>) {
	chomp;
	print "$_\n";	
        push (@FED_Cpty,$_);
}  ## end while CTPY_FILE
close($FEDCPTY_FH);

my $Cpty_Cnt = scalar(@FED_Cpty);
print "\n-------------------------------------------------------\n";
print "|$Cpty_Cnt| cpty records found for processing...\n";

###################################
## --- Init Variables        --- ##
###################################
my $Total_Interest = 0.00;	
my $Transfer_Interest = 0.00;	
my $Org_Payment_Amount = 0.00;
my $Org_Principal = 0.00;
my $Org_Interest = 0.00;	
my $chk_cnt = 0;	
my $print_cnt = 0;	
my $missing_cnt = 0;	
my $col;
my $ProcessedPmt_Comments;
print $PROCESSED_FH "ProcessDate:|$processing_date|\n";
print "\nProcessing_Date:|$processing_date|\n";

##################################################

PAYMENT: foreach $col (@Calypso_Payments) {

	my ( $File_Date,$Principal,$Interest,$Sender_ABA,$Sender_ShortName,$Sender_Ref,$Receiver_ABA,$Receiver_ShortName,$Transfer_Type,$Bene_CustNo,$Bene_AccType,$Bene_AccNo,$Bene_Name,$Bene_Address_1,$Bene_Ref,$Originator,$TradeId,$Instrument,$Bene_Address_2,$Bene_Address_3,$Rec_Nostro ) = ( $$col[0],$$col[1],$$col[2],$$col[3],$$col[4],$$col[5],$$col[6],$$col[7],$$col[8],$$col[9],$$col[10],$$col[11],$$col[12],$$col[13],$$col[14],$$col[15],$$col[16],$$col[17],$$col[18],$$col[19],$$col[20] );

		next PAYMENT if ( $Principal =~ /Principal/ );
		$chk_cnt++;

		##################################################
		## if ( $m_MidasId !~ /\d+/ ){} # how to check if numeric
		## $m_Balance =~ s/^\.\d+/0\.00000000/g; $m_Balance =~ s/\s+//g;
		## $m_ODRate =~ s/^\.0{2,10}\d+/0\.00000000/g; $m_ODRate =~ s/\s+//g;
		## $m_SDRate =~ s/^\.0{2,10}\d+/0\.00000000/g; $m_SDRate =~ s/\s+//g;
		## $m_ODLimit =~ s/^\.\d+/0\.00000000/g; $m_ODLimit =~ s/\s+//g;
		## $m_Branch =~ s/"//g; # remove quote
		## $m_MidasId = sprintf "%0${ZeroPadNo}d", $m_MidasId; # pad zeros
		## my ($mm,$dd,$yyyy) = split /\//, $kpf_MaturityDate;
		## my $yy = substr $yyyy, 2,2;
		##################################################
		## $d2nNearFwd_NovationPts_AllIn = $d2nNearPts + $d2nNearMargin;
		## $d2nNearFwd_NovationPts_AllIn = sprintf "%.9f", $d2nNearFwd_NovationPts_AllIn;
		## $d2nNearFwd_ChkPtsCalc = $d2nNearFwd_NovationPts_AllIn / ( 10 ** $d2nPointsDigit ) ;
		##################################################
	
		##################################################
		## --- Cleanup unwanted characters from data--- ##
		##################################################
		$File_Date =~ s/"//g; # remove quote
		##################################################
		$Principal =~ s/"//g; # remove quote
		$Principal =~ s/,//g; # remove comma
		$Org_Principal = $Principal;	
		$Principal =~ s/\.//g; # remove decimal
		##################################################
	 	if ( $Interest eq "") {	
			$Interest = 0.00;
		}
		$Interest =~ s/"//g; # remove quote
		$Interest =~ s/,//g; # remove comma
		$Org_Interest = $Interest;	
		$Interest =~ s/\.//g; # remove decimal
		$Total_Interest = $Total_Interest + $Org_Interest;
		##################################################
		## --- Set Wire Payment Amount		    --- ##
		##################################################
		my $Org_Payment_Amount = $Org_Principal + $Org_Interest;
		my $Payment_Amount = $Principal + $Interest;
		##################################################
		$Interest =~ s/"//g; # remove quote
		$Sender_ABA =~ s/"//g; # remove quote
		##################################################
		## --- 	Set Sender ShortName 		    --- ##
		## 18 chars only 			    --- ##
		## constant value			    --- ##
		##################################################
		$Sender_ShortName =~ s/"//g; # remove quote
		$Sender_ShortName = "ERSTE GRP BK AG NY BRANCH";
		##################################################
		$Sender_Ref =~ s/"//g; # remove quote
		$Receiver_ABA =~ s/"//g; # remove quote
		$Receiver_ShortName =~ s/"//g; # remove quote
		$Transfer_Type =~ s/"//g; # remove quote
		$Bene_CustNo =~ s/"//g; # remove quote
		$Bene_CustNo =~ s/\s+//g; # remove quote
		$Bene_AccType =~ s/"//g; # remove quote
		##################################################
		$Bene_AccNo =~ s/"//g; # remove quote
		## my $Org_Bene_AccNo;
		my $Org_Bene_AccNo = "";
		if ( $Bene_AccNo eq "") {
			$Org_Bene_AccNo = "MISSING";
		}
		##################################################
		$Bene_Name =~ s/"//g; # remove quote
		$Bene_Name =~ s/,/ /g; # replace comma with space

		$Bene_Address_1 =~ s/"//g; # remove quote
		$Bene_Address_1 =~ s/,/ /g; #  replace comma with space
		$Bene_Address_1 =~ s/�/'/g; #  replace comma with space
		$Bene_Address_1 =~ s/�//g; #  replace comma with space

		$Bene_Ref =~ s/"//g; # remove quote
		$Originator =~ s/"//g; # remove quote
		$TradeId =~ s/"//g; # remove quote
		$Instrument =~ s/"//g; # remove quote

		$Bene_Address_2 =~ s/"//g; # remove quote
		$Bene_Address_2 =~ s/,/ /g; #  replace comma with space
		$Bene_Address_2 =~ s/�/'/g; #  replace comma with space
		$Bene_Address_2 =~ s/�//g; #  replace comma with space

		$Bene_Address_3 =~ s/"//g; # remove quote
		$Bene_Address_3 =~ s/,/ /g; #  replace comma with space
		$Bene_Address_3 =~ s/�/'/g; #  replace comma with space
		$Bene_Address_3 =~ s/�//g; #  replace comma with space

		##############################################################
		my $Org_Rec_Nostro = "";
		$Org_Rec_Nostro = $Rec_Nostro;
		$Rec_Nostro =~ s/"//g; # remove quote
		##############################################################

		for( @FED_Cpty ) {
			if ($_ eq $Bene_CustNo) {
				$Rec_Nostro = "FEDUSAXXXXXXX";
				last;	
			}
		}

		print "cpty_switch is:|$cpty_switch| REc_Nostro is: |$Rec_Nostro|\n";
		##############################################################
		##--- Create Wire Payment if Cpty in Process List	--- ##
		##############################################################
		if ( $cpty_switch eq "PARTIAL" ) { 

		#
		## print $IGNORED_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Bene_AccNo,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n" if $Rec_Nostro =~ m/BOFA/;
		print $IGNORED_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Bene_AccNo,$Bene_Address_2,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n" if $Rec_Nostro =~ m/BOFA/;

		next PAYMENT if $Rec_Nostro =~ m/BOFA/ ;

		## if ( $Org_Bene_AccNo =~ m/MISSING/ ) {
			if ( $Org_Bene_AccNo =~ m/MISSING/ && $Transfer_Type =~ m/Cust/ ) {
				## print $MISSING_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Org_Bene_AccNo,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
				print $MISSING_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Org_Bene_AccNo,$Bene_Address_2,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
				$missing_cnt++;
			}
		
		print "\n\n***************************************************\n";
		print "***************************************************";
		print "\nprocessing $TradeId|$Instrument|$Bene_CustNo|$Org_Payment_Amount|$Org_Principal|$Org_Interest";

		##############################################################
		## --- accumulate interest for separate payment		 ---## 
		##############################################################
		## $Transfer_Interest = $Transfer_Interest + $Interest;
		$Transfer_Interest = $Transfer_Interest + $Org_Interest;
		##############################################################

		print "\npassing values |$File_Date,$Payment_Amount,$Sender_ABA,$Sender_ShortName,$Sender_Ref,$Receiver_ABA,$Receiver_ShortName,$Transfer_Type,$Bene_AccType,$Bene_AccNo,$Bene_Name,$Bene_Address_1,$Bene_Ref,$Originator,$TradeId,$Instrument,$Bene_Address_2,$Bene_Address_3,$Rec_Nostro|\n";

		&GenFEDWirePmt ($File_Date,$Payment_Amount,$Sender_ABA,$Sender_ShortName,$Sender_Ref,$Receiver_ABA,$Receiver_ShortName,$Transfer_Type,$Bene_AccType,$Bene_AccNo,$Bene_Name,$Bene_Address_1,$Bene_Ref,$Originator,$TradeId,$Instrument,$Bene_Address_2,$Bene_Address_3,$Rec_Nostro,$PROCESSED_FH,$FEDPAY_FH);

		## print $FEDINTEREST_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
		## print $PROCESSED_FH "$TradeId|$Instrument|$Bene_Name|$Bene_CustNo|$Org_Payment_Amount|$Org_Principal|$Org_Interest|\n";
		print $FEDINTEREST_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Bene_Address_2,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
		print $PROCESSED_FH "$TradeId|$Instrument|$Bene_Name|$Bene_CustNo|$Bene_Address_2|$Org_Payment_Amount|$Org_Principal|$Org_Interest|\n";

		print $CALYPSO_PAY_TEMPLATE_FH "$File_Date,$Principal,$Interest,$Sender_ABA,$Sender_ShortName,$Sender_Ref,$Receiver_ABA,$Receiver_ShortName,$Transfer_Type,$Bene_CustNo,$Bene_AccType,$Bene_AccNo,$Bene_Name,$Bene_Address_1,$Bene_Ref,$Originator,$TradeId,$Instrument,$Bene_Address_2,$Bene_Address_3,$Rec_Nostro\n";  

		$print_cnt++;
		}
		else { 

		##############################################################
		## --- 		PROCESS ALL PAYMENTS			--- ##
		##############################################################
		## if ( $Org_Bene_AccNo =~ m/MISSING/ ) {
			if ( $Org_Bene_AccNo =~ m/MISSING/ && $Transfer_Type =~ m/Cust/ ) {
				## print $MISSING_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Org_Bene_AccNo,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
				print $MISSING_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Org_Bene_AccNo,$Bene_Address_2,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
				$missing_cnt++;
			}
		
		##############################################################
		## --- accumulate interest for separate payment		 ---## 
		##############################################################
		## $Transfer_Interest = $Transfer_Interest + $Interest;
		$Transfer_Interest = $Transfer_Interest + $Org_Interest;
		##############################################################
		print "\npassing values |$File_Date,$Payment_Amount,$Sender_ABA,$Sender_ShortName,$Sender_Ref,$Receiver_ABA,$Receiver_ShortName,$Transfer_Type,$Bene_AccType,$Bene_AccNo,$Bene_Name,$Bene_Address_1,$Bene_Ref,$Originator,$TradeId,$Instrument,$Bene_Address_2,$Bene_Address_3,$Rec_Nostro|\n";

		&GenFEDWirePmt ($File_Date,$Payment_Amount,$Sender_ABA,$Sender_ShortName,$Sender_Ref,$Receiver_ABA,$Receiver_ShortName,$Transfer_Type,$Bene_AccType,$Bene_AccNo,$Bene_Name,$Bene_Address_1,$Bene_Ref,$Originator,$TradeId,$Instrument,$Bene_Address_2,$Bene_Address_3,$Rec_Nostro,$PROCESSED_FH,$FEDPAY_FH);

		## print $FEDINTEREST_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
		## print $PROCESSED_FH "$TradeId|$Instrument|$Bene_Name|$Bene_CustNo|$Org_Payment_Amount|$Org_Principal|$Org_Interest|\n";
		print $FEDINTEREST_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Bene_Address_2,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
		print $PROCESSED_FH "$TradeId|$Instrument|$Bene_Name|$Bene_CustNo|$Bene_Address_2|$Org_Payment_Amount|$Org_Principal|$Org_Interest|\n";
	
		print $CALYPSO_PAY_TEMPLATE_FH "$File_Date,$Principal,$Interest,$Sender_ABA,$Sender_ShortName,$Sender_Ref,$Receiver_ABA,$Receiver_ShortName,$Transfer_Type,$Bene_CustNo,$Bene_AccType,$Bene_AccNo,$Bene_Name,$Bene_Address_1,$Bene_Ref,$Originator,$TradeId,$Instrument,$Bene_Address_2,$Bene_Address_3,$Rec_Nostro\n";  



		$print_cnt++;
		}	
		##############################################################

##################################################################################################
} ## end foreach PAYMENT 	
##################################################################################################

##################################################################################################
print "\n\n|$print_cnt of $chk_cnt| FED Wire Payments records created...\n" if( $print_cnt > 1 );
print $PROCESSED_FH "\n\n|$print_cnt of $chk_cnt| FED Wire Payments records created...\n" if( $chk_cnt > 1 );
###################################
close($FEDPAY_FH);

		##############################################################
		##############################################################
		##--- 		Send FED Batch Payments File 		 ---## 
		##############################################################
		##############################################################
###################################
## --- Set Email Variables   --- ##
## for Batch Repayments File     ##	
###################################
$Email_Type = 'Notification::';
$Email_Subject = "$Email_Type $Email_RunType FED Batch Repayments File is Ready";
$Email_Body = "Hi,\n\n
The FED Batch Repayments file is ready for upload.\n
You can find it in the shared drive under S:\\FEDLineAdvantage\\Upload\n";
$Email_Server = '10.252.50.50';

&SendEmailPS ( $Email_Type,$Email_Sender,$Email_Distribution_List,$Email_Subject,$Email_Body,$PROCESSED_FH,$fed_wirepayments,$Email_Server) if ( $print_cnt > 0 );

&RoboCopyFile ( $rc_source_path,$rc_upload_path,$fed_wirepayments_filename,$PROCESSED_FH) if ( $print_cnt > 0 );
&RoboCopyFile ( $rc_srctemplate_path,$rc_template_path,$calypso_payments_template_filename,$PROCESSED_FH) if ( $print_cnt > 0 );
###################################


		##############################################################
		##############################################################
		##--- 		Process Interest Transfer		 ---## 
		##############################################################
		##############################################################

###################################
my $formatted_Transfer_Interest = $Transfer_Interest;
$formatted_Transfer_Interest =~ s/"//g; # remove quote
$formatted_Transfer_Interest =~ s/,//g; # remove comma
$formatted_Transfer_Interest =~ s/\.//g; # remove decimal
###################################
print "\n|$print_cnt|\nTotal interest to transfer to the FED |$Transfer_Interest of $Total_Interest|...\n" if( $print_cnt > 0 );
print $PROCESSED_FH "\n\nTotal interest to transfer to the FED |$Transfer_Interest of $Total_Interest|...\n" if( $print_cnt > 0 );

###################################
close($MISSING_FH);
###################################
## --- Set Email Variables   --- ##
## for Interest Transfer	 ##	
###################################
$Email_Type = 'ALERT::';
$Email_Subject = "$Email_Type $Email_RunType FED Batch Repayments - MISSING DATA";
$Email_Body = "Hi,\n\n The Beneficiary Account No is MISSING!\n\n";
$Email_Server = '10.252.50.50';

&SendEmailPS ( $Email_Type,$Email_Sender,$Email_Distribution_List,$Email_Subject,$Email_Body,$PROCESSED_FH,$missing_data_log,$Email_Server) if ( $missing_cnt > 0 );

###################################
close($FEDINTEREST_FH);
###################################
## --- Set Email Variables   --- ##
## for Interest Transfer	 ##	
 ##################################
$Email_Type = 'Notification::';
$Email_Subject = "$Email_Type $Email_RunType FED Batch Repayments - BOA to FED Interest Transfer Amount";
$Email_Body = "Hi,\n\n The total interest to transfer to the FED is: |$Transfer_Interest|.\n\n";
$Email_Server = '10.252.50.50';

&SendEmailPS ( $Email_Type,$Email_Sender,$Email_Distribution_List,$Email_Subject,$Email_Body,$PROCESSED_FH,$fed_interest,$Email_Server) if ( $print_cnt > 0 );

&RoboCopyFile ($rc_source_path,$rc_upload_path,$fed_interest_filename,$PROCESSED_FH) if ( $print_cnt > 0 );
##################################

close($FEDSWITCH_FH);
close($PROCESSED_FH);
close($IGNORED_FH);

###################################
