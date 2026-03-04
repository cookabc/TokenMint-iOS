# Apple 平台项目/代码规范（共享基础）

> 跨 iOS / macOS 的通用开发规范。平台专属规则见 `CODE_STANDARDS_iOS.md` 和 `CODE_STANDARDS_macOS.md`。
> 制定日期：2026-02-27 | 最后修订：2026-02-28

> [!IMPORTANT]
> **持续演进原则**：本规范应随 Swift 语言和平台 SDK 的演进而更新。
> 当 Swift 引入新语言特性或 SwiftUI / SwiftData 提供更优 API 时，
> 应及时评估并将最佳实践纳入。每次更新须注明修订日期与变更摘要。

> [!NOTE]
> **三文档结构**：
> - **本文档**：所有平台共享的架构、模式、规范
> - **CODE_STANDARDS_iOS.md**：iOS 专属增量（导航、触觉、Liquid Glass 等）
> - **CODE_STANDARDS_macOS.md**：macOS 专属增量（多窗口、全局热键、NSPanel 等）

---

## 一、技术栈（共享）

| 维度 | 选型 | 备注 |
|------|------|------|
| 语言 | Swift 6.2 | `SWIFT_STRICT_CONCURRENCY = complete` |
| UI | SwiftUI 7 | 平台原生 API 仅限逃生舱口场景（见 §四） |
| 观察 | `@Observable` | 禁止 `ObservableObject` / `@Published` / `@StateObject` |
| 依赖注入 | 协议 + 构造器注入 + `@Environment` | 无第三方 DI，无上帝容器 |
| 并发 | Structured Concurrency | 默认禁止 Combine / GCD（见 §四 逃生舱口） |
| 持久化 | SwiftData（默认） | 加密场景允许 Keychain / 加密文件 |
| 网络 | URLSession（默认） | 复杂场景允许 Alamofire（见 §九） |
| 测试 | Swift Testing（单元/集成）+ XCTest（UI） | `import Testing` + `@Test` + `#expect` |
| 本地化 | `Localizable.xcstrings` + `String(localized:)` | 中英双语 |
| Lint | SwiftLint | 零 error，零 warning |
| 项目生成 | XcodeGen（`project.yml`） | |
| CI | GitHub Actions（macOS 16 runner） | Xcode 26.2 |

> 平台版本、导航方式、特有 API 等见各平台增量文档。

---

## 二、目录结构

```
ProjectName/
├── App/
│   ├── ProjectNameApp.swift          # @main 入口，组装完整依赖图
│   ├── ContentView.swift             # 顶层容器（TabView / NavigationSplitView）
│   ├── Info.plist
│   ├── PrivacyInfo.xcprivacy         # iOS 放 App/；macOS 放 Resources/
│   └── Assets.xcassets/
│
├── Core/
│   ├── Constants/
│   │   ├── DesignTokens.swift        # 色彩 / 字体 / 间距 / 圆角
│   │   └── AnimationTokens.swift     # 动效曲线 / 时长
│   ├── Extensions/
│   │   ├── Color+Extensions.swift    # Color(hex:) 初始化器
│   │   └── View+Extensions.swift     # 通用修饰符
│   ├── Models/                       # SwiftData @Model / Sendable struct
│   ├── Protocols/                    # 所有 Service / Repository 协议
│   ├── Repositories/                 # 数据仓库实现
│   ├── Services/                     # 业务服务实现
│   ├── Navigation/
│   │   └── Router.swift              # @Observable @MainActor Router
│   └── Utils/
│       ├── Logger.swift              # os.Logger 扩展
│       ├── AppError.swift            # 统一错误枚举（含恢复建议）
│       ├── ViewState.swift           # ViewState<T> 泛型枚举（含 .retrying）
│       ├── Accessibility.swift       # ID / Label / Hint 三枚举
│       └── AppThemeOption.swift      # System / Light / Dark
│
├── Features/
│   └── FeatureName/
│       ├── Components/               # 功能私有子组件
│       ├── ViewModels/               # @Observable @MainActor ViewModel
│       └── Views/                    # SwiftUI View
│
├── Resources/
│   ├── Localizable.xcstrings         # 中英双语 String Catalog
│   └── PreviewContent/
│
├── Tests/
│   ├── UnitTests/                    # Swift Testing
│   ├── IntegrationTests/             # SwiftData 集成测试
│   └── UITests/                      # XCTest + XCUIApplication
│
├── .github/workflows/ci.yml
├── .swiftlint.yml
├── .gitignore
├── project.yml                       # XcodeGen 配置
└── README.md
```

---

## 三、并发隔离策略

### 3.1 隔离规则

