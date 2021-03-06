 Param
	(
	[Parameter(Mandatory=$True)]
	[string]$Platform
	)

# this script adds accounts to the performance log group. simples.

# let's clean the error variable as we are not starting a fresh session
$Error.Clear()

# setup the parameter file
$parameterfile = "r:\powershell\xml\spconfig-"+$Platform+".xml"
[xml]$accountstoadd = Get-Content $parameterfile

# Get the local performance log users group
$logusersGroup = ([ADSI]"WinNT://$env:COMPUTERNAME/Performance Log Users,group")
# Get the members of the log users group
$logusers = $logusersGroup.psbase.invoke("Members") | ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
#loop through the users stated in the configuration XML to add the stated users
foreach ($accounttoadd in $accountstoadd.farm.groupmemberships.logusers.account) {
		Write-Host "INFO: Adding account $($accounttoadd.Name)..." -NoNewline -ForegroundColor Yellow
		Try {
			$ManagedAccountDomain,$ManagedAccountUser = $accounttoadd.Name -Split "\\"
			# Add account to group by first testing that it is not already a member
			If (!($logusers -contains $ManagedAccountUser)) {
				([ADSI]"WinNT://$env:COMPUTERNAME/Performance Log Users,group").Add("WinNT://$ManagedAccountDomain/$ManagedAccountUser")
				Write-Host "Done!"	-BackgroundColor DarkGreen	
			}
			Else {
				Write-Host ""
				# we use write-warning here as we could request input from the console if we desired
				Write-Warning "$($accounttoadd.Name) is already a local admin!"
				$warning = $true
			}
		}
		Catch {
			$_
			Write-Host "."
			Write-Warning "ERROR: Could not add $($accounttoadd.Name)!"
		}
}
Write-Host ''
# here we are testing to see if we should note to the console that warnings were generated this is not really necessary and is just here to show a multiple condition test
if ((!$warning) -and (!$Error)) {
	Write-Host "SUCCESS: Done adding accounts to groups!" -BackgroundColor DarkGreen
}
else {
	Write-Warning "Done Adding Accounts, but errors or warnings were generated!"
}

# here we dump a file to the desktop to let us know if the process completed or threw an error
if (!$Error) {
	Out-File $env:USERPROFILE\desktop\$(($MyInvocation).mycommand.name)' completed'.txt
}
else {
	Out-File $env:USERPROFILE\desktop\$(($MyInvocation).mycommand.name)' failed'.txt
}

#    The PowerShell Tutorial for SharePoint 2010
#    Copyright (C) 2014 Seb Matthews
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.