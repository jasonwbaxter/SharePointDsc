function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Description,

        [Parameter(Mandatory = $true)]
        [String]
        $Realm,

        [Parameter(Mandatory = $true)]
        [String]
        $SignInUrl,

        [Parameter(Mandatory = $true)]
        [String]
        $IdentifierClaim,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ClaimsMappings,

        [Parameter()]
        [String]
        $SigningCertificateThumbprint,

        [Parameter()]
        [String]
        $SigningCertificateFilePath,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [String]
        $ClaimProviderName,

        [Parameter()]
        [String]
        $ProviderSignOutUri,

        [Parameter()]
        [System.Boolean]
        $UseWReplyParameter = $false,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting SPTrustedIdentityTokenIssuer '$Name' settings"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $claimsMappings = @()
        $spTrust = Get-SPTrustedIdentityTokenIssuer -Identity $params.Name `
            -ErrorAction SilentlyContinue
        if ($spTrust)
        {
            $description = $spTrust.Description
            $realm = $spTrust.DefaultProviderRealm
            $signInUrl = $spTrust.ProviderUri.OriginalString
            $identifierClaim = $spTrust.IdentityClaimTypeInformation.InputClaimType
            $SigningCertificateThumbprint = $spTrust.SigningCertificate.Thumbprint
            $currentState = "Present"
            $claimProviderName = $sptrust.ClaimProviderName
            $providerSignOutUri = $sptrust.ProviderSignOutUri.OriginalString
            $useWReplyParameter = $sptrust.UseWReplyParameter

            $spTrust.ClaimTypeInformation | ForEach-Object -Process {
                $claimsMappings = $claimsMappings + @{
                    Name              = $_.DisplayName
                    IncomingClaimType = $_.InputClaimType
                    LocalClaimType    = $_.MappedClaimType
                }
            }
        }
        else
        {
            $description = ""
            $realm = ""
            $signInUrl = ""
            $identifierClaim = ""
            $SigningCertificateThumbprint = ""
            $currentState = "Absent"
            $claimProviderName = ""
            $providerSignOutUri = ""
            $useWReplyParameter = $false
        }

        return @{
            Name                         = $params.Name
            Description                  = $description
            Realm                        = $realm
            SignInUrl                    = $signInUrl
            IdentifierClaim              = $identifierClaim
            ClaimsMappings               = $claimsMappings
            SigningCertificateThumbprint = $SigningCertificateThumbprint
            SigningCertificateFilePath   = ""
            Ensure                       = $currentState
            ClaimProviderName            = $claimProviderName
            ProviderSignOutUri           = $providerSignOutUri
            UseWReplyParameter           = $useWReplyParameter
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Description,

        [Parameter(Mandatory = $true)]
        [String]
        $Realm,

        [Parameter(Mandatory = $true)]
        [String]
        $SignInUrl,

        [Parameter(Mandatory = $true)]
        [String]
        $IdentifierClaim,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ClaimsMappings,

        [Parameter()]
        [String]
        $SigningCertificateThumbprint,

        [Parameter()]
        [String]
        $SigningCertificateFilePath,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [String]
        $ClaimProviderName,

        [Parameter()]
        [String]
        $ProviderSignOutUri,

        [Parameter()]
        [System.Boolean]
        $UseWReplyParameter = $false,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPTrustedIdentityTokenIssuer '$Name' settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present")
    {
        if ($CurrentValues.Ensure -eq "Absent")
        {
            if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and `
                    $PSBoundParameters.ContainsKey("SigningCertificateFilePath"))
            {
                $message = ("Cannot use both parameters SigningCertificateThumbprint and SigningCertificateFilePath at the same time.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            if (!$PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and `
                    !$PSBoundParameters.ContainsKey("SigningCertificateFilePath"))
            {
                $message = ("At least one of the following parameters must be specified: " + `
                        "SigningCertificateThumbprint, SigningCertificateFilePath.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            Write-Verbose -Message "Creating SPTrustedIdentityTokenIssuer '$Name'"
            $null = Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
                -ScriptBlock {
                $params = $args[0]
                $eventSource = $args[1]

                if ($params.SigningCertificateThumbprint)
                {
                    Write-Verbose -Message ("Getting signing certificate with thumbprint " + `
                            "$($params.SigningCertificateThumbprint) from the certificate store 'LocalMachine\My'")

                    if ($params.SigningCertificateThumbprint -notmatch "^[A-Fa-f0-9]{40}$")
                    {
                        $message = ("Parameter SigningCertificateThumbprint does not match valid format '^[A-Fa-f0-9]{40}$'.")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }

                    $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object -FilterScript {
                        $_.Thumbprint -match $params.SigningCertificateThumbprint
                    }

                    if (!$cert)
                    {
                        $message = ("Signing certificate with thumbprint $($params.SigningCertificateThumbprint) " + `
                                "was not found in certificate store 'LocalMachine\My'.")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }

                    if ($cert.HasPrivateKey)
                    {
                        $message = ("SharePoint requires that the private key of the signing certificate" + `
                                " is not installed in the certificate store.")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }
                else
                {
                    Write-Verbose -Message "Getting signing certificate from file system path '$($params.SigningCertificateFilePath)'"
                    try
                    {
                        $cert = New-Object -TypeName "System.Security.Cryptography.X509Certificates.X509Certificate2" `
                            -ArgumentList @($params.SigningCertificateFilePath)
                    }
                    catch
                    {
                        $message = ("Signing certificate was not found in path '$($params.SigningCertificateFilePath)'.")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }

                $claimsMappingsArray = @()
                $params.ClaimsMappings | ForEach-Object -Process {
                    $runParams = @{ }
                    $runParams.Add("IncomingClaimTypeDisplayName", $_.Name)
                    $runParams.Add("IncomingClaimType", $_.IncomingClaimType)

                    if ($null -eq $_.LocalClaimType)
                    {
                        $runParams.Add("LocalClaimType", $_.IncomingClaimType)
                    }
                    else
                    {
                        $runParams.Add("LocalClaimType", $_.LocalClaimType)
                    }

                    $newMapping = New-SPClaimTypeMapping @runParams
                    $claimsMappingsArray += $newMapping
                }

                $mappings = ($claimsMappingsArray | Where-Object -FilterScript {
                        $_.InputClaimType -like $params.IdentifierClaim
                    })
                if ($null -eq $mappings)
                {
                    $message = ("IdentifierClaim does not match any claim type specified in ClaimsMappings.")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                $runParams = @{ }
                $runParams.Add("ImportTrustCertificate", $cert)
                $runParams.Add("Name", $params.Name)
                $runParams.Add("Description", $params.Description)
                $runParams.Add("Realm", $params.Realm)
                $runParams.Add("SignInUrl", $params.SignInUrl)
                $runParams.Add("IdentifierClaim", $params.IdentifierClaim)
                $runParams.Add("ClaimsMappings", $claimsMappingsArray)
                $runParams.Add("UseWReply", $params.UseWReplyParameter)
                $trust = New-SPTrustedIdentityTokenIssuer @runParams

                if ($null -eq $trust)
                {
                    $message = "SharePoint failed to create the SPTrustedIdentityTokenIssuer."
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                if ($false -eq [String]::IsNullOrWhiteSpace($params.ClaimProviderName))
                {
                    $claimProvider = (Get-SPClaimProvider | Where-Object -FilterScript {
                            $_.DisplayName -eq $params.ClaimProviderName
                        })
                    if ($null -ne $claimProvider)
                    {
                        $trust.ClaimProviderName = $params.ClaimProviderName
                    }
                }

                if ($params.ProviderSignOutUri)
                {
                    $installedVersion = Get-SPDscInstalledProductVersion
                    # This property does not exist in SharePoint 2013
                    if ($installedVersion.FileMajorPart -ne 15)
                    {
                        $trust.ProviderSignOutUri = New-Object -TypeName System.Uri ($params.ProviderSignOutUri)
                    }
                }
                $trust.Update()
            }
        }
    }
    else
    {
        Write-Verbose "Removing SPTrustedIdentityTokenIssuer '$Name'"
        $null = Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            $Name = $params.Name
            # SPTrustedIdentityTokenIssuer must be removed from each zone of each web app before
            # it can be deleted
            Get-SPWebApplication | ForEach-Object -Process {
                $wa = $_
                $webAppUrl = $wa.Url
                $update = $false
                $urlZones = [Enum]::GetNames([Microsoft.SharePoint.Administration.SPUrlZone])
                $urlZones | ForEach-Object -Process {
                    $zone = $_
                    $providers = Get-SPAuthenticationProvider -WebApplication $wa.Url `
                        -Zone $zone `
                        -ErrorAction SilentlyContinue
                    if (!$providers)
                    {
                        return
                    }
                    $trustedProviderToRemove = $providers | Where-Object -FilterScript {
                        $_ -is [Microsoft.SharePoint.Administration.SPTrustedAuthenticationProvider] `
                            -and $_.LoginProviderName -like $params.Name
                    }
                    if ($trustedProviderToRemove)
                    {
                        Write-Verbose -Message ("Removing SPTrustedAuthenticationProvider " + `
                                "'$Name' from web app '$webAppUrl' in zone " + `
                                "'$zone'")
                        $wa.GetIisSettingsWithFallback($zone).ClaimsAuthenticationProviders.Remove($trustedProviderToRemove) | Out-Null
                        $update = $true
                    }
                }
                if ($update)
                {
                    $wa.Update()
                }
            }

            $runParams = @{
                Identity = $params.Name
                Confirm  = $false
            }
            Remove-SPTrustedIdentityTokenIssuer @runParams
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Description,

        [Parameter(Mandatory = $true)]
        [String]
        $Realm,

        [Parameter(Mandatory = $true)]
        [String]
        $SignInUrl,

        [Parameter(Mandatory = $true)]
        [String]
        $IdentifierClaim,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ClaimsMappings,

        [Parameter()]
        [String]
        $SigningCertificateThumbprint,

        [Parameter()]
        [String]
        $SigningCertificateFilePath,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [String]
        $ClaimProviderName,

        [Parameter()]
        [String]
        $ProviderSignOutUri,

        [Parameter()]
        [System.Boolean]
        $UseWReplyParameter = $false,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPTrustedIdentityTokenIssuer '$Name' settings"

    if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and `
            $PSBoundParameters.ContainsKey("SigningCertificateFilePath"))
    {
        $message = ("Cannot use both parameters SigningCertificateThumbprint and SigningCertificateFilePath at the same time.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -eq $false -and `
            $PSBoundParameters.ContainsKey("SigningCertificateFilePath") -eq $false)
    {
        $message = ("At least one of the following parameters must be specified: " + `
                "SigningCertificateThumbprint, SigningCertificateFilePath.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPTrustedIdentityTokenIssuer\MSFT_SPTrustedIdentityTokenIssuer.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $tips = Get-SPTrustedIdentityTokenIssuer

    $i = 1
    $total = $tips.Length
    foreach ($tip in $tips)
    {
        try
        {
            $tokenName = $tip.Name
            Write-Host "Scanning Trusted Identity Token Issuer [$i/$total] {$tokenName}"

            $PartialContent = ''

            $params.Name = $tokenName
            $params.Description = $tip.Description

            $property = @{
                Handle = 0
            }
            $fake = New-CimInstance -ClassName Win32_Process -Property $property -Key Handle -ClientOnly

            if (!$params.Contains("ClaimsMappings"))
            {
                $params.Add("ClaimsMappings", $fake)
            }
            $results = Get-TargetResource @params

            $foundOne = $false
            foreach ($ctm in $results.ClaimsMappings)
            {
                $ctmResult = Get-SPDscClaimTypeMapping -params $ctm
                if ($null -ne $ctmResult)
                {
                    if (!$foundOne)
                    {
                        $PartialContent += "        `$members = @();`r`n"
                        $foundOne = $true
                    }
                    $PartialContent += "        `$members += " + $ctmResult + ";`r`n"
                }
            }

            if ($foundOne)
            {
                $results.ClaimsMappings = "`$members"
            }

            $PartialContent += "        SPTrustedIdentityTokenIssuer " + [System.Guid]::NewGuid().toString() + "`r`n"
            $PartialContent += "        {`r`n"

            if ($null -ne $results.Get_Item("SigningCertificateThumbprint") -and $results.Contains("SigningCertificateFilePath"))
            {
                $results.Remove("SigningCertificateFilePath")
            }

            if ($results.Contains("InstallAccount"))
            {
                $results.Remove("InstallAccount")
            }
            $results = Repair-Credentials -results $results
            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $Content += $PartialContent
            $i++
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Trusted Identity Token Issuer]" + $tip.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
