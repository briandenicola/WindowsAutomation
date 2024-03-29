#
#$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present","Absent"
#$Shell = New-xDscResourceProperty -Name Name -Type String -Attribute Key -Description "Name of the Shell" -ValidateSet "powerShell.exe","cmd.exe"
#New-xDscResource –Name cDefaultSHell -Property $Shell, $Ensure -Path (Join-Path -Path $PWD.Path -ChildPath "cDefaultShell")
#

Set-Variable -Name WinLogonRegKeyPath        -Value 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Option Constant
Set-Variable -Name WinLogonShell             -Value 'Shell'                                                      -Option Constant

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("powershell.exe","cmd.exe")]
		[System.String]
		$Name
	)

	Write-Verbose "Use this cmdlet to deliver information about command processing."
    	$returnValue = @{
        	Ensure = "Present"
        	Name   = "Cmd.exe"
	}

    	if( (Test-Path -Path $WinLogonRegKeyPath) ) {
        	$shell = Get-ItemProperty -Path $WinLogonRegKeyPath | Select -ExpandProperty $WinLogonShell
        	$returnValue.Name = $shell
    	}
    
	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("powershell.exe","cmd.exe")]
		[System.String]
		$Name,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    	if( $Ensure -eq "Absent" ) {
        	Set-ItemProperty -Path $WinLogonRegKeyPath -Name $WinLogonShell -Value "cmd.exe"
	}
	else {
        	Set-ItemProperty -Path $WinLogonRegKeyPath -Name $WinLogonShell -Value $Name
	}

	$global:DSCMachineStatus = 1
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("powershell.exe","cmd.exe")]
		[System.String]
		$Name,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    	$Value = Get-TargetResource -Name $Name
	$ResultValues = @{}

    	if( $Value.Ensure -eq $Ensure -and $Value.Name -eq $Name ) {
        	$ResultValues.Ensure = $true
        	$ResultValues.Name   = $Value.Name 
	}
    	else {
        	$ResultValues.Ensure = $false 
        	$ResultValues.Name   = $Value.Name 
    	}

    	$ResultValues
}


Export-ModuleMember -Function *-TargetResource

