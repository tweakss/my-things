### Source Perl Modules ###
import datetime, re, sys, time
import pathlib, shutil

import SendTools
import GenWirePayments


# data dumper not used?

###################################
## --- Source Custom Modules  ---##
###################################


###################################
sys.stdout.flush()			# --- autoflush stdout to print right away
###################################


###################################
## --- Date Variables	      ---##
###################################
todays_date = datetime.datetime.today()
processing_date = todays_date.strftime("%d.%m.%Y")
file_date = todays_date.strftime("%m%d%Y_%H%M%S")

print(f"Processing Date:|{processing_date}|")
print(f"File Date:|{file_date}|")

###################################
## --- Directory Path	      ---##
###################################
archive_file = None

########################
### =begin PROD_PATH ###
########################
fed_input_path = r'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\In'
fed_output_path = r'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Out'
fed_log_path = r'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Log'
fed_template_path = r'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Template'
fed_archive_path = r'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Archive'
rc_srctemplate_path = r'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Template'
rc_source_path = r'C:\Users\BUAdmin\MyPerl\FedLineAdvantage\perl\data\Out'
rc_upload_path = r'\\ehny20-2\FILESHARES\Shared Data\FedLineAdvantage\Upload'
rc_template_path = r'\\ehny20-2\FILESHARES\Shared Data\FedLineAdvantage\Template'
### =end PROD_PATH ###

###################
### Input Files ###
###################
calypso_payments_filename = 'calypso_payments.txt'
calypso_payments = fed_input_path + f"\{calypso_payments_filename}"

fed_switch_filename = 'fed_repayment_switch.txt'
fed_switch = fed_input_path + f"\{fed_switch_filename}"

fed_cpty_filename = 'fed_cpty_repayment_list.txt'
fed_cpty = fed_input_path + f"\{fed_cpty_filename}"

fed_holidays_filename = 'fed_holidays.csv'
fed_holidays = fed_input_path + f"\{fed_holidays_filename}"

####################
### Output Files ###
####################
fed_interest_filename = 'FED_Interest2Transfer_' + f'{file_date}' + ".csv"
fed_interest = fed_output_path + f"\{fed_interest_filename}"

fed_wirepayments_filename = 'FED_Pmts_' + f'{file_date}' + ".txt"
fed_wirepayments = fed_output_path + f"\{fed_wirepayments_filename}"

calypso_payments_template_filename = 'calypso_payments_TEMPLATE_' + f'{file_date}' + ".csv"
calypso_payments_template = fed_template_path + f"\{calypso_payments_template_filename}"

#################
### Log Files ###
#################
ignored_log_filename = 'calypso_payments_ignored_' + f'{file_date}' + ".csv"
ignored_log = fed_log_path + f"\{ignored_log_filename}"

processed_log_filename = 'calypso_payments_processed_log_' + f'{file_date}' + ".txt"
processed_log = fed_log_path + f"\{processed_log_filename}"

missing_data_log_filename = 'calypso_missing_data_' + f'{file_date}' + ".csv"
missing_data_log = fed_log_path + f"\{missing_data_log_filename}"

###########################
### Set Email Variables ###
###########################
## Email_Distribution_List = "'MLNYBackOfficeEH_NY@erstegroup.com', 'MLInterITEH_NY@erstegroup.com'" # PROD
Email_Distribution_List = "'erwin.ortega@erstegroup.com', 'john.ferrante@erstegroup.com'" ## TEST
Email_Distribution_List = "'Dinesh.Patadia@erstegroup.com', 'erwin.ortega@erstegroup.com'" ## DEV
print(f"{Email_Distribution_List}")
#######################
Email_Type = 'Notification::'
## Email_RunType = 'MANUAL'
Email_RunType = 'Daily'
Email_Sender = 'MLInterITEH_NY@erstegroup.com'
Email_Subject = f"{Email_Type} {Email_RunType} FedLineAdvantage Batch Repayments"
Email_Body = r"""Hi,

The FED Batch Repayments file is ready for upload.

You can find it in the shared drive under S:\FEDLineAdvantage\Out
"""
Email_Server = '10.252.50.50'

            #################################
            ## P R E - P R O C E S S I N G ##
            ################################################
            ## - only proceed if the file date is current ##
            ################################################    

