#####################################################################
## Package for Sending Email, Transmitting Files
## Created by:	EO 2022-03-27
##
#####################################################################
package SendTools;

use strict;
use warnings;
use MIME::Lite;
use Email::Stuffer;
use Email::Sender::Transport::SMTP ();

use Exporter;
## our (@EXPORT, @ISA);
## use Exporter qw(import);
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
@EXPORT_OK   = qw(SendEmailPS SendEmailMIME SendEmailStuffer RoboCopyFile);  
%EXPORT_TAGS = ( DEFAULT => [qw(SendEmailPS)], Both    => [qw(SendEmailPS SendEmailMIME SendEmailStuffer RoboCopyFile)]);

##################################################################################################
##				---	SUBROUTINES	---					##
##################################################################################################

# ---------------------------------------------------------------------------------------------- #
sub SendEmailPS {

	my($Type,$Sender,$Distribution_List,$Subject,$Body,$Main_LOG_FH,$File,$Server)=@_;

        print "\n-----------------------------------------\n";
        print "\nCalling SendEmailPS function...\n";
	print $Main_LOG_FH "\nCalling SendEmailPS function...\n";

	my $powershell = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';
	## my $ps_command = "Send-MailMessage -From '$Sender' -To '$Distribution_List' -Subject '$Subject' -Body '$Body' -attachment '$File' -SmtpServer $Server";
	my $ps_command = "Send-MailMessage -From '$Sender' -To $Distribution_List -Subject '$Subject' -Body '$Body' -attachment '$File' -SmtpServer $Server";
	## my $ps_command = "Send-MailMessage -From '$Email_Sender' -To '$Email_Distribution_List' -Subject '$Email_Subject' -Body '$Email_Body' -attachment '$fed_wirepayments' -SmtpServer $Email_Server";
	my $result = `$powershell -command "$ps_command"`;

	print "SendEmailPS_Status:\n|$result|\n";
	print $Main_LOG_FH "SendEmailPS_Status:\n|$result|\n";

	print "\n-------------------------------------------------------\n";
	## print $Main_LOG_FH "Notification email sent!\n" if( $Type =~ m/Notification/ );
	## print $Main_LOG_FH "ALERT email sent!\n" if( $Type =~ m/Alert/ );

	return ($result);

} ## end of function call SendEmailPS

# ---------------------------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------------------------- #
sub SendEmailMIME {

	my($Type,$Sender,$Distribution_List,$Subject,$Body,$Main_LOG_FH)=@_;

        print "\n-----------------------------------------\n";
        print "\nCalling SendEmailMIME function...\n";

	my $msg = MIME::Lite->new
	(
		Subject => '$Subject',
		From    => '$Sender',
		To      => '$Distribution_List',
		Type    => 'text/html',
		Data    => '$Body'
	);

	$msg->send();
	## $msg->send('smtp',"10.252.50.50",AuthUser=>"",AuthPass=>"");

	print "\n-------------------------------------------------------\n";
	print $Main_LOG_FH "Notification email sent!\n" if( $Type =~ m/Notify/ );
	print $Main_LOG_FH "ALERT email sent!\n" if( $Type =~ m/Alert/ );

	return ($Type);

} ## end of function call SendEmailMIME

# ---------------------------------------------------------------------------------------------- #
=begin STUFFER
# ---------------------------------------------------------------------------------------------- #
sub SendEmailStuffer {

	my($Type,$Sender,$Distribution_List,$Subject,$Body,$Main_LOG_FH)=@_;

        print "\n-----------------------------------------\n";
        print "\nCalling SendEmailStuffer function...\n";

	my $mail = Email::Stuffer->to($Distribution_List)->from($Sender)->subject($Subject)->text_body($Body);

	# $mail->attach_file('/path/to/file.txt'); # guesses MIME type
	## or if you have the file data in memory
	# $mail->attach($contents, name => 'foo.dat', filename => 'foo.dat',
	 # content_type => 'application/octet-stream');

	# to change the transport
	$mail->transport('SMTP', host => '10.252.50.50' );
	$mail->transport(Email::Sender::Transport::SMTP->new(host => mail.smtp.com));

	$mail->send_or_die;

	## $msg->send('smtp',"10.252.50.50",AuthUser=>"",AuthPass=>"");

	print "\n-------------------------------------------------------\n";
	print $Main_LOG_FH "Notification email sent!\n" if( $Type =~ m/Notify/ );
	print $Main_LOG_FH "ALERT email sent!\n" if( $Type =~ m/Alert/ );

	return ($Type);

} ## end of function call SendEmailStuffer
# ---------------------------------------------------------------------------------------------- #
=end STUFFER
=cut
# ---------------------------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------------------------- #
sub RoboCopyFile{

	## C:\Windows\System32\robocopy.exe \\ehny105\ftproot\Calypso\Prod\ \\ehny20-2\FILESHARES\Departments\Information_Tech\EDP\MyPerl\FedLineAdvantage\perl\data\IN /log+:c:\logs\cerberus_calypso_log.txt
	## C:\Windows\System32\robocopy.exe \\ehny105\ftproot\Calypso\Prod\ \\ehny120\IN /log+:c:\logs\cerberus_calypso_log.txt

	my($Source_Loc,$Target_Loc,$Source_File,$Main_LOG_FH)=@_;

        print "\n-----------------------------------------\n";
        print "\nCalling RoboCopyFile function...\n";
	print $Main_LOG_FH "\nCalling RoboCopyFile function...\n";

	my $rc_exec= 'C:\Windows\System32\robocopy.exe';

	my $rc_command = "'$Source_File' '$Target_Loc' '$Source_File' ";
	my $result = `$rc_exec "$Source_Loc" "$Target_Loc" "$Source_File" /mt /z`;

	print "RoboCopyFile_Status:\n|$result|\n";
	print $Main_LOG_FH "RoboCopyFile_Status:\n|$result|\n";

	print "\n-------------------------------------------------------\n";
	return ($result);

} ## end of function call RoboCopyFile

# ---------------------------------------------------------------------------------------------- #






#

# ---------------------------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------------------------- #
1;
# ---------------------------------------------------------------------------------------------- #
