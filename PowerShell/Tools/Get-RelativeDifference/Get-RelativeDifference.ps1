<#
.SYNOPSIS
Calculates relative (percentage) difference.

.DESCRIPTION
Calculates relative (percentage) difference between two values,
A and B, to a specified precision and using the specified denominator function.
See the NOTES section with Get-Help -Full for available denominators.

.PARAMETER A
The first value to compare against. This must be a valid System.Decimal.

.PARAMETER B
The second value to compare against. This must be a valid System.Decimal.

.PARAMETER Precision
Level of precision (decimal places). Default = 2, Valid Range = 0-28

.PARAMETER Method
The denominator function to use.
Allowed values = Max, MaxAbs, Min, MinAbs, MeanSum, MeanAbsSum, MeanSumAbs
See the NOTES section with Get-Help -Full for how these functions differ.

.PARAMETER Percent
This switch causes the output to be a string percentage instead of a
System.Decimal number.

.PARAMETER SkipNull
This switch causes no value to be returned if an error occurs or there is no
output. By default, $null is output in these cases, in order to maintain data
alignment for multiple inputs. Note that if -SkipNull is passed, the output
data set may be smaller than the input one.

.INPUTS
System.Object. Get-RelativeDifference accepts pipeline
input from objects with property names A/X/First/0 and B/Y/Second/1.

.OUTPUTS
System.Decimal. Get-RelativeDifference returns the relative difference as a decimal.

.OUTPUTS
System.String. If -Percentage is passed, Get-RelativeDifference returns a string
representation of the percentage difference.

.EXAMPLE
PS> .\Get-RelativeDifference.ps1 -A -92 -B 12 -Method MaxAbs -Precision 4
1.1304

Gets the relative difference of -92 and 12 using the largest absolute (92)
as the denominator, to 4 decimal places.

.EXAMPLE
PS> .\Get-RelativeDifference.ps1 -A 15 -B 22.3 -Method MeanAbsSum -Percent
39.14%

Gets the relative difference of 15 and 22.3 using the mean of the absolute sum
[(15+22.3)/2] as the denominator, in string form, to 2 decimal places.

.EXAMPLE
PS> .\Get-RelativeDifference.ps1 -A -55 -B 60 -Method Min -Percent -Precision 5
-209.09091%

Gets the relative difference of -55 and 60 using the smallest number (-55)
as the denominator, in string form, to 5 decimal places.

.EXAMPLE
PS> .\Get-RelativeDifference.ps1 42 4242 MeanSum 7
1.9607843

Gets the relative difference of 42 and 4,242 using the mean of the sum
as the denominator, to 7 decimal places, using positional parameters.

.EXAMPLE
PS> $Data = New-Object 'System.Collections.Generic.List[pscustomobject]'
PS> for ($i = 1; $i -le 1e5; $i++) {
>>     $Data.Add([pscustomobject]@{
>>         A = $i
>>         B = [math]::Pow($i, 2)
>>     })
>> }
PS> $Results = $Data | .\Get-RelativeDifference.ps1 -Method MeanAbsSum -Precision 15
PS> $Results.Count
100000
PS> $Results[5]
1.428571428571429

Creates a list of 100,000 custom objects with varying values A = x and B = x^2, and
calculates the relative difference using the mean of the absolute sum as the
denominator. Shows the number of results and the 6th result (A=6, B=36).
Passing values through the pipeline this way is much more efficient for large datasets.

.EXAMPLE
PS> $Data = New-Object 'System.Collections.Generic.List[pscustomobject]'
PS> for ($i = 1; $i -le 5; $i++) {
>>     $Data.Add([pscustomobject]@{
>>         A = -3
>>         B = $i
>>     })
>> }
PS> $Results = $Data | .\Get-RelativeDifference.ps1 -Method MeanSum
WARNING: Cannot divide by zero. A different method than "MeanSum" should be used for A=-3, B=3
PS> $Results.Count
5
PS> $Results -join ', '
-4, -10, , 14, 8