##########################
### Read Holidays File ###
##########################
# my(@FED_Holidays) #not being used??
holiday_flag = "N"
holiday = "01.01.1999"
holiday_name = " "
eval_date = processing_date
regExPeriods = re.compile(r"\.")
eval_date = regExPeriods.sub("", eval_date)

try:
    with open(f"{fed_holidays}", "r", encoding="utf-8") as HOLIDAYS_FH:
        for line in HOLIDAYS_FH:
            currLine = line.removesuffix("\n")
            holiday, holiday_name = currLine.split(",")
            holiday = regExPeriods.sub("", holiday)
            regexPattern = re.compile(f"{holiday}")
            if regexPattern.search(eval_date):
                holiday_flag = "Y"
                break
except IOError as e:
    print("IOError", e)

if(holiday_flag == "Y"):
    # raise exception here?
    print(f"\n|{processing_date}|{holiday}|{holiday_name}| is a holiday. Exiting program. sys exit\n")
    sys.exit()

print(f"\n|{processing_date}| is a business day. Proceeding..\n")

#########################
### Archive log files ###
#########################
logFiles = fed_log_path.glob("calypso*")
for archive_file in logFiles:
    # print("archive_file:", archive_file)
    fed_archive_path_obj = pathlib.Path(fed_archive_path)
    archiveFileName = archive_file.parts[len(archive_file.parts) - 1]
    archiveFileAtDestStr = str(fed_archive_path_obj) + "\\" + archiveFileName
    archiveFileAtDest = pathlib.Path(archiveFileAtDestStr)
    
    if archiveFileAtDest.exists():
        # print("archiveFileAtDest exists... deleting the file")
        archiveFileAtDest.unlink()
    
    # print("moved:", shutil.move(archive_file, fed_archive_path))
    shutil.move(archive_file, fed_archive_path)

########################
try:
    CALYPSO_FH = open(calypso_payments, 'r')
except OSError as err:
    print("OSError:", err, "\nExiting...")
    sys.exit()

try:
    PROCESSED_FH = open(processed_log, 'w')
except OSError as err:
    print("OSError:", err, "\nExiting...")
    sys.exit()

##########################
### Check Calypso Date ###
##########################
calypso_date = "31.12.1999"
wait_time, wait_limit = 900, 7200
wait_mins = int(wait_time/60)
wait_total = int(wait_limit/60)
########################
Email_Type = 'ALERT::'
Email_Subject = f"{Email_Type} {Email_RunType} FED Batch Repayments"
Email_Body = f"Hi,\n\n The Calypso payments file has NOT been delivered. The process will wait and check again in |{wait_mins}| minutes."
########################
# try:
#     CALYPSO_FH = open(calypso_payments, 'r')
# except OSError as err:
#     print("OSError:", err, "\nExiting...")
#     sys.exit()

calypso_file = CALYPSO_FH.read()
CALYPSO_FH.close()
calypso_date = re.search(r"\d{2,2}.\d{2,2}.\d{4,4}", calypso_file)
print(f"CHECK...Processing_date is:|{processing_date}|")
print(f"CHECK...Calypso_date is:|{calypso_date.group()}|")

