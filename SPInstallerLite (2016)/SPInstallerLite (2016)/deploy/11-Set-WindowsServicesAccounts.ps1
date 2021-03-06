 Param
	(
	[Parameter(Mandatory=$True, HelpMessage="You must provide a platform suffix so the script can find the paramter file!")]
	[string]$Platform
	)

# this script will update the windows service accounts. simples.
# notice how with regions used and functions declared we can make things very neat, folded and one-paged?
# Groovy!

# let's clean the error variable as we are not starting a fresh session
$Error.Clear()

# setup the parameter file
$parameterfile = "r:\powershell\xml\spconfig-"+$Platform+".xml"

#REGION load snapins and assemblies
# check for the sharepoint snap-in. this is from Ed Wilson.
$snapinsToCheck = @("Microsoft.SharePoint.PowerShell") #you can add more snapins to this array to load more
$currentSnapins = Get-PSSnapin
$snapinsToCheck | ForEach-Object `
    {$snapin = $_;
        if(($CurrentSnapins | Where-Object {$_.Name -eq "$snapin"}) -eq $null)
        {
            Write-Host "$snapin snapin not found, loading it"
            Add-PSSnapin $snapin
            Write-Host "$snapin snapin loaded"
        }
    }
#ENDREGION

#REGION variables
# get the variables from the parameter file
Try {
	# here we are turning a non-terminating error into a terminating error if the file does not exist, this is so we can catch it
	[xml]$serviceaccountstoupdate = Get-Content $parameterfile -ErrorAction Stop
}
Catch {
	Write-Warning "There is no parameter file called $parameterfile!"
	Break
}

#ENDREGION

#REGION Function Declaration
# In this region we are showing the declaration of functions that will be called later in the script.
# This time we're passing parameters into some of the functions using the param approach.
# In these examples we are showing how to correctly construct the beginning of a function to include information
# about the funtion that is useful to the reader and that can be invoked from the command line such as a description, examples or notes.
# Muy bueno!

# in this example you can see one of the ways we can pass a parameter into a function
# this approach is the smarter way and gives us all of the goodies we get by using a param block

Function Update-SPWindowsServiceAccounts {
	param(
	    [Parameter(Mandatory=$true)]
	    [STRING]$servicetoupdate,
		[Parameter(Mandatory=$true)]
	    [STRING]$identity
	    )
	<#
	   .Synopsis
	    This function updates Windows service identities
	   .Description
	    This function updates the Windows Service identities within a SharePoint 2016 farm.  
		This function has only been tested with SharePoint 2016.
		This function will only run from an elevated PowerShell session and requires the running user to
		have permission to the SharePoint configuration database.
	   .Example
	   	Update-SPWindowsServiceAccounts -servicetoupdate $servicename -identity $serviceaccount
	   .Notes
	    NAME: Update-SPWindowsServiceAccounts
	    AUTHOR: Seb Matthews @sebmatthews #bigseb
	    DATE: September 2015
	   .Link
	    http://sebmatthews.net
	#>

	# let's pass the farm deets into a variable so we can test against one of its properties
	$farm = Get-SPFarm
	if ($servicetoupdate -ne "OSearch16") {
		$updservice = $farm.Services | ?{$_.Name -eq $($servicetoupdate)} 
		Write-Host "INFO: Updating $servicetoupdate..." -NoNewline 
		$managedAccount = Get-SPManagedAccount $identity
		$updservice.ProcessIdentity.CurrentIdentityType = "SpecificUser"
		$updservice.ProcessIdentity.ManagedAccount = $managedAccount
		$updservice.ProcessIdentity.Update()
		$updservice.ProcessIdentity.Deploy()
		Write-Host "Done!" -BackgroundColor DarkGreen
		Write-Host
	}
	if ($servicetoupdate -eq "OSearch16") {
		Write-Host "INFO: Updating $servicetoupdate..." -NoNewline 
		$managedAccount = Get-SPManagedAccount $identity
		$updsearchservice = (Get-SPEnterpriseSearchService).get_ProcessIdentity()
		$updsearchservice.CurrentIdentityType = "SpecificUser"
		$updsearchservice.ManagedAccount = $managedaccount
		$updsearchservice.Update()
		$updsearchservice.Deploy()
		Write-Host "Done!" -BackgroundColor DarkGreen
		Write-Host
	}
}

#ENDREGION

#REGION Execute
# here we do all the work in 3 lines
foreach ($service in $serviceaccountstoupdate.farm.svcaccounts.service) {
	Update-SPWindowsServiceAccounts -servicetoupdate $service.servicename -identity $service.serviceaccount
}

if (!$Error) {
	Write-Host "SUCCESS: Windows services updated!" -BackgroundColor DarkGreen
	Out-File $env:USERPROFILE\desktop\$(($MyInvocation).mycommand.name)'completed'.txt
	}
else {
	Write-Host "ERROR: There was an issue with the service update, please review!" -BackgroundColor Red
	start-process "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\BIN\psconfigui.exe" -argumentlist "-cmd showcentraladmin"
	Out-File $env:USERPROFILE\desktop\$(($MyInvocation).mycommand.name)'failed'.txt
	}
	Write-Host
#ENDREGION

#    The PowerShell Tutorial for SharePoint 2016
#    Copyright (C) 2015 Seb Matthews
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