# 478 呼吸

基于 4-7-8 呼吸法（吸气 4 秒 → 屏息 7 秒 → 呼气 8 秒，循环往复）的极简呼吸引导 App。

## 功能

- 呼吸圆环随吸气/屏息/呼气实时放大、保持、缩小，配合秒数倒计时。
- 每次切换阶段播放提示音（可关闭）。
- 支持定时停止（5 / 7 / 15 分钟或不限时），并通过 Android 前台服务在**熄屏/切后台后**继续计时和播放提示音，直到设定时长结束。
- 可选"训练时保持屏幕常亮"。

## 权限说明

只申请两类权限，且都直接服务于"熄屏后台继续工作"这一个需求：

| 权限 | 用途 |
| --- | --- |
| `POST_NOTIFICATIONS`（运行时权限，仅 Android 13+ 弹窗询问） | 前台服务要求常驻一条通知，用来告知系统"计时仍在进行"。 |
| `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_MEDIA_PLAYBACK` / `WAKE_LOCK`（普通权限，系统自动授予，不会弹窗） | 让计时与提示音播放在息屏后继续运行。 |

不申请相机、麦克风、定位、通讯录、存储等任何与功能无关的权限。

## 技术栈与架构

- **Flutter**（仅 Android，`android/` 工程为手写模板，未运行过 `flutter create`）。
- `lib/core/`：纯 Dart 的呼吸状态机（`BreathingSession`），不依赖 Flutter/平台 API，可在 `test/` 下直接单元测试。
- `lib/services/foreground_task_handler.dart`：运行在 [flutter_foreground_task](https://pub.dev/packages/flutter_foreground_task) 提供的后台 isolate 中，是计时与提示音播放的唯一权威时钟；UI 只是订阅它汇报的状态做渲染，这样息屏、切后台、App 被系统回收 UI 引擎都不会打断计时。
- `assets/sounds/*.wav`：本地合成的提示音（`scripts` 未随包提供，由仓库作者用 Python 生成后直接提交为二进制资源）。

## 本地不编译，全部走 GitHub Actions

`.github/workflows/android-build.yml` 会在每次 push / PR / 手动触发时：

1. `flutter analyze` + `flutter test`（跑 `test/breathing_session_test.dart`）。
2. 用 CI runner 自带的 `gradle wrapper --gradle-version 8.10` **现场生成** Gradle Wrapper（包括二进制的 `gradle-wrapper.jar`），因此仓库里不需要提交这个二进制文件。
3. `flutter build apk --release`，把裸 APK 发布到一个滚动更新的 GitHub Release（tag 固定为 `latest`）。

### 如何拿到安装包

直接打开 **[Releases 页面](../../releases/latest)**（仓库首页右侧栏也有入口），下载 `breathe478.apk` 这个文件——它是未压缩的裸 APK，不是 Actions Artifact 那种登录后才能下载、还带 zip 壳的东西。传到手机后在"设置里允许安装未知来源应用"，点击文件即可安装。

每次成功构建都会覆盖同一个 `latest` release，所以这个链接长期有效，不用每次都去找最新的一次运行。

当前 release 包用的是 Flutter 默认的 debug 签名（`flutter build apk --release` 的默认行为），仅适合直接安装到自己手机测试，**不能**直接上架 Google Play——上架前需要生成正式 keystore，作为 GitHub Secret 注入构建。

## iOS

暂未接入。当前没有 Apple Developer Program 付费账号，无法做真机长期签名安装，因此 `ios/` 工程还未创建，CI 里也没有 iOS 构建任务。等有账号后，可以：

1. 用 `flutter create --platforms=ios .` 补出 `ios/` 工程。
2. 在 GitHub Actions 中加一个 `macos-latest` 的 job，用 Secrets 存放签名证书/描述文件，`flutter build ipa` 后通过 TestFlight 分发。

## 目录结构

```
lib/
  core/            纯 Dart 状态机，无平台依赖
  services/        前台服务、音频提示、设置持久化
  ui/               界面与主题
android/            手写的 Android 工程模板（未提交 gradlew/wrapper 二进制）
assets/sounds/      提示音 WAV
test/               单元测试
```
