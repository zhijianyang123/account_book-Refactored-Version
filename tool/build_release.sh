#!/usr/bin/env bash
# 构建精简版正式签名安装包（按 ABI 拆分）。
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
set -euo pipefail

cd "$(dirname "$0")/.."

flutter build apk --release \
  --split-per-abi \
  --target-platform android-arm,android-arm64 \
  --obfuscate \
  --split-debug-info=build/symbols

mkdir -p dist
for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
  cp "$apk" dist/
  echo "  $(basename "$apk")  ($(du -h "$apk" | cut -f1))"
done
echo
echo "发布包已复制到 dist/ 目录。"
