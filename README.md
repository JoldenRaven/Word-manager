# Word Contacts

离线 SQLite 单词与页码管理应用，目标为 Windows 10/11、Android 7.0 及以上。包含原生平台工程与锁定依赖；数据层自动化测试通过，设备验收状态见 [测试报告](docs/TEST_REPORT.md)。

## 构建

开发版本：Flutter 3.47.8 stable / Dart 3.13.7，JDK 21、Android SDK 36。Windows 构建还需要 Visual Studio 2022 的“使用 C++ 的桌面开发”、Windows SDK、CMake；安装程序需要 Inno Setup 6。从现有源码构建，不需要再次执行 flutter create。

```powershell
flutter pub get --enforce-lockfile
flutter analyze
flutter test
powershell -ExecutionPolicy Bypass -File scripts/build_all.ps1
```

可分别执行 `scripts/build_windows.ps1`、`scripts/build_android.ps1` 和 `scripts/package.ps1`。Linux/macOS 可执行 `scripts/build_android.sh`。源码打包可执行 `python scripts/source_zip.py`。

输出：`dist/windows/WordContactsPortable/`、`dist/windows/WordContactsPortable.zip`、`dist/windows/WordContactsSetup.exe`、`dist/android/WordContacts.apk`、`dist/source/WordContacts_Source.zip`。只有构建成功才会生成对应文件；本次 Android APK 已实际构建并通过签名校验；Windows 成品尚未构建，具体状态以测试报告为准。已有便携目录时打包停止，备份并移走该目录后再执行，避免覆盖个人数据。

Android 应用 ID 为 `com.wordcontacts.app`。默认使用调试密钥签署 release，限本地测试。正式发布时复制 `android/key.properties.example` 为 `android/key.properties` 并在本机填写私有密钥路径和密码，Gradle 会自动选择该签名。升级已有安装须使用相同签名；切换签名前先导出数据。禁止提交真实签名文件。

## 使用

点击加号新增单词及页码，点击记录编辑，垃圾桶按钮确认删除。只允许英文字母及内部连字符、撇号；页数为 1 至 2147483647。重复单词不区分大小写，更新前确认。编辑为另一个已存在的单词时，仅更新该已有词页码，保留原记录。

顶部搜索为不区分大小写的包含搜索（也涵盖前缀）。右侧字母跳到对应组。更多菜单可导入/导出 JSON 和显示数据库实际路径；导入先验证整份文件，再确认跳过重复或更新已有页码，在事务中完成。备份内重复项按文件顺序处理。

Windows 便携目录可写时使用 `data/words.db` 并创建 `backups/`；受保护安装目录或开发用 build 目录改用当前用户应用支持目录，菜单展示实际路径。关闭应用后复制完整便携目录即可携带数据；若使用回退目录，使用 JSON 迁移。安装脚本不包含个人数据库，卸载默认保留用户数据。

Android 使用应用私有目录。将 APK 传到手机，按系统提示允许该来源安装。通过系统文件选择界面导入电脑 JSON；从菜单导出手机 JSON，再复制到电脑。卸载应用可能清除数据库，请先备份。

## 手动验收（尚需设备执行）

1. 新增 Apple、banana、don't；检查大小写排序、重复提示、非法页数拒绝及编辑删除。
2. A–Z 各添加记录，点击末尾字母检查真实跳转；搜索不同大小写、前缀、子串及无结果。
3. 关闭、重启应用和系统，确认数据仍在。
4. Windows 可写便携目录、迁移目录、受保护安装目录各验证实际路径，卸载后确认用户数据保留。
5. Windows 与 Android 双向导出导入，验证重复跳过/更新、非法文件报错且原数据不变。
6. 验证手机小屏、横屏、软键盘和 Windows 窗口调整；测试大量数据的滚动与搜索。
