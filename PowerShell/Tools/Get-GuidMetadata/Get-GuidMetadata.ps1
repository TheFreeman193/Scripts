<#
.SYNOPSIS
Gets version and variant metadata from a GUID/UUID

.DESCRIPTION
Retrieves all GUIDs/UUIDs from the passed string and attempts to
extract the version and variant metadata from each.

.PARAMETER GUID
A string containing the GUID(s)/UUID(s) to examine

.PARAMETER Strict
Causes strict processing; the version is only interpreted for variant 1 and 2 GUIDs/UUIDs,
and the version must be 1-5 (or 0 for a nil UUID). Failure of any conditions results in an
error being displayed and no output for that GUID.

.INPUTS
System.String. A string containing the GUID(s)/UUID(s) to examine.

.OUTPUTS
System.Management.Automation.PSCustomObject. A custom object for each GUID/UUID with the
following properties:
- GUID/UUID: The GUID/UUID found in the string. This property name depends on which
  alias is used to call the function (Get-Guid-/Get-Uuid-).
- Variant: The variant of the GUID/UUID. Valid variants are 0-3.
- Version: The version number of the GUID/UUID. Valid versions are 1-5, or 0 for nil UUIDs.
When -Strict is passed, the Version and VersionName properties are only populated for variant
1 and 2 GUIDs/UUIDs.

.FUNCTIONALITY
Analysis

.LINK
https://github.com/TheFreeman193/Scripts/blob/main/PowerShell/Tools/Get-GuidMetadata/Get-GuidMetadata.ps1

.LINK
License: https://github.com/TheFreeman193/Scripts/blob/main/LICENSE.md

.EXAMPLE
PS> New-Guid | .\Get-GuidMetadata.ps1

GUID        : d2fced0e-8eec-439e-8380-041a4daa99f1
Variant     : 1
Version     : 4
VariantName : RFC 4122/DCE 1.1
VersionName : Random

Creates a new GUID and passes it through the pipeline via the "GUID"
property name.

.EXAMPLE
PS> .\Get-GuidMetadata.ps1 -Guid '96ecce79-3dd9-4984-841a-56e12a6ded74' | Select-Object *UID

GUID
----
96ecce79-3dd9-4984-841a-56e12a6ded74

PS> Copy-Item .\Get-GuidMetadata.ps1 .\Get-UuidMetadata.ps1
PS> .\Get-UuidMetadata.ps1 -Uuid '96ecce79-3dd9-4984-841a-56e12a6ded74' | Select-Object *UID

UUID
----
96ecce79-3dd9-4984-841a-56e12a6ded74

Demonstrates use of both the GUID and UUID aliases. Note that the property name output matches
the input. Output property name is based on the script filename used alone; the -Guid/-Uuid
parameter can be used interchangeably in both cases.

.EXAMPLE
PS> "{3afcd7d5-0d95-3e9b-a442-aca4f52d4443}{7dc5b610-800a-5ac9-83ff-68be05e9d5fd}",(New-Guid) |
>> .\Get-GuidMetadata.ps1 | Format-Table -AutoSize

GUID                                 Variant Version VariantName      VersionName
----                                 ------- ------- -----------      -----------
3afcd7d5-0d95-3e9b-a442-aca4f52d4443       1       3 RFC 4122/DCE 1.1 Namespace + Name MD5
7dc5b610-800a-5ac9-83ff-68be05e9d5fd       1       5 RFC 4122/DCE 1.1 Namespace + Name SHA-1
f8207515-b220-41c7-a006-ce7bc93739b2       1       4 RFC 4122/DCE 1.1 Random

Passes a string containing 2 GUIDs, plus a third as a separate item, via the pipeline, and
formats the output into a table. The output is not grouped; strings with multiple GUIDs and
individual strings passed in an array or list are treated the same.

.EXAMPLE
PS> '0000000000-0000-0000-0000-000000000000' | .\Get-GuidMetadata.ps1

GUID        : 00000000-0000-0000-0000-000000000000
Variant     :
Version     : 0
VariantName :
VersionName : Nil

Demonstrates the "Nil" GUID/UUID.

.EXAMPLE
PS> .\Get-GuidMetadata.ps1 306c5a03-c68c-6676-beba-2f78b549c623 -Strict
Get-GuidMetadata.ps1: Unrecognized GUID version "6" (Parameter 'Guid')
PS> .\Get-GuidMetadata.ps1 306c5a03-c68c-6676-beba-2f78b549c623

GUID        : 306c5a03-c68c-6676-beba-2f78b549c623
Variant     : 1
Version     : 6
VariantName : RFC 4122/DCE 1.1
VersionName :

Demonstrates how the -Strict parameter changes the behaviour for invalid versions.

.EXAMPLE
PS> .\Get-GuidMetadata.ps1 e0696a21-63fe-49ac-e312-3fd96beede31 -Strict

GUID        : e0696a21-63fe-49ac-e312-3fd96beede31
Variant     : 3
Version     :
VariantName : Future-reserved
VersionName :

PS> .\Get-GuidMetadata.ps1 e0696a21-63fe-49ac-e312-3fd96beede31

