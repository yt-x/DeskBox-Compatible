#Requires -Version 5.1
<#
    DeskBox 17763 readiness probe  (fork/specs/changes/0001)

    Read-only fact collector for the Windows 10 LTSC 2019 / build 17763 target
    machine. Answers "can DeskBox's stack run here" before any build effort is
    spent. Writes exactly one report file next to itself; touches nothing else
    (no installs, no registry writes, no network).

    Usage (on the target machine):
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\17763-readiness.ps1
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\17763-readiness.ps1 -OutFile C:\Temp\report.txt

    Exit codes: 0 = report written, 1 = probe itself failed.
#>
[CmdletBinding()]
param(
    [string]$OutFile
)

$ErrorActionPreference = 'Continue'
$script:Findings = New-Object System.Collections.ArrayList
$script:Started  = Get-Date

function Add-Finding {
    param(
        [Parameter(Mandatory)][string]$Area,
        [Parameter(Mandatory)][string]$Item,
        [Parameter(Mandatory)][string]$Value,
        [ValidateSet('OK','WARN','FAIL','INFO')][string]$Level = 'INFO',
        [string]$Note = ''
    )
    [void]$script:Findings.Add([pscustomobject]@{
        Area = $Area; Item = $Item; Value = $Value; Level = $Level; Note = $Note
    })
    $tag = switch ($Level) { 'OK' {'[ OK ]'} 'WARN' {'[WARN]'} 'FAIL' {'[FAIL]'} default {'[INFO]'} }
    Write-Host ("{0} {1} :: {2} = {3}" -f $tag, $Area, $Item, $Value)
    if ($Note) { Write-Host ("        {0}" -f $Note) }
}

function Invoke-Safe {
    param([Parameter(Mandatory)][scriptblock]$Body, $OnError = '')
    try { return & $Body } catch { return $OnError }
}

Write-Host ''
Write-Host '========================================================'
Write-Host ' DeskBox 17763 readiness probe'
Write-Host " started: $($script:Started.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host '========================================================'

# ---------------------------------------------------------------- 1. OS facts
$cv = Invoke-Safe { Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' } $null
if ($cv) {
    $build = [int]$cv.CurrentBuild
    Add-Finding 'OS' 'ProductName'    $cv.ProductName
    Add-Finding 'OS' 'EditionID'      $cv.EditionID
    Add-Finding 'OS' 'DisplayVersion' $cv.DisplayVersion
    Add-Finding 'OS' 'CurrentBuild'   "$($cv.CurrentBuild).$($cv.UBR)"
    Add-Finding 'OS' 'Architecture'   $env:PROCESSOR_ARCHITECTURE

    if ($build -ge 22000) {
        Add-Finding 'OS' 'FloorCheck' "$build >= 22000 (Win11 family)" 'INFO' 'This is NOT the LTSC 2019 target.'
    } elseif ($build -ge 19041) {
        Add-Finding 'OS' 'FloorCheck' "$build >= 19041" 'OK' 'Meets upstream floor; floor lowering not needed here.'
    } elseif ($build -ge 17763) {
        Add-Finding 'OS' 'FloorCheck' "$build >= 17763 (below upstream 19041)" 'WARN' 'This is the target profile: upstream floor must be lowered.'
    } else {
        Add-Finding 'OS' 'FloorCheck' "$build < 17763" 'FAIL' 'Below the intended target; out of scope.'
    }
} else {
    Add-Finding 'OS' 'CurrentVersion' 'unreadable' 'FAIL'
}

Add-Finding 'OS' 'PowerShellVersion' $PSVersionTable.PSVersion.ToString()
Add-Finding 'OS' 'CLR' ($PSVersionTable.CLRVersion | Out-String).Trim()

# ------------------------------------------------- 2. WinAppSDK / VC++ runtime
# Unpackaged self-contained WinAppSDK apps still need the VC++ runtime.
# LoadLibrary is the meaningful test: API-set DLLs such as
# api-ms-win-crt-runtime-l1-1-0.dll have no physical file in System32 (they
# resolve through the apiset schema), so Test-Path would report false misses.
$rtSig = @'
using System;
using System.Runtime.InteropServices;
public static class DeskBoxRuntimeProbe {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Ansi)]
    public static extern IntPtr LoadLibrary(string n);
}
'@
$rtReady = $false
try { Add-Type -TypeDefinition $rtSig -ErrorAction Stop; $rtReady = $true }
catch { Add-Finding 'Runtime' 'Add-Type' $_.Exception.Message 'WARN' 'Runtime load probing unavailable.' }

