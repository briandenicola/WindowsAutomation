Set-Variable -Name SChannelProtocolRoot           -Value "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\{0}"                                -Option Constant
Set-Variable -Name SChannelClientProtocolKey      -Value "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\{0}\Client"                          -Option Constant
Set-Variable -Name SChannelServerProtocolKey      -Value "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\{0}\Server"                          -Option Constant
Set-Variable -Name SChannelMPUHProtocolKey        -Value "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Server" -Option Constant
Set-Variable -Name EnabledItemPropertyValue       -Value "Enabled"                                                                                                         -Option Constant
Set-Variable -Name DisabledByDefaultPropertyValue -Value "DisabledByDefault"                                                                                               -Option Constant

$TLS_Lookup = New-Object PSObject -Property @{
    PCT   = "PCT 1.0"
    SSL2  = "SSL 2.0"
    SSL3  = "SSL 3.0"
    TLS1  = "TLS 1.0"
    TLS11 = "TLS 1.1"
    TLS12 = "TLS 1.2"
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
		$PCT,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$SSL2,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$SSL3,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TLS1,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TLS11,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TLS12
	)

	$returnValue = @{
        PCT   = $false
        SSL2  = $false
        SSL3  = $false
        TLS1  = $false
        TLS11 = $false
        TLS12 = $false
    }

    foreach( $protocol in ($TLS_Lookup.psobject.Properties | Select -ExpandProperty Name) ) {

        if( (Test-Path -Path ($SChannelProtocolRoot -f $TLS_Lookup.$protocol) ) ) {
            $client_bydefault = Get-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.$protocol) -Name $DisabledByDefaultPropertyValue  | Select -ExpandProperty $DisabledByDefaultPropertyValue
            $server_enabled   = Get-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.$protocol) -Name $EnabledItemPropertyValue        | Select -ExpandProperty $EnabledItemPropertyValue
            $server_bydefault = Get-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.$protocol) -Name $DisabledByDefaultPropertyValue  | Select -ExpandProperty $DisabledByDefaultPropertyValue

            if( $client_bydefault -eq $DWORD.ALL_ZEROS -and $server_enabled -eq $DWORD.ALL_ONES -and $server_bydefault -eq $DWORD.ALL_ZEROS ) {
                $returnValue.$protocol = $true
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
		$PCT,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$SSL2,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$SSL3,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TLS1,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TLS11,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TLS12
	)

    New-Item -Path ($SChannelProtocolRoot -f "Multi-Protocol Unified Hello") -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path ($SChannelProtocolRoot -f "Multi-Protocol Unified Hello\Server") -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $SChannelMPUHProtocolKey -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ZEROS
    Set-ItemProperty -Path $SChannelMPUHProtocolKey -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE

    foreach( $protocol in ($TLS_Lookup.psobject.Properties | Select -ExpandProperty Name)) {
        New-Item -Path ($SChannelProtocolRoot -f $TLS_Lookup.$protocol) -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path ($SChannelClientProtocolKey -f $TLS_Lookup.$protocol) -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path ($SChannelServerProtocolKey -f $TLS_Lookup.$protocol) -ErrorAction SilentlyContinue | Out-Null

    }

    if( $PCT ) {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.PCT) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.PCT) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ONES
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.PCT) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }
    else {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.PCT) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.PCT) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.PCT) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
    }

    if( $SSL2 ) {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.SSL2) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.SSL2) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ONES
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.SSL2) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }
    else {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.SSL2) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.SSL2) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.SSL2) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
    }

    if( $SSL3 ) {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.SSL3) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.SSL3) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ONES
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.SSL3) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }
    else {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.SSL3) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.SSL3) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.SSL3) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
    }

    if( $TLS1 ) {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.TLS1) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS1) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ONES
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS1) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }
    else {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.TLS1) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS1) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS1) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
    }

    if( $TLS11 ) {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.TLS11) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS11) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ONES
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS11) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }
    else {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.TLS11) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS11) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS11) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
    }

    if( $TLS12 ) {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.TLS12) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS12) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ONES
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS12) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ALL_ZEROS
    }
    else {
        Set-ItemProperty -Path ($SChannelClientProtocolKey -f $TLS_Lookup.TLS12) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS12) -Name $EnabledItemPropertyValue       -Type DWord -Value $DWORD.ALL_ZEROS
        Set-ItemProperty -Path ($SChannelServerProtocolKey -f $TLS_Lookup.TLS12) -Name $DisabledByDefaultPropertyValue -Type DWord -Value $DWORD.ONE
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param (
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$PCT,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$SSL2,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$SSL3,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TLS1,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TLS11,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$TLS12
	)

    $Value = Get-TargetResource -PCT $PCT -SSL2 $SSL2 -SSL3 $SSL3 -TLS1 $TLS1 -TLS11 $TLS11 -TLS12 $TLS12
    [System.Boolean] $ResultValues = $false

    if( $Value.PCT -eq $PCT -and $Value.SSL2 -eq $SSL2 -and $Value.SSL3 -eq $SSL3 -and $Value.TLS1 -eq $TLS1 -and $Value.TLS11 -eq $TLS11 -and $Value.TLS12 -eq $TLS12 ) {
        [System.Boolean] $ResultValues = $true
    }

    $ResultValues

}


Export-ModuleMember -Function *-TargetResource

