# iOS 平台增量规范

> 本文档是 `CODE_STANDARDS.md`（共享基础）的 **iOS 平台增量**。
> 仅包含 iOS 专属的规则，共享规范不在此重复。
> 适用于 Swift 6.2 + iOS 26 + SwiftUI 7。

---

## 一、技术栈（iOS 增量）

| 维度 | 选型 | 备注 |
|------|------|------|
| 最低版本 | iOS 26.0 | Liquid Glass + SwiftUI 7 |
| 导航 | `NavigationStack` + `Router` | 类型安全路由 |
| 触觉 | `.sensoryFeedback()` 修饰符 | 零 UIKit 依赖 |
| 相机 / 扫描 | AVFoundation / DataScannerViewController | 逃生舱口（见 §六） |

---

## 二、导航（NavigationStack + Router）

### 2.1 Router

```swift
import SwiftUI

enum AppDestination: Hashable, Sendable {
    case featureA
    case featureB(id: UUID)
    // 各 App 按需扩展...
}

@MainActor
@Observable
final class Router {
    var path = NavigationPath()
    // 如有 TabView：
    // var selectedTab: AppTab = .home

    func navigate(to destination: AppDestination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
```

### 2.2 NavigationStack 使用

```swift
NavigationStack(path: $router.path) {
    contentView
        .navigationTitle("Title")
        .navigationDestination(for: AppDestination.self) { destination in
            switch destination {
            case .featureA:
                FeatureAView()
            case .featureB(let id):
                FeatureBView(id: id)
            }
        }
}
```

### 2.3 Deep Linking

```swift
// 1. 定义 URL → Destination 映射
extension AppDestination {
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        switch components.path {
        case "/featureA":
            self = .featureA
        case "/featureB":
            guard let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
                  let id = UUID(uuidString: idString) else { return nil }
            self = .featureB(id: id)
        default:
            return nil
        }
    }
}

// 2. 在 App 入口处理
WindowGroup {
    ContentView()
        .onOpenURL { url in
            if let destination = AppDestination(url: url) {
                router.navigate(to: destination)
            }
        }
}
```

---

## 三、设计令牌（iOS 增量）

### 3.1 Colors（iOS 语义色）

```swift
enum DesignTokens {
    enum Colors {
        // iOS 使用 UIColor 语义名称
        static let primary    = Color(.label)
        static let secondary  = Color(.secondaryLabel)
        static let tertiary   = Color(.tertiaryLabel)
        static let surface    = Color(.secondarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        static let accent     = Color(hex: "XXX")   // App 自定义
        static let error      = Color(.systemRed)
        static let success    = Color(.systemGreen)
        static let warning    = Color(.systemOrange)
    }
}
```

### 3.2 Radius（iOS）

```swift
    enum Radius {
        static let small:      CGFloat = 8
        static let medium:     CGFloat = 12
        static let large:      CGFloat = 16
        static let extraLarge: CGFloat = 20
    }
```

### 3.3 HapticToken（SensoryFeedback 映射）

```swift
import SwiftUI

enum HapticToken {
    case buttonTap    // .impact(weight: .light)
    case selection    // .selection
    case success      // .success
    case warning      // .warning
    case error        // .error
    case longPress    // .impact(weight: .medium)

    var feedback: SensoryFeedback {
        switch self {
        case .buttonTap: .impact(weight: .light)
        case .selection: .selection
        case .success:   .success
        case .warning:   .warning
        case .error:     .error
        case .longPress: .impact(weight: .medium)
        }
    }
}
```

---

## 四、触觉反馈（纯 SwiftUI）

不使用 UIKit `UIFeedbackGenerator`。使用 SwiftUI 原生 `.sensoryFeedback()` 修饰符。

```swift
struct HapticFeedbackModifier: ViewModifier {
    let token: HapticToken
    let trigger: Int
    @AppStorage("hapticEnabled") private var hapticEnabled = true

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(token.feedback, trigger: trigger) { _, _ in
                hapticEnabled
            }
    }
}

extension View {
    func hapticFeedback(_ token: HapticToken, trigger: some Equatable) -> some View {
        self.sensoryFeedback(token.feedback, trigger: trigger)
    }
}
```

### 用法

```swift
@State private var saveTrigger = 0

Button("Save") {
    save()
    saveTrigger += 1
}
.hapticFeedback(.success, trigger: saveTrigger)
```

用户可通过 `@AppStorage("hapticEnabled")` 开关控制。

---

## 五、Liquid Glass

- **不覆盖** NavigationBar / TabBar appearance — 系统自动应用 Liquid Glass
- 浮层背景使用 `.regularMaterial` / `.ultraThinMaterial`
- 避免不透明背景阻挡 Glass 效果

```swift
// ✅ 拥抱 Liquid Glass
.toolbarBackgroundVisibility(.automatic, for: .navigationBar)

// ❌ 禁止覆盖系统材质
UINavigationBar.appearance().backgroundColor = .white  // 破坏 Liquid Glass
```

---

## 六、UIKit 逃生舱口

以下场景允许使用 UIKit，须标注逃生舱口注释：