| 类型 | 隔离 | 理由 |
|------|------|------|
| SwiftUI View | 自动 `@MainActor` | SwiftUI 7 保证 |
| ViewModel（`@Observable`） | `@MainActor` | UI 线程属性观察 |
| Repository（SwiftData） | `@MainActor` | `ModelContext` 不可跨 actor |
| Repository（文件 I/O） | `actor` | 无 UI 依赖 |
| Service（需主线程 API） | `@MainActor` | 平台 API 要求 |
| Service（纯计算） | `actor` 或 `Sendable struct` | 无 UI 依赖 |
| 缓存 | `actor` | 线程安全内部可变状态 |
| 数据模型 | `Sendable struct` 或 `@Model class` | SwiftData 模型不标 `Sendable` |
| 枚举（Codable） | `Sendable` | 值类型，天然安全 |

### 3.2 禁止项（默认）

```swift
// ❌ 默认禁止 — 需要时走逃生舱口流程
@unchecked Sendable
static let shared = ...                // 单例
DispatchQueue.main.async { ... }       // 用 @MainActor 替代
Timer.publish(every:)                  // 用 Task + Task.sleep 替代
@Published / ObservableObject          // 用 @Observable 替代
NavigationView                         // 用 NavigationStack / NavigationSplitView
@EnvironmentObject                     // 用 @Environment 替代
```

### 3.3 逃生舱口（Escape Hatch）

以下场景允许突破默认禁止项，**须在代码中以注释标注理由**：

| 场景 | 允许使用 | 标注格式 |
|------|----------|----------|
| C 回调 / 旧 SDK 桥接 | `@unchecked Sendable` | `// ESCAPE: @unchecked Sendable — <理由>` |
| 第三方 SDK 要求 Combine | `import Combine`（限桥接层） | `// ESCAPE: Combine — <SDK 名称>` |
| SwiftUI 不支持的平台 API | UIKit / AppKit | `// ESCAPE: UIKit/AppKit — <API 名称>` |
| 需全局唯一的系统资源 | `static let shared` | `// ESCAPE: Singleton — <资源名称>` |

> **规则**：逃生舱口代码应隔离在单独的文件或类型中，不可扩散到 View / ViewModel 层。

---

## 四、依赖注入模式

### 4.1 协议定义

所有 Service / Repository 定义协议，放在 `Core/Protocols/`。

**关键原则：协议不绑定 `Observable`**。只有具体实现按需添加 `@Observable`。

```swift
// Repository 协议 — @MainActor（SwiftData 场景）
@MainActor
protocol ItemRepositoryProtocol {
    func fetchAll() throws -> [ItemModel]
    func insert(_ item: ItemModel) throws
    func delete(_ item: ItemModel) throws
    func save() throws
}

// Service 协议 — 不要求 Observable
@MainActor
protocol ItemServiceProtocol {
    var items: [ItemModel] { get }
    func loadItems() throws
    func addItem(_ item: ItemModel) throws
    func deleteItem(_ item: ItemModel) throws
}

// 跨 actor 安全的协议
protocol DataProviderProtocol: Sendable {
    func fetch(query: String) async throws -> [ResultItem]
}
```

### 4.2 实现

```swift
// Repository — @MainActor，不标 @Observable
@MainActor
final class ItemRepository: ItemRepositoryProtocol {
    private let modelContext: ModelContext
    init(modelContext: ModelContext) { self.modelContext = modelContext }
    // ...
}

// Service — @MainActor @Observable（因为需要被 View 通过 @Environment 观察）
@MainActor
@Observable
final class ItemService: ItemServiceProtocol {
    private(set) var items: [ItemModel] = []
    private let repository: ItemRepositoryProtocol
    init(repository: ItemRepositoryProtocol) { self.repository = repository }
    // ...
}
```

> **为什么 Service 标 `@Observable`？**
> 当 Service 直接通过 `@Environment` 注入 View 时，View 需要观察其属性变化。
> 但**协议层不要求** Observable，这样测试 Mock 无需继承 Observable 约束。

### 4.3 App 入口组装

```swift
@main
struct MyApp: App {
    let modelContainer: ModelContainer
    @State private var repository: ItemRepository
    @State private var service: ItemService
    @State private var router = Router()
    @AppStorage("selectedTheme") private var selectedTheme: AppThemeOption = .system

    init() {
        do {
            let container = try ModelContainer(
                for: ItemModel.self,
                migrationPlan: MyMigrationPlan.self
            )
            self.modelContainer = container
            let repo = ItemRepository(modelContext: container.mainContext)
            self._repository = State(initialValue: repo)
            self._service = State(initialValue: ItemService(repository: repo))
        } catch {
            fatalError("ModelContainer init failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(service)
                .environment(router)
                .preferredColorScheme(selectedTheme.colorScheme)
        }
        .modelContainer(modelContainer)
    }
}
```

