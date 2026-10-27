# 测试报告（2026-10-27）

环境：Linux，Flutter 3.47.8 / Dart 3.13.7，Temurin JDK 21.0.9（下载已验证 SHA-256），Android SDK 36。

- `flutter pub get`：成功，生成 pubspec.lock。
- `flutter analyze`：通过，No issues found。
- `flutter test`：8 项通过，0 失败。覆盖词/页码校验、大小写重复、排序和搜索、CRUD、关闭重开持久化、JSON 往返及非法备份、重复导入策略、插入及更新失败事务回滚、完整备份恢复、含 1000 条记录的分组跳转索引。另验证真实 Flutter 录入界面仅含两个业务字段、负页码报错、弹窗关闭无异常。
- 字母索引测试验证数据到滚动位置的映射；未等同于设备触摸与滚动验收。
- `flutter build apk --release`：成功（396.8 秒），生成 `dist/android/WordContacts.apk`，约 55.7 MB。
- `apksigner verify --verbose --print-certs`：通过 APK v2 签名校验，Android Debug 测试签名。
- `aapt dump badging`：包名 `com.wordcontacts.app`，显示名称 Word Contacts，版本 1.0.0，最低 Android 7.0（API 24），目标 API 36。
- 构建有 file_picker 使用旧 Kotlin Gradle Plugin 的未来兼容性警告；当前版本构建成功。
- Windows 构建/安装包：未运行，Linux 不具备 Windows C++ 工具链与 Inno Setup。
- Windows/Android 真机 UI、性能、安装卸载和系统文件选择器：未验证。

已修复最初的 SDK 网络下载与只读缓存问题、界面语法错误及页数负号被过滤的问题。当前源码已包含 Windows/Android 官方平台工程及正式签名配置模板。

首次构建的 Gradle 代理、NDK 自动下载和完整 JDK 缺失问题已解决。当前证书校验保持开启。PowerShell / Inno Setup 脚本尚未在 Windows 执行；不将其标为构建通过。
