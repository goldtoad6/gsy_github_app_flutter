# Flare → Rive 资源迁移

2026-09-13：三个旧 `.flr` 已转换为 `.riv`，下拉刷新改用 Rive；生产依赖中移除
`flare_flutter`。转换源码、原始文件、纯 Rive macOS demo 和完整迁移记录迁至
[CarGuo/OldFlareToRive](https://github.com/CarGuo/OldFlareToRive)。

## 应用内改动

- `static/file/loading_world_now.riv`：实际用于下拉刷新的 `Earth Moving`。
- `static/file/Space-Demo.riv`、`flare_flutter_logo_.riv`：替换已有备用素材，保留原动画名称。
- `GSYRivePullAnimation` / `GSYRivePullPainter`：沿用原下拉距离 ×0.6、阈值分支、平方进度及刷新时 2 倍速；用 Flutter Renderer、cover / topCenter，并保留组件边界裁剪。
- 删除两个旧 Flare 控制器与 Flare git 依赖。旧原件由独立仓库 `sources/` 保存，GSY 不再打包 `.flr`。

`launch.riv` 和既有 Rive 版本不变，不涉及状态管理或网络逻辑迁移。

## 构建与复现

使用 `.fvmrc` 指定的 Flutter 3.47.2。不要混用 PATH 上其他 SDK 的 Gradle 配置、
package config 或生成的插件注册文件。迁移移除了 Flare 依赖；2026-09-14 的 iOS
启动修复另移除旧 test_api / matcher override，并由 pub 生成配套锁文件。
版本与故障说明见 [本地环境搭建](local-setup.md)。

转换成品已经提交到独立工程；无需运行 CLI 即可运行纯 Rive demo。修改转换器后，在独立仓库运行：

```sh
python3 -m unittest -v test_conversion
python3 build.py --rive /path/to/rive
```

然后把 `demo/assets/` 中三个 `.riv` 同步至 GSY `static/file/`，核对
`evidence/artifact-hashes.json`。转换和运行时精度限制见独立仓库的
[VALIDATION.md](https://github.com/CarGuo/OldFlareToRive/blob/main/docs/VALIDATION.md)。

## GSY 运行时冒烟

`tool/ai/smoke/rive_refresh.dart` 使用真实 `GSYPullLoadWidget`、刷新 sliver 和
`GSYTabBarWidget` adaptive shell，显示本地 fixture 行，不需要账号和网络数据。

```sh
fvm flutter run -d <device-id> -t tool/ai/smoke/rive_refresh.dart
```

用官方 Dart MCP 连接 DTD，`vm_service` 调用入口中的 `beginPull`、`updatePull`、
`releasePull`、`finishRefresh`，通过 `ScrollPosition.drag` 驱动实际滚动。
`smokeSnapshot` 只读取已挂载的生产组件状态。避免新增 adb 坐标点击脚本。

覆盖小幅下拉、越过阈值后释放、刷新保持、完成回收、再次刷新，并收集 widget tree
与 runtime errors。实际经过分栏路径，须在 Pixel Fold 执行硬件 `emu fold` / `emu unfold`
各验证一次，结束后恢复展开。截图仅补充视觉证据；多显示屏设备应通过
`dumpsys SurfaceFlinger --display-id` 获取屏幕 ID，再传给 `screencap -d`，避免警告文本污染 PNG。

本次证据目录：`tool/ai/smoke/evidence/20260913-rive-refresh/`。
最终设备、状态、编译结论与证据文件见该目录 `VALIDATION.md`。

## 精度边界

地球通过既定严格像素阈值；Space 和 Logo 保留颜色量化及透明边缘差异，未通过同一
严格阈值。转换器未以放宽阈值或图片序列伪装通过。只有实际覆盖到的旧格式子集受到支持；
独立对比工程的 Flare 依赖仅供验证，GSY 和默认 demo 都不需要它。