### 4.4 View 中使用

```swift
struct SomeView: View {
    @Environment(ItemService.self) private var service
    @Environment(Router.self) private var router
    // ...
}
```

### 4.5 何时使用独立 ViewModel

| 场景 | 推荐 |
|------|------|
| 简单 CRUD 页面 | 直接注入 Service |
| 需要组合多个 Service | 创建独立 ViewModel |
| 需要页面级临时状态 | 创建独立 ViewModel |
| 复杂表单验证逻辑 | 创建独立 ViewModel |

```swift
// 复杂场景：独立 ViewModel 组合多个 Service
@MainActor
@Observable
final class DashboardViewModel {
    private let itemService: ItemServiceProtocol
    private let statsService: StatsServiceProtocol

    var dashboardState: ViewState<DashboardData> = .idle

    init(itemService: ItemServiceProtocol, statsService: StatsServiceProtocol) {
        self.itemService = itemService
        self.statsService = statsService
    }
}
```

---

## 五、设计令牌体系

每个 App 独立定义 `DesignTokens`，遵循统一结构和命名。**平台专属的色彩 / 字号 / 圆角值见各平台增量文档**。

### 5.1 Colors（结构）

```swift
enum DesignTokens {
    enum Colors {
        // 语义化色彩 — 各平台使用对应语义色（见平台增量文档）
        static let primary: Color = ...
        static let secondary: Color = ...
        static let tertiary: Color = ...
        static let surface: Color = ...
        static let accent: Color = ...       // App 自定义
        static let error = Color.red
        static let success = Color.green
        static let warning = Color.orange
    }
}
```

### 5.2 Typography（语义 Font — 支持 Dynamic Type）

**关键原则**：使用 SwiftUI 语义 Font API，确保 Dynamic Type 全流程支持。

```swift
    enum Typography {
        // ✅ 正确：语义 Font，自动支持 Dynamic Type
        static let largeTitle = Font.largeTitle
        static let title      = Font.title
        static let title2     = Font.title2
        static let title3     = Font.title3
        static let headline   = Font.headline
        static let body       = Font.body
        static let callout    = Font.callout
        static let subheadline = Font.subheadline
        static let footnote   = Font.footnote
        static let caption    = Font.caption
        static let caption2   = Font.caption2

        // 需要自定义大小时，使用 relativeTo 保持 Dynamic Type 支持
        static let brandTitle = Font.system(size: 28, weight: .bold, design: .rounded)
                                    .leading(.tight)
    }
```

```swift
        // ❌ 禁止：硬编码尺寸破坏 Dynamic Type
        static let body = Font.system(size: 16, weight: .regular)  // 不会跟随系统字号
```

> **说明**：使用 `Font.body` 而非 `Font.system(size: 16)`。系统会在 iOS 和 macOS 上自动
> 选择合适的默认大小（iOS body = 17pt, macOS body = 13pt），并支持 Dynamic Type 缩放。
> 仅在品牌定制字号等特殊场景使用 `Font.system(size:)`，且应搭配 `.dynamicTypeSize()` 测试。

### 5.3 Spacing

```swift
    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }
```

### 5.4 AnimationTokens

```swift
enum AnimationTokens {
    static let spring       = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let quick        = Animation.easeOut(duration: 0.2)
    static let smooth       = Animation.easeInOut(duration: 0.3)
    static let standard     = Animation.easeInOut(duration: 0.25)
    static let slow         = Animation.easeInOut(duration: 0.4)
    static let smoothSpring = Animation.spring(response: 0.4, dampingFraction: 0.85)
}
```

### 5.5 Size / IconSize / Border

```swift
    enum Size {
        // 各 App 按需定义功能相关尺寸
        // 例：static let fabButton: CGFloat = 56
    }

    enum IconSize {
        static let small:      CGFloat = 12
        static let medium:     CGFloat = 16
        static let large:      CGFloat = 20
        static let extraLarge: CGFloat = 24
    }

    enum Border {
        static let thin:    CGFloat = 0.5
        static let regular: CGFloat = 1
        static let thick:   CGFloat = 2
    }
```

> **Radius / 平台色彩 / 触觉令牌** 分别在 iOS / macOS 增量文档中定义。

---

## 六、核心基础设施模板

### 6.1 ViewState（含重试状态）

```swift
enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case error(AppError)
    case retrying(attempt: Int, maxAttempts: Int)

    var isLoading: Bool {
        if case .loading = self { return true }
        if case .retrying = self { return true }
        return false
    }
}
```

### 6.2 AppError（含恢复建议）

