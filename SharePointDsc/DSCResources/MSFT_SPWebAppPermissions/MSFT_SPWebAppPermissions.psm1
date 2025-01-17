function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [ValidateSet("Manage Lists", "Override List Behaviors", "Add Items", "Edit Items",
            "Delete Items", "View Items", "Approve Items", "Open Items",
            "View Versions", "Delete Versions", "Create Alerts",
            "View Application Pages")]
        [System.String[]]
        $ListPermissions,

        [Parameter()]
        [ValidateSet("Manage Permissions", "View Web Analytics Data", "Create Subsites",
            "Manage Web Site", "Add and Customize Pages", "Apply Themes and Borders",
            "Apply Style Sheets", "Create Groups", "Browse Directories",
            "Use Self-Service Site Creation", "View Pages", "Enumerate Permissions",
            "Browse User Information", "Manage Alerts", "Use Remote Interfaces",
            "Use Client Integration Features", "Open", "Edit Personal User Information")]
        [System.String[]]
        $SitePermissions,

        [Parameter()]
        [ValidateSet("Manage Personal Views", "Add/Remove Personal Web Parts",
            "Update Personal Web Parts")]
        [System.String[]]
        $PersonalPermissions,

        [Parameter()]
        [System.Boolean]
        $AllPermissions,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting permissions for Web Application '$WebAppUrl'"

    Test-SPDscInput @PSBoundParameters

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa)
        {
            return @{
                WebAppUrl = $params.WebAppUrl
            }
        }

        if ($wa.RightsMask -eq [Microsoft.SharePoint.SPBasePermissions]::FullMask)
        {
            $returnval = @{
                WebAppUrl      = $params.WebAppUrl
                AllPermissions = $true
            }
        }
        else
        {
            $ListPermissions = @()
            $SitePermissions = @()
            $PersonalPermissions = @()

            $rightsmask = ($wa.RightsMask -split ",").trim()
            foreach ($rightmask in $rightsmask)
            {
                switch ($rightmask)
                {
                    "ManageLists"
                    {
                        $ListPermissions += "Manage Lists"
                    }
                    "CancelCheckout"
                    {
                        $ListPermissions += "Override List Behaviors"
                    }
                    "AddListItems"
                    {
                        $ListPermissions += "Add Items"
                    }
                    "EditListItems"
                    {
                        $ListPermissions += "Edit Items"
                    }
                    "DeleteListItems"
                    {
                        $ListPermissions += "Delete Items"
                    }
                    "ViewListItems"
                    {
                        $ListPermissions += "View Items"
                    }
                    "ApproveItems"
                    {
                        $ListPermissions += "Approve Items"
                    }
                    "OpenItems"
                    {
                        $ListPermissions += "Open Items"
                    }
                    "ViewVersions"
                    {
                        $ListPermissions += "View Versions"
                    }
                    "DeleteVersions"
                    {
                        $ListPermissions += "Delete Versions"
                    }
                    "CreateAlerts"
                    {
                        $ListPermissions += "Create Alerts"
                    }
                    "ViewFormPages"
                    {
                        $ListPermissions += "View Application Pages"
                    }

                    "ManagePermissions"
                    {
                        $SitePermissions += "Manage Permissions"
                    }
                    "ViewUsageData"
                    {
                        $SitePermissions += "View Web Analytics Data"
                    }
                    "ManageSubwebs"
                    {
                        $SitePermissions += "Create Subsites"
                    }
                    "ManageWeb"
                    {
                        $SitePermissions += "Manage Web Site"
                    }
                    "AddAndCustomizePages"
                    {
                        $SitePermissions += "Add and Customize Pages"
                    }
                    "ApplyThemeAndBorder"
                    {
                        $SitePermissions += "Apply Themes and Borders"
                    }
                    "ApplyStyleSheets"
                    {
                        $SitePermissions += "Apply Style Sheets"
                    }
                    "CreateGroups"
                    {
                        $SitePermissions += "Create Groups"
                    }
                    "BrowseDirectories"
                    {
                        $SitePermissions += "Browse Directories"
                    }
                    "CreateSSCSite"
                    {
                        $SitePermissions += "Use Self-Service Site Creation"
                    }
                    "ViewPages"
                    {
                        $SitePermissions += "View Pages"
                    }
                    "EnumeratePermissions"
                    {
                        $SitePermissions += "Enumerate Permissions"
                    }
                    "BrowseUserInfo"
                    {
                        $SitePermissions += "Browse User Information"
                    }
                    "ManageAlerts"
                    {
                        $SitePermissions += "Manage Alerts"
                    }
                    "UseRemoteAPIs"
                    {
                        $SitePermissions += "Use Remote Interfaces"
                    }
                    "UseClientIntegration"
                    {
                        $SitePermissions += "Use Client Integration Features"
                    }
                    "Open"
                    {
                        $SitePermissions += "Open"
                    }
                    "EditMyUserInfo"
                    {
                        $SitePermissions += "Edit Personal User Information"
                    }

                    "ManagePersonalViews"
                    {
                        $PersonalPermissions += "Manage Personal Views"
                    }
                    "AddDelPrivateWebParts"
                    {
                        $PersonalPermissions += "Add/Remove Personal Web Parts"
                    }
                    "UpdatePersonalWebParts"
                    {
                        $PersonalPermissions += "Update Personal Web Parts"
                    }
                }
            }

            $returnval = @{
                WebAppUrl           = $params.WebAppUrl
                ListPermissions     = $ListPermissions
                SitePermissions     = $SitePermissions
                PersonalPermissions = $PersonalPermissions
            }
        }
        return $returnval
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [ValidateSet("Manage Lists", "Override List Behaviors", "Add Items", "Edit Items",
            "Delete Items", "View Items", "Approve Items", "Open Items",
            "View Versions", "Delete Versions", "Create Alerts",
            "View Application Pages")]
        [System.String[]]
        $ListPermissions,

        [Parameter()]
        [ValidateSet("Manage Permissions", "View Web Analytics Data", "Create Subsites",
            "Manage Web Site", "Add and Customize Pages", "Apply Themes and Borders",
            "Apply Style Sheets", "Create Groups", "Browse Directories",
            "Use Self-Service Site Creation", "View Pages", "Enumerate Permissions",
            "Browse User Information", "Manage Alerts", "Use Remote Interfaces",
            "Use Client Integration Features", "Open", "Edit Personal User Information")]
        [System.String[]]
        $SitePermissions,

        [Parameter()]
        [ValidateSet("Manage Personal Views", "Add/Remove Personal Web Parts",
            "Update Personal Web Parts")]
        [System.String[]]
        $PersonalPermissions,

        [Parameter()]
        [System.Boolean]
        $AllPermissions,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting permissions for Web Application '$WebAppUrl'"

    Test-SPDscInput @PSBoundParameters

    $result = Get-TargetResource @PSBoundParameters

    if ($AllPermissions)
    {
        $result = Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $wa = Get-SPWebApplication -Identity $params.WebAppUrl `
                -ErrorAction SilentlyContinue

            if ($null -eq $wa)
            {
                $message = "The specified web application could not be found."
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            $wa.RightsMask = [Microsoft.SharePoint.SPBasePermissions]::FullMask
            $wa.Update()
        }
    }
    else
    {
        $result = Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $wa = Get-SPWebApplication -Identity $params.WebAppUrl `
                -ErrorAction SilentlyContinue

            if ($null -eq $wa)
            {
                $message = "The specified web application could not be found."
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            $newMask = [Microsoft.SharePoint.SPBasePermissions]::EmptyMask
            foreach ($lp in $params.ListPermissions)
            {
                switch ($lp)
                {
                    "Manage Lists"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManageLists
                    }
                    "Override List Behaviors"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::CancelCheckout
                    }
                    "Add Items"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::AddListItems
                    }
                    "Edit Items"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::EditListItems
                    }
                    "Delete Items"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::DeleteListItems
                    }
                    "View Items"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ViewListItems
                    }
                    "Approve Items"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ApproveItems
                    }
                    "Open Items"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::OpenItems
                    }
                    "View Versions"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ViewVersions
                    }
                    "Delete Versions"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::DeleteVersions
                    }
                    "Create Alerts"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::CreateAlerts
                    }
                    "View Application Pages"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ViewFormPages
                    }
                }
            }

            foreach ($sp in $params.SitePermissions)
            {
                switch ($sp)
                {
                    "Manage Permissions"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManagePermissions
                    }
                    "View Web Analytics Data"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ViewUsageData
                    }
                    "Create Subsites"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManageSubwebs
                    }
                    "Manage Web Site"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManageWeb
                    }
                    "Add and Customize Pages"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::AddAndCustomizePages
                    }
                    "Apply Themes and Borders"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ApplyThemeAndBorder
                    }
                    "Apply Style Sheets"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ApplyStyleSheets
                    }
                    "Create Groups"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::CreateGroups
                    }
                    "Browse Directories"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::BrowseDirectories
                    }
                    "Use Self-Service Site Creation"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::CreateSSCSite
                    }
                    "View Pages"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ViewPages
                    }
                    "Enumerate Permissions"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::EnumeratePermissions
                    }
                    "Browse User Information"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::BrowseUserInfo
                    }
                    "Manage Alerts"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManageAlerts
                    }
                    "Use Remote Interfaces"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::UseRemoteAPIs
                    }
                    "Use Client Integration Features"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::UseClientIntegration
                    }
                    "Open"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::Open
                    }
                    "Edit Personal User Information"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::EditMyUserInfo
                    }
                }
            }

            foreach ($pp in $params.PersonalPermissions)
            {
                switch ($pp)
                {
                    "Manage Personal Views"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManagePersonalViews
                    }
                    "Add/Remove Personal Web Parts"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::AddDelPrivateWebParts
                    }
                    "Update Personal Web Parts"
                    {
                        $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::UpdatePersonalWebParts
                    }
                }
            }
            $wa.RightsMask = $newMask
            $wa.Update()
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [ValidateSet("Manage Lists", "Override List Behaviors", "Add Items", "Edit Items",
            "Delete Items", "View Items", "Approve Items", "Open Items",
            "View Versions", "Delete Versions", "Create Alerts",
            "View Application Pages")]
        [System.String[]]
        $ListPermissions,

        [Parameter()]
        [ValidateSet("Manage Permissions", "View Web Analytics Data", "Create Subsites",
            "Manage Web Site", "Add and Customize Pages", "Apply Themes and Borders",
            "Apply Style Sheets", "Create Groups", "Browse Directories",
            "Use Self-Service Site Creation", "View Pages", "Enumerate Permissions",
            "Browse User Information", "Manage Alerts", "Use Remote Interfaces",
            "Use Client Integration Features", "Open", "Edit Personal User Information")]
        [System.String[]]
        $SitePermissions,

        [Parameter()]
        [ValidateSet("Manage Personal Views", "Add/Remove Personal Web Parts",
            "Update Personal Web Parts")]
        [System.String[]]
        $PersonalPermissions,

        [Parameter()]
        [System.Boolean]
        $AllPermissions,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing permissions for Web Application '$WebAppUrl'"

    Test-SPDscInput @PSBoundParameters

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($AllPermissions -eq $true)
    {
        if ($CurrentValues.ContainsKey("AllPermissions"))
        {
            $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
                -Source $($MyInvocation.MyCommand.Source) `
                -DesiredValues $PSBoundParameters `
                -ValuesToCheck @("AllPermissions")
        }
        else
        {
            $result = $false
        }
    }
    else
    {
        if ($CurrentValues.ContainsKey("AllPermissions"))
        {
            $source = $MyInvocation.MyCommand.Source
            $EventMessage = "<SPDscEvent>`r`n"
            $EventMessage += "    <ConfigurationDrift Source=`"$source`">`r`n"
            $EventMessage += "        <ParametersNotInDesiredState>`r`n"
            $EventMessage += "            <Param Name=`"AllPermissions`"> AllPermissions is configured, but Desired State has individual permissions specified.</Param>`r`n"
            $EventMessage += "        </ParametersNotInDesiredState>`r`n"
            $EventMessage += "        <DesiredState>`r`n"
            $EventMessage += "            <WebAppUrl>$WebAppUrl</WebAppUrl>`r`n"
            if ($PSBoundParameters.ContainsKey('ListPermissions'))
            {
                $EventMessage += "            <ListPermissions>$($ListPermissions -join ", ")</ListPermissions>`r`n"

            }
            if ($PSBoundParameters.ContainsKey('SitePermissions'))
            {
                $EventMessage += "            <SitePermissions>$($SitePermissions -join ", ")</SitePermissions>`r`n"

            }
            if ($PSBoundParameters.ContainsKey('PersonalPermissions'))
            {
                $EventMessage += "            <PersonalPermissions>$($PersonalPermissions -join ", ")</PersonalPermissions>`r`n"

            }
            $EventMessage += "        </DesiredState>`r`n"
            $EventMessage += "    </ConfigurationDrift>`r`n"
            $EventMessage += "</SPDscEvent>"

            Add-SPDscEvent -Message $EventMessage -EntryType 'Error' -EventID 1 -Source $source

            $result = $false
        }
        else
        {
            $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
                -Source $($MyInvocation.MyCommand.Source) `
                -DesiredValues $PSBoundParameters `
                -ValuesToCheck @("ListPermissions",
                "SitePermissions",
                "PersonalPermissions"
            )
        }
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Test-SPDscInput()
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [ValidateSet("Manage Lists", "Override List Behaviors", "Add Items", "Edit Items",
            "Delete Items", "View Items", "Approve Items", "Open Items",
            "View Versions", "Delete Versions", "Create Alerts",
            "View Application Pages")]
        [System.String[]]
        $ListPermissions,

        [Parameter()]
        [ValidateSet("Manage Permissions", "View Web Analytics Data", "Create Subsites",
            "Manage Web Site", "Add and Customize Pages", "Apply Themes and Borders",
            "Apply Style Sheets", "Create Groups", "Browse Directories",
            "Use Self-Service Site Creation", "View Pages", "Enumerate Permissions",
            "Browse User Information", "Manage Alerts", "Use Remote Interfaces",
            "Use Client Integration Features", "Open", "Edit Personal User Information")]
        [System.String[]]
        $SitePermissions,

        [Parameter()]
        [ValidateSet("Manage Personal Views", "Add/Remove Personal Web Parts",
            "Update Personal Web Parts")]
        [System.String[]]
        $PersonalPermissions,

        [Parameter()]
        [System.Boolean]
        $AllPermissions,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    if ($AllPermissions)
    {
        # AllPermissions parameter specified with and one of the other parameters
        if ($ListPermissions -or $SitePermissions -or $PersonalPermissions)
        {
            $message = ("Do not specify parameters ListPermissions, SitePermissions " + `
                    "or PersonalPermissions when specifying parameter AllPermissions")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }
    else
    {
        # You have to specify all three parameters
        if (-not ($ListPermissions -and $SitePermissions -and $PersonalPermissions))
        {
            $message = ("One of the parameters ListPermissions, SitePermissions or " + `
                    "PersonalPermissions is missing")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    #Checks
    if ($ListPermissions -contains "Approve Items" -and -not ($ListPermissions -contains "Edit Items"))
    {
        $message = "Edit Items is required when specifying Approve Items"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($ListPermissions -contains "Manage Lists" `
                -or $ListPermissions -contains "Override List Behaviors" `
                -or $ListPermissions -contains "Add Items" `
                -or $ListPermissions -contains "Edit Items" `
                -or $ListPermissions -contains "Delete Items" `
                -or $ListPermissions -contains "Approve Items" `
                -or $ListPermissions -contains "Open Items" `
                -or $ListPermissions -contains "View Versions" `
                -or $ListPermissions -contains "Delete Versions" `
                -or $ListPermissions -contains "Create Alerts" `
                -or $SitePermissions -contains "Manage Permissions" `
                -or $SitePermissions -contains "Manage Web Site" `
                -or $SitePermissions -contains "Add and Customize Pages" `
                -or $SitePermissions -contains "Manage Alerts" `
                -or $SitePermissions -contains "Use Client Integration Features" `
                -or $PersonalPermissions -contains "Manage Personal Views" `
                -or $PersonalPermissions -contains "Add/Remove Personal Web Parts" `
                -or $PersonalPermissions -contains "Update Personal Web Parts") `
            -and -not ($ListPermissions -contains "View Items"))
    {
        $message = ("View Items is required when specifying Manage Lists, Override List Behaviors, " + `
                "Add Items, Edit Items, Delete Items, Approve Items, Open Items, View " + `
                "Versions, Delete Versions, Create Alerts, Manage Permissions, Manage Web Site, " + `
                "Add and Customize Pages, Manage Alerts, Use Client Integration Features, " + `
                "Manage Personal Views, Add/Remove Personal Web Parts or Update Personal Web Parts")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($ListPermissions -contains "View Versions" `
                -or $SitePermissions -contains "Manage Permissions") `
            -and -not ($ListPermissions -contains "Open Items"))
    {
        $message = "Open Items is required when specifying View Versions or Manage Permissions"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($ListPermissions -contains "Delete Versions" `
                -or $SitePermissions -contains "Manage Permissions") `
            -and -not ($ListPermissions -contains "View Versions"))
    {
        $message = "View Versions is required when specifying Delete Versions or Manage Permissions"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($SitePermissions -contains "Manage Alerts" `
            -and -not ($ListPermissions -contains "Create Alerts"))
    {
        $message = "Create Alerts is required when specifying Manage Alerts"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($SitePermissions -contains "Manage Web Site" `
            -and -not ($SitePermissions -contains "Add and Customize Pages"))
    {
        $message = "Add and Customize Pages is required when specifying Manage Web Site"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($SitePermissions -contains "Manage Permissions" `
                -or $SitePermissions -contains "Manage Web Site" `
                -or $SitePermissions -contains "Add and Customize Pages" `
                -or $SitePermissions -contains "Enumerate Permissions") `
            -and -not ($SitePermissions -contains "Browse Directories"))
    {
        $message = ("Browse Directories is required when specifying Manage Permissions, Manage Web " + `
                "Site, Add and Customize Pages or Enumerate Permissions")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($ListPermissions -contains "Manage Lists" `
                -or $ListPermissions -contains "Override List Behaviors" `
                -or $ListPermissions -contains "Add Items" `
                -or $ListPermissions -contains "Edit Items" `
                -or $ListPermissions -contains "Delete Items" `
                -or $ListPermissions -contains "View Items" `
                -or $ListPermissions -contains "Approve Items" `
                -or $ListPermissions -contains "Open Items" `
                -or $ListPermissions -contains "View Versions" `
                -or $ListPermissions -contains "Delete Versions" `
                -or $ListPermissions -contains "Create Alerts" `
                -or $SitePermissions -contains "Manage Permissions" `
                -or $SitePermissions -contains "View Web Analytics Data" `
                -or $SitePermissions -contains "Create Subsites" `
                -or $SitePermissions -contains "Manage Web Site" `
                -or $SitePermissions -contains "Add and Customize Pages" `
                -or $SitePermissions -contains "Apply Themes and Borders" `
                -or $SitePermissions -contains "Apply Style Sheets" `
                -or $SitePermissions -contains "Create Groups" `
                -or $SitePermissions -contains "Browse Directories" `
                -or $SitePermissions -contains "Use Self-Service Site Creation" `
                -or $SitePermissions -contains "Enumerate Permissions" `
                -or $SitePermissions -contains "Manage Alerts" `
                -or $PersonalPermissions -contains "Manage Personal Views" `
                -or $PersonalPermissions -contains "Add/Remove Personal Web Parts" `
                -or $PersonalPermissions -contains "Update Personal Web Parts") `
            -and -not ($SitePermissions -contains "View Pages"))
    {
        $message = ("View Pages is required when specifying Manage Lists, Override List Behaviors, " + `
                "Add Items, Edit Items, Delete Items, View Items, Approve Items, Open Items, " + `
                "View Versions, Delete Versions, Create Alerts, Manage Permissions, View Web " + `
                "Analytics Data, Create Subsites, Manage Web Site, Add and Customize Pages, " + `
                "Apply Themes and Borders, Apply Style Sheets, Create Groups, Browse " + `
                "Directories, Use Self-Service Site Creation, Enumerate Permissions, Manage " + `
                "Alerts, Manage Personal Views, Add/Remove Personal Web Parts or Update " + `
                "Personal Web Parts")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($SitePermissions -contains "Manage Permissions" `
                -or $SitePermissions -contains "Manage Web Site") `
            -and -not ($SitePermissions -contains "Enumerate Permissions"))
    {
        $message = ("Enumerate Permissions is required when specifying Manage Permissions or " + `
                "Manage Web Site")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($SitePermissions -contains "Manage Permissions" `
                -or $SitePermissions -contains "Create Subsites" `
                -or $SitePermissions -contains "Manage Web Site" `
                -or $SitePermissions -contains "Create Groups" `
                -or $SitePermissions -contains "Use Self-Service Site Creation" `
                -or $SitePermissions -contains "Enumerate Permissions" `
                -or $SitePermissions -contains "Edit Personal User Information") `
            -and -not ($SitePermissions -contains "Browse User Information"))
    {
        $message = ("Browse User Information is required when specifying Manage Permissions, " + `
                "Create Subsites, Manage Web Site, Create Groups, Use Self-Service Site " + `
                "Creation, Enumerate Permissions or Edit Personal User Information")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($SitePermissions -contains "Use Client Integration Features" `
            -and -not ($SitePermissions -contains "Use Remote Interfaces"))
    {
        $message = "Use Remote Interfaces is required when specifying Use Client Integration Features"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($ListPermissions -contains "Manage Lists" `
                -or $ListPermissions -contains "Override List Behaviors" `
                -or $ListPermissions -contains "Add Items" `
                -or $ListPermissions -contains "Edit Items" `
                -or $ListPermissions -contains "Delete Items" `
                -or $ListPermissions -contains "View Items" `
                -or $ListPermissions -contains "Approve Items" `
                -or $ListPermissions -contains "Open Items" `
                -or $ListPermissions -contains "View Versions" `
                -or $ListPermissions -contains "Delete Versions" `
                -or $ListPermissions -contains "Create Alerts" `
                -or $ListPermissions -contains "View Application Pages" `
                -or $SitePermissions -contains "Manage Permissions" `
                -or $SitePermissions -contains "View Web Analytics Data" `
                -or $SitePermissions -contains "Create Subsites" `
                -or $SitePermissions -contains "Manage Web Site" `
                -or $SitePermissions -contains "Add and Customize Pages" `
                -or $SitePermissions -contains "Apply Themes and Borders" `
                -or $SitePermissions -contains "Apply Style Sheets" `
                -or $SitePermissions -contains "Create Groups" `
                -or $SitePermissions -contains "Browse Directories" `
                -or $SitePermissions -contains "Use Self-Service Site Creation" `
                -or $SitePermissions -contains "View Pages" `
                -or $SitePermissions -contains "Enumerate Permissions" `
                -or $SitePermissions -contains "Browse User Information" `
                -or $SitePermissions -contains "Manage Alerts" `
                -or $SitePermissions -contains "Use Remote Interfaces" `
                -or $SitePermissions -contains "Use Client Integration Features" `
                -or $SitePermissions -contains "Edit Personal User Information" `
                -or $PersonalPermissions -contains "Manage Personal Views" `
                -or $PersonalPermissions -contains "Add/Remove Personal Web Parts" `
                -or $PersonalPermissions -contains "Update Personal Web Parts") `
            -and -not ($SitePermissions -contains "Open"))
    {
        $message = "Open is required when specifying any of the other permissions"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PersonalPermissions -contains "Add/Remove Personal Web Parts" `
            -and -not ($PersonalPermissions -contains "Update Personal Web Parts"))
    {
        $message = "Update Personal Web Parts is required when specifying Add/Remove Personal Web Parts"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPWebAppPermissions\MSFT_SPWebAppPermissions.psm1" -Resolve
    $params = Get-DSCFakeParameters -ModulePath $module
    $Content = ''
    $webApps = Get-SPWebApplication
    foreach ($wa in $webApps)
    {
        try
        {
            if ($null -ne $wa)
            {
                $params.WebAppUrl = $wa.Url
                $params.Remove("ListPermissions")
                $params.Remove("SitePermissions")
                $params.Remove("PersonalPermissions")
                $PartialContent = "        SPWebAppPermissions " + [System.Guid]::NewGuid().toString() + "`r`n"
                $PartialContent += "        {`r`n"
                $results = Get-TargetResource @params

                if ($results.Contains("InstallAccount"))
                {
                    $results.Remove("InstallAccount")
                }

                <# Fix an issue with SP DSC (forward) 1.6.0.0 #>
                if ($results.WebAppUrl -eq "url")
                {
                    $results.WebAppUrl = $wa.Url
                }
                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
            }
        }
        catch
        {
            $Global:ErrorLog += "[Web Application Permissions]" + $wa.Url + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
        $Content += $PartialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
