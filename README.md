# 记账本 (Ledger)

一个本地离线的 Flutter 记账应用，支持收支记录、统计图表、预算管理、数据导入导出等功能。数据仅保存在设备本地，无需联网。

**当前版本：v2.1.0**

## 更新日志

### v2.1.0
- 安装包体积优化：默认不再产出包含三种 CPU 架构的通用 APK，改为按 ABI 拆分（arm64-v8a / armeabi-v7a），并剔除仅模拟器使用的 x86_64
- 开启 Dart 符号混淆（`--obfuscate`），进一步压缩 `libapp.so`
- 精简本地化数据：仅打包英文与简体中文的语言资源，AOT 快照去掉其余约 110 种语言
- 修复“关于”页与导出备份中的版本号与应用版本不一致的问题
- 通用 APK 由 ~51.5 MB 降至 arm64-v8a ~16.5 MB、armeabi-v7a ~14.0 MB

### v2.0.0
- 移除 `keframe` 依赖，简化统计页渲染逻辑，直接渲染所有卡片
- 统计页动画过渡设置为 `Duration.zero`，消除动画延迟
- 移除 `keframe` 相关许可声明
- 版本号升级至 `2.0.0+2`

### v1.0.0
- 项目初始化
- 底部三 Tab 架构（明细、统计、我的）
- 记一笔、分类管理、预算管理、数据导入导出

## 功能概览

- **明细**：按日期分组查看账单，支持搜索、筛选、左滑删除、批量操作
- **统计**：支出/收入饼图、趋势折线图、分类汇总、预算执行进度
- **我的**：分类管理、预算管理、数据导入导出、应用设置
- **记一笔**：快速记录支出或收入，支持分类九宫格选择、金额快捷计算
- **数据管理**：JSON 格式导出/导入备份，支持覆盖/合并/追加模式
- **多语言**：支持简体中文和 English
- **主题**：浅色/深色/跟随系统

## 使用技术

| 技术 | 用途 |
|------|------|
| Flutter 3.x | 跨平台 UI 框架 |
| Provider | 状态管理 |
| sqflite | 本地 SQLite 数据库 |
| fl_chart | 图表渲染（饼图、折线图） |
| intl | 日期时间格式化 |
| file_picker | 文件选择（导入/导出） |
| Material 3 | UI 设计语言 |
| 华为沉浸光感 | 视觉设计规范（悬浮感、流光动效） |

## 项目结构

```
lib/
├── main.dart                 # 应用入口，初始化 Provider
├── app.dart                  # MaterialApp 配置（主题、语言）
├── models/                   # 数据模型
│   ├── app_settings.dart     # 应用设置模型
│   ├── category.dart         # 分类模型
│   ├── budget.dart           # 预算模型
│   ├── tx_record.dart        # 交易记录模型
│   ├── tx_filter.dart        # 筛选模型
│   ├── saved_filter.dart     # 保存的筛选条件
│   ├── import_models.dart    # 导入相关模型
│   └── backup_envelope.dart  # 备份信封
├── providers/                # 状态管理
│   ├── settings_provider.dart
│   ├── category_provider.dart
│   ├── transaction_provider.dart
│   ├── budget_provider.dart
│   ├── stats_provider.dart
│   └── saved_filter_provider.dart
├── db/                       # 数据库 DAO
│   ├── app_database.dart     # 数据库实例
│   ├── category_dao.dart
│   ├── transaction_dao.dart
│   ├── budget_dao.dart
│   ├── settings_dao.dart
│   └── saved_filter_dao.dart
├── screens/                  # 页面
│   ├── root_shell.dart       # 底部导航主壳
│   ├── detail/               # 明细页
│   │   ├── detail_screen.dart
│   │   ├── transaction_edit_screen.dart
│   │   └── search_filter_screen.dart
│   ├── stats/                # 统计页
│   │   └── stats_screen.dart
│   ├── profile/              # 我的页
│   │   └── profile_screen.dart
│   ├── manage/               # 管理页
│   │   ├── category_manage_screen.dart
│   │   └── budget_manage_screen.dart
│   ├── data/                 # 数据管理
│   │   ├── data_manage_screen.dart
│   │   ├── export_options_screen.dart
│   │   └── import_preview_screen.dart
│   └── settings/             # 设置
│       ├── settings_screen.dart
│       └── about_screen.dart
├── widgets/                  # 通用组件
│   ├── amount_keypad.dart    # 金额键盘
│   ├── category_grid.dart    # 分类九宫格
│   ├── transaction_tile.dart # 账单列表项
│   ├── filter_sheet.dart     # 筛选面板
│   ├── category_picker_sheet.dart
│   ├── wheel_pickers.dart    # 滚轮选择器
│   └── immersive.dart        # 沉浸光感动效
├── theme/                    # 主题
│   └── app_theme.dart
├── utils/                    # 工具类
│   ├── money.dart            # 金额处理（分）
│   ├── date_x.dart           # 日期扩展
│   ├── stats_calculator.dart # 统计计算
│   ├── calculator.dart       # 快捷计算
│   ├── constants.dart        # 常量
│   ├── app_icons.dart        # 图标
│   ├── backup_codec.dart     # 备份编解码
│   └── app_refresh.dart      # 刷新控制
├── services/                 # 服务
│   └── import_export_service.dart
└── l10n/                     # 国际化
    ├── app_localizations.dart
    └── app_localization_delegates.dart  # 仅中/英的本地化 delegate（精简体积）

tool/
├── build_release.ps1         # Windows 一键构建精简正式包
└── build_release.sh          # macOS / Linux 一键构建精简正式包
```

