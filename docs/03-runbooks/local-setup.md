# 本地开发环境

## 基线要求

- Flutter SDK：**3.47.2 stable**（仓库根 [`.fvmrc`](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/.fvmrc) 已锁定；CI 的 `subosito/flutter-action@v2` 通过 `flutter-version-file: .fvmrc` 读同一份契约，避免本地 / CI 版本漂移）
- Dart SDK 下限：**3.13.0**（pubspec.yaml `environment.sdk: '>=3.13.0 <4.0.0'`）
- 推荐使用 [FVM](https://fvm.app/) 管理版本：`fvm install 3.47.2 && fvm use 3.47.2`
- iOS 部署目标下限：**iOS 15.0**（Flutter 3.47 官方硬要求）
- Android 工具链：AGP **9.0.1** + Gradle **9.1.0** + Kotlin **2.2.20**
- Java：Android 构建需要 JDK 17+（Gradle 9 要求）
- Android SDK：`compileSdk=35`（AGP 9 最低 34）

## 首次启动

1. 安装 Flutter（或 `fvm install 3.47.2`），并确认 `flutter doctor`
2. 运行 `flutter pub get`
3. 创建 `lib/common/config/ignoreConfig.dart`
4. 填入 GitHub OAuth 所需的 `CLIENT_ID` 和 `CLIENT_SECRET`

示例：

```dart
class NetConfig {
  static const CLIENT_ID = "xxxx";
  static const CLIENT_SECRET = "xxxx";
}
```

## 常用命令

```bash
flutter pub get
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release --target-platform=android-arm64 --no-shrink
```

## 什么时候需要重新生成

- 改模型、序列化、Riverpod 注解或 env 源文件时，跑 `build_runner`
- 改 ARB 多语言文件时，重新生成本地化输出

## 常见失败原因

- 缺少 `ignoreConfig.dart`
- Flutter 版本不匹配（本地未按 [`.fvmrc`](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/.fvmrc) 切到 3.47.2，可能撞到 iOS 15.0 部署目标 / AGP 9 兼容性等新硬约束）
- 拉包时网络或代理异常
- 手改生成文件但没同步源文件

### iOS 编译提示 `Declarer` / `Invoker` 缺失（2026-09-14）

若错误来自 `test_core/lib/src/scaffolding.dart`，先检查测试包的配套版本。
本次失败时实际加载了 `test_core 0.6.20`，但旧 `dependency_overrides` 强制使用
`test_api 0.7.7` 与 `matcher 0.12.17`，绕过了依赖自身的兼容范围。
`riverpod` 的运行库导入 `package:test/test.dart`，因此正常 App 编译也会受影响。

修复是移除这两个过时 override，让 `flutter_test` 与 `test/test_core` 共同求解。
Flutter 3.47.2 下解析结果为 `test 1.31.1`、`test_core 0.6.18`、
`test_api 0.7.12`、`matcher 0.12.20`。不要单独换成另一组硬编码 override。
依据见 [Dart dependency overrides 文档](https://dart.dev/tools/pub/dependencies#dependency-overrides)
及当前 Flutter SDK 的 `packages/flutter_test/pubspec.yaml`。

使用同一个 SDK 和包源重新生成依赖配置；本仓库锁文件使用 `pub.flutter-io.cn`：

```bash
PUB_HOSTED_URL=https://pub.flutter-io.cn fvm flutter pub get
fvm flutter test --no-pub test/app/smoke_post_frame_test.dart
PUB_HOSTED_URL=https://pub.flutter-io.cn fvm flutter run -d <ios-simulator-id>
```

不要只还原 `pubspec.lock` 而保留旧 `.dart_tool/package_config.json`，也不要为了这个
Dart 编译错误去删除 Pods、改变 SwiftPM 配置或恢复 Flare 依赖。修复前后测试与 iOS
运行证据保存在 `tool/ai/smoke/evidence/20260914-ios-test-dependencies/`。

本次修复后，iOS 模拟器已进入真实首页并跑通 Rive 下拉刷新，Android release APK
也构建成功。同次交互另捕获 `IOSScrollViewFlingVelocityTracker` 的时间戳倒退断言；
它发生在运行阶段，具体触发原因尚未确认，不能用这次依赖修复宣称它也已解决。
原始错误、后续刷新无新增错误的记录与验证边界见该目录的 `VALIDATION.md`。
同次日志还有已捕获的 HTTP 401，因此动画生命周期通过不等同于服务端数据刷新成功。

## 当前本地验证策略

仓库已有 `test/` 与 `patrol_test/` 双自动化测试目录，本地验证走"静态检查 + 单测 + Patrol 集成 + 手工冒烟"的组合：

- 静态：`flutter analyze`
- 单测：`fvm flutter test`（全量约 353 case）
- 集成：Patrol 场景见 [patrol-regression.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/04-quality/patrol-regression.md)
- 构建：对构建相关改动跑 APK 构建
- 冒烟：真机 / 模拟器上手工验证改动功能，走 `mcp_dart` 抓 widget tree + runtime errors 作为主证据
