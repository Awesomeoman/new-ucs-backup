<#
.SYNOPSIS
Backup Cisco UCS Manager cluster

.PARAMETER
None yet

.DESCRIPTION
Connect securely to a UCS Manager cluster and perform all four backup types. Backup files are saved via http to a customisable location. Results will then be emailed for successfull and failed backups.

.EXAMPLES
.\run-ucs-backup.ps1
#>

# Things still todo:
# Make email body more meaningful
# Change subject of email if one or more of the jobs has failed
# Add param support for all of the variables


# Hostname or IP for your SMTP server
$SMTPServer = x.x.x.x
# Email recipients go here
$mailto = me@email.com 
# Sender addresses
$mailfrom = UCS@email.com 

# Hostname or IP for UCS Cluster
$UCSHostName = x.x.x.x
# Username for account with rights to backup UCS
$UCSUser = user

# These paths are used by the backup jobs to store each of the four types in their own folder with a unique name. Customise as required.
$BackupPath = .\UCS\Backups\
$fullstatePath =  "$BackupPath\full-state\$UCSHostName-{0:yyyMMdd-HHmm}.xml" -f (get-date)
$configallPath =  "$BackupPath\config-all\$UCSHostName-{0:yyyMMdd-HHmm}.xml" -f (get-date)
$configlogicalPath =  "$BackupPath\config-logical\$UCSHostName-{0:yyyMMdd-HHmm}.xml" -f (get-date)
$configsystemPath =  "$BackupPath\config-system\$UCSHostName-{0:yyyMMdd-HHmm}.xml" -f (get-date)


# You should store this in a txt file to run the script non interatively. See http://blogs.technet.com/b/robcost/archive/2008/05/01/powershell-tip-storing-and-using-password-credentials.aspx
$pwd = read-host -AsSecureString | ConvertFrom-SecureString 	
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $UCSUser,$pwd

$result = @()
# Function to test for the presence of a backup file matching the name generated above. If it is present it will return the name, size and creation date in the email body.
function Backup_Check($path){
		$test = test-path $path
		if ($test){
			$jobresults = get-childitem $path | select name,length,creationtime
		} else{
			$jobresults = $path + "backup has failed. File is not present"
		}
			
		return $jobresults
}

# Connect to UCS Manager and execute the four backup jobs
connect-ucs $UCSHostName -credential $cred
backup-ucs -type full-state -pathpattern $fullstatePath
backup-ucs -type config-all -pathpattern $configallPath
backup-ucs -type config-logical -pathpattern $configlogicalPath
backup-ucs -type config-system -pathpattern $configsystemPath

# Run the Backup Check function and save the results in the array $result
$result += Backup_Check($fullstatePath)
$result += Backup_Check($configallPath)
$result += Backup_Check($configlogicalPath)
$result += Backup_Check($configsystemPath)

# Convert $result to a string so it can be used as the body of send-mail message
$body = $result | out-string

# Email results of backups
send-mailmessage -to $mailto -Subject 'UCS Backup Report' -from $mailfrom -smtpserver $SMTPServer -body $body