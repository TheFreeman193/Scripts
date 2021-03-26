<#
.SYNOPSIS
Retrieves supported syntax highlighting hints on StackExchange websites.

.DESCRIPTION
Retrieves a list of supported syntax highlighting hints available on
StackExchange websites, and returns the lang-* hint, friendly name, and
aliases for each. It can also retrieve the hints for non-English
StackExchange websites such as "Stack Overflow in Spanish".

.PARAMETER Language
The StackExchange website language, as a 2-digit ISO 639-1 code.
e.g. "en" for English. Currently supported StackExchange website languages are
English (en), Spanish (es), Japanese (ja), and Russian (ru).

.PARAMETER UseHTTP
Causes the script to use HTTP to download the highlightJS data.

.INPUTS
System.String. Accepts multiple strings for the Language parameter from
the pipeline.

.OUTPUTS
System.Object[]. Array of custom objects with the following properties:
- Hint          The lang-* highlighting language hint
- FriendlyName  The descriptive name for the highlighted language
- Aliases       Alternative lang-* aliases, separated by spaces
- Language      The StackExchange website language this hint is for,
                as an ISO 639-1 code

.EXAMPLE
PS> .\Get-StackExchangeHighlightHints.ps1

Gets a list of syntax highlighting hints supported by the English (en)
StackExchange website.

.EXAMPLE
PS> .\Get-StackExchangeHighlightHints.ps1 -Language ru

Gets a list of syntax highlighting hints supported by the Russian (ru)
StackExchange website.

.EXAMPLE
PS> 'en','ja' | Get-StackExchangeHighlightHints -UseHTTP |
    Format-Table -GroupBy Language

Gets the syntax highlighting hints supported by the English (en) and
Japanese (ja) StackExchange websites, using unsecured HTTP, and groups the
results.

.NOTES
To use a highlighting hint in the form lang-* in a question, answer or
comment, append it to the opening code fences, e.g. for C# highlighting:

```lang-cs
[DllImport("shlwapi.dll", CharSet = CharSet.Unicode, ExactSpelling = true)]
private static extern int SHLoadIndirectString(string pszSource, StringBuilder pszOutBuf, int cchOutBuf, IntPtr ppvReserved);
```

.LINK
https://github.com/TheFreeman193/Scripts/blob/master/PowerShell/Scripts/Get-StackExchangeHighlightHints.ps1
#>

#Requires -Version 2.0
[CmdletBinding(ConfirmImpact = 'None')]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    [ValidateSet('en', 'es', 'ja', 'ru')]
    [string]
    $Language = 'en',

    [Parameter()]
    [switch]
    $UseHTTP
)
begin {
    $commonPrefix = 'hljs\.registerLanguage\([''"](?<hint>[^''"]+?)[''"],.+?return\s?\{\s*?[''"]?name[''"]?:\s?[''"]'
    $HighlightJsPattern = '{0}(?<fname>[^''"]+?)[''"],' -f $commonPrefix
    $HighlightJsPatternWAlias = '{0}.+?[''"],.+?aliases[''"]?:\s?\[(?<alias>[^\]]+?)\],' -f $commonPrefix
    $ListSepConsistencyPattern = '",\s?"'
    $RegexOpt = (
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
        [System.Text.RegularExpressions.RegexOptions]::Singleline -bor
        [System.Text.RegularExpressions.RegexOptions]::CultureInvariant -bor
        [System.Text.RegularExpressions.RegexOptions]::ExplicitCapture
    )
    $HighlightMatch = New-Object regex -ArgumentList $HighlightJsPattern, $RegexOpt
    $HighlightMatchWAlias = New-Object regex -ArgumentList $HighlightJsPatternWAlias, $RegexOpt
    $ListSepConsistencyRep = New-Object regex -ArgumentList $ListSepConsistencyPattern, $RegexOpt
    $WebClient = New-Object System.Net.WebClient
}
process {
    $Protocol = if ($UseHTTP) { 'http' } else { 'https' }
    $SOHighlightLoaderURI = "{0}://dev.sstatic.net/js/highlightjs-loader.{1}.js" -f $Protocol, $Language

    #region Download Data
    Write-Verbose "Downloading highlightJS script from $SOHighlightLoaderURI"
    $RawData = $WebClient.DownloadData($SOHighlightLoaderURI)
    #endregion

    #region Search Data
    if ($null -eq $RawData -or $RawData.Count -lt 100000) {
        Write-Error -Exception (
            New-Object System.Net.WebException "Unable to get data from $SOHighlightLoaderURI"
        )
    }
    $SOHighlightLoader = [System.Text.Encoding]::UTF8.GetString($RawData)

    Write-Verbose "Searching highlightJS-loader for language hints"
    $MatchRes = $HighlightMatch.Matches($SOHighlightLoader)

    if ($null -eq $MatchRes -or $MatchRes.Count -lt 1) {
        Write-Error -Message "Invalid data received from $SOHighlightLoaderURI"
    }

    Write-Verbose "Searching highlightJS-loader for language hints with aliases"
    $MatchResWAlias = $HighlightMatchWAlias.Matches($SOHighlightLoader)

    $HintsWAlias = @{}
    foreach ($aliasMatch in $MatchResWAlias) {
        $HintsWAlias[$aliasMatch.Groups['hint'].Value] = $ListSepConsistencyRep.Replace($aliasMatch.Groups['alias'].Value, "', '")
    }
    #endregion

    #region Format Data
    $MatchRes | ForEach-Object {
        if ($_.Success) {
            $hint = $_.Groups['hint'].Value
            $outputObj = New-Object PSCustomObject -Property @{
                FriendlyName = $_.Groups['fname'].Value
                Hint         = 'lang-' + $hint
                Aliases      = $null
                Language     = $Language
            }
            if ($HintsWAlias.ContainsKey($hint)) {
                $outputObj.Aliases = (
                    $HintsWAlias[$hint].Trim('''"') -split "', '" | ForEach-Object {
                        'lang-' + $_
                    }
                ) -join ' '
            }
            $outputObj
        }
    } | Sort-Object Hint | Select-Object Hint, FriendlyName, Aliases, Language
    #endregion
}
end {
    $WebClient.Dispose()
}