```swift
enum AppError: LocalizedError, Sendable {
    // 通用
    case dataLoadFailed(underlying: String)
    case dataSaveFailed(underlying: String)
    case networkError(underlying: String)
    case unknown(underlying: String)
    // 各 App 按需添加业务 case...

    var errorDescription: String? {
        switch self {
        case .dataLoadFailed(let msg):
            String(localized: "Failed to load data: \(msg)")
        case .dataSaveFailed(let msg):
            String(localized: "Failed to save data: \(msg)")
        case .networkError(let msg):
            String(localized: "Network error: \(msg)")
        case .unknown(let msg):
            String(localized: "Unknown error: \(msg)")
        }
    }

    /// 用户可见的恢复建议
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            String(localized: "Please check your network connection and try again.")
        case .dataLoadFailed, .dataSaveFailed:
            String(localized: "Please try again. If the problem persists, restart the app.")
        default:
            nil
        }
    }
}
```

### 6.3 Router（基础结构）

```swift
import SwiftUI

/// 各 App 定义自己的 AppDestination 枚举
/// 导航容器（NavigationStack / NavigationSplitView）见各平台增量文档

@MainActor
@Observable
final class Router {
    // iOS 使用 NavigationPath: var path = NavigationPath()
    // macOS 使用 Sidebar Tab: var selectedTab: AppTab = .defaultTab
    // 具体实现见各平台增量文档
}
```

### 6.4 Logger

```swift
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.example.app"

    static let app      = Logger(subsystem: subsystem, category: "app")
    static let data     = Logger(subsystem: subsystem, category: "data")
    static let network  = Logger(subsystem: subsystem, category: "network")
    static let ui       = Logger(subsystem: subsystem, category: "ui")
    static let services = Logger(subsystem: subsystem, category: "services")
    // 各 App 按需添加 category...
}
```

### 6.5 Color(hex:)

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let (a, r, g, b): (UInt64, UInt64, UInt64, UInt64) = switch hex.count {
        case 6: (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
```

### 6.6 AppThemeOption

```swift
enum AppThemeOption: String, CaseIterable, Sendable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }

    var displayName: String {
        switch self {
        case .system: String(localized: "System")
        case .light:  String(localized: "Light")
        case .dark:   String(localized: "Dark")
        }
    }
}
```

### 6.7 View 扩展

```swift
extension View {
    /// 条件修饰符
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
```

---

## 七、SwiftData 规范

### 7.1 Schema 版本化（必须）

从 V1 起使用 `VersionedSchema`，确保后续迁移路径：

```swift
enum MySchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ItemModel.self] }

    @Model
    final class ItemModel {
        @Attribute(.unique) var id: UUID
        var title: String
        var createdAt: Date
        // ...
        init(id: UUID = UUID(), title: String, createdAt: Date = .now) {
            self.id = id
            self.title = title
            self.createdAt = createdAt
        }
    }
}

typealias ItemModel = MySchemaV1.ItemModel

enum MyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [MySchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
```

### 7.2 枚举存储

SwiftData 直接存储 `Codable` 枚举：

```swift
enum ItemCategory: String, Codable, CaseIterable, Sendable {
    case typeA, typeB
    var displayName: String { /* String(localized:) */ }
    var systemImage: String { /* SF Symbol */ }
}
```

### 7.3 外部存储

大数据（图片等）使用 `@Attribute(.externalStorage)`：

```swift
@Attribute(.externalStorage) var imageData: Data?
```

### 7.4 Preview 支持

```swift
extension ItemRepository {
    @MainActor
    static var preview: ItemRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ItemModel.self, configurations: config)
        return ItemRepository(modelContext: container.mainContext)
    }
}
```

### 7.5 Repository 查询

使用 `FetchDescriptor` + `#Predicate`：

```swift
func fetchItems(query: String?, limit: Int?) throws -> [ItemModel] {
    var descriptor = FetchDescriptor<ItemModel>(
        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    if let query, !query.isEmpty {
        descriptor.predicate = #Predicate { item in
            item.title.localizedStandardContains(query)
        }
    }
    if let limit { descriptor.fetchLimit = limit }
    return try modelContext.fetch(descriptor)
}
```

### 7.6 数据库损坏恢复

`ModelContainer` 初始化失败时的防御策略：

```swift
init() {
    do {
        let container = try ModelContainer(
            for: ItemModel.self,
            migrationPlan: MyMigrationPlan.self
        )
        self.modelContainer = container
    } catch {
        Logger.data.error("ModelContainer init failed: \(error). Attempting recovery...")
        // 尝试删除损坏的数据库并重建
        do {
            let url = URL.applicationSupportDirectory
                .appending(path: "default.store")
            try FileManager.default.removeItem(at: url)
            Logger.data.warning("Deleted corrupted database. Rebuilding...")
            let container = try ModelContainer(for: ItemModel.self)
            self.modelContainer = container
        } catch {
            fatalError("Database recovery failed: \(error)")
        }
    }
}
```

