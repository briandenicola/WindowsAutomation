Set-Variable -Name SChannelRegKeyPath        -Value 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL' -Option Constant
Set-Variable -Name SChannelDisableServerKey  -Value 'DisableRenegoOnServer'                                             -Option Constant
Set-Variable -Name SChannelDisableClientKey  -Value 'DisableRenegoOnClient'                                             -Option Constant
Set-Variable -Name Disable                   -Value 1                                                                   -Option Constant

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure 
	)

    $returnValue = @{
		Ensure = "Absent"
	}

    Write-Verbose -Message ("Testing for presents of {0}" -f $SChannelRegKeyPath)
    try {
        if( (Test-Path -Path $SChannelRegKeyPath) ) {    
            $Key = Get-Item -Path $SChannelRegKeyPath
            Write-Verbose -Message ("Key Value {0}" -f $key)

            if( $key.GetValue($SChannelDisableServerKey) -and $key.GetValue($SChannelDisableClientKey) ) {
                $server = Get-ItemProperty -Path $SChannelRegKeyPath -Name $SChannelDisableServerKey | Select -Expand $SChannelDisableServerKey
                $client = Get-ItemProperty -Path $SChannelRegKeyPath -Name $SChannelDisableClientKey | Select -Expand $SChannelDisableClientKey

                Write-Verbose -Message ("Client Value {0}" -f $client)
                Write-Verbose -Message ("Server Value {0}" -f $server)

                if( $server -eq 1 -and $client -eq 1 ) { 
                    $returnValue.Ensure = "Present"
                }
            }
        }
    } 
    catch {}

    Write-Verbose -Message ("Get-TargetResource Value {0}" -f $returnValue.Ensure )
	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure 

	)

    Write-Verbose -Message ("Inside Set-TargetResource. Setting to {0}" -f $Ensure)

    if( $Ensure -eq "Absent" ) {
        Write-Verbose -Message ("Removing {0} and {1} keys" -f $SChannelDisableServerKey, $SChannelDisableClientKey)
        Remove-ItemProperty -Path $SChannelRegKeyPath -Name $SChannelDisableServerKey
        Remove-ItemProperty -Path $SChannelRegKeyPath -Name $SChannelDisableClientKey
    }
    else {
        Write-Verbose -Message ("Setting {0} and {1} keys" -f $SChannelDisableServerKey, $SChannelDisableClientKey)
        Set-ItemProperty -Path $SChannelRegKeyPath -Name $SChannelDisableServerKey -Value $Disable
        Set-ItemProperty -Path $SChannelRegKeyPath -Name $SChannelDisableClientKey -Value $Disable
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param (
		[parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure 
	)

    $Value = Get-TargetResource -Ensure $Ensure 
    $ResultValues = $false

    if( $Value.Ensure -ieq $Ensure ) {
        $ResultValues = $true
    }

    Write-Verbose -Message ("Test-TargetResource. ResultValues - {0}. Values from Get-TargetResource - {1}. Ensure Value - {2}" -f $ResultValues, $Value.Ensure, $Ensure)
    $ResultValues
}


Export-ModuleMember -Function *-TargetResource

