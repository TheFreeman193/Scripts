Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.IO;
public static class IndirectString
{
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, ExactSpelling = true)]
    private static extern int SHLoadIndirectString(string pszSource, StringBuilder pszOutBuf, int cchOutBuf, IntPtr ppvReserved);

    private static readonly Regex validFilePattern = new Regex(
        @"^@(?<quot>""?)[^"",\?@]+?\k<quot>,\-\d{1,5}(;v\d+)?$",
        RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled | RegexOptions.ExplicitCapture
    );
    private static readonly Regex validPackagePattern = new Regex(
        @"^@\{[^\?\}""@]+?\? *ms\-resource://[^\}]+?\}$",
        RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled
    );
    private static readonly Regex typePackagePattern = new Regex(@"^@\{", RegexOptions.Compiled);
    private static readonly Char quoteChar = Char.Parse("\"");
    private static readonly string msResourceProtocol = "ms-resource://";
    public static string Query(string resourceQuery, int bufferSize)
    {
        if (bufferSize < 1 || bufferSize > 0xFFFF)
            throw new ArgumentOutOfRangeException(
                "bufferSize", bufferSize,
                "Buffer size out of range. Specify a value between 1 and 65535"
            );
        if (!(validFilePattern.IsMatch(resourceQuery) || validPackagePattern.IsMatch(resourceQuery)))
            throw new ArgumentException(
                String.Format(
                    typePackagePattern.IsMatch(resourceQuery) ?
                    @"The package or PRI indirect string query was malformed: ""{0}""" :
                    @"The file indirect string query was malformed: ""{0}""", resourceQuery
                ), "resourceQuery"
            );
        StringBuilder strBuffer = new StringBuilder(bufferSize);
        int result = SHLoadIndirectString(resourceQuery, strBuffer, strBuffer.Capacity, IntPtr.Zero);
        switch (result)
        {
            case 0:
                return strBuffer.ToString();
            case -2147467259:
                throw new ExternalException("Indirect string could not be retrieved due to an unspecified error", result);
            case -2147024891:
                throw new ExternalException(String.Format(@"Access was denied to the path or file ""{0}""", resourceQuery), result);
            case -2147024894:
            case -2147024893:
                throw new ExternalException(String.Format(@"The PRI path or file does not exist or could not be read: ""{0}""", resourceQuery), result);
            case -2147024809:
                throw new ExternalException(String.Format(@"The package path was malformed: ""{0}""", resourceQuery), result);
            case -2147023728:
                throw new ExternalException(String.Format(@"The package could not be found: ""{0}""", resourceQuery), result);
            case -2147009769:
            case -2147009761:
                throw new ExternalException(String.Format(@"The named resource could not be found for the package or PRI: ""{0}""", resourceQuery), result);
            default:
                throw new ExternalException(String.Format(@"SHLoadIndirectString returned an unknown error. HRESULT 0x{0:x2}", result), result);
        }
    }
    public static string Query(string resourceQuery)
    {
        return Query(resourceQuery, 2048);
    }
    public static string ReadFromFile(string filePath, int resourceId, int bufferSize, int versionModifier)
    {
        string expandedfilePath = Environment.ExpandEnvironmentVariables(filePath).Trim(quoteChar);
        if (resourceId < 0 || resourceId > 99999)
        {
            throw new ArgumentOutOfRangeException("resourceId", resourceId, "Resource ID out of range. Specify a value between 0 and 99999");
        }
        StringBuilder query = new StringBuilder("@\"", 512);
        query.Append(expandedfilePath);
        query.Append("\",-");
        query.Append(resourceId.ToString("f0"));
        if (versionModifier > 0)
        {
            query.Append(";v");
            query.Append(versionModifier.ToString("f0"));
        }
        return Query(query.ToString(), bufferSize);
    }
    public static string ReadFromFile(string filePath, int resourceId, int bufferSize)
    {
        return ReadFromFile(filePath, resourceId, bufferSize, 0);
    }
    public static string ReadFromFile(string filePath, int resourceId)
    {
        return ReadFromFile(filePath, resourceId, 2048, 0);
    }
    public static string ReadFromPackage(string packageName, string resourceUri, int bufferSize)
    {
        StringBuilder query = new StringBuilder("@{", 512);
        query.Append(packageName);
        query.Append("?");
        if (!resourceUri.StartsWith(msResourceProtocol)) query.Append(msResourceProtocol);
        query.Append(resourceUri);
        query.Append("}");
        return Query(query.ToString(), bufferSize);
    }
    public static string ReadFromPackage(string packageName, string resourceUri)
    {
        return ReadFromPackage(packageName, resourceUri, 2048);
    }
    public static string ReadFromPri(string priPath, string resourceUri, int bufferSize)
    {
        string expandedPriPath = Environment.ExpandEnvironmentVariables(priPath).Trim(quoteChar);
        if (!File.Exists(expandedPriPath))
        {
            throw new ArgumentException(String.Format(@"The file does not exist or could not be read: ""{0}""", priPath), "priPath");
        }
        return ReadFromPackage(priPath, resourceUri, bufferSize);
    }
    public static string ReadFromPri(string priPath, string resourceUri)
    {
        return ReadFromPri(priPath, resourceUri, 2048);
    }
}
'@

<#

USAGE:

    [IndirectString]::Query( string resourceQuery [, int bufferSize] )

    [IndirectString]::ReadFromFile( string filePath, int resourceId [, int bufferSize [, int versionModifier]] )

    [IndirectString]::ReadFromPri( string priPath, string resourceUri [, int bufferSize] )

    [IndirectString]::ReadFromPackage(string packageName, string resourceUri [, int bufferSize] )

EXAMPLES:

    PS> [IndirectString]::Query('@shell32.dll,-51556')
    Your stuff matters – keep it protected by choosing a backup option that works for you

    PS> [IndirectString]::Query('@{Microsoft.WindowsCalculator_10.2101.10.0_x64__8wekyb3d8bbwe?ms-resource://Microsoft.WindowsCalculator/Resources/AppStoreName}')
    Windows Calculator

    PS> [IndirectString]::ReadFromFile('shell32.dll', 51556)
    Your stuff matters – keep it protected by choosing a backup option that works for you

    PS> $PriFile = 'C:\Program Files\WindowsApps\Microsoft.WindowsCalculator_10.2101.10.0_x64__8wekyb3d8bbwe\resources.pri'
    PS> [IndirectString]::ReadFromPri($PriFile, 'ms-resource://Microsoft.WindowsCalculator/Resources/AppStoreName')
    Windows Calculator
    PS> [IndirectString]::ReadFromPri($PriFile, 'Microsoft.WindowsCalculator/Resources/AppStoreName')
    Windows Calculator

    PS> [IndirectString]::ReadFromPackage('Microsoft.WindowsCalculator_10.2101.10.0_x64__8wekyb3d8bbwe', 'Microsoft.WindowsCalculator/Resources/AppStoreName')
    Windows Calculator

#>