> **注意**：仅在数据库完全无法打开时使用，会导致数据丢失。生产环境应配合备份策略。

---

## 八、网络层

### 8.1 适用场景

| 场景 | 推荐 |
|------|------|
| 纯本地 App（无网络） | 不需要网络层 |
| 简单 REST API（≤ 5 个接口） | URLSession 直接使用 |
| 复杂 REST API（> 5 个接口） | Endpoint 协议 + APIClient |
| 需要认证 / 重试 / 拦截器 | Alamofire（通过 SPM） |

### 8.2 Endpoint 协议

```swift
import Foundation

protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    var timeoutInterval: TimeInterval { get }
}

extension Endpoint {
    var headers: [String: String] { ["Content-Type": "application/json"] }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var timeoutInterval: TimeInterval { 30 }

    func urlRequest() throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw AppError.networkError(underlying: "Invalid URL")
        }
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        return request
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
```

### 8.3 APIClient

```swift
actor APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try endpoint.urlRequest()
        Logger.network.debug("→ \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError(underlying: "Invalid response")
        }

        Logger.network.debug("← \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError(underlying: "HTTP \(httpResponse.statusCode)")
        }

        return try decoder.decode(T.self, from: data)
    }
}
```

### 8.4 重试策略

```swift
enum RetryPolicy {
    case none
    case fixed(maxAttempts: Int, delay: Duration)
    case exponentialBackoff(maxAttempts: Int, baseDelay: Duration, maxDelay: Duration)
}

extension APIClient {
    func requestWithRetry<T: Decodable>(
        _ endpoint: Endpoint,
        retryPolicy: RetryPolicy = .exponentialBackoff(maxAttempts: 3, baseDelay: .seconds(1), maxDelay: .seconds(30))
    ) async throws -> T {
        switch retryPolicy {
        case .none:
            return try await request(endpoint)
        case .fixed(let maxAttempts, let delay):
            return try await retry(maxAttempts: maxAttempts) {
                try await Task.sleep(for: delay)
                return try await self.request(endpoint)
            }
        case .exponentialBackoff(let maxAttempts, let baseDelay, let maxDelay):
            return try await retryWithBackoff(
                maxAttempts: maxAttempts,
                baseDelay: baseDelay,
                maxDelay: maxDelay
            ) {
                try await self.request(endpoint)
            }
        }
    }

    private func retryWithBackoff<T>(
        maxAttempts: Int,
        baseDelay: Duration,
        maxDelay: Duration,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxAttempts - 1 {
                    let delay = min(
                        baseDelay * Int(pow(2.0, Double(attempt))),
                        maxDelay
                    )
                    try await Task.sleep(for: delay)
                }
            }
        }
        throw lastError ?? AppError.networkError(underlying: "Max retries exceeded")
    }
}
```

---

## 九、SPM 依赖管理

### 9.1 原则

- **默认零依赖**：优先使用系统框架和自研代码
- **引入标准**：只有当自研成本显著高于维护第三方依赖的风险时才引入
- **审批流程**：新增依赖需在 PR 中说明引入理由、替代方案、维护状态

### 9.2 允许清单

| 包名 | 场景 | 条件 |
|------|------|------|
| Alamofire | 复杂网络请求 | > 5 个 API + 需认证/重试/拦截器 |
| KeychainAccess | 安全存储 | 需要跨 App Group 共享 |
| swift-algorithms | 集合算法 | Apple 官方维护 |
| swift-collections | 高级数据结构 | Apple 官方维护 |

### 9.3 project.yml 集成

```yaml
packages:
  Alamofire:
    url: https://github.com/Alamofire/Alamofire
    version: 5.10.0  # 锁定大版本

targets:
  ProjectName:
    dependencies:
      - package: Alamofire
```

---

## 十、App 生命周期

### 10.1 ScenePhase 处理

```swift
@main
struct MyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Logger.app.info("App became active")
                // 刷新数据、恢复定时器等
            case .inactive:
                Logger.app.info("App became inactive")
                // 暂停非关键任务
            case .background:
                Logger.app.info("App entered background")
                // 保存状态、释放资源
            @unknown default:
                break
            }
        }
    }
}
```

### 10.2 首次启动检测

```swift
@AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false

// 在 ContentView 中
.task {
    if !hasLaunchedBefore {
        // 执行首次启动逻辑（引导页、默认数据等）
        hasLaunchedBefore = true
    }
}
```