######################## 
while ( calypso_date != processing_date ):
    print(f"WHILE...wait_limit is:|{wait_limit}|")
    if ( wait_limit == 0 ):
        Email_Body = f"Hi,\n\n The Calypso payments file was NOT delivered after waiting for |{wait_total} minutes.\n" \
		f"Exiting program.  FileDate:|{calypso_date}| IS NOT EQUAL to the ProcessDate:|{processing_date}|"
        PROCESSED_FH.write(Email_Body)
        SendTools.sendEmailPShell(Email_Type, Email_Sender, Email_Distribution_List, Email_Subject, Email_Body, PROCESSED_FH, calypso_payments, Email_Server)
        print(f"DIE...Calypso_date is:|{calypso_date}|")
        sys.exit(Email_Body)
    
    print(f"{Email_Body}")
    PROCESSED_FH.write(Email_Body)
    if (calypso_date != processing_date):
        SendTools.sendEmailPShell(Email_Type, Email_Sender, Email_Distribution_List, Email_Subject, Email_Body, PROCESSED_FH, calypso_payments, Email_Server)
    time.sleep(wait_time)
    wait_limit = wait_limit - wait_time

    try:
        CALYPSO_FH = open(calypso_payments, 'r')
    except OSError as err:
        print("OSError:", err, "\nExiting...")
        sys.exit()
    calypso_file = CALYPSO_FH.read()
    CALYPSO_FH.close()
    calypso_date = re.search(r"\d{2,2}.\d{2,2}.\d{4,4}", calypso_file)
    print(f"WHILE...Calypso_date is:|{calypso_date.group()}|")
# end while loop
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

print("\n-----------------------------------------------------------")
print("\n-----------------------------------------------------------")
print(f"PROCEEDING to Main Process...Calypso_date is:|{calypso_date}|")
time.sleep(10)

		##############################################################
		##############################################################
		##--- 		FILES ARCHIVE PROCESS			 ---## 
		##############################################################
		##############################################################
        

###################################
## --- Archive Input File    --- ##
###################################
transferfile = None
globObj = pathlib.Path(fed_input_path).glob("*.txt")
inputfiles = list(globObj)
# print("inputfiles:", inputfiles)
for archive_file in inputfiles:
    transferfile = str(archive_file.parent) + f"\{archive_file.stem}" + f"_{file_date}" + ".txt"
    
    try:
        copy2Result = shutil.copy2(archive_file, transferfile)
    except OSError as err:
        print("Copy failed:", err)

    transferfilePathObj = pathlib.Path(transferfile)
    transferfileName = transferfilePathObj.parts[len(transferfilePathObj.parts) - 1]
    transferfileAtNewDest = pathlib.Path(fed_archive_path + f"\{transferfileName}")

    if(transferfileAtNewDest.exists()):
        # print("dest file exists, going to remove")
        transferfileAtNewDest.unlink()

    try:
        shutil.move(transferfile, fed_archive_path)
    except OSError as err:
        print("Move failed:", err)

###################################
## --- Archive Output File   --- ##
###################################
globObj = pathlib.Path(fed_output_path).glob("FED*")
outputfiles = list(globObj)
for archive_file in outputfiles:
    try:
        shutil.move(archive_file, fed_archive_path)
    except OSError as err:
        print("Move failed:", err)

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
sys.stdout.flush()		# --- autoflush stdout to print right away
###################################
###################################

###################################
## --- Read Calypso File     --- ##
###################################
try:
    CALYPSO_FH = open(calypso_payments, 'r')
except OSError as err: 
    print("OSError:", err)
    sys.exit()

Calypso_Payments = []
fields = []

for line in CALYPSO_FH:
    currLine = line.removesuffix(";\n")
    fields = currLine.split(";")
    Calypso_Payments.append(fields[0])

CALYPSO_FH.close()

Calypso_Payments_Cnt = len(Calypso_Payments)
print("\n-------------------------------------------------------")
print(f"|{Calypso_Payments_Cnt}| calypso records found for processing...")

if(Calypso_Payments_Cnt < 2):
    Email_Type = 'Alert::'
    Email_Subject = f"{Email_Type} {Email_RunType} FED Batch Repayments"
    Email_Body = "Hi,\n\n The Calypso import file is EMPTY!!! Please investigate. \n\n"
    CALYPSO_FH.close()
    SendTools.sendEmailPShell(Email_Type, Email_Sender, Email_Distribution_List, Email_Subject, Email_Body, PROCESSED_FH, calypso_payments, Email_Server)
    PROCESSED_FH.write(f"{Calypso_Payments_Cnt} NO Calypso payment records found...\n")
    sys.exit("\nNO CALYPSO RECORDS TO PROCESS HERE! EXITING Program...\n")

