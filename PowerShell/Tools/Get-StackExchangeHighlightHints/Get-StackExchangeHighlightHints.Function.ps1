function Get-StackExchangeHighlightHints {
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

    .PARAMETER Http
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
    PS> Get-StackExchangeHighlightHints

    Gets a list of syntax highlighting hints supported by the English (en)
    StackExchange website.

    .EXAMPLE
    PS> Get-StackExchangeHighlightHints -Language ru

    Gets a list of syntax highlighting hints supported by the Russian (ru)
    StackExchange website.

    .EXAMPLE
    PS> 'en','ja' | Get-StackExchangeHighlightHints -Http |
        Format-Table -GroupBy Language

    Gets the syntax highlighting hints supported by the English (en) and
    Japanese (ja) StackExchange websites, using unsecured HTTP, and groups the
    results.

    .NOTES
    To use a highlighting hint in the form lang-* in a question, answer or
    comment, append it to the opening code fences, e.g. for C# highlighting:

    ```lang-cs
    Console.WriteLine(@"Hello {0}!", "World")
    ```

    .LINK
    https://github.com/TheFreeman193/Scripts/blob/master/PowerShell/Tools/Get-StackExchangeHighlightHints/Get-StackExchangeHighlightHints.Function.ps1

    .LINK
    License: https://github.com/TheFreeman193/Scripts/blob/master/LICENSE.md
    #>

    #Requires -Version 2.0
    [CmdletBinding(ConfirmImpact = 'None')]
    [Alias('gsehh', 'Get-StackOverflowHighlightHints', 'gsohh')]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [ValidateSet('en', 'es', 'ja', 'ru')]
        [string]
        $Language = 'en',

        [Parameter()]
        [switch]
        $Http
    )
    begin {
        $PS5OrLater = $PSVersionTable.PSVersion -ge '5.0'
        $IgnoreAction = if ($PS5OrLater) { 'Ignore' } else { 'SilentlyContinue' }
        if ($null -eq $StackExchangeHighlightHints_LocalStrings) {
            $LocalizeOpts = @{
                FileName    = 'StackExchangeHighlightHints_Lang'
                ErrorAction = $IgnoreAction
            }
            if ($PS5OrLater) {
                $global:StackExchangeHighlightHints_LocalStrings =
                Microsoft.PowerShell.Utility\Import-LocalizedData @LocalizeOpts
            }
            else {
                $LocalizeOpts['BindingVariable'] = 'StackExchangeHighlightHints_LocalStrings'
                Microsoft.PowerShell.Utility\Import-LocalizedData @LocalizeOpts
            }
            if (-not $?) {
                $global:StackExchangeHighlightHints_LocalStrings = data {
                    # Default values
                    @{
                        DEBUG_Imported                = 'Using default (en) resources'
                        ERROR_CouldNotGetData         = 'Unable to get data from "{0}"'
                        ERROR_InvalidDataFrom         = 'Invalid data received from "{0}"'
                        VERBOSE_DownloadingScript     = 'Downloading highlightJS file from "{0}"'
                        VERBOSE_SearchingHints        = 'Searching highlightJS file for language hints'
                        VERBOSE_SearchingHintsAliases = 'Searching highlightJS file for language hints with aliases'
                    }
                }
            }
            Write-Debug $StackExchangeHighlightHints_LocalStrings.DEBUG_Imported
        }

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
        $Protocol = if ($Http) { 'http' } else { 'https' }
        $SOHighlightLoaderURI = "{0}://dev.sstatic.net/js/highlightjs-loader.{1}.js" -f $Protocol, $Language

        #region Download Data
        Write-Verbose ($StackExchangeHighlightHints_LocalStrings.VERBOSE_DownloadingScript -f $SOHighlightLoaderURI)
        $RawData = $WebClient.DownloadData($SOHighlightLoaderURI)
        #endregion

        #region Search Data
        if ($null -eq $RawData -or $RawData.Count -lt 100000) {
            $Record = New-Object System.Management.Automation.ErrorRecord @(
                (New-Object System.Net.WebException (
                        $StackExchangeHighlightHints_LocalStrings.ERROR_CouldNotGetData -f $SOHighlightLoaderURI
                    )),
                'CouldNotGetData',
                'ResourceUnavailable'
                $SOHighlightLoaderURI
            )
            $PSCmdlet.WriteError($Record)
            return
        }
        $SOHighlightLoader = [System.Text.Encoding]::UTF8.GetString($RawData)

        Write-Verbose $StackExchangeHighlightHints_LocalStrings.VERBOSE_SearchingHints
        $MatchRes = $HighlightMatch.Matches($SOHighlightLoader)

        if ($null -eq $MatchRes -or $MatchRes.Count -lt 1) {
            $Record = New-Object System.Management.Automation.ErrorRecord @(
                (New-Object System.IO.InvalidDataException (
                        $StackExchangeHighlightHints_LocalStrings.ERROR_InvalidDataFrom -f $SOHighlightLoaderURI
                    )),
                'InvalidHighlightData',
                'InvalidData'
                $SOHighlightLoader
            )
            $PSCmdlet.WriteError($Record)
            return
        }

        Write-Verbose $StackExchangeHighlightHints_LocalStrings.VERBOSE_SearchingHintsAliases
        $MatchResWAlias = $HighlightMatchWAlias.Matches($SOHighlightLoader)

        $HintsWAlias = @{}
        foreach ($aliasMatch in $MatchResWAlias) {
            $HintsWAlias[$aliasMatch.Groups['hint'].Value] =
            $ListSepConsistencyRep.Replace($aliasMatch.Groups['alias'].Value, "', '")
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
}
