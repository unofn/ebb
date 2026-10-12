# 把 `flutter build windows --release` 的产物打成安装程序和免安装 zip。
#   pwsh tool/packaging/windows/package.ps1 -Version 0.1.0
# 产物：build/dist/ebb-<版本>-windows-setup.exe、build/dist/ebb-<版本>-windows.zip
param([Parameter(Mandatory)][string]$Version)
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path "$PSScriptRoot/../../..").Path
$release = Join-Path $root 'build/windows/x64/runner/Release'
if (-not (Test-Path "$release/ebb.exe")) { throw "找不到 $release/ebb.exe，先运行 flutter build windows --release" }
$release = (Resolve-Path $release).Path
$dist = (New-Item -ItemType Directory -Force (Join-Path $root 'build/dist')).FullName

# 干净的 Windows 10 没有 VC++ 运行库，flutter build 也不带，照 Flutter 的发布说明放到 exe 旁边。
$vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$redist = Get-ChildItem "$vs/VC/Redist/MSVC" -Directory | Where-Object Name -Match '^\d' |
  Sort-Object { [version]$_.Name } | Select-Object -Last 1
$crt = Get-ChildItem "$($redist.FullName)/x64" -Directory -Filter 'Microsoft.VC*.CRT' | Select-Object -First 1
if (-not $crt) { throw "找不到 VC++ 运行库目录：$($redist.FullName)/x64" }
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
  Copy-Item (Join-Path $crt.FullName $dll) $release
}
Write-Host "VC++ 运行库：$($crt.FullName)"

# 构建机自带 Inno Setup 6；找不到时用 choco 装。
$iscc = (Get-Command iscc -ErrorAction SilentlyContinue).Source
if (-not $iscc) { $iscc = "${env:ProgramFiles(x86)}/Inno Setup 6/ISCC.exe" }
if (-not (Test-Path $iscc)) {
  choco install innosetup -y --no-progress | Out-Host
  $iscc = "${env:ProgramFiles(x86)}/Inno Setup 6/ISCC.exe"
}
& $iscc "/DAppVersion=$Version" "/DBuildDir=$release" "/DOutputDir=$dist" (Join-Path $root 'windows/installer/ebb.iss')
if ($LASTEXITCODE -ne 0) { throw "ISCC 失败：$LASTEXITCODE" }

# 免安装版：解压出一个 Ebb 文件夹。
$stage = Join-Path ([IO.Path]::GetTempPath()) "ebb-zip-$Version"
Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
Copy-Item -Recurse $release (Join-Path $stage 'Ebb')
$zip = Join-Path $dist "ebb-$Version-windows.zip"
Remove-Item -Force $zip -ErrorAction SilentlyContinue
& 7z a -tzip $zip (Join-Path $stage 'Ebb') | Out-Null
if ($LASTEXITCODE -ne 0) { throw "7z 失败：$LASTEXITCODE" }

Get-ChildItem $dist -Filter "ebb-$Version-windows*" | ForEach-Object { Write-Host $_.FullName }