PS> $Results = $Data | .\Get-RelativeDifference.ps1 -Method MeanSum -SkipNull
WARNING: Cannot divide by zero. A different method than "MeanSum" should be used for A=-3, B=3
PS> $Results.Count
4
PS> $Results -join ', '
-4, -10, 14, 8

Demonstrates how the -SkipNull parameter affects output. When an invalid output is generated, a $null value
is normally returned, so that the input and output data size are the same. This may be undesirable in some
circumstances, however. Therefore, with -SkipNull, only valid results are sent to the output stream.

.NOTES
Get-RelativeDifference supports 7 common functions for the denominator:
1)  Max: Denominator is the largest of of A and B
        Formula: |A - B| / max(A, B)
2)  MaxAbs: Denominator is the largest of the absolutes of A and B
        Formula: |A - B| / max(|A|, |B|)
3)  Min: Denominator is the smallest of of A and B
        Formula: |A - B| / min(A, B)
4)  MinAbs: Denominator is the smallest of the absolutes of A and B
        Formula: |A - B| / min(|A|, |B|)
5)  MeanSum: Denominator is half the sum of A and B
        Formula: |A - B| / ((A + B) / 2)
        === 2 * |A - B| / (A + B)
6)  MeanAbsSum: Denominator is half the absolute of the sum of A and B
        Formula: |A - B| / ((|A + B|) / 2)
        === 2 * |A - B| / |A + B|
7)  MeanSumAbs: Denominator is half the sum of the absolutes of A and B
        Formula: |A - B| / ((|A| + |B|) /2 )
        === 2 * |A - B| / (|A| + |B|)

.FUNCTIONALITY
Mathematics

.LINK
https://github.com/TheFreeman193/Scripts/blob/master/PowerShell/Tools/Get-RelativeDifference/Get-RelativeDifference.ps1

.LINK
License: https://github.com/TheFreeman193/Scripts/blob/master/LICENSE.md

.LINK
Relative difference on Wikipedia: https://en.wikipedia.org/wiki/Relative_change_and_difference#Formulae
#>