---

## 十一、错误处理与重试

### 11.1 View 层错误展示

```swift
Group {
    switch viewState {
    case .idle, .loading:
        ProgressView()
    case .success:
        if items.isEmpty {
            ContentUnavailableView(
                "No Items",
                systemImage: "tray",
                description: Text(String(localized: "Add your first item."))
            )
        } else {
            contentView
        }
    case .error(let error):
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
            }
        } actions: {
            Button(String(localized: "Retry")) {
                Task { await retry() }
            }
        }
    case .retrying(let attempt, let maxAttempts):
        VStack {
            ProgressView()
            Text(String(localized: "Retrying (\(attempt)/\(maxAttempts))..."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

### 11.2 ViewModel 重试逻辑

```swift
@MainActor
@Observable
final class ItemListViewModel {
    var viewState: ViewState<[ItemModel]> = .idle
    private let service: ItemServiceProtocol
    private let maxRetries = 3

    func loadItems() async {
        viewState = .loading
        do {
            try service.loadItems()
            viewState = .success(service.items)
        } catch let error as AppError {
            viewState = .error(error)
        } catch {
            viewState = .error(.unknown(underlying: error.localizedDescription))
        }
    }

    func retry() async {
        for attempt in 1...maxRetries {
            viewState = .retrying(attempt: attempt, maxAttempts: maxRetries)
            do {
                try await Task.sleep(for: .seconds(Double(attempt)))
                try service.loadItems()
                viewState = .success(service.items)
                return
            } catch {
                if attempt == maxRetries {
                    viewState = .error(.dataLoadFailed(underlying: error.localizedDescription))
                }
            }
        }
    }
}
```

---

## 十二、无障碍（Accessibility）

### 12.1 三枚举结构

```swift
// AccessibilityID — UI 测试标识符（snake_case）
enum AccessibilityID {
    static let someButton = "some_button"
    static let itemList = "item_list"
    // ...
}

// AccessibilityLabel — VoiceOver 朗读文本
enum AccessibilityLabel {
    static let someButton = String(localized: "Do something", comment: "Accessibility label")
    // 动态标签用 static func
    static func itemDescription(_ name: String) -> String {
        String(localized: "Item \(name)", comment: "Accessibility label")
    }
}

// AccessibilityHint — 操作提示
enum AccessibilityHint {
    static let someButton = String(localized: "Double tap to do something", comment: "Accessibility hint")
}
```

### 12.2 使用规则

- **所有交互元素**必须有 `.accessibilityIdentifier` + `.accessibilityLabel` + `.accessibilityHint`
- 容器使用 `.accessibilityElement(children: .combine)` 合并子元素
- **WCAG AA 对比度 ≥ 4.5:1**（所有文字/背景组合，两平台均适用）
- Dynamic Type：`xSmall ... xxxLarge` 全流程不溢出

---

## 十三、View 编写规范

### 13.1 状态驱动

见 §十一 中的 ViewState switch 模式。

### 13.2 Preview

每个 View 文件必须包含 `#Preview`，注入所有必需 `@Environment`：

```swift
#Preview {
    SomeView()
        .environment(Router())
        .environment(ItemService(repository: ItemRepository.preview))
}
```

### 13.3 微交互

```swift
// 数字变化
Text("\(count)")
    .contentTransition(.numericText())

// 状态切换
withAnimation(AnimationTokens.spring) { ... }
```

> 平台特有的导航容器 / 材质 / 控件等见各平台增量文档。

---

## 十四、ViewModel 模式

### 14.1 @AppStorage + @ObservationIgnored

`@AppStorage` 与 `@Observable` 不直接兼容，需 `@ObservationIgnored`：

```swift
@MainActor
@Observable
final class SettingsViewModel {
    @ObservationIgnored @AppStorage("featureEnabled")
    var featureEnabled = false

    @ObservationIgnored @AppStorage("selectedTheme")
    var selectedTheme: AppThemeOption = .system
}
```

---

## 十五、测试规范

### 15.1 单元测试（Swift Testing）

```swift
import Testing
@testable import ProjectName

@Suite("ItemService Tests")
struct ItemServiceTests {

    @Test("loads items successfully")
    @MainActor
    func loadItems() throws {
        let mock = MockItemRepository()
        mock.items = [ItemModel(title: "Test")]
        let service = ItemService(repository: mock)
        try service.loadItems()
        #expect(service.items.count == 1)
    }

    @Test("throws on load failure")
    @MainActor
    func loadItemsError() {
        let mock = MockItemRepository()
        mock.shouldThrow = true
        let service = ItemService(repository: mock)
        #expect(throws: AppError.self) {
            try service.loadItems()
        }
    }
}
```