if ($rtReady) {
    $vcDlls = @('vcruntime140.dll','vcruntime140_1.dll','msvcp140.dll','ucrtbase.dll','api-ms-win-crt-runtime-l1-1-0.dll')
    $vcMissing = @()
    foreach ($d in $vcDlls) {
        if ([DeskBoxRuntimeProbe]::LoadLibrary($d) -eq [IntPtr]::Zero) { $vcMissing += $d }
    }
    if ($vcMissing.Count -eq 0) {
        Add-Finding 'Runtime' 'VC++ runtime load test' 'all load' 'OK'
    } else {
        Add-Finding 'Runtime' 'VC++ runtime load test' ("cannot load: " + ($vcMissing -join ', ')) 'FAIL' `
            'Install the VC++ Redistributable (x64) before running DeskBox.'
    }
}

$ucrt = Invoke-Safe { Get-Item "$env:WINDIR\System32\ucrtbase.dll" } $null
if ($ucrt) { Add-Finding 'Runtime' 'ucrtbase.dll version' $ucrt.VersionInfo.FileVersion }

# ------------------------------------------------------------ 3. AppX platform
# Authoritative signals only. NOTE: an earlier draft followed the upstream
# uninstall script and tested {win}\System32\WindowsApps; that path is absent on
# a healthy Win11 25H2 machine (packages live in %ProgramFiles%\WindowsApps), so
# the directory test produces false "stripped OS" readings and is NOT used here.
$pkgRoot = Join-Path $env:ProgramFiles 'WindowsApps'
$pkgRootSeen = $false
try { $pkgRootSeen = [bool](Get-Item -LiteralPath $pkgRoot -Force -ErrorAction Stop) } catch { $pkgRootSeen = $false }
Add-Finding 'AppX' 'package root (Program Files\WindowsApps)' $(if ($pkgRootSeen) { 'present' } else { 'not visible' }) `
    $(if ($pkgRootSeen) { 'OK' } else { 'WARN' }) `
    'Not visible to a standard user even when healthy; rely on the signals below.'

$appxSvc = Invoke-Safe { Get-Service -Name AppXSvc -ErrorAction Stop } $null
if ($appxSvc) {
    # StartType is the meaningful signal: a Stopped-but-Automatic service is healthy.
    $svcLevel = if ($appxSvc.StartType -eq 'Disabled') { 'FAIL' } else { 'OK' }
    Add-Finding 'AppX' 'AppXSvc' "Status=$($appxSvc.Status) StartType=$($appxSvc.StartType)" $svcLevel
} else {
    Add-Finding 'AppX' 'AppXSvc' 'not found' 'FAIL' 'No AppX servicing; a packaged/runtime-dependent path may be unavailable.'
}

$appxMod = Invoke-Safe { Get-Module -ListAvailable -Name Appx | Select-Object -First 1 } $null
Add-Finding 'AppX' 'Appx PowerShell module' $(if ($appxMod) { $appxMod.Version.ToString() } else { 'not available' })

# The decisive capability test: can the machine actually enumerate packages?
$pkgCount = Invoke-Safe { @(Get-AppxPackage -ErrorAction Stop).Count } 'FAIL'
if ($pkgCount -eq 'FAIL') {
    Add-Finding 'AppX' 'Get-AppxPackage' 'unavailable' 'WARN' 'AppX platform likely absent or restricted.'
} else {
    Add-Finding 'AppX' 'Get-AppxPackage' "$pkgCount packages" 'OK'
}

# Does the private WinAppSDK framework package resolve on this machine?
$warPkgs = Invoke-Safe { @(Get-AppxPackage -Name 'Microsoft.WindowsAppRuntime*' -ErrorAction SilentlyContinue) } @()
if (@($warPkgs).Count -gt 0) {
    $warVersions = (@($warPkgs) | ForEach-Object { "$($_.Name) $($_.Version)" } | Sort-Object -Unique) -join '; '
    Add-Finding 'AppX' 'installed WindowsAppRuntime packages' $warVersions 'OK' 'Framework-dependent mode could work; DeskBox Full ships self-contained anyway.'
} else {
    Add-Finding 'AppX' 'installed WindowsAppRuntime packages' 'none' 'INFO' 'Expected for a bare LTSC image; DeskBox Full carries a private runtime.'
}

# ------------------------------------------------------- 4. Everything (search)
$evPaths = @(
    "$env:ProgramFiles\Everything\Everything.exe",
    "${env:ProgramFiles(x86)}\Everything\Everything.exe"
)
$evFound = @($evPaths | Where-Object { Test-Path $_ })
Add-Finding 'Search' 'Everything executable' $(if ($evFound.Count) { $evFound -join '; ' } else { 'not found' })
$evProc = Invoke-Safe { @(Get-Process -Name Everything -ErrorAction SilentlyContinue) } @()
Add-Finding 'Search' 'Everything process count' "$(@($evProc).Count)"

# ------------------------------------------- 5. uxtheme ordinal resolvability
# hazard C4: deskbox-thumbnail-proxy calls private uxtheme ordinal exports.
# Resolution success does NOT prove the ordinal points at the intended function;
# it only proves the slot is non-empty and callable.
$ordSig = @'
using System;
using System.Runtime.InteropServices;
public static class DeskBoxOrdinalProbe {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern IntPtr LoadLibraryEx(string f, IntPtr h, uint flags);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr GetModuleHandle(string n);
    [DllImport("kernel32.dll", SetLastError=true, EntryPoint="GetProcAddress")]
    public static extern IntPtr GetProcAddressByOrdinal(IntPtr h, IntPtr ord);
    [DllImport("kernel32.dll", SetLastError=true, EntryPoint="GetProcAddress", CharSet=CharSet.Ansi)]
    public static extern IntPtr GetProcAddressByName(IntPtr h, string n);
}
'@
$ordReady = $false
try { Add-Type -TypeDefinition $ordSig -ErrorAction Stop; $ordReady = $true }
catch { Add-Finding 'uxtheme' 'Add-Type' $_.Exception.Message 'WARN' 'Ordinal probing unavailable.' }

if ($ordReady) {
    # LOAD_LIBRARY_AS_DATAFILE (0x2) = map only, never execute, never run DllMain.
    $hUx = [DeskBoxOrdinalProbe]::LoadLibraryEx("$env:WINDIR\System32\uxtheme.dll", [IntPtr]::Zero, 2)
    if ($hUx -eq [IntPtr]::Zero) {
        Add-Finding 'uxtheme' 'load' 'failed' 'WARN'
    } else {
        $uxVer = (Get-Item "$env:WINDIR\System32\uxtheme.dll").VersionInfo.FileVersion
        Add-Finding 'uxtheme' 'FileVersion' $uxVer

        # Ordinal numbers paired with labels; a list of pairs avoids hashtable
        # key-ordering and stringification pitfalls in Windows PowerShell 5.1.
        $ordinalMap = @(
            @{ Ordinal = 135; Label = 'PREFERRED_APP_MODE' },
            @{ Ordinal = 133; Label = 'ALLOW_DARK_MODE_FOR_WINDOW' },
            @{ Ordinal = 136; Label = 'FLUSH_MENU_THEMES' },
            @{ Ordinal = 104; Label = 'REFRESH_COLOR_POLICY' }
        )
        $resolvedAddrs = @{}
        foreach ($entry in $ordinalMap) {
            $o = [int]$entry.Ordinal
            $addr = [DeskBoxOrdinalProbe]::GetProcAddressByOrdinal($hUx, [IntPtr]$o)
            $resolvedAddrs[$o] = $addr
            $label = "ordinal $o ($($entry.Label))"
            if ($addr -eq [IntPtr]::Zero) {
                Add-Finding 'uxtheme' $label 'NOT RESOLVED' 'FAIL' 'DeskBox thumbnail-proxy menu theming cannot work here.'
            } else {
                Add-Finding 'uxtheme' $label "resolved @ $addr" 'INFO' 'Non-empty slot; semantics NOT verified by this probe.'
            }
        }
        $distinct = @($resolvedAddrs.Values | Where-Object { $_ -ne [IntPtr]::Zero } | Sort-Object -Unique)
        $nonZero  = @($resolvedAddrs.Values | Where-Object { $_ -ne [IntPtr]::Zero })
        if ($nonZero.Count -gt 1 -and $distinct.Count -lt $nonZero.Count) {
            Add-Finding 'uxtheme' 'ordinal address collisions' "$($nonZero.Count) resolved, $($distinct.Count) distinct" 'FAIL' 'Two ordinals share a target: at least one is the wrong function.'
        } elseif ($nonZero.Count -gt 0) {
            Add-Finding 'uxtheme' 'ordinal addresses distinct' 'yes' 'OK'
        }

        # Named exports here are ordinal-only on modern builds; record for comparison.
        foreach ($n in 'ShouldAppsUseDarkMode','AllowDarkModeForWindow','SetPreferredAppMode','FlushMenuThemes') {
            $a = [DeskBoxOrdinalProbe]::GetProcAddressByName($hUx, $n)
            Add-Finding 'uxtheme' "named export $n" $(if ($a -eq [IntPtr]::Zero) { 'not exported by name' } else { "$a" })
        }
    }
}

# ------------------------------------- 6. WinRT contract + AdvancedEffectsEnabled
# hazard C3: upstream references UISettings.AdvancedEffectsEnabled directly and
# justifies it by UniversalApiContract v10 (a 19041 contract). 17763 is v8.
$is51 = ($PSVersionTable.PSVersion.Major -lt 6)
if (-not $is51) {
    Add-Finding 'WinRT' 'UISettings probe' 'skipped' 'WARN' 'WinRT type-literal syntax needs Windows PowerShell 5.1; re-run with powershell.exe (not pwsh).'
} else {
    $uiType = Invoke-Safe {
        [void][Windows.UI.ViewManagement.UISettings,Windows.UI.ViewManagement,ContentType=WindowsRuntime]
        [Windows.UI.ViewManagement.UISettings]
    } $null
    if (-not $uiType) {
        Add-Finding 'WinRT' 'UISettings type' 'unavailable' 'FAIL'
    } else {
        Add-Finding 'WinRT' 'UISettings type' 'available' 'OK'
        $api = Invoke-Safe {
            [void][Windows.Foundation.Metadata.ApiInformation,Windows.Foundation.FoundationContract,ContentType=WindowsRuntime]
            [Windows.Foundation.Metadata.ApiInformation]
        } $null
        if ($api) {
            $present = Invoke-Safe {
                [Windows.Foundation.Metadata.ApiInformation]::IsPropertyPresent('Windows.UI.ViewManagement.UISettings','AdvancedEffectsEnabled')
            } 'error'
            if ($present -eq $true) {
                Add-Finding 'WinRT' 'UISettings.AdvancedEffectsEnabled' 'PRESENT' 'OK' 'Hazard C3 does not trigger on this machine.'
            } elseif ($present -eq $false) {
                Add-Finding 'WinRT' 'UISettings.AdvancedEffectsEnabled' 'ABSENT' 'FAIL' 'Hazard C3 triggers: upstream direct reference will fail here.'
            } else {
                Add-Finding 'WinRT' 'UISettings.AdvancedEffectsEnabled' "probe error: $present" 'WARN'
            }
            $evtPresent = Invoke-Safe {
                [Windows.Foundation.Metadata.ApiInformation]::IsEventPresent('Windows.UI.ViewManagement.UISettings','AdvancedEffectsEnabledChanged')
            } 'error'
            Add-Finding 'WinRT' 'AdvancedEffectsEnabledChanged event' "$evtPresent"
        } else {
            Add-Finding 'WinRT' 'ApiInformation' 'unavailable' 'WARN' 'Cannot verify property presence.'
        }
        $inst = Invoke-Safe { New-Object Windows.UI.ViewManagement.UISettings } $null
        if ($inst) {
            Add-Finding 'WinRT' 'UISettings instantiation' 'ok' 'OK'
            $val = Invoke-Safe { $inst.AdvancedEffectsEnabled } 'unreadable'
            Add-Finding 'WinRT' 'AdvancedEffectsEnabled (runtime read)' "$val"
        } else {
            Add-Finding 'WinRT' 'UISettings instantiation' 'failed' 'WARN'
        }
    }
}

# ------------------------------------------------- 7. filesystem / environment
$testRoot = Join-Path $env:TEMP 'deskbox-probe-write-test'
$wOk = Invoke-Safe {
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
    Set-Content -Path (Join-Path $testRoot 'probe.tmp') -Value 'ok' -Encoding ASCII
    $r = Test-Path (Join-Path $testRoot 'probe.tmp')
    Remove-Item $testRoot -Recurse -Force
    $r
} $false
Add-Finding 'FS' 'write to TEMP' $(if ($wOk) { 'ok' } else { 'failed' }) $(if ($wOk) {'OK'} else {'FAIL'})

$longPath = Invoke-Safe { (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -ErrorAction Stop).LongPathsEnabled } 'unset'
Add-Finding 'FS' 'LongPathsEnabled' "$longPath"

$free = Invoke-Safe { Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null } } @()
foreach ($d in $free) {
    Add-Finding 'FS' "drive $($d.Name):" ("free {0:N1} GB / used {1:N1} GB" -f ($d.Free/1GB), ($d.Used/1GB))
}

Add-Finding 'Env' 'IsAdmin' $(Invoke-Safe {
    (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} 'unknown')
Add-Finding 'Env' 'LocalAppData' $env:LOCALAPPDATA
Add-Finding 'Env' 'UserProfile' $env:USERPROFILE

# ------------------------------------------------------------------ 8. Report
$elapsed = (Get-Date) - $script:Started
$failCount = @($script:Findings | Where-Object Level -eq 'FAIL').Count
$warnCount = @($script:Findings | Where-Object Level -eq 'WARN').Count

$verdict = if ($failCount -gt 0) {
    'BLOCKED - one or more FAIL findings; DeskBox 17763 floor lowering is unlikely to succeed as-is.'
} elseif ($warnCount -gt 0) {
    'CONDITIONAL - no hard blockers found; review WARN findings. Ordinal semantics and real startup still need an actual DeskBox run.'
} else {
    'CLEAR - no blockers found. Only an actual DeskBox run can confirm startup.'
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('DeskBox 17763 readiness probe report')
[void]$sb.AppendLine('=====================================')
[void]$sb.AppendLine("generated : $($script:Started.ToString('yyyy-MM-dd HH:mm:ss'))")
[void]$sb.AppendLine("host      : $env:COMPUTERNAME")
[void]$sb.AppendLine("user      : $env:USERDOMAIN\$env:USERNAME")
[void]$sb.AppendLine("duration  : $([math]::Round($elapsed.TotalSeconds,1)) s")
[void]$sb.AppendLine("findings  : $($script:Findings.Count) total, $failCount FAIL, $warnCount WARN")
[void]$sb.AppendLine('')
[void]$sb.AppendLine("VERDICT   : $verdict")
[void]$sb.AppendLine('')
foreach ($group in ($script:Findings | Group-Object Area)) {
    [void]$sb.AppendLine("--- $($group.Name) ---")
    foreach ($f in $group.Group) {
        [void]$sb.AppendLine(("  [{0,-4}] {1} = {2}" -f $f.Level, $f.Item, $f.Value))
        if ($f.Note) { [void]$sb.AppendLine("           note: $($f.Note)") }
    }
    [void]$sb.AppendLine('')
}
[void]$sb.AppendLine('Interpretation notes:')
[void]$sb.AppendLine('  * uxtheme ordinals are private, undocumented exports. "resolved" means the slot is')
[void]$sb.AppendLine('    non-empty and callable; it does NOT prove it is the intended function.')
[void]$sb.AppendLine('  * This probe is read-only. A CLEAR/CONDITIONAL verdict is not proof DeskBox starts.')
[void]$sb.AppendLine('  * Send this file back to the build machine; it becomes specs/evidence/ input.')

if (-not $OutFile) {
    $OutFile = Join-Path $PSScriptRoot ("17763-readiness-{0}.txt" -f $env:COMPUTERNAME)
}
try {
    [System.IO.File]::WriteAllText($OutFile, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ''
    Write-Host '========================================================'
    Write-Host " VERDICT: $verdict"
    Write-Host " report : $OutFile"
    Write-Host '========================================================'
} catch {
    Write-Host "FAILED to write report: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
exit 0