| API | 场景 | 标注 |
|-----|------|------|
| `UIApplication.shared.open(_:)` | 打开外部链接 | `// ESCAPE: UIKit — UIApplication.open` |
| `UNUserNotificationCenter` | 本地通知 | `// ESCAPE: UIKit — UNUserNotificationCenter` |
| `UIActivityViewController` | 系统分享 | `// ESCAPE: UIKit — UIActivityViewController` |
| `AVCaptureSession` | 相机 | `// ESCAPE: UIKit — AVCaptureSession` |
| `DataScannerViewController` | 文字/条码扫描 | `// ESCAPE: UIKit — DataScannerViewController` |

> 逃生舱口代码隔离在 `Core/PlatformBridge/` 或独立的桥接文件中。

---

## 七、PressEffect 按钮样式

```swift
extension View {
    func pressEffect() -> some View {
        self.buttonStyle(PressEffectButtonStyle())
    }
}

struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AnimationTokens.quick, value: configuration.isPressed)
    }
}
```

---

## 八、Dynamic Type 要求

- 使用语义 Font（见共享规范 §五）
- **全流程测试**：`xSmall` → `xxxLarge` 不截断、不溢出
- 避免固定高度容器（用 `.frame(minHeight:)` 替代 `.frame(height:)`）
- Preview 中添加 Dynamic Type 变体：

```swift
#Preview("Large Text") {
    SomeView()
        .environment(\.dynamicTypeSize, .xxxLarge)
}
```

---

## 九、内存压力响应（iOS）

```swift
// 在 App 入口
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
    Task { await imageCache.clearAll() }
    Logger.app.warning("Memory warning received, cache cleared")
}
```

---

## 十、性能预算（iOS）

| 指标 | 目标 | 测量工具 |
|------|------|----------|
| 冷启动 | < 500ms | Instruments → App Launch |
| 内存（idle） | < 80MB | Instruments → Allocations |
| 列表滚动 | 60fps | Instruments → Core Animation |
| SwiftData 查询（100 条） | < 100ms | `os_signpost` |
| ImageCache 命中率 | > 90% | 自定义 `os_signpost` |

---

## 十一、Tuist 配置模板（iOS）

### 11.1 `Tuist.swift`（项目根目录）

```swift
import ProjectDescription

let config = Config()
```

### 11.2 `Tuist/ProjectDescriptionHelpers/Project+App.swift`

```swift
import ProjectDescription

extension Project {
    public static func app(
        name: String,
        bundleId: String,
        displayName: String? = nil,
        infoPlist: [String: Plist.Value] = [:],
        testSources: [String] = ["Tests/UnitTests/**", "Tests/IntegrationTests/**"],
        schemeConfig: Configuration.Variant = .release
    ) -> Project {
        // See actual implementation in Tuist/ProjectDescriptionHelpers/
    }
}
```

### 11.3 `Project.swift`（项目清单）

```swift
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.app(
    name: "ProjectName",
    bundleId: "com.example.projectName",
    displayName: "ProjectName"
)
```

---

## 十二、CI/CD 配置模板（iOS）

```yaml
name: iOS CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-and-test:
    runs-on: macos-16
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode 26.2
        run: sudo xcode-select -s /Applications/Xcode_26.2.app

      - name: Cache DerivedData
        uses: actions/cache@v4
        with:
          path: ~/Library/Developer/Xcode/DerivedData
          key: ${{ runner.os }}-${{ hashFiles('**/*.swift') }}
          restore-keys: ${{ runner.os }}-

      - name: Install Tuist
        run: curl -Ls https://install.tuist.io | bash

      - name: Install SwiftLint
        run: brew install swiftlint

      - name: Generate Xcode project
        run: tuist generate --no-open

      - name: SwiftLint
        run: swiftlint lint --strict --reporter github-actions-logging

      - name: Build & Test
        run: |
          xcodebuild test \
            -project ProjectName.xcodeproj \
            -scheme ProjectName \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.0' \
            -enableCodeCoverage YES \
            -resultBundlePath TestResults.xcresult \
            SWIFT_VERSION=6.2 \
            SWIFT_STRICT_CONCURRENCY=complete

      - name: Check Coverage
        run: |
          xcrun xccov view --report TestResults.xcresult --json | \
            python3 -c "
          import json, sys
          data = json.load(sys.stdin)
          coverage = data['lineCoverage']
          print(f'Coverage: {coverage:.1%}')
          if coverage < 0.50:
              print('ERROR: Coverage below 50%% threshold')
              sys.exit(1)
          "
```

---

## 十三、Checklist（iOS 增量）

> 在共享 Checklist（见 `CODE_STANDARDS.md` §二十一）基础上：

- [ ] `Core/Constants/HapticTokens.swift` — HapticToken 枚举
- [ ] `Core/Extensions/View+PressEffect.swift` — PressEffect 按钮样式
- [ ] DesignTokens 使用 iOS 语义色（`.label` / `.secondarySystemBackground`）
- [ ] Radius 使用 iOS 值（8/12/16/20）
- [ ] NavigationStack + Router 导航模式
- [ ] Deep Linking URL → AppDestination 映射
- [ ] Dynamic Type 全流程测试（xSmall → xxxLarge）
- [ ] Liquid Glass 未被覆盖
- [ ] `App/PrivacyInfo.xcprivacy` 位于 App/ 目录
- [ ] CI destination = `iPhone 17 Pro,OS=26.0`
- [ ] 冷启动 < 500ms，内存 < 80MB
