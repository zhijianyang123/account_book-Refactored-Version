# 构建精简版正式签名安装包（按 ABI 拆分）
#
# 产物（远小于默认的通用 APK）：
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   —— 主流真机（推荐）
#   build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk —— 老设备
#
# 说明：
#   --split-per-abi            每个 ABI 单独打包，去掉其余架构的原生库
#   --target-platform ...      只保留 arm/arm64，剔除仅模拟器使用的 x86_64
#   --obfuscate                Dart 符号混淆，进一步压缩 libapp.so
#   --split-debug-info         混淆后导出符号表，便于还原崩溃堆栈（不会打进 APK）
#
# 签名读取 android/key.properties + android/app/account_new.jks（不入库）。
#
# 用法：powershell -ExecutionPolicy Bypass -File tool/build_release.ps1

$ErrorActionPreference = 'Stop'

Push-Location (Join-Path $PSScriptRoot '..')
try {
    flutter build apk --release `
        --split-per-abi `
        --target-platform android-arm,android-arm64 `
        --obfuscate `
        --split-debug-info=build/symbols

    $out = 'build/app/outputs/flutter-apk'
    New-Item -ItemType Directory -Force -Path dist | Out-Null
    Get-ChildItem "$out/app-*-release.apk" | ForEach-Object {
        Copy-Item $_.FullName dist -Force
        $mb = [math]::Round($_.Length / 1MB, 2)
        Write-Host ("  {0}  ({1} MB)" -f $_.Name, $mb)
    }
    Write-Host "`n发布包已复制到 dist/ 目录。"
} finally {
    Pop-Location
}