### 15.2 Mock 编写

Mock 实现对应协议，放在 `Tests/UnitTests/Mocks/`：

```swift
@MainActor
final class MockItemRepository: ItemRepositoryProtocol {
    var items: [ItemModel] = []
    var shouldThrow = false
    var saveCallCount = 0

    func fetchAll() throws -> [ItemModel] {
        if shouldThrow { throw AppError.dataLoadFailed(underlying: "mock") }
        return items
    }
    func insert(_ item: ItemModel) throws { items.append(item) }
    func delete(_ item: ItemModel) throws { items.removeAll { $0.id == item.id } }
    func save() throws { saveCallCount += 1 }
}
```

> **关键**：因为协议不要求 Observable（见 §四），Mock 不需要标 `@Observable`。

### 15.3 异步 Mock

```swift
actor MockAPIClient {
    var responses: [String: Any] = [:]
    var shouldFail = false

    func mockResponse<T: Decodable>(for path: String) throws -> T {
        if shouldFail { throw AppError.networkError(underlying: "mock") }
        guard let response = responses[path] as? T else {
            throw AppError.networkError(underlying: "No mock for \(path)")
        }
        return response
    }
}
```

### 15.4 集成测试（SwiftData）

使用 `isStoredInMemoryOnly` 内存容器：

```swift
@Suite("SwiftData Integration", .serialized)
@MainActor
struct DataIntegrationTests {
    @Test("Insert and fetch")
    func insertAndFetch() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ItemModel.self, configurations: config)
        let context = container.mainContext
        let item = ItemModel(title: "Test")
        context.insert(item)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<ItemModel>())
        #expect(fetched.count == 1)
    }
}
```

### 15.5 UI 测试（XCTest）

```swift
import XCTest

final class AppUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    func testAppLaunches() throws {
        // 验证核心 UI 元素存在
        let element = app.buttons[AccessibilityID.someButton]
        XCTAssertTrue(element.waitForExistence(timeout: 5))
    }
}
```

> **注意**：UI 测试 `launchArguments` 统一使用 `["--ui-testing"]`（两平台一致）。

### 15.6 覆盖率目标

| 层级 | 目标 |
|------|------|
| Service / Repository | ≥ 80% |
| ViewModel | ≥ 60% |
| 整体 | ≥ 50% |

### 15.7 CI 覆盖率门禁

在 CI 中强制检查覆盖率，低于阈值则失败：

```yaml
      - name: Check Coverage
        run: |
          xcrun xccov view --report TestResults.xcresult --json | \
            python3 -c "
          import json, sys
          data = json.load(sys.stdin)
          coverage = data['lineCoverage']
          print(f'Coverage: {coverage:.1%}')
          if coverage < 0.50:
              print('ERROR: Coverage below 50% threshold')
              sys.exit(1)
          "
```

---

## 十六、缓存模式（含内存压力）

### 16.1 Actor 缓存

```swift
actor ImageCache {
    private var cache: [URL: Data] = [:]
    private var accessOrder: [URL] = []
    private let maxCount = 100
    private let maxBytes = 100 * 1024 * 1024  // 100 MB

    func get(_ url: URL) -> Data? {
        guard let data = cache[url] else { return nil }
        // LRU：移到末尾
        accessOrder.removeAll { $0 == url }
        accessOrder.append(url)
        return data
    }

    func set(_ data: Data, for url: URL) {
        cache[url] = data
        accessOrder.removeAll { $0 == url }
        accessOrder.append(url)
        evictIfNeeded()
    }

    func clearAll() {
        cache.removeAll()
        accessOrder.removeAll()
    }

    private func evictIfNeeded() {
        // 条目数淘汰
        while accessOrder.count > maxCount, let oldest = accessOrder.first {
            cache.removeValue(forKey: oldest)
            accessOrder.removeFirst()
        }
        // 总大小淘汰
        var totalBytes = cache.values.reduce(0) { $0 + $1.count }
        while totalBytes > maxBytes, let oldest = accessOrder.first {
            if let data = cache.removeValue(forKey: oldest) {
                totalBytes -= data.count
            }
            accessOrder.removeFirst()
        }
    }
}
```

### 16.2 内存压力响应

在 App 入口注册内存警告监听：

```swift
// iOS
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
    Task { await imageCache.clearAll() }
}

// macOS — 使用 DispatchSource.makeMemoryPressureSource
// ESCAPE: GCD — DispatchSource.makeMemoryPressureSource (no SwiftUI equivalent)
private func setupMemoryPressureMonitor() {
    let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical])
    source.setEventHandler { [weak self] in
        Task { await self?.imageCache.clearAll() }
    }
    source.resume()
}
```