GUID        : e0696a21-63fe-49ac-e312-3fd96beede31
Variant     : 3
Version     : 4
VariantName : Future-reserved
VersionName : Random

Demonstrates how the -Strict parameter changes the behaviour for type 0 and 3 GUIDs/UUIDs.
#>

[CmdletBinding(ConfirmImpact = 'None')]
[OutputType('System.Management.Automation.PSCustomObject')]
param (
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [ValidateNotNull()]
    [Alias('Uuid')]
    [string]
    $Guid,

    [Parameter()]
    [switch]
    $Strict
)
begin {
    #Requires -Version 2.0

    $PS5OrLater = $PSVersionTable.PSVersion -ge '5.0'
    $IgnoreAction = if ($PS5OrLater) { 'Ignore' } else { 'SilentlyContinue' }
    if ($null -eq $GuidMetadata_LocalStrings) {
        $LocalizeOpts = @{
            FileName    = 'GuidMetadata_Strings'
            ErrorAction = $IgnoreAction
        }
        if ($PS5OrLater) {
            $global:GuidMetadata_LocalStrings =
            Microsoft.PowerShell.Utility\Import-LocalizedData @LocalizeOpts
        }
        else {
            $LocalizeOpts['BindingVariable'] = 'GuidMetadata_LocalStrings'
            Microsoft.PowerShell.Utility\Import-LocalizedData @LocalizeOpts
        }
        if (-not $?) {
            $global:GuidMetadata_LocalStrings = data {
                # Default values
                @{
                    DEBUG_Imported            = 'Using default (en) resources'
                    ERROR_InvalidInput        = '"{1}" is not a valid {0} input'
                    ERROR_NoVariant           = 'Couldn''t interpret {0} variant from input "{1}"'
                    ERROR_NilVersion          = '{0} has nil version {1} but is not the "nil" {0}'
                    ERROR_UnrecognizedVersion = 'Unrecognized {0} version "{1}"'
                    OUTPUT_ReservedType       = '{0}-reserved'
                    OUTPUT_FutureReserved     = 'Future-reserved'
                    OUTPUT_NamespaceAndName   = 'Namespace + Name'
                    OUTPUT_Random             = 'Random'
                    OUTPUT_DateAndTime        = 'Date & Time'
                    OUTPUT_NilType            = 'Nil'
                    OUTPUT_SecurityType       = 'Security'
                }
            }
        }
        Write-Debug $GuidMetadata_LocalStrings.DEBUG_Imported
    }

    $PrefName = switch -Wildcard ($MyInvocation.InvocationName) {
        '*Get-GuidMetadata*' { 'GUID'; break }
        '*ggm*' { 'GUID'; break }
        '*Get-UuidMetadata*' { 'UUID'; break }
        '*gum*' { 'UUID'; break }
        default { 'GUID' }
    }
    $VariantNames = @(
        $GuidMetadata_LocalStrings.OUTPUT_ReservedType -f 'Apollo NCS'
        'RFC 4122/DCE 1.1'
        $GuidMetadata_LocalStrings.OUTPUT_ReservedType -f 'Microsoft'
        $GuidMetadata_LocalStrings.OUTPUT_FutureReserved
    )
    $VersionNames = @(
        $GuidMetadata_LocalStrings.OUTPUT_NilType
        '{0} + MAC' -f $GuidMetadata_LocalStrings.OUTPUT_DateAndTime
        'DCE {0}' -f $GuidMetadata_LocalStrings.OUTPUT_SecurityType
        '{0} MD5' -f $GuidMetadata_LocalStrings.OUTPUT_NamespaceAndName
        $GuidMetadata_LocalStrings.OUTPUT_Random
        '{0} SHA-1' -f $GuidMetadata_LocalStrings.OUTPUT_NamespaceAndName
    )

    $1Hex = '[A-F0-9]'
    $SelectFirst = '({0}){0}{{3}}' -f $1Hex
    $SelectFour = '{0}{{4}}' -f $1Hex
    $PatternTemplate = '{0}{{{{8}}}}\-{0}{{{{4}}}}\-{{0}}\-{{1}}\-{0}{{{{12}}}}' -f $1Hex
    $VersionPatternStr = $PatternTemplate -f $SelectFirst, $SelectFour
    $VariantPatternStr = $PatternTemplate -f $SelectFour, $SelectFirst
    $NullPatternStr = '0{8}\-(0{4}\-){3}0{12}'
    $RegexOpt = (
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
        [System.Text.RegularExpressions.RegexOptions]::Singleline -bor
        [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
    )

    # PS 2.0-4.x compatibility
    if ($PS5OrLater) {
        filter local:ArgumentError {
            param($Target, $Message, $Parameter, $Category, $Id)
            [System.Management.Automation.ErrorRecord]::new(
                [System.ArgumentException]::new($Message, $Parameter),
                $Id,
                $Category,
                $Target
            )
        }
        $RegexTimeout = [timespan]::new(0, 0, 0, 0, 10)
        $VersionPattern = [regex]::new($VersionPatternStr, $RegexOpt, $RegexTimeout)
        $VariantPattern = [regex]::new($VariantPatternStr, $RegexOpt, $RegexTimeout)
        $NullPattern = [regex]::new($NullPatternStr, $RegexOpt, $RegexTimeout)
    }
    else {
        filter local:ArgumentError {
            param($Target, $Message, $Parameter, $Category, $Id)
            New-Object System.Management.Automation.ErrorRecord @(
                (New-Object System.ArgumentException $Message, $Parameter),
                $Id,
                $Category,
                $Target
            )
        }
        $VersionPattern = New-Object regex -ArgumentList $VersionPatternStr, $RegexOpt
        $VariantPattern = New-Object regex -ArgumentList $VariantPatternStr, $RegexOpt
        $NullPattern = New-Object regex -ArgumentList $NullPatternStr, $RegexOpt
    }
}
process {
    :matchesLoop foreach ($MatchGUID in $VersionPattern.Matches($Guid)) {
        #region Interpret
        if (-not $MatchGUID.Success) {
            $ErrorParams = @{
                Target    = $MatchGUID.Value
                Message   = $GuidMetadata_LocalStrings.ERROR_InvalidInput -f $PrefName, $MatchGUID.Value
                Parameter = $PrefName[0] + 'uid'
                Category  = 'InvalidArgument'
                Id        = 'InvalidInput'
            }
            $PSCmdlet.WriteError((ArgumentError @ErrorParams))
            continue matchesLoop
        }

        $OutputProperties = @{
            $PrefName   = $MatchGUID.Value
            Variant     = $null
            Version     = $null
            VariantName = $null
            VersionName = $null
        }

        # PS 2.0-4.x compatibility
        $OutputObj = if ($PS5OrLater) { [pscustomobject]$OutputProperties }
        else { New-Object pscustomobject -Property $OutputProperties }

        $MatchNull = $NullPattern.Match($MatchGUID.Value)
        $MatchVariant = $VariantPattern.Match($MatchGUID.Value)
        #endregion

        #region Null Detection
        if ($MatchNull.Success) {
            $OutputObj.Version = 0
            $OutputObj.VersionName = $VersionNames[0]
            $OutputObj
            continue matchesLoop
        }
        #endregion

        #region Variant
        if (-not $MatchVariant.Success) {
            $ErrorParams = @{
                Target    = $MatchGUID.Value
                Message   = $GuidMetadata_LocalStrings.ERROR_NoVariant -f $PrefName, $MatchGUID.Value
                Parameter = $PrefName[0] + 'uid'
                Category  = 'InvalidType'
                Id        = 'GuidHasNoVariant'
            }
            $PSCmdlet.WriteError((ArgumentError @ErrorParams))
            continue matchesLoop
        }

        $Variant = switch ([System.Convert]::ToUInt16($MatchVariant.Groups[1].Value, 16)) {
            { $_ -ge 16 } { break }
            { $_ -ge 14 } { 3; break }
            { $_ -ge 12 } { 2; break }
            { $_ -ge 8 } { 1; break }
            { $_ -ge 0 } { 0; break }
            default {}
        }

        if ($null -eq $OutputObj.$PrefName) {
            $OutputObj.$PrefName = $MatchVariant.Value
        }

        if ($null -ne $Variant -and $Variant -lt $VariantNames.Count) {
            $OutputObj.Variant = $Variant
            $OutputObj.VariantName = $VariantNames[$Variant]
        }

        if (1, 2 -notcontains $Variant -and $Strict.IsPresent) {
            $OutputObj
            continue matchesLoop
        }
        #endregion

        #region Version
        $Version = [System.Convert]::ToUInt16($MatchGUID.Groups[1].Value, 16)
        switch ($Version) {
            { $_ -eq 0 } {
                if ($Strict.IsPresent) {
                    $ErrorParams = @{
                        Target    = $MatchGUID.Value
                        Message   = $GuidMetadata_LocalStrings.ERROR_NilVersion -f $PrefName, $Version
                        Parameter = $PrefName[0] + 'uid'
                        Category  = 'InvalidType'
                        Id        = 'GuidIsNotNil'
                    }
                    $PSCmdlet.WriteError((ArgumentError @ErrorParams))
                    continue matchesLoop
                }
                $OutputObj.Version = 0
                break
            }
            { $_ -lt 6 -or -not $Strict.IsPresent } {
                $OutputObj.Version = $Version
                break
            }
            default {
                $ErrorParams = @{
                    Target    = $MatchGUID.Value
                    Message   = $GuidMetadata_LocalStrings.ERROR_UnrecognizedVersion -f $PrefName, $Version
                    Parameter = $PrefName[0] + 'uid'
                    Category  = 'InvalidType'
                    Id        = 'GuidUnknownVersion'
                }
                $PSCmdlet.WriteError((ArgumentError @ErrorParams))
                continue matchesLoop
            }
        }
        if ($null -ne $Version -and $Version -lt $VersionNames.Count) {
            $OutputObj.VersionName = $VersionNames[$Version]
        }
        #endregion

        $OutputObj
    }
}