###################################
## --- Open File Handles      ---##
###################################
###################################
try:
    FEDSWITCH_FH = open(fed_switch, 'r')
except OSError as err:
    print("OSError:", err)
    sys.exit()


try:
    FEDCPTY_FH= open(fed_cpty, 'r')
except OSError as err:
    print("OSError:", err)
    sys.exit()

try:
    FEDINTEREST_FH = open(fed_interest, 'w')
except OSError as err:
    print("OSError:", err)
    sys.exit()

try:
    FEDPAY_FH = open(fed_wirepayments, 'w')
except OSError as err:
    print("OSError:", err)
    sys.exit()

try:
    CALYPSO_PAY_TEMPLATE_FH = open(calypso_payments_template, 'w')
except OSError as err:
    print("OSError:", err)
    sys.exit()

try:
    IGNORED_FH = open(ignored_log, 'w')
except OSError as err:
    print("OSError:", err)
    sys.exit()

try:
    MISSING_FH = open(missing_data_log, 'w')
except OSError as err:
    print("OSError:", err)
    sys.exit()

###################################
## --- Print File Headers    --- ##
###################################
IGNORED_FH.write("TradeId,Instrument,Cust_Name,Calypso_CustNbr,Bene_AccNo,Bene_Address_2,TotalPayment,Principal,Interest_Amount\n")
MISSING_FH.write("TradeId,Instrument,Cust_Name,Calypso_CustNbr,Bene_AccNo,Bene_Address_2,TotalPayment,Principal,Interest_Amount\n")
FEDINTEREST_FH.write("TradeId,Instrument,Cust_Name,Calypso_CustNbr,Bene_Address_2,TotalPayment,Principal,Interest_Amount\n")
CALYPSO_PAY_TEMPLATE_FH.write("File_Date,Principal,Interest,Sender_ABA,Sender_ShortName,Sender_Ref,Receiver_ABA,Receiver_ShortName,Transfer_Type,Bene_CustNo,Bene_AccType,Bene_AccNo,Bene_Name,Bene_Address_1,Bene_Ref,Originator,TradeId,Instrument,Bene_Address_2,Bene_Address_3,Rec_Nostro\n")

###################################
## --- Read FED SWITCH File  --- ##
###################################
cpty_switch = FEDSWITCH_FH.read()
FEDSWITCH_FH.close()
print(f"\nCPTY SWITCH is: |{cpty_switch}|")
PROCESSED_FH.write(f"\nCPTY SWITCH is: |{cpty_switch}|\n")

###################################
## --- Read FED Cpty File    --- ##
###################################
FED_Cpty = []

for line in FEDCPTY_FH:
    currLine = line.removesuffix('\n')
    FED_Cpty.append(currLine)
FEDCPTY_FH.close()

Cpty_Cnt = len(FED_Cpty)
print("\n-------------------------------------------------------\n")
print(f"|{Cpty_Cnt}| cpty records found for processing...\n")

###################################
## --- Init Variables        --- ##
###################################
Total_Interest = 0.00
Transfer_Interest = 0.00
Org_Payment_Amount = 0.00
Org_Principal = 0.00
Org_Interest = 0.00	
chk_cnt = 0
print_cnt = 0
missing_cnt = 0
col = None
ProcessedPmt_Comments = None
PROCESSED_FH.write(f"ProcessDate:|{processing_date}|\n")
print(f"\nProcessing_Date:|{processing_date}|")

##################################################