## 数据模型

金额以"分"为单位存储（整数），显示时除以 100。

| 表 | 字段 |
|----|------|
| categories | id, name, type, icon, color, sort_order, parent_id, is_default, is_hidden |
| accounts | id, name, type, balance_cents, initial_balance_cents, currency, icon, color, include_in_net_worth, is_hidden |
| transactions | id, type, amount_cents, category_id, account_id, date, time, note, merchant, reimbursement_status, created_at, updated_at, deleted_at |
| tags | id, name, color |
| budgets | id, period_type, amount_cents, category_id, start_date, end_date, include_transfer |
| settings | key, value |

默认分类：餐饮、交通、购物、居家、娱乐、医疗

## 安装与运行

### 前置条件

- Flutter 3.x SDK
- Android Studio 或 VS Code
- Android 设备或模拟器

### 获取项目

```bash
git clone https://github.com/zhijianyang123/account_book-Refactored-Version.git
cd account_book-Refactored-Version
```

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
flutter run
```

### 构建 APK

为获得最小体积，使用随仓库提供的脚本按 ABI 拆分构建：

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File tool/build_release.ps1
```

```bash
# macOS / Linux
bash tool/build_release.sh
```

脚本等价于：

```bash
flutter build apk --release \
  --split-per-abi \
  --target-platform android-arm,android-arm64 \
  --obfuscate --split-debug-info=build/symbols
```

生成的 APK 位于 `build/app/outputs/flutter-apk/`，并会复制到 `dist/`：

| 文件 | 适用设备 | 体积 |
|------|----------|------|
| `app-arm64-v8a-release.apk` | 绝大多数现代手机（推荐） | ~16.5 MB |
| `app-armeabi-v7a-release.apk` | 较老的 32 位设备 | ~14.0 MB |

> **注意**：发布签名配置位于 `android/key.properties`，keystore 为 `android/app/account_new.jks`，两者均已被 `.gitignore` 排除，不会上传到仓库。只要沿用同一 keystore，新包即可直接覆盖安装旧版本。

### 安装包体积优化说明

默认的 `flutter build apk --release` 会把三种 CPU 架构（`arm64-v8a`、`armeabi-v7a`、`x86_64`）全部打进同一个通用 APK，其中仅模拟器使用的 `x86_64` 就占约 19 MB。本项目的优化策略：

1. **按 ABI 拆分**：每个架构单独打包，并剔除 `x86_64`，体积直接下降约 2/3。
2. **Dart 符号混淆**：`--obfuscate` 让 `libapp.so` 再小约 1 MB；`--split-debug-info` 导出符号表用于还原崩溃堆栈（不入 APK）。
3. **精简本地化**：`lib/l10n/app_localization_delegates.dart` 只引用英文与简体中文的翻译包，使 AOT 快照丢弃其余约 110 种语言（约 0.2 MB）。
4. **图标 tree-shaking**：Flutter 默认会把 `MaterialIcons` 由 ~1.6 MB 裁剪到 ~18 KB。

如需兼容模拟器的通用包，可执行 `flutter build apk --release`（体积较大）。

## 使用指南

### 记一笔

1. 点击底部导航"明细"Tab
2. 点击右下角"+"按钮
3. 选择支出/收入类型
4. 输入金额（支持快捷计算，如 `12+8` 自动得出 `20`）
5. 选择分类（九宫格）
6. 选择日期
7. 填写备注（可选）
8. 点击"保存"或"保存并继续"

### 筛选与搜索

1. 在明细页点击搜索/筛选图标
2. 设置类型、分类、金额范围、日期范围等条件
3. 支持组合筛选
4. 可保存常用筛选条件供后续快速调用

### 数据备份与迁移

1. 进入"我的" → "数据管理"
2. **导出**：选择导出范围（全部/按日期/按月份/按分类），点击保存到本地
3. **导入**：选择备份 JSON 文件 → 预览 → 选择导入模式（覆盖/合并/追加）→ 执行导入
4. 导入过程使用事务，失败自动回滚

### 设置

进入"我的" → "应用设置"：

- **主题**：浅色/深色/跟随系统
- **语言**：简体中文/English
- **货币单位**：人民币 (CNY)
- **一周第一天**：周一/周日
- **默认记账类型**：支出/收入
- **记账偏好**：保存后继续记下一笔、金额快捷计算、自动补零
- **颜色方案**：自定义支出/收入颜色

## 快捷键与技巧

- 金额键盘支持快捷计算：输入 `12+8` 自动得出 `20`
- 左滑账单可删除，删除后可撤销
- 长按进入多选模式，支持批量删除和修改分类
- 点击统计页饼图扇区可跳转到明细页并自动筛选该分类
- 删除分类后，关联账单自动回退到"无类型"

## 开源许可

本项目开源，详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request。