> **注意**：macOS 内存压力监听使用 GCD，这是逃生舱口场景（见 §三）。

---

## 十七、本地化

```swift
// ✅ 正确
Text(String(localized: "Save"))
String(localized: "Failed to load data: \(msg)")

// ❌ 禁止
Text("Save")                              // 硬编码字符串
NSLocalizedString("Save", comment: "")     // 旧 API
```

- 使用 `Localizable.xcstrings`（Xcode 15+ String Catalog）
- 中英双语完整覆盖
- 无障碍标签也需本地化

---

## 十八、SwiftLint 配置（统一基线）

两平台使用相同基线配置：

```yaml
opt_in_rules:
  - empty_count
  - empty_string
  - closure_spacing
  - force_unwrapping
  - implicitly_unwrapped_optional
  - contains_over_first_not_nil
  - fatal_error_message
  - first_where
  - modifier_order
  - overridden_super_call
  - sorted_first_last
  - toggle_bool
  - unneeded_parentheses_in_closure_argument
  - vertical_parameter_alignment_on_call

disabled_rules:
  - todo
  - trailing_comma
  - trailing_whitespace
  - opening_brace

line_length:
  warning: 120
  error: 200

function_body_length:
  warning: 50
  error: 100

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 1200

cyclomatic_complexity:
  warning: 10
  error: 20

identifier_name:
  min_length: 2
  max_length: 60
  excluded: [id, x, y, r, g, b]

included:
  - App
  - Core
  - Features
  - Tests

excluded:
  - .build
  - DerivedData
  - "*.xcodeproj"

reporter: xcode
```

---

## 十九、命名约定

| 类别 | 规则 | 示例 |
|------|------|------|
| 类型 | UpperCamelCase | `ItemService`, `DashboardViewModel` |
| 协议 | 名词 + `Protocol` 后缀 | `ItemRepositoryProtocol` |
| 方法 / 属性 | lowerCamelCase | `loadItems()`, `selectedTab` |
| 枚举 case | lowerCamelCase | `.typeA`, `.settings` |
| 常量 | lowerCamelCase（`static let`） | `DesignTokens.Spacing.md` |
| 文件 | 与主类型同名 | `ItemService.swift` |
| Accessibility ID | snake_case 字符串 | `"add_item_button"` |
| Logger category | 小写单词 | `"app"`, `"data"`, `"network"` |
| 本地化 comment | 说明用途 | `comment: "Accessibility label"` |

---

## 二十、Git 规范

### 分支

- `main` — 发布分支
- `develop` — 开发分支
- `feature/xxx` — 功能分支
- `fix/xxx` — 修复分支
- `rewrite/v2` — 重写分支（如适用）

### Commit Message

```
<type>: <简短描述>

<详细说明（可选）>
```

type: `feat` / `fix` / `refactor` / `test` / `chore` / `docs` / `style` / `perf`

---

## 二十一、Checklist（共享基础）

> 各平台增量文档中有平台专属 checklist 项。

- [ ] `project.yml` + `xcodegen generate`
- [ ] `Core/Constants/` — DesignTokens / AnimationTokens
- [ ] `Core/Extensions/` — Color+Extensions / View+Extensions
- [ ] `Core/Navigation/Router.swift`
- [ ] `Core/Utils/` — AppError / ViewState / Logger / Accessibility / AppThemeOption
- [ ] `Core/Protocols/` — 所有协议定义
- [ ] `Core/Models/` — SwiftData @Model + Schema 版本化
- [ ] `Core/Repositories/` — 实现 + Preview 支持
- [ ] `Core/Services/` — 业务 Service
- [ ] `App/ProjectNameApp.swift` — 依赖图组装 + ScenePhase
- [ ] `Resources/Localizable.xcstrings`
- [ ] `.swiftlint.yml`
- [ ] `.gitignore`
- [ ] `.github/workflows/ci.yml`（含覆盖率门禁）
- [ ] `Tests/UnitTests/` — Mock + 基础测试
- [ ] `Tests/IntegrationTests/` — SwiftData 集成测试
- [ ] `Tests/UITests/` — 启动 + 导航测试
- [ ] SwiftLint 零 violation
- [ ] Build + Test 全绿

---

## 二十二、变更日志

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-02-27 | 1.0 | 初始版本，基于已有 iOS/macOS 项目提取 |
| 2026-02-28 | 2.0 | 重构为三文档结构；新增网络层、SPM 管理、App 生命周期、错误重试、DB 恢复、缓存内存压力、CI 覆盖率门禁；Typography 改用语义 Font 支持 Dynamic Type；并发策略增加逃生舱口；DI 协议不绑定 Observable；统一两平台 SwiftLint 基线 |