for col in Calypso_Payments:
    [File_Date, Principal, Interest, Sender_ABA, Sender_ShortName, Sender_Ref, Receiver_ABA, Receiver_ShortName, Transfer_Type, Bene_CustNo, Bene_AccType, Bene_AccNo, Bene_Name, Bene_Address_1, Bene_Ref, Originator, TradeId, Instrument, Bene_Address_2, Bene_Address_3, Rec_Nostro] = col

    if("Principal" in Principal):
        continue

    chk_cnt += 1

    ##################################################
	## --- Cleanup unwanted characters from data--- ##
	##################################################
    File_Date = File_Date.replace('\"', '') # remove quote
    ##################################################
    Principal = Principal.replace('\"', '') # remove quote
    Principal = Principal.replace(',', '') # remove comma
    Org_Principal = Principal
    Principal = Principal.replace('.', '') # remove decimal
    ##################################################
    if ( Interest == ""):
        Interest = 0.00
    
    Interest = Interest.replace('\"', '') # remove quote
    Interest = Interest.replace(',', '') # remove comma
    Org_Interest = Interest	
    Interest = Interest.replace('.', '') # remove decimal
    Total_Interest = Total_Interest + Org_Interest
    ##################################################
	## --- Set Wire Payment Amount		    --- ##
	##################################################
    Org_Payment_Amount = Org_Principal + Org_Interest
    Payment_Amount = Principal + Interest
    ##################################################
    Interest = Interest.replace('\"', '') # remove quote
    Sender_ABA = Sender_ABA.replace('\"', '') # remove quote
	##################################################
    ## --- 	Set Sender ShortName 		    --- ##
	## 18 chars only 			    --- ##
	## constant value			    --- ##
	##################################################
    Sender_ShortName = Sender_ShortName.replace('\"', '') # remove quote
    Sender_ShortName = "ERSTE GRP BK AG NY BRANCH"
	##################################################
    Sender_Ref = Sender_Ref.replace('\"', '') # remove quote
    Receiver_ABA = Receiver_ABA.replace('\"', '') # remove quote
    Receiver_ShortName = Receiver_ShortName.replace('\"', '') # remove quote
    Transfer_Type = Transfer_Type.replace('\"', '') # remove quote
    Bene_CustNo = Bene_CustNo.replace('\"', '') # remove quote
    reg_ex_whitespace = re.compile(r"\s+")
    Bene_CustNo = reg_ex_whitespace.sub("", Bene_CustNo) # remove all whitespace chars
    Bene_AccType = Bene_AccType.replace('\"', '') # remove quote
	##################################################
    Bene_AccNo = Bene_AccNo.replace('\"', '') # remove quote
	## my $Org_Bene_AccNo;
    Org_Bene_AccNo = ""
    if ( Bene_AccNo == ""):
            Org_Bene_AccNo = "MISSING"
	##################################################
    Bene_Name = Bene_Name.replace('\"', '') # remove quote
    Bene_Name = Bene_Name.replace(",", " ") # replace comma with space

    Bene_Address_1 = Bene_Address_1.replace('\"', '') # remove quote
    Bene_Address_1 = Bene_Address_1.replace(",", " ") #  replace comma with space
    Bene_Address_1 = Bene_Address_1.replace(",", " ") #  replace comma with space
    Bene_Address_1 = Bene_Address_1.replace(",", " ") #  replace comma with space
    
    Bene_Ref = Bene_Ref.replace('\"', '') # remove quote
    Originator = Originator.replace('\"', '') # remove quote
    TradeId = TradeId.replace('\"', '') # remove quote
    Instrument = Instrument.replace('\"', '') # remove quote
    
    Bene_Address_2.replace('\"', '') # remove quote
    Bene_Address_2.replace(",", " ") #  replace comma with space
    # Bene_Address_2.replace(",", " ") #  replace comma with space
    # Bene_Address_2.replace(",", " ") #  replace comma with space
    
    Bene_Address_3.replace('\"', '') # remove quote
    Bene_Address_3.replace(",", " ") #  replace comma with space
    # Bene_Address_3.replace(",", " ") #  replace comma with space
    # Bene_Address_3.replace(",", " ") #  replace comma with space

	##############################################################
    myOrg_Rec_Nostro = ""
    Org_Rec_Nostro = Rec_Nostro
    Rec_Nostro = Rec_Nostro.replace('\"', '') # remove quote
	##############################################################
    for line in FED_Cpty:  
        if (line == Bene_CustNo):
            Rec_Nostro = "FEDUSAXXXXXXX"
            break
        
	
    print(f"cpty_switch is:|{cpty_switch}| REc_Nostro is: |{Rec_Nostro}s|")
    ##############################################################
	##--- Create Wire Payment if Cpty in Process List	--- ##
	##############################################################
    if ( cpty_switch == "PARTIAL" ):
		## print $IGNORED_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Bene_AccNo,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n" if $Rec_Nostro =~ m/BOFA/;
        if ("BOFA" in Rec_Nostro):
            IGNORED_FH.write(f"{TradeId},{Instrument},{Bene_Name},{Bene_CustNo},{Bene_AccNo},{Bene_Address_2},{Org_Payment_Amount},{Org_Principal},{Org_Interest}\n")
            continue
            
		## if ( $Org_Bene_AccNo =~ m/MISSING/ ) {
        if (("MISSING" in Org_Bene_AccNo) and ("Cust" in Transfer_Type)):
            ## print $MISSING_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Org_Bene_AccNo,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
            MISSING_FH.write(f"{TradeId},{Instrument},{Bene_Name},{Bene_CustNo},{Org_Bene_AccNo},{Bene_Address_2},{Org_Payment_Amount},{Org_Principal},{Org_Interest}\n")
            missing_cnt += 1
		
        print("\n\n***************************************************")
        print("***************************************************")
        print(f"\nprocessing {TradeId}|{Instrument}|{Bene_CustNo}|{Org_Payment_Amount}|{Org_Principal}|{Org_Interest}")

		##############################################################
		## --- accumulate interest for separate payment		 ---## 
		##############################################################
		## $Transfer_Interest = $Transfer_Interest + $Interest;
        Transfer_Interest = Transfer_Interest + Org_Interest
		##############################################################

        print(f"\npassing values |{File_Date}, {Payment_Amount}, {Sender_ABA}, {Sender_ShortName}, {Sender_Ref}, {Receiver_ABA}, {Receiver_ShortName}, {Transfer_Type}, {Bene_AccType}, {Bene_AccNo}, {Bene_Name}, {Bene_Address_1}, {Bene_Ref}, {Originator}, {TradeId}, {Instrument}, {Bene_Address_2}, {Bene_Address_3}, {Rec_Nostro}|")

        if(GenWirePayments.GenFEDWirePmt(File_Date, Payment_Amount, Sender_ABA, Sender_ShortName, Sender_Ref, Receiver_ABA, Receiver_ShortName, Transfer_Type, Bene_AccType, Bene_AccNo, Bene_Name, Bene_Address_1, Bene_Ref, Originator, TradeId, Instrument, Bene_Address_2, Bene_Address_3, Rec_Nostro, PROCESSED_FH, FEDPAY_FH) == "continue"):
            continue
        
		## print $FEDINTEREST_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
		## print $PROCESSED_FH "$TradeId|$Instrument|$Bene_Name|$Bene_CustNo|$Org_Payment_Amount|$Org_Principal|$Org_Interest|\n";
        FEDINTEREST_FH.write(f"{TradeId},{Instrument},{Bene_Name},{Bene_CustNo},{Bene_Address_2},{Org_Payment_Amount},{Org_Principal},{Org_Interest}\n")
        PROCESSED_FH.write(f"{TradeId}|{Instrument}|{Bene_Name}|{Bene_CustNo}|{Bene_Address_2}|{Org_Payment_Amount}|{Org_Principal}|{Org_Interest}|\n")

        CALYPSO_PAY_TEMPLATE_FH.write(f"{File_Date},{Principal},{Interest},{Sender_ABA},{Sender_ShortName},{Sender_Ref},{Receiver_ABA},{Receiver_ShortName},{Transfer_Type},{Bene_CustNo},{Bene_AccType},{Bene_AccNo},{Bene_Name},{Bene_Address_1},{Bene_Ref},{Originator},{TradeId},{Instrument},{Bene_Address_2},{Bene_Address_3},{Rec_Nostro}\n")

        print_cnt += 1
    else:
    ##############################################################
    ## --- 		PROCESS ALL PAYMENTS			--- ##
    ##############################################################
    ## if ( $Org_Bene_AccNo =~ m/MISSING/ ) {
        if ( ("MISSING" in Org_Bene_AccNo) and ("Cust" in Transfer_Type) ):
            ## print $MISSING_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Org_Bene_AccNo,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
            MISSING_FH.write(f"{TradeId},{Instrument},{Bene_Name},{Bene_CustNo},{Org_Bene_AccNo},{Bene_Address_2},{Org_Payment_Amount},{Org_Principal},{Org_Interest}\n")
            missing_cnt += 1
    

    ##############################################################
    ## --- accumulate interest for separate payment		 ---## 
    ##############################################################
    ## $Transfer_Interest = $Transfer_Interest + $Interest;
    Transfer_Interest = Transfer_Interest + Org_Interest
    ##############################################################
    print(f"\npassing values |{File_Date},{Payment_Amount},{Sender_ABA},{Sender_ShortName},{Sender_Ref},{Receiver_ABA},{Receiver_ShortName},{Transfer_Type},{Bene_AccType},{Bene_AccNo},{Bene_Name},{Bene_Address_1},{Bene_Ref},{Originator},{TradeId},{Instrument},{Bene_Address_2},{Bene_Address_3},{Rec_Nostro}|")

    GenWirePayments.GenFEDWirePmt(File_Date, Payment_Amount, Sender_ABA, Sender_ShortName, Sender_Ref, Receiver_ABA, Receiver_ShortName, Transfer_Type, Bene_AccType, Bene_AccNo, Bene_Name, Bene_Address_1, Bene_Ref, Originator, TradeId, Instrument, Bene_Address_2, Bene_Address_3, Rec_Nostro, PROCESSED_FH, FEDPAY_FH)

    ## print $FEDINTEREST_FH "$TradeId,$Instrument,$Bene_Name,$Bene_CustNo,$Org_Payment_Amount,$Org_Principal,$Org_Interest\n";
    ## print $PROCESSED_FH "$TradeId|$Instrument|$Bene_Name|$Bene_CustNo|$Org_Payment_Amount|$Org_Principal|$Org_Interest|\n";
    FEDINTEREST_FH.write(f"{TradeId},{Instrument},{Bene_Name},{Bene_CustNo},{Bene_Address_2},{Org_Payment_Amount},{Org_Principal},{Org_Interest}\n")
    PROCESSED_FH.write(f"{TradeId}|{Instrument}|{Bene_Name}|{Bene_CustNo}|{Bene_Address_2}|{Org_Payment_Amount}|{Org_Principal}|{Org_Interest}|\n")

    CALYPSO_PAY_TEMPLATE_FH.write(f"{File_Date},{Principal},{Interest},{Sender_ABA},{Sender_ShortName},{Sender_Ref},{Receiver_ABA},{Receiver_ShortName},{Transfer_Type},{Bene_CustNo},{Bene_AccType},{Bene_AccNo},{Bene_Name},{Bene_Address_1},{Bene_Ref},{Originator},{TradeId},{Instrument},{Bene_Address_2},{Bene_Address_3},{Rec_Nostro}\n")



    print_cnt += 1
    	
    ##############################################################

