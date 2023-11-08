#####################################################################
## Package for Generating FedLineAdvantage Wire Payments Messages for Import
## Created by:	EO 2022-03-27
##
#####################################################################
package GenWirePayments;
## package GenWirePayments_AddNostro;

use strict;
use warnings;
use MailTools;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Data::Dumper;
use POSIX qw(strftime);
use FileHandle;
use Time::Local;
use File::Copy;
use File::Copy "cp";
use Net::FTP;
use Net::SMTP;
use IO::Handle;
use IO::Socket;

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT_OK   = qw(GenFEDWirePmt);  
%EXPORT_TAGS = ( DEFAULT => [qw(GenFEDWirePmt)], Both    => [qw(GenFEDWirePmt)]);

##################################################################################################
##				---	SUBROUTINES	---					##
##################################################################################################

# ---------------------------------------------------------------------------------------------- #
sub GenFEDWirePmt {
        print "\n-----------------------------------------\n";
        print "\nCalling GenFEDWirePmt function...\n";

	my ( $File_Date,$Transfer_Amount,$Sender_ABA,$Sender_ShortName,$Sender_Ref,$Receiver_ABA,$Receiver_ShortName,$Transfer_Type,$Bene_AccType,$Bene_AccNo,$Bene_Name,$Bene_Address_1,$Bene_Ref,$Originator,$TradeId,$Instrument,$Bene_Address_2,$Bene_Address_3,$Rec_Nostro,$process_log,$import_file ) = @_;

##################################################
##################################################
## 	Define and Set Variables		##
##################################################
##################################################

##################################################
## 	Counters				##
##################################################
my $chk_cnt = 0;	
my $print_cnt = 0;	
my $col;
my $ZeroPadNo;
my $ProcessedPmt_Comments;

##################################################
## 1.0 Mandatory FEDLine Message Tags		##
##################################################
my $Leading_Info = "YFT811  ";
my $SS_1500 = "{1500}3002601120T ";
my $Type_1510 = "{1510}1600";
my $IMAD_1520 = "{1520}                      ";
##################################################
my $Amount_2000 = "000000000000";
my $Amount_2000_speclen= length($Amount_2000); # take length for later padding
print "amount length limit |$Amount_2000_speclen|...\n";
$Amount_2000 = "{2000}";
##################################################

my $SenderDI_3100 = "{3100}";
my $SenderSN_3100_len = 18;
my $ReceiverDI_3400 = "{3400}";
my $ReceiverSN_2400_len = 18;
my $BusFunctionCode_3600 = "{3600}";

##################################################
## 3.0 Other FEDLine Transfer Message Tags	##
##################################################
my $SenderReference_3320;
my $PrevMsgIdentifier_3500;
my $LocalInstrument_3610;
my $Charges_3700; 
my $InstAmount_3710; 
my $ExchangeRate_3720;

##################################################
## 4.0 Beneficiary Information Tags		##
##################################################
my $IntermediaryFI_4000;
my $BeneficiaryFI_4100;
my $Beneficiary_4200 = "{4200}";
my $Beneficiary_4200_len = 34;
## my $RefBeneficiary_4320 = "{4320}DAILY TRANSFER*"; # conditional if BTR
my $RefBeneficiary_4320 = "{4320}";
my $AccDBDrawDown_4400; 

##################################################
## 5.0 Originator Information Tags		##
##################################################
my $Originator_5000 = "{5000}"; # conditional if CTR
my $OrigOptionF_5010;
my $OrigFI_5100;
my $InstringFI_5200; 
my $AccCRDrawDown_5400; 
my $OrigToBeneInfo_6000; 

##################################################
## 6.0 FI to FI Information Tags		##
##################################################
my $RecFIInfo_6100 = "{6100}";
my $DrwDwnDBAccAdviceInfo_6110;
my $IntFIInfo_6200;
my $IntFIAdviceInfo_6210;
my $BeneFIInfo_6300;
my $BeneFIAdviceInfo_6310;
my $BeneInfo_6400;
my $BeneAdviceInfo_6410;
my $MethodPmtBene_6420;
my $FItoFIInfo_6500;

##################################################
## 7.0 FI to FI Information Tags		##
##################################################
my $SeqB33B_7033;
my $SeqB50A_7050;
my $SeqB52A_7052;
my $SeqB56A_7056;
my $SeqB57A_7057;
my $SeqB59A_7059;
my $SeqB70_7070;
my $SeqB72_7072;

##################################################
## 8.0 unstructured Addenda Information Tags	##
##################################################
my $UnsAddaInfo_8200;

##################################################
## 9.0 Related Remittance Information Tags	##
##################################################
my $RelRemitInfo_8250;

##################################################
## 10.0 StructuredRemittance Information Tags	##
##################################################
my $RemitOrig_8300;
my $RemitBene_8350;
my $PrimRemitDoc_8400;
my $ActAmtPd_8450;
my $GrossAmtRemitDoc_8500;
my $AmtNegDisc_8550;
my $AdjInfo_8600;
my $DateRemitDoc_8650;
my $SecRemitDoc_8700;
my $RemitFreeTxt_8750;

##################################################
## 11.0 Svc message Information Tags		##
##################################################
my $SvcMsgInfo_9000;

	
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
		
		##################################################
		## --- Cleanup unwanted characters from data--- ##
		##################################################
		$File_Date =~ s/"//g; # remove quote

		##################################################
		## --- Enforce Length on Sender ShortName   --- ##
		##################################################
		$Sender_ShortName =~ s/"//g; # remove quote
		$Sender_ShortName = substr($Sender_ShortName,0,$SenderSN_3100_len);
		##################################################
		$Sender_Ref =~ s/"//g; # remove quote

		##################################################
		## --- Enforce Length on Receiver ShortName   --- ##
		##################################################
		$Receiver_ShortName =~ s/"//g; # remove quote
		$Receiver_ShortName = substr($Receiver_ShortName,0,$ReceiverSN_2400_len);
		##################################################

		##################################################
		## --- Enforce Length on Bene Name          --- ##
		## length is 35 chars 			    --- ##
		##################################################
		$Bene_Name =~ s/"//g; # remove quote
		$Bene_Name = substr($Bene_Name,0,34);

		##################################################
		## --- Enforce Length on Bene Address       --- ##
		## length is 35 chars 			    --- ##
		##################################################
		$Bene_Address_1 =~ s/"//g; # remove quote
		$Bene_Address_1 = substr($Bene_Address_1,0,35);

		$Bene_Address_2 =~ s/"//g; # remove quote
		$Bene_Address_2 = substr($Bene_Address_2,0,35);

		$Bene_Address_3 =~ s/"//g; # remove quote
		$Bene_Address_3 = substr($Bene_Address_3,0,35);

		##################################################
		$Bene_Ref =~ s/"//g; # remove quote
		$Originator =~ s/"//g; # remove quote
		$Transfer_Amount =~ s/,//g; # remove comma
		$Transfer_Amount =~ s/\.//g; # remove decimal

		print "\nProcessing payment for |$TradeId|$Instrument|$Bene_Name|$Bene_Address_1*$Bene_Address_2*$Bene_Address_3|...";
		print $process_log "\nProcessing payment for |$TradeId|$Instrument|$Bene_Name|...";

		##################################################
		## --- Zero pad Amount			    --- ##
		##################################################
		my $Transfer_Amount_len= length($Transfer_Amount); # take length for later padding
		##################################################
		print "\namount before zero pad |$Transfer_Amount|...\n";
		print "transfer amount length |$Transfer_Amount_len|...\n";
		##################################################
		$ZeroPadNo = $Amount_2000_speclen - $Transfer_Amount_len; 
		print "zeros to pad |$ZeroPadNo|...\n";
		##################################################
		$Transfer_Amount = sprintf "%0${Amount_2000_speclen}d", $Transfer_Amount; # pad zeros
		##################################################
		## my $Transfer_Amount_Pad = 0;
		## my $Transfer_Amount_Pad = 0;
		## $Transfer_Amount_Pad = sprintf ("%03d", $Transfer_Amount_Pad); # pad zeros
		### $Transfer_Amount = qq($Transfer_Amount_Pad) . qq($Transfer_Amount);
		##################################################
		print "amount after zero pad |$Transfer_Amount|...\n";
	
		##################################################
		## --- Concatenate Sender Info 			##
		##################################################
		my $Sender = qq($SenderDI_3100) . qq($Sender_ABA) . qq($Sender_ShortName) . "*";
			
		##################################################
		## --- Concatenate Receiver Info		##
		##################################################
		my $Receiver = qq($ReceiverDI_3400) . qq($Receiver_ABA) . qq($Receiver_ShortName) . "*";

		##################################################
		## --- Determine Business Function Code      ---##
		##################################################
		my $BusFunctionCode;
		if ( $Transfer_Type =~ m/Bank/ ) {
			$BusFunctionCode = qq($BusFunctionCode_3600) . "BTR";
		}
		else {
			$BusFunctionCode = qq($BusFunctionCode_3600) . "CTR";
		}
		$Bene_Ref = qq($RefBeneficiary_4320) . qq($Bene_Ref) . "*";
		## $Originator = qq($Originator_5000) . qq($Originator) . "*"; 

		##################################################
		## --- Concatenate Beneficiary Info		##
		##################################################
		my $Beneficiary;
		my $AcctPrefix;
			
		if ( $Bene_AccType =~ m/DDA/ ) {
			$AcctPrefix = "D";
		}
		elsif( $Bene_AccType =~ m/BIC/ ) {
			$AcctPrefix = "B";
		}
		elsif( $Bene_AccType =~ m/FED/ ) {
			$AcctPrefix = "F";
		}
		elsif( $Bene_AccType =~ m/BEI/ ) {
			$AcctPrefix = "T";
		}
		else {
			$AcctPrefix = "T";
			print "\nIGNORED RECORD |$TradeId,$Instrument,$Transfer_Amount,$Sender_ABA,$Sender_ShortName,$Sender_Ref,$Receiver_ABA,$Receiver_ShortName,$Transfer_Type,$Bene_AccType,$Bene_AccNo,$Bene_Name,$Bene_Address_1,$Bene_Ref,$Originator|\n";
			next PAYMENT;
		}

		##################################################
		my $Bene_Address = "";
		my $Rec_Address = "";
		my $Originator_Address = qq($Sender_ShortName) . "*";

		if ( $Bene_Address_1 ne "" ) {
			$Bene_Address = $Bene_Address_1 . "*";
			## $Originator_Address= $Bene_Address_1 . "*";
			$Rec_Address= $Bene_Address_1 . "*";
		}
		if ( $Bene_Address_2 ne "" ) {
			$Bene_Address = $Bene_Address . $Bene_Address_2 . "*";
			## $Originator_Address = $Originator_Address . $Bene_Address_2 . "*";
			$Rec_Address = $Rec_Address . $Bene_Address_2 . "*";
		}
		if ( $Bene_Address_3 ne "" ) {
			$Bene_Address = $Bene_Address . $Bene_Address_3 . "*";
			## $Originator_Address = $Originator_Address . $Bene_Address_3 . "*";
			$Rec_Address = $Rec_Address . $Bene_Address_3 . "*";
		}

		##################################################
		$Originator = qq($Originator_5000) . qq($Originator) . "*" . $Originator_Address; 

		## $Beneficiary= qq($Beneficiary_4200) . qq($AcctPrefix) . qq($Bene_AccNo) . "*" . qq($Bene_Name) . "*" . $Bene_Address;
		##################################################
		
		if ( $BusFunctionCode =~ m/BTR/ ) {
			$Beneficiary = qq($RecFIInfo_6100) . qq($Receiver_ShortName) . "*" . $Rec_Address;

			## print $import_file "$Leading_Info$SS_1500$Type_1510$IMAD_1520$Amount_2000$Transfer_Amount$Sender$Receiver$BusFunctionCode$Originator\n";
			print $import_file "$Leading_Info$SS_1500$Type_1510$IMAD_1520$Amount_2000$Transfer_Amount$Sender$Receiver$BusFunctionCode$Originator$Beneficiary\n";
		}
		else {
			$Beneficiary= qq($Beneficiary_4200) . qq($AcctPrefix) . qq($Bene_AccNo) . "*" . qq($Bene_Name) . "*" . $Bene_Address;
			print $import_file "$Leading_Info$SS_1500$Type_1510$IMAD_1520$Amount_2000$Transfer_Amount$Sender$Receiver$BusFunctionCode$Beneficiary$Bene_Ref$Originator\n";
		}

		print "\n-----------------------------------------\n";

	return ($Beneficiary);

} ## end of function call GenFEDWirePmt

# ---------------------------------------------------------------------------------------------- #
1;
# ---------------------------------------------------------------------------------------------- #
