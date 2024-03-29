Set-Variable -Name SChannelCiphersPath      -Value "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\{0}\"   -Option Constant
Set-Variable -Name EnabledItemPropertyValue -Value "Enabled"                                                                          -Option Constant

$Cipher_Lookup = New-Object PSObject -Property @{
    AES128  = "AES 128/128"
    AES256  = "AES 256/256"
    DES     = "DES 56/56"
    NULLEncryption    = "NULL"
    RC2     = @("RC2 128/128", "RC2 40/128", "RC2 56/128")
    RC4     = @("RC4 128/128", "RC4 40/128", "RC4 56/128", "RC4 64/128")
    TripleDES = "Triple DES 168/168"
}

$DWORD = New-Object PSObject -Property @{
    ALL_ZEROS = "00000000"
    ALL_ONES  = "4294967295"
    ONE       = "00000001"
}

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$AES128,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$AES256,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$NULLEncryption,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$RC2,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$RC4,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$DES,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TripleDES
	)

	$returnValue = @{
        AES128    = $false
        AES256    = $false
        NULLEncryption      = $false
        RC2       = $false
        RC4       = $false
        DES       = $false
        TripleDES = $false
    }

    foreach( $protocol in ($Cipher_Lookup.psobject.Properties | Select -ExpandProperty Name) ) {    
            if( $protocol -imatch "RC" ) {
                $returnValue.$protocol = $true 
                foreach( $rc_protocol in $Cipher_Lookup.$protocol ) {
                    if( (Test-Path -Path ($SChannelCiphersPath -f $rc_protocol)) ) {
                        $protocol_enabled = Get-ItemProperty -Path ($SChannelCiphersPath -f $rc_protocol) -Name $EnabledItemPropertyValue | Select -ExpandProperty $EnabledItemPropertyValue

                        if( $protocol_enabled -ne $DWORD.ALL_ONES ) { 
                            $returnValue.$protocol = $false
                            break
                        }
                    }
                }
            }
            else {
                 if( (Test-Path -Path ($SChannelCiphersPath -f $Cipher_Lookup.$protocol)) ) {
                    $protocol_enabled = Get-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.$protocol) -Name $EnabledItemPropertyValue | Select -ExpandProperty $EnabledItemPropertyValue     
    
                    if( $protocol_enabled -eq $DWORD.ALL_ONES ) {
                        $returnValue.$protocol = $true
                    }
                }
            }
    }

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$AES128,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$AES256,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$NULLEncryption,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$RC2,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$RC4,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$DES,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TripleDES
	)

    $ciphers_path = 'SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers'
    foreach( $protocol in ($Cipher_Lookup.psobject.Properties | Select -ExpandProperty Name)) {
        if( $protocol -imatch "RC" )  { 
            foreach( $rc_protocol in $Cipher_Lookup.$protocol ) {
                $key = (Get-Item HKLM:\).OpenSubKey($ciphers_path, $true).CreateSubKey($rc_protocol)
                $key.close()
                #New-Item -Path ($SChannelCiphersPath -f $rc_protocol) #-ErrorAction SilentlyContinue | Out-Null
            }
        } 
        else {
            $key = (Get-Item HKLM:\).OpenSubKey($ciphers_path, $true).CreateSubKey($Cipher_Lookup.$protocol)
            $key.close()
            #New-Item -Path ($SChannelCiphersPath -f $Cipher_Lookup.$protocol) #-ErrorAction SilentlyContinue | Out-Null
        }

    }

    if( $AES128 ) {
        Set-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.AES128) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ONES
    }
    else {
        Set-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.AES128) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }

    if( $AES256 ) {
        Set-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.AES256) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ONES
    }
    else {
        Set-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.AES256) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }

    if( $NULLEncryption ) {
        Set-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.NULL) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ONES
    }
    else {
        Set-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.NULL) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }

    if( $DES ) {
        Set-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.DES) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ONES
    }
    else {
        Set-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.DES) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }

    if( $TripleDES ) {
        Set-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.TripleDES) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ONES
    }
    else {
        Set-ItemProperty -Path ($SChannelCiphersPath -f $Cipher_Lookup.TripleDES) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }

    if( $RC2 ) {
        foreach( $protocol in $Cipher_Lookup.RC2 ) {
            Set-ItemProperty -Path ($SChannelCiphersPath -f $protocol) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ONES
        }
    }
    else {
        foreach( $protocol in $Cipher_Lookup.RC2 ) {
            Set-ItemProperty -Path ($SChannelCiphersPath -f $protocol) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
        }
    }

    if( $RC4 ) {
        foreach( $protocol in $Cipher_Lookup.RC4 ) {
            Set-ItemProperty -Path ($SChannelCiphersPath -f $protocol) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ONES
        }
    }
    else {
        foreach( $protocol in $Cipher_Lookup.RC4 ) {
            Set-ItemProperty -Path ($SChannelCiphersPath -f $protocol) -Name $EnabledItemPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
        }
    }

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param (
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$AES128,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$AES256,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$NULLEncryption,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$RC2,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$RC4,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$DES,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TripleDES
	)

    $Value = Get-TargetResource -AES128 $AES128 -AES256 $AES256 -NULLEncryption $NULLEncryption -RC2 $RC2 -RC4 $RC4 -DES $DES -TripleDES $TripleDES
    [System.Boolean] $ResultValues = $false

    if( $Value.AES128 -eq $AES128 -and $Value.AES256 -eq $AES256 -and $Value.NULLEncryption -eq $NULLEncryption -and $Value.RC2 -eq $RC2 -and $Value.RC4 -eq $RC4 -and $Value.DES -eq $DES -and $Value.TripleDES -eq $TripleDES ) {
        [System.Boolean] $ResultValues = $true
    }

    $ResultValues

}


Export-ModuleMember -Function *-TargetResource