##################################################################################################
 ## end foreach PAYMENT 	
##################################################################################################

##################################################################################################
if( print_cnt > 1 ):
    print(f"\n\n|{print_cnt} of {chk_cnt}| FED Wire Payments records created...")

if( chk_cnt > 1 ):
    PROCESSED_FH.write(f"\n\n|{print_cnt} of {chk_cnt}| FED Wire Payments records created...\n")
###################################
FEDPAY_FH.close()     

		##############################################################
		##############################################################
		##--- 		Send FED Batch Payments File 		 ---## 
		##############################################################
		##############################################################
###################################
## --- Set Email Variables   --- ##
## for Batch Repayments File     ##	
###################################
Email_Type = 'Notification::'
Email_Subject = f"{Email_Type} {Email_RunType} FED Batch Repayments File is Ready"
Email_Body = r"""Hi,

The FED Batch Repayments file is ready for upload.

You can find it in the shared drive under S:\\FEDLineAdvantage\\Upload
"""
Email_Server = '10.252.50.50'

if ( print_cnt > 0 ):
    SendTools.sendEmailPShell(Email_Type, Email_Sender, Email_Distribution_List, Email_Subject, Email_Body, PROCESSED_FH, fed_wirepayments, Email_Server)

if ( print_cnt > 0 ):
    SendTools.RoboCopyFile( rc_source_path, rc_upload_path, fed_wirepayments_filename, PROCESSED_FH)