[CmdletBinding(
    ConfirmImpact = 'None',
    DefaultParameterSetName = 'AsDecimal'
)]
[OutputType([System.Decimal], ParameterSetName = 'AsDecimal')]
[OutputType([System.String], ParameterSetName = 'AsStringPercent')]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
    [Alias('X', 'First', 0)]
    [decimal]
    $A,

    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
    [Alias('Y', 'Second', 1)]
    [decimal]
    $B,

    [Parameter(Mandatory = $true, Position = 2)]
    [Alias('Denominator', 'Function')]
    [ValidateSet('Max', 'MaxAbs', 'Min', 'MinAbs', 'MeanSum', 'MeanAbsSum', 'MeanSumAbs')]
    [string]
    $Method,

    [Parameter(Position = 3)]
    [Alias('DecimalPlaces')]
    [ValidateRange(0, 28)]
    [UInt16]
    $Precision = 2,

    [Parameter(Position = 4, ParameterSetName = 'AsStringPercent')]
    [Alias('Percentage', 'AsPercentage')]
    [switch]
    $Percent,

    [Parameter(Position = 4, ParameterSetName = 'AsDecimal')]
    [Parameter(Position = 5, ParameterSetName = 'AsStringPercent')]
    [switch]
    $SkipNull
)
begin {
    $PS5OrLater = $PSVersionTable.PSVersion -ge '5.0'
    $IgnoreAction = if ($PS5OrLater) { 'Ignore' } else { 'SilentlyContinue' }
    if ($null -eq $RelativeDifference_LocalStrings) {
        $LocalizeOpts = @{
            FileName    = 'RelativeDifference_Lang'
            ErrorAction = $IgnoreAction
        }
        if ($PS5OrLater) {
            $global:RelativeDifference_LocalStrings =
            Microsoft.PowerShell.Utility\Import-LocalizedData @LocalizeOpts
        }
        else {
            $LocalizeOpts['BindingVariable'] = 'RelativeDifference_LocalStrings'
            Microsoft.PowerShell.Utility\Import-LocalizedData @LocalizeOpts
        }
        if (-not $?) {
            $global:RelativeDifference_LocalStrings = data {
                # Default values
                @{
                    DEBUG_Imported       = 'Using default (en) resources'
                    DEBUG_ParamSetName   = 'Using parameter set "{0}"'
                    ERROR_InvalidMethod  = 'Invalid denominator method specified "{0}"'
                    WARNING_DivideByZero = 'Cannot divide by zero. A different method than "{0}" should be used for A={1}, B={2}'
                    WARNING_NoResult     = 'No result was returned for A={1}, B={2} with method "{0}"'
                }
            }
        }
        $PSCmdlet.WriteDebug($RelativeDifference_LocalStrings.DEBUG_Imported)
    }
    $PercentTemplate = "{0:P$Precision}"
    $PSCmdlet.WriteDebug($RelativeDifference_LocalStrings.DEBUG_ParamSetName -f $PSCmdlet.ParameterSetName)
}
process {
    trap [System.DivideByZeroException] {
        $PSCmdlet.WriteWarning(($RelativeDifference_LocalStrings.WARNING_DivideByZero -f $Method, $A, $B))
        if (-not $SkipNull.IsPresent) { $null }
        return
    }
    [decimal]$Result = switch ($Method) {
        'Max' {
            [decimal]::Divide(
                [math]::Abs([decimal]::Subtract($A, $B)),
                [math]::Max($A, $B)
            )
            break
        }
        'MaxAbs' {
            [decimal]::Divide(
                [math]::Abs([decimal]::Subtract($A, $B)),
                [math]::Max([math]::Abs($A), [math]::Abs($B))
            )
            break
        }
        'Min' {
            [decimal]::Divide(
                [math]::Abs([decimal]::Subtract($A, $B)),
                [math]::Min($A, $B)
            )
            break
        }
        'MinAbs' {
            [decimal]::Divide(
                [math]::Abs([decimal]::Subtract($A, $B)),
                [math]::Min([math]::Abs($A), [math]::Abs($B))
            )
            break
        }
        'MeanSum' {
            [decimal]::Divide(
                [decimal]::Multiply(2, [math]::Abs([decimal]::Subtract($A, $B))),
                [decimal]::Add($A, $B)
            )
            break
        }
        'MeanAbsSum' {
            [decimal]::Divide(
                [decimal]::Multiply(2, [math]::Abs([decimal]::Subtract($A, $B))),
                [math]::Abs([decimal]::Add($A, $B))
            )
            break
        }
        'MeanSumAbs' {
            [decimal]::Divide(
                [decimal]::Multiply(2, [math]::Abs([decimal]::Subtract($A, $B))),
                [decimal]::Add([math]::Abs($A), [math]::Abs($B))
            )
            break
        }
        default {
            $Record = New-Object System.Management.Automation.ErrorRecord @(
                (New-Object System.ArgumentException (
                        $RelativeDifference_LocalStrings.ERROR_InvalidMethod -f $Method
                    ), 'Method'),
                'InvalidDifferenceMethod',
                [System.Management.Automation.ErrorCategory]::InvalidArgument
                $Method
            )
            $PSCmdlet.ThrowTerminatingError($Record)
        }
    }
    if ($null -ne $Result) {
        if ($Percent.IsPresent) {
            $PercentTemplate -f $Result
        }
        else {
            [decimal]::Round($Result, $Precision)
        }
    }
    else {
        $PSCmdlet.WriteWarning(($RelativeDifference_LocalStrings.WARNING_NoResult -f $Method, $A, $B ))
        if (-not $SkipNull.IsPresent) { $null }
        return
    }
}
