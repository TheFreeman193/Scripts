Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices; using System.Text;
public static class IndirectString
{
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, ExactSpelling = true)]
    private static extern int SHLoadIndirectString(string pszSource, StringBuilder pszOutBuf, int cchOutBuf, IntPtr ppvReserved);
    public static string Query(string resourceQuery)
    {
        StringBuilder strBuffer = new StringBuilder(2048);
        int result = SHLoadIndirectString(resourceQuery, strBuffer, strBuffer.Capacity, IntPtr.Zero);
        if (result == 0) return strBuffer.ToString();
        throw new ExternalException(String.Format(@"SHLoadIndirectString returned an error. HRESULT 0x{0:x2}", result));
    }
}
'@

<#

USAGE:

    [IndirectString]::Query( string resourceQuery )

EXAMPLES:

    PS> [IndirectString]::Query('@shell32.dll,-51556')
    Your stuff matters – keep it protected by choosing a backup option that works for you

    PS> [IndirectString]::Query('@{Microsoft.WindowsCalculator_10.2101.10.0_x64__8wekyb3d8bbwe?ms-resource://Microsoft.WindowsCalculator/Resources/AppStoreName}')
    Windows Calculator

#>