if ( print_cnt > 0 ):
    SendTools.RoboCopyFile ( rc_srctemplate_path, rc_template_path, calypso_payments_template_filename, PROCESSED_FH)

###################################


		##############################################################
		##############################################################
		##--- 		Process Interest Transfer		 ---## 
		##############################################################
		##############################################################

###################################
formatted_Transfer_Interest = Transfer_Interest
formatted_Transfer_Interest = formatted_Transfer_Interest.replace('\"', '') # remove quote
formatted_Transfer_Interest = formatted_Transfer_Interest.replace(',', '') # remove comma
formatted_Transfer_Interest = formatted_Transfer_Interest.replace('.', '') # remove decimal
###################################
if( print_cnt > 0 ):
    print(f"\n|{print_cnt}|\nTotal interest to transfer to the FED |{Transfer_Interest} of {Total_Interest}|...")

if( print_cnt > 0 ):
    PROCESSED_FH.write(f"\n\nTotal interest to transfer to the FED |{Transfer_Interest} of {Total_Interest}|...\n")

###################################
MISSING_FH.close()
###################################
## --- Set Email Variables   --- ##
## for Interest Transfer	 ##	
###################################
Email_Type = 'ALERT::'
Email_Subject = "$Email_Type $Email_RunType FED Batch Repayments - MISSING DATA"
Email_Body = "Hi,\n\n The Beneficiary Account No is MISSING!\n\n"
Email_Server = '10.252.50.50'

if ( missing_cnt > 0 ):
    SendTools.sendEmailPShell(Email_Type, Email_Sender, Email_Distribution_List, Email_Subject, Email_Body, PROCESSED_FH, missing_data_log, Email_Server)

###################################
FEDINTEREST_FH.close()
###################################
## --- Set Email Variables   --- ##
## for Interest Transfer	 ##	
 ##################################
Email_Type = 'Notification::'
Email_Subject = "$Email_Type $Email_RunType FED Batch Repayments - BOA to FED Interest Transfer Amount"
Email_Body = "Hi,\n\n The total interest to transfer to the FED is: |$Transfer_Interest|.\n\n"
Email_Server = '10.252.50.50'

if ( print_cnt > 0 ):
    SendTools.sendEmailPShell(Email_Type, Email_Sender, Email_Distribution_List, Email_Subject, Email_Body, PROCESSED_FH, fed_interest, Email_Server)

if ( print_cnt > 0 ):
    SendTools.RoboCopyFile(rc_source_path, rc_upload_path, fed_interest_filename, PROCESSED_FH)
##################################

FEDSWITCH_FH.close()
PROCESSED_FH.close()
IGNORED_FH.close()

###################################