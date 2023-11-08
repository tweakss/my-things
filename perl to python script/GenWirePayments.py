
def GenFEDWirePmt(File_Date, Transfer_Amount, Sender_ABA, Sender_ShortName, Sender_Ref, Receiver_ABA, Receiver_ShortName, Transfer_Type, Bene_AccType, Bene_AccNo, Bene_Name, Bene_Address_1, Bene_Ref, Originator, TradeId, Instrument, Bene_Address_2, Bene_Address_3, Rec_Nostro, process_log, import_file):
    print("\n-----------------------------------------")
    print("\nCalling GenFEDWirePmt function...")

    ##################################################
    ##################################################
    ## 	Define and Set Variables		##
    ##################################################
    ##################################################

    ##################################################
    ## 	Counters				##
    ##################################################
    chk_cnt = 0
    print_cnt = 0
    col = None
    ZeroPadNo = None
    ProcessedPmt_Comments = None

    ##################################################
    ## 1.0 Mandatory FEDLine Message Tags		##
    ##################################################
    Leading_Info = "YFT811  "
    SS_1500 = r"{1500}3002601120T "
    Type_1510 = r"{1510}1600"
    IMAD_1520 = r"{1520}                      "
    ##############################################
    Amount_2000 = "000000000000"
    Amount_2000_speclen= len(Amount_2000); # take length for later padding
    print(f"amount length limit |{Amount_2000_speclen}|...")
    Amount_2000 = r"{2000}"
    ##################################################

    SenderDI_3100 = f"{3100}"
    SenderSN_3100_len = 18
    ReceiverDI_3400 = f"{3400}"
    ReceiverSN_2400_len = 18
    BusFunctionCode_3600 = f"{3600}"

    ##################################################
    ## 3.0 Other FEDLine Transfer Message Tags	##
    ##################################################
    SenderReference_3320 = None
    PrevMsgIdentifier_3500 = None
    LocalInstrument_3610 = None
    Charges_3700 = None
    InstAmount_3710 = None
    ExchangeRate_3720 = None

    ##################################################
    ## 4.0 Beneficiary Information Tags		##
    ##################################################
    IntermediaryFI_4000 = None
    BeneficiaryFI_4100 = None
    Beneficiary_4200 = r"{4200}"
    Beneficiary_4200_len = 34
    ## my $RefBeneficiary_4320 = "{4320}DAILY TRANSFER*"; # conditional if BTR
    RefBeneficiary_4320 = r"{4320}"
    AccDBDrawDown_4400 = None

    ##################################################
    ## 5.0 Originator Information Tags		##
    ##################################################
    Originator_5000 = r"{5000}" # conditional if CTR
    OrigOptionF_5010 = None
    OrigFI_5100 = None
    InstringFI_5200 = None
    AccCRDrawDown_5400 = None
    OrigToBeneInfo_6000 = None

    ##################################################
    ## 6.0 FI to FI Information Tags		##
    ##################################################
    RecFIInfo_6100 = r"{6100}"
    DrwDwnDBAccAdviceInfo_6110 = None
    IntFIInfo_6200 = None
    IntFIAdviceInfo_6210 = None
    BeneFIInfo_6300 = None
    BeneFIAdviceInfo_6310 = None
    BeneInfo_6400 = None
    BeneAdviceInfo_6410 = None
    MethodPmtBene_6420 = None
    FItoFIInfo_6500 = None

    ##################################################
    ## 7.0 FI to FI Information Tags		##
    ##################################################
    SeqB33B_7033 = None
    SeqB50A_7050 = None
    SeqB52A_7052 = None
    SeqB56A_7056 = None
    SeqB57A_7057 = None
    SeqB59A_7059 = None
    SeqB70_7070 = None
    SeqB72_7072 = None

    ##################################################
    ## 8.0 unstructured Addenda Information Tags	##
    ##################################################
    UnsAddaInfo_8200 = None

    ##################################################
    ## 9.0 Related Remittance Information Tags	##
    ##################################################
    RelRemitInfo_8250 = None

    ##################################################
    ## 10.0 StructuredRemittance Information Tags	##
    ##################################################
    myRemitOrig_8300 = None
    myRemitBene_8350 = None
    myPrimRemitDoc_8400 = None
    myActAmtPd_8450 = None
    myGrossAmtRemitDoc_8500 = None
    myAmtNegDisc_8550 = None
    myAdjInfo_8600 = None
    myDateRemitDoc_8650 = None
    mySecRemitDoc_8700 = None
    myRemitFreeTxt_8750 = None

    ##################################################
    ## 11.0 Svc message Information Tags		##
    ##################################################
    SvcMsgInfo_9000 = None

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
    File_Date.replace('\"', '') # remove quote

    ##################################################
    ## --- Enforce Length on Sender ShortName   --- ##
    ##################################################
    Sender_ShortName.replace('\"', '') # remove quote
    Sender_ShortName = Sender_ShortName[0:SenderSN_3100_len]
    ##################################################
    Sender_Ref.replace('\"', '') # remove quote

    ##################################################
    ## --- Enforce Length on Receiver ShortName --- ##
    ##################################################
    Receiver_ShortName.replace('\"', '') # remove quote
    Receiver_ShortName = Receiver_ShortName[0:ReceiverSN_2400_len]
    ##################################################

    ##################################################
    ## --- Enforce Length on Bene Name          --- ##
    ## length is 35 chars 			    --- ##
    ##################################################
    Bene_Name.replace('\"', '') # remove quote
    Bene_Name = Bene_Name[0:34]

    ##################################################
    ## --- Enforce Length on Bene Address       --- ##
    ## length is 35 chars 			    --- ##
    ##################################################
    Bene_Address_1.replace('\"', '') # remove quote
    Bene_Address_1 = Bene_Address_1[0:35]

    Bene_Address_2.replace('\"', '') # remove quote
    Bene_Address_2 = Bene_Address_2[0:35]

    Bene_Address_3.replace('\"', '') # remove quote
    Bene_Address_3 = Bene_Address_3[0:35]

    ##################################################
    Bene_Ref.replace('\"', '') # remove quote
    Originator.replace('\"', '') # remove quote
    Transfer_Amount.replace(',', '') # remove comma
    Transfer_Amount.replace('.', '') # remove decimal

    print(f"\nProcessing payment for |{TradeId}|{Instrument}|{Bene_Name}|{Bene_Address_1}*{Bene_Address_2}*{Bene_Address_3}|...")
    print(process_log, f"\nProcessing payment for |{TradeId}|{Instrument}|{Bene_Name}|...")

    ##################################################
    ## --- Zero pad Amount			    --- ##
    ##################################################
    Transfer_Amount_len = len(Transfer_Amount); # take length for later padding
    ##################################################
    print(f"\namount before zero pad |{Transfer_Amount}|...")
    print(f"transfer amount length |{Transfer_Amount_len}|...")
    ##################################################
    ZeroPadNo = Amount_2000_speclen - Transfer_Amount_len
    print(f"zeros to pad |{ZeroPadNo}|...")
    ##################################################
    Transfer_Amount = "{0:0{Amount_2000_speclen}d}".format(Transfer_Amount, Amount_2000_speclen = Amount_2000_speclen) # pad zeros
    ##################################################
    ## my $Transfer_Amount_Pad = 0;
    ## my $Transfer_Amount_Pad = 0;
    ## $Transfer_Amount_Pad = sprintf ("%03d", $Transfer_Amount_Pad); # pad zeros
    ### $Transfer_Amount = qq($Transfer_Amount_Pad) . qq($Transfer_Amount);
    ##################################################
    print(f"amount after zero pad |{Transfer_Amount}|...")

    ##################################################
    ## --- Concatenate Sender Info 			##
    ##################################################
    Sender = SenderDI_3100 + Sender_ABA + Sender_ShortName + "*"
        
    ##################################################
    ## --- Concatenate Receiver Info		##
    ##################################################
    Receiver = ReceiverDI_3400 + Receiver_ABA + Receiver_ShortName + "*"

    ##################################################
    ## --- Determine Business Function Code      ---##
    ##################################################
    BusFunctionCode = None
    if("Bank" in Transfer_Type):
        BusFunctionCode = f"{BusFunctionCode_3600}" + "BTR"
    else:
        BusFunctionCode = f"{BusFunctionCode_3600}" + "CTR"
    
    Bene_Ref = f"{RefBeneficiary_4320}" + f"{Bene_Ref}" + "*"
    ## $Originator = qq($Originator_5000) . qq($Originator) . "*"; 

    ##################################################
    ## --- Concatenate Beneficiary Info		##
    ##################################################
    Beneficiary = None
    AcctPrefix = None
        
    if ( "DDA" in Bene_AccType ):
        AcctPrefix = "D"
    elif( "BIC" in Bene_AccType ):
        AcctPrefix = "B"
    elif( "FED" in Bene_AccType ):
        AcctPrefix = "F"
    elif( "BEI" in Bene_AccType ):
        AcctPrefix = "T"
    else:
        AcctPrefix = "T"
        print(f"\nIGNORED RECORD |{TradeId}, {Instrument}, {Transfer_Amount}, {Sender_ABA}, {Sender_ShortName}, {Sender_Ref}, {Receiver_ABA}, {Receiver_ShortName}, {Transfer_Type}, {Bene_AccType}, {Bene_AccNo}, {Bene_Name}, {Bene_Address_1}, {Bene_Ref}, {Originator}|")
        # next PAYMENT;
        return "continue"
    

    ##################################################
    Bene_Address = ""
    Rec_Address = ""
    Originator_Address = f"{Sender_ShortName}" + "*"

    if ( Bene_Address_1 != "" ):
        Bene_Address = Bene_Address_1 + "*"
        ## $Originator_Address= $Bene_Address_1 . "*";
        Rec_Address = Bene_Address_1 + "*"
    
    if ( Bene_Address_2 != "" ):
        Bene_Address = Bene_Address + Bene_Address_2 + "*"
        ## $Originator_Address = $Originator_Address . $Bene_Address_2 . "*";
        Rec_Address = Rec_Address + Bene_Address_2 + "*"
    
    if ( Bene_Address_3 != "" ):
        Bene_Address = Bene_Address + Bene_Address_3 + "*"
        ## $Originator_Address = $Originator_Address . $Bene_Address_3 . "*";
        Rec_Address = Rec_Address + Bene_Address_3 + "*"
    

    ##################################################
    Originator = f"{Originator_5000}{Originator}*{Originator_Address}"

    ## $Beneficiary= qq($Beneficiary_4200) . qq($AcctPrefix) . qq($Bene_AccNo) . "*" . qq($Bene_Name) . "*" . $Bene_Address;
    ##################################################
    
    if ( "BTR" in BusFunctionCode ):
        Beneficiary = f"{RecFIInfo_6100}{Receiver_ShortName}*{Rec_Address}"

        ## print $import_file "$Leading_Info$SS_1500$Type_1510$IMAD_1520$Amount_2000$Transfer_Amount$Sender$Receiver$BusFunctionCode$Originator\n";
        print(import_file, f"{Leading_Info}{SS_1500}{Type_1510}{IMAD_1520}{Amount_2000}{Transfer_Amount}{Sender}{Receiver}{BusFunctionCode}{Originator}{Beneficiary}")
    else:
        Beneficiary = f"{Beneficiary_4200}{AcctPrefix}{Bene_AccNo}*{Bene_Name}*{Bene_Address}"
        print(import_file, f"{Leading_Info}{SS_1500}{Type_1510}{IMAD_1520}{Amount_2000}{Transfer_Amount}{Sender}{Receiver}{BusFunctionCode}{Beneficiary}{Bene_Ref}{Originator}")

    print("\n-----------------------------------------")

    return Beneficiary

## end of function call GenFEDWirePmt

# ---------------------------------------------------------------------------------------------- #
# 1;
# ---------------------------------------------------------------------------------------------- #
