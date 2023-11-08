import subprocess


def sendEmailPShell(Type, Sender, Distribution_List, Subject, Body, Main_LOG_FH, File, Server) :
    # print(f"sendEmailPShell, Type:{Type}, Sender:{Sender}, Distribution_List:{Distribution_List}, Subject:{Subject}, Body:{Body}, Main_LOG_FH:{Main_LOG_FH}, File:{File}, Server:{Server}")
    print("-----------------------------------------")
    print("Calling SendEmailPS function...")
    Main_LOG_FH.write("\nCalling SendEmailPS function...")

    # powershell = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
	## y $ps_command = "Send-MailMessage -From '$Sender' -To '$Distribution_List' -Subject '$Subject' -Body '$Body' -attachment '$File' -SmtpServer $Server";
    ps_command = f"Send-MailMessage -From {Sender} -To {Distribution_List} -Subject {Subject} -Body {Body} -attachment {File} -SmtpServer {Server}"
    ## y $ps_command = "Send-MailMessage -From '$   Email_Sender' -To '$Email_Distribution_List' -Subject '$Email_Subject' -Body '$Email_Body' -attachment '$fed_wirepayments' -SmtpServer $Email_Server";
    PopenObj = subprocess.Popen(["powershell", "-command", ps_command], stdout = subprocess.PIPE, text = True)
    communicateStdData = PopenObj.communicate()
    result = communicateStdData[0]

    print(f"SendEmailPS_Status:\n|{result}|")
    Main_LOG_FH.write(f"SendEmailPS_Status:\n|{result}|")

    print("\n-------------------------------------------------------\n")
	# print $Main_LOG_FH "Notification email sent!\n" if( $Type =~ m/Notification/ );
	# print $Main_LOG_FH "ALERT email sent!\n" if( $Type =~ m/Alert/ );

    return (result)


def RoboCopyFile(Source_Loc, Target_Loc, Source_File, Main_LOG_FH):
    ## C:\Windows\System32\robocopy.exe \\ehny105\ftproot\Calypso\Prod\ \\ehny20-2\FILESHARES\Departments\Information_Tech\EDP\MyPerl\FedLineAdvantage\perl\data\IN /log+:c:\logs\cerberus_calypso_log.txt
	## C:\Windows\System32\robocopy.exe \\ehny105\ftproot\Calypso\Prod\ \\ehny120\IN /log+:c:\logs\cerberus_calypso_log.txt

    print("\n-----------------------------------------")
    print("\nCalling RoboCopyFile function...")
    Main_LOG_FH.write("\nCalling RoboCopyFile function...\n")

    rc_exec = r'C:\Windows\System32\robocopy.exe'

    PopenObj = subprocess.Popen([rc_exec, Source_Loc, Target_Loc, Source_File, '/E','/mt'], stdout = subprocess.PIPE, text = True)
    
    communicateStdData = PopenObj.communicate()
    result = communicateStdData[0]

    print(f"RoboCopyFile_Status:\n|{result}|")
    Main_LOG_FH.write(f"RoboCopyFile_Status:\n|{result}|\n")
    
    print("\n-------------------------------------------------------")
    return result