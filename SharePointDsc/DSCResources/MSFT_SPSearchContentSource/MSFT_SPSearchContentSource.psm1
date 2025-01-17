function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("SharePoint", "Website", "FileShare", "Business")]
        [System.String]
        $ContentSourceType,

        [Parameter()]
        [System.String[]]
        $Addresses,

        [Parameter()]
        [ValidateSet("CrawlEverything", "CrawlFirstOnly", "CrawlVirtualServers", "CrawlSites", "Custom")]
        [System.String]
        $CrawlSetting,

        [Parameter()]
        [System.Boolean]
        $ContinuousCrawl,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $IncrementalSchedule,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $FullSchedule,

        [Parameter()]
        [ValidateSet("Normal", "High")]
        [System.String]
        $Priority,

        [Parameter()]
        [System.UInt32]
        $LimitPageDepth,

        [Parameter()]
        [System.UInt32]
        $LimitServerHops,

        [Parameter()]
        [System.String[]]
        $LOBSystemSet,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Boolean]
        $Force,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Content Source Setting for '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $PSScriptRoot) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $ScriptRoot = $args[2]

        $relativePath = "..\..\Modules\SharePointDsc.Search\SPSearchContentSource.Schedules.psm1"
        $modulePath = Join-Path -Path $ScriptRoot `
            -ChildPath $relativePath `
            -Resolve
        Import-Module -Name $modulePath

        $source = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName `
            -ErrorAction SilentlyContinue | `
                Where-Object { $_.Name -eq $params.Name }
        if ($null -eq $source)
        {
            return @{
                Name              = $params.Name
                ServiceAppName    = $params.ServiceAppName
                ContentSourceType = $params.ContentSourceType
                Ensure            = "Absent"
            }
        }

        switch ($source.Type)
        {
            "SharePoint"
            {
                $crawlSetting = "CrawlVirtualServers"
                if ($source.SharePointCrawlBehavior -eq "CrawlSites")
                {
                    $crawlSetting = "CrawlSites"
                }

                $incrementalSchedule = Get-SPDscSearchCrawlSchedule `
                    -Schedule $source.IncrementalCrawlSchedule
                $fullSchedule = Get-SPDscSearchCrawlSchedule `
                    -Schedule $source.FullCrawlSchedule

                $result = @{
                    Name                = $params.Name
                    ServiceAppName      = $params.ServiceAppName
                    Ensure              = "Present"
                    ContentSourceType   = "SharePoint"
                    Addresses           = [array] $source.StartAddresses.AbsoluteUri
                    CrawlSetting        = $crawlSetting
                    ContinuousCrawl     = $source.EnableContinuousCrawls
                    IncrementalSchedule = $incrementalSchedule
                    FullSchedule        = $fullSchedule
                    Priority            = $source.CrawlPriority
                }
            }
            "Web"
            {
                $crawlSetting = "Custom"
                if ($source.MaxPageEnumerationDepth -eq [System.Int32]::MaxValue)
                {
                    $crawlSetting = "CrawlEverything"
                }
                if ($source.MaxPageEnumerationDepth -eq 0)
                {
                    $crawlSetting = "CrawlFirstOnly"
                }

                $incrementalSchedule = Get-SPDscSearchCrawlSchedule `
                    -Schedule $source.IncrementalCrawlSchedule
                $fullSchedule = Get-SPDscSearchCrawlSchedule `
                    -Schedule $source.FullCrawlSchedule

                $result = @{
                    Name                = $params.Name
                    ServiceAppName      = $params.ServiceAppName
                    Ensure              = "Present"
                    ContentSourceType   = "Website"
                    Addresses           = [array] $source.StartAddresses.AbsoluteUri
                    CrawlSetting        = $crawlSetting
                    IncrementalSchedule = $incrementalSchedule
                    FullSchedule        = $fullSchedule
                    LimitPageDepth      = $source.MaxPageEnumerationDepth
                    LimitServerHops     = $source.MaxSiteEnumerationDepth
                    Priority            = $source.CrawlPriority
                }
            }
            "File"
            {
                $crawlSetting = "CrawlFirstOnly"
                if ($source.FollowDirectories -eq $true)
                {
                    $crawlSetting = "CrawlEverything"
                }

                $addresses = [array] $source.StartAddresses.AbsoluteUri
                $addresses = $addresses.Replace("file:///", "\\").Replace("/", "\")

                $incrementalSchedule = Get-SPDscSearchCrawlSchedule `
                    -Schedule $source.IncrementalCrawlSchedule
                $fullSchedule = Get-SPDscSearchCrawlSchedule `
                    -Schedule $source.FullCrawlSchedule

                $result = @{
                    Name                = $params.Name
                    ServiceAppName      = $params.ServiceAppName
                    Ensure              = "Present"
                    ContentSourceType   = "FileShare"
                    Addresses           = $addresses
                    CrawlSetting        = $crawlSetting
                    IncrementalSchedule = $incrementalSchedule
                    FullSchedule        = $fullSchedule
                    Priority            = $source.CrawlPriority
                }
            }
            "Business"
            {
                $result = @{
                    Name                = $params.Name
                    ServiceAppName      = $params.ServiceAppName
                    Ensure              = "Present"
                    ContentSourceType   = "Business"
                    CrawlSetting        = $crawlSetting
                    IncrementalSchedule = $incrementalSchedule
                    FullSchedule        = $fullSchedule
                    Priority            = $source.CrawlPriority
                }

                if ($null -ne $params.LOBSystemSet)
                {
                    $bdcSegments = $source.StartAddresses[0].Segments
                    if ($bdcSegments.Length -ge 5)
                    {
                        [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
                        $LOBSystemName = [System.Web.HttpUtility]::UrlDecode($bdcSegments[4].Replace("/", ""))
                        $LOBSystemInstanceName = [System.Web.HttpUtility]::UrlDecode($bdcSegments[5].Split('&')[0])
                        $LOBSystemSet = @($LOBSystemName, $LOBSystemInstanceName)
                        $result.Add("LOBSystemSet", $LOBSystemSet)
                    }
                }
            }
            Default
            {
                $message = ("SharePointDsc does not currently support '$($source.Type)' content " + `
                        "sources. Please use only 'SharePoint', 'FileShare', 'Website' or 'Business'.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
        }
        return $result
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
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("SharePoint", "Website", "FileShare", "Business")]
        [System.String]
        $ContentSourceType,

        [Parameter()]
        [System.String[]]
        $Addresses,

        [Parameter()]
        [ValidateSet("CrawlEverything", "CrawlFirstOnly", "CrawlVirtualServers", "CrawlSites", "Custom")]
        [System.String]
        $CrawlSetting,

        [Parameter()]
        [System.Boolean]
        $ContinuousCrawl,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $IncrementalSchedule,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $FullSchedule,

        [Parameter()]
        [ValidateSet("Normal", "High")]
        [System.String]
        $Priority,

        [Parameter()]
        [System.UInt32]
        $LimitPageDepth,

        [Parameter()]
        [System.UInt32]
        $LimitServerHops,

        [Parameter()]
        [System.String[]]
        $LOBSystemSet,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Boolean]
        $Force,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Content Source Setting for '$Name'"

    switch ($ContentSourceType)
    {
        "SharePoint"
        {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true)
            {
                $message = "Parameter LimitPageDepth is not valid for SharePoint content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true)
            {
                $message = "Parameter LimitServerHops is not valid for SharePoint content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($CrawlSetting -ne "CrawlVirtualServers" -and
                $CrawlSetting -ne "CrawlSites"
            )
            {
                $message = ("Parameter CrawlSetting can only be set to CrawlVirtualServers or CrawlSites " + `
                        "for SharePoint content sources")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        "Website"
        {
            if ($PSBoundParameters.ContainsKey("ContinuousCrawl") -eq $true)
            {
                $message = "Parameter ContinuousCrawl is not valid for Website content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true)
            {
                $message = "Parameter LimitServerHops is not valid for Website content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        "FileShare"
        {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true)
            {
                $message = "Parameter LimitPageDepth is not valid for FileShare content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true)
            {
                $message = "Parameter LimitServerHops is not valid for FileShare content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($CrawlSetting -eq "Custom")
            {
                $message = "Parameter CrawlSetting can only be set to custom for website content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        "Business"
        {
            if ($PSBoundParameters.ContainsKey("ContinuousCrawl") -eq $true)
            {
                $message = "Parameter ContinuousCrawl is not valid for Business content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true)
            {
                $message = "Parameter LimitPageDepth is not valid for Business content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true)
            {
                $message = "Parameter LimitServerHops is not valid for Business content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($ContentSourceType -ne $CurrentValues.ContentSourceType -and $Force -eq $false)
    {
        $message = ("The type of the a search content source can not be changed from " + `
                "'$($CurrentValues.ContentSourceType)' to '$ContentSourceType' without " + `
                "deleting and adding it again. Specify 'Force = `$true' in order to allow " + `
                "DSC to do this, or manually remove the existing content source and re-run " + `
                "the configuration.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($ContentSourceType -ne $CurrentValues.ContentSourceType -and $Force -eq $true) `
            -or ($Ensure -eq "Absent" -and $CurrentValues.Ensure -ne $Ensure))
    {
        # Remove the existing content source
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters) `
            -ScriptBlock {
            $params = $args[0]
            Remove-SPEnterpriseSearchCrawlContentSource -Identity $params.Name `
                -SearchApplication $params.ServiceAppName `
                -Confirm:$false
        }
    }

    if ($Ensure -eq "Present")
    {
        # Create the new content source and then apply settings to it
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $OFS = ","
            $startAddresses = "$($params.Addresses)"

            $source = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName `
                -ErrorAction SilentlyContinue | `
                    Where-Object { $_.Name -eq $params.Name }

            if ($null -eq $source)
            {
                switch ($params.ContentSourceType)
                {
                    "SharePoint"
                    {
                        $newType = "SharePoint"
                        $newCrawlSetting = $crawlSetting
                    }
                    "Website"
                    {
                        $newType = "Web"
                    }
                    "FileShare"
                    {
                        $newType = "File"
                    }
                    "Business"
                    {
                        $newType = "Business"
                    }
                }
                if ($params.ContentSourceType -eq "SharePoint")
                {
                    $source = New-SPEnterpriseSearchCrawlContentSource `
                        -SearchApplication $params.ServiceAppName `
                        -Type $newType `
                        -Name $params.Name `
                        -StartAddresses $startAddresses `
                        -SharePointCrawlBehavior $newCrawlSetting
                }
                elseif ($params.ContentSourceType -ne "Business")
                {
                    $source = New-SPEnterpriseSearchCrawlContentSource `
                        -SearchApplication $params.ServiceAppName `
                        -Type $newType `
                        -Name $params.Name `
                        -StartAddresses $startAddresses
                }
                else
                {
                    $proxyGroup = Get-SPServiceApplicationProxyGroup -Default
                    $source = New-SPEnterpriseSearchCrawlContentSource `
                        -SearchApplication $params.ServiceAppName `
                        -Type $newType `
                        -Name $params.Name `
                        -BDCApplicationProxyGroup $proxyGroup `
                        -LOBSystemSet $params.LOBSystemSet
                }

                if ($null -eq $source)
                {
                    $message = ("An error occurred during creation of the Content Source, " + `
                            "please check if all parameters are correct.")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
            }

            $allSetArguments = @{
                Identity          = $params.Name
                SearchApplication = $params.ServiceAppName
                Confirm           = $false
            }

            if ($params.ContentSourceType -eq "SharePoint" -and `
                    $source.EnableContinuousCrawls -eq $true)
            {
                Set-SPEnterpriseSearchCrawlContentSource @allSetArguments `
                    -EnableContinuousCrawls $false
                Write-Verbose -Message ("Pausing to allow Continuous Crawl to shut down " + `
                        "correctly before continuing updating the configuration.")
                Start-Sleep -Seconds 300
            }

            if ($source.CrawlStatus -ne "Idle")
            {
                Write-Verbose -Message ("Content source '$($params.Name)' is not idle, " + `
                        "stopping current crawls to allow settings to be updated")

                $source = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName | `
                        Where-Object { $_.Name -eq $params.Name }

                $source.StopCrawl()
                $loopCount = 0

                $sourceToWait = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName | `
                        Where-Object { $_.Name -eq $params.Name }

                while ($sourceToWait.CrawlStatus -ne "Idle" -and $loopCount -lt 15)
                {
                    $sourceToWait = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName | `
                            Where-Object { $_.Name -eq $params.Name }

                    Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - Waiting " + `
                            "for content source '$($params.Name)' to be idle " + `
                            "(waited $loopCount of 15 minutes)")
                    Start-Sleep -Seconds 60
                    $loopCount++
                }
            }

            $primarySetArgs = @{
                StartAddresses = $startAddresses
            }

            if ($params.ContainsKey("ContinuousCrawl") -eq $true)
            {
                $primarySetArgs.Add("EnableContinuousCrawls", $params.ContinuousCrawl)
            }

            if ($params.ContainsKey("Priority") -eq $true)
            {
                switch ($params.Priority)
                {
                    "High"
                    {
                        $primarySetArgs.Add("CrawlPriority", "2")
                    }
                    "Normal"
                    {
                        $primarySetArgs.Add("CrawlPriority", "1")
                    }
                }
            }

            Set-SPEnterpriseSearchCrawlContentSource @allSetArguments @primarySetArgs

            # Set the incremental search values
            if ($params.ContainsKey("IncrementalSchedule") -eq $true -and `
                    $null -ne $params.IncrementalSchedule)
            {
                $incrementalSetArgs = @{
                    ScheduleType = "Incremental"
                }
                switch ($params.IncrementalSchedule.ScheduleType)
                {
                    "None"
                    {
                        $incrementalSetArgs.Add("RemoveCrawlSchedule", $true)
                    }
                    "Daily"
                    {
                        $incrementalSetArgs.Add("DailyCrawlSchedule", $true)
                    }
                    "Weekly"
                    {
                        $incrementalSetArgs.Add("WeeklyCrawlSchedule", $true)
                        $propertyTest = Test-SPDscObjectHasProperty `
                            -Object $params.IncrementalSchedule `
                            -PropertyName "CrawlScheduleDaysOfWeek"

                        if ($propertyTest -eq $true)
                        {
                            $OFS = ","
                            $enumValue = `
                                [enum]::Parse([Microsoft.Office.Server.Search.Administration.DaysOfWeek], `
                                    "$($params.IncrementalSchedule.CrawlScheduleDaysOfWeek)")

                            $incrementalSetArgs.Add("CrawlScheduleDaysOfWeek", $enumValue)
                        }
                    }
                    "Monthly"
                    {
                        $incrementalSetArgs.Add("MonthlyCrawlSchedule", $true)
                        $propertyTest = Test-SPDscObjectHasProperty `
                            -Object $params.IncrementalSchedule `
                            -PropertyName "CrawlScheduleDaysOfMonth"

                        if ($propertyTest -eq $true)
                        {
                            $incrementalSetArgs.Add("CrawlScheduleDaysOfMonth", `
                                    $params.IncrementalSchedule.CrawlScheduleDaysOfMonth)
                        }

                        $propertyTest = Test-SPDscObjectHasProperty `
                            -Object $params.IncrementalSchedule `
                            -PropertyName "CrawlScheduleMonthsOfYear"

                        if ($propertyTest -eq $true)
                        {
                            foreach ($month in $params.IncrementalSchedule.CrawlScheduleMonthsOfYear)
                            {
                                $months += [Microsoft.Office.Server.Search.Administration.MonthsOfYear]::$month
                            }
                            $incrementalSetArgs.Add("CrawlScheduleMonthsOfYear", $months)
                        }
                    }
                }

                $propertyTest = Test-SPDscObjectHasProperty -Object $params.IncrementalSchedule `
                    -PropertyName "CrawlScheduleRepeatDuration"
                if ($propertyTest -eq $true)
                {
                    $incrementalSetArgs.Add("CrawlScheduleRepeatDuration",
                        $params.IncrementalSchedule.CrawlScheduleRepeatDuration)
                }

                $propertyTest = Test-SPDscObjectHasProperty -Object $params.IncrementalSchedule `
                    -PropertyName "CrawlScheduleRepeatInterval"
                if ($propertyTest -eq $true)
                {
                    $incrementalSetArgs.Add("CrawlScheduleRepeatInterval",
                        $params.IncrementalSchedule.CrawlScheduleRepeatInterval)
                }

                $propertyTest = Test-SPDscObjectHasProperty -Object $params.IncrementalSchedule `
                    -PropertyName "CrawlScheduleRunEveryInterval"
                if ($propertyTest -eq $true)
                {
                    $incrementalSetArgs.Add("CrawlScheduleRunEveryInterval",
                        $params.IncrementalSchedule.CrawlScheduleRunEveryInterval)
                }

                $propertyTest = Test-SPDscObjectHasProperty -Object $params.IncrementalSchedule `
                    -PropertyName "StartHour"
                if ($propertyTest -eq $true)
                {
                    $incrementalSetArgs.Add("CrawlScheduleStartDateTime",
                        "$($params.IncrementalSchedule.StartHour):$($params.IncrementalSchedule.StartMinute)")
                }
                Set-SPEnterpriseSearchCrawlContentSource @allSetArguments @incrementalSetArgs
            }

            # Set the full search values
            if ($params.ContainsKey("FullSchedule") -eq $true)
            {
                $fullSetArgs = @{
                    ScheduleType = "Full"
                }
                switch ($params.FullSchedule.ScheduleType)
                {
                    "None"
                    {
                        $fullSetArgs.Add("RemoveCrawlSchedule", $true)
                    }
                    "Daily"
                    {
                        $fullSetArgs.Add("DailyCrawlSchedule", $true)
                    }
                    "Weekly"
                    {
                        $fullSetArgs.Add("WeeklyCrawlSchedule", $true)
                        $propertyTest = Test-SPDscObjectHasProperty -Object $params.FullSchedule `
                            -PropertyName "CrawlScheduleDaysOfWeek"
                        if ($propertyTest -eq $true)
                        {
                            foreach ($day in $params.FullSchedule.CrawlScheduleDaysOfWeek)
                            {
                                $daysOfweek += [Microsoft.Office.Server.Search.Administration.DaysOfWeek]::$day
                            }
                            $fullSetArgs.Add("CrawlScheduleDaysOfWeek", $daysOfweek)
                        }
                    }
                    "Monthly"
                    {
                        $fullSetArgs.Add("MonthlyCrawlSchedule", $true)
                        $propertyTest = Test-SPDscObjectHasProperty -Object $params.FullSchedule `
                            -PropertyName "CrawlScheduleDaysOfMonth"
                        if ($propertyTest -eq $true)
                        {
                            $fullSetArgs.Add("CrawlScheduleDaysOfMonth",
                                $params.FullSchedule.CrawlScheduleDaysOfMonth)
                        }

                        $propertyTest = Test-SPDscObjectHasProperty -Object $params.FullSchedule `
                            -PropertyName "CrawlScheduleMonthsOfYear"
                        if ($propertyTest -eq $true)
                        {
                            foreach ($month in $params.FullSchedule.CrawlScheduleMonthsOfYear)
                            {
                                $months += [Microsoft.Office.Server.Search.Administration.MonthsOfYear]::$month
                            }
                            $fullSetArgs.Add("CrawlScheduleMonthsOfYear", $months)
                        }
                    }
                }

                $propertyTest = Test-SPDscObjectHasProperty -Object $params.FullSchedule `
                    -PropertyName "CrawlScheduleRepeatDuration"
                if ($propertyTest -eq $true)
                {
                    $fullSetArgs.Add("CrawlScheduleRepeatDuration",
                        $params.FullSchedule.CrawlScheduleRepeatDuration)
                }

                $propertyTest = Test-SPDscObjectHasProperty -Object $params.FullSchedule `
                    -PropertyName "CrawlScheduleRepeatInterval"
                if ($propertyTest -eq $true)
                {
                    $fullSetArgs.Add("CrawlScheduleRepeatInterval",
                        $params.FullSchedule.CrawlScheduleRepeatInterval)
                }

                $propertyTest = Test-SPDscObjectHasProperty -Object $params.FullSchedule `
                    -PropertyName "CrawlScheduleRunEveryInterval"
                if ($propertyTest -eq $true)
                {
                    $fullSetArgs.Add("CrawlScheduleRunEveryInterval",
                        $params.FullSchedule.CrawlScheduleRunEveryInterval)
                }

                $propertyTest = Test-SPDscObjectHasProperty -Object $params.FullSchedule `
                    -PropertyName "StartHour"
                if ($propertyTest -eq $true)
                {
                    $fullSetArgs.Add("CrawlScheduleStartDateTime",
                        "$($params.FullSchedule.StartHour):$($params.FullSchedule.StartMinute)")
                }
                Set-SPEnterpriseSearchCrawlContentSource @allSetArguments @fullSetArgs
            }
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
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("SharePoint", "Website", "FileShare", "Business")]
        [System.String]
        $ContentSourceType,

        [Parameter()]
        [System.String[]]
        $Addresses,

        [Parameter()]
        [ValidateSet("CrawlEverything", "CrawlFirstOnly", "CrawlVirtualServers", "CrawlSites", "Custom")]
        [System.String]
        $CrawlSetting,

        [Parameter()]
        [System.Boolean]
        $ContinuousCrawl,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $IncrementalSchedule,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $FullSchedule,

        [Parameter()]
        [ValidateSet("Normal", "High")]
        [System.String]
        $Priority,

        [Parameter()]
        [System.UInt32]
        $LimitPageDepth,

        [Parameter()]
        [System.UInt32]
        $LimitServerHops,

        [Parameter()]
        [System.String[]]
        $LOBSystemSet,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Boolean]
        $Force,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Content Source Setting for '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    switch ($ContentSourceType)
    {
        "SharePoint"
        {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true)
            {
                $message = "Parameter LimitPageDepth is not valid for SharePoint content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true)
            {
                $message = "Parameter LimitServerHops is not valid for SharePoint content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($CrawlSetting -ne "CrawlVirtualServers" -and
                $CrawlSetting -ne "CrawlSites"
            )
            {
                $message = ("Parameter CrawlSetting can only be set to CrawlVirtualServers or CrawlSites " + `
                        "for SharePoint content sources")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        "Website"
        {
            if ($PSBoundParameters.ContainsKey("ContinuousCrawl") -eq $true)
            {
                $message = "Parameter ContinuousCrawl is not valid for Website content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true)
            {
                $message = "Parameter LimitServerHops is not valid for Website content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        "FileShare"
        {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true)
            {
                $message = "Parameter LimitPageDepth is not valid for FileShare content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true)
            {
                $message = "Parameter LimitServerHops is not valid for FileShare content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($CrawlSetting -eq "Custom")
            {
                $message = "Parameter CrawlSetting can only be set to custom for website content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        "Business"
        {
            if ($PSBoundParameters.ContainsKey("ContinuousCrawl") -eq $true)
            {
                $message = "Parameter ContinuousCrawl is not valid for Business content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true)
            {
                $message = "Parameter LimitPageDepth is not valid for Business content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true)
            {
                $message = "Parameter LimitServerHops is not valid for Business content sources"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Absent" -or $CurrentValues.Ensure -eq "Absent")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")

        Write-Verbose -Message "Test-TargetResource returned $result"

        return $result
    }

    $relativePath = "..\..\Modules\SharePointDsc.Search\SPSearchContentSource.Schedules.psm1"
    $modulePath = Join-Path -Path $PSScriptRoot `
        -ChildPath $relativePath `
        -Resolve
    Import-Module -Name $modulePath

    if (($PSBoundParameters.ContainsKey("IncrementalSchedule") -eq $true) -and ($null -ne $IncrementalSchedule))
    {
        $propertyTest = Test-SPDscSearchCrawlSchedule -CurrentSchedule $CurrentValues.IncrementalSchedule `
            -DesiredSchedule $IncrementalSchedule
        if ($propertyTest -eq $false)
        {
            $message = ("Specified IncrementalSchedule does not match desired state.")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if (($PSBoundParameters.ContainsKey("FullSchedule") -eq $true) -and ($null -ne $FullSchedule))
    {
        $propertyTest = Test-SPDscSearchCrawlSchedule -CurrentSchedule $CurrentValues.FullSchedule `
            -DesiredSchedule $FullSchedule
        if ($propertyTest -eq $false)
        {
            $message = ("Specified FullSchedule does not match desired state.")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    # Compare the addresses as Uri objects to handle things like trailing /'s on URLs
    $currentAddresses = @()
    foreach ($address in $CurrentValues.Addresses)
    {
        $currentAddresses += New-Object -TypeName System.Uri -ArgumentList $address
    }
    $desiredAddresses = @()
    foreach ($address in $Addresses)
    {
        $desiredAddresses += New-Object -TypeName System.Uri -ArgumentList $address
    }

    if ($null -ne (Compare-Object -ReferenceObject $currentAddresses `
                -DifferenceObject $desiredAddresses))
    {
        $message = ("Specified addresses do not match desired state: " + `
                "Actual: $($currentAddresses -join ", ") Desired: " + `
                "$($desiredAddresses -join ", ")")
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("ContentSourceType",
            "CrawlSetting",
            "ContinuousCrawl",
            "Priority",
            "LimitPageDepth",
            "LimitServerHops",
            "LOBSystemSet",
            "Ensure")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $SearchSAName,

        [Parameter()]
        [System.String[]]
        $DependsOn
    )

    $VerbosePreference = "SilentlyContinue"
    $content = ''
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPSearchContentSource\MSFT_SPSearchContentSource.psm1" -Resolve

    $params = Get-DSCFakeParameters -ModulePath $module

    $contentSources = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $searchSAName

    $j = 1
    $totalCS = $contentSources.Length
    foreach ($contentSource in $contentSources)
    {
        try
        {
            $csName = $contentSource.Name
            Write-Host "    -> Scanning Content Source [$j/$totalCS] {$csName}"

            $sscsGuid = [System.Guid]::NewGuid().toString()

            $params.Name = $csName
            $params.ServiceAppName = $searchSAName

            $partialContent = ""

            if ($contentSource.Type -ne "CustomRepository")
            {
                $results = Get-TargetResource @params
                $partialContent = "        SPSearchContentSource " + $contentSource.Name.Replace(" ", "") + $sscsGuid + "`r`n"
                $partialContent += "        {`r`n"

                $searchScheduleModulePath = Join-Path -Path $ParentModuleBase -ChildPath "\Modules\SharePointDsc.Search\SPSearchContentSource.Schedules.psm1"
                Import-Module -Name $searchScheduleModulePath
                # TODO: Figure out way to properly pass CimInstance objects and then add the schedules back;
                if ($contentSource.IncrementalCrawlSchedule)
                {
                    $incremental = Get-SPDSCSearchCrawlSchedule -Schedule $contentSource.IncrementalCrawlSchedule
                    $results.IncrementalSchedule = Get-SPCrawlSchedule $incremental
                }
                else
                {
                    $results.Remove("IncrementalSchedule")
                }

                if ($contentSource.FullCrawlSchedule)
                {
                    $full = Get-SPDSCSearchCrawlSchedule -Schedule $contentSource.FullCrawlSchedule
                    $results.FullSchedule = Get-SPCrawlSchedule $full
                }
                else
                {
                    $results.Remove("FullSchedule")
                }

                if ($dependsOn)
                {
                    $results.add("DependsOn", $dependsOn)
                }

                $results = Repair-Credentials -results $results

                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                if ($contentSource.IncrementalCrawlSchedule)
                {
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "IncrementalSchedule"
                }

                if ($contentSource.FullCrawlSchedule)
                {
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "FullSchedule"
                }

                $partialContent += $currentBlock.replace('`', '"')
                $partialContent += "        }`r`n"
            }
        }
        catch
        {
            $_
        }
        $Content += $partialContent
        $j++
    }
    return $content
    #endregion
}

Export-ModuleMember -Function *-TargetResource
