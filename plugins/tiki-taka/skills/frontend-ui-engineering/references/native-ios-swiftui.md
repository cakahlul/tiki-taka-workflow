# Native iOS UI — SwiftUI & UIKit

Reference for the `frontend-ui-engineering` skill. Native iOS with SwiftUI (default) and UIKit (legacy / interop). Use this when building **iOS-native** screens outside Kotlin Multiplatform, or bridging Swift UI to a KMP Compose app.

Which reference to use:

- **KMP + Compose Multiplatform** (shared UI runs on iOS) → `references/native-mobile-compose.md`.
- **Native iOS in Swift** (no shared Compose, or the iOS-only part of a KMP app) → this file.
- Bridging the two (KMP Compose embedded via `UIViewController`, or SwiftUI wrapping a Compose screen) → the **Interop** section below.

The parent `SKILL.md` standards apply unchanged: no AI aesthetic, design-token adherence, real loading/empty/error states, accessibility, adaptive layout. This file is the SwiftUI/UIKit *how*.

Default to SwiftUI. Only reach for UIKit when the task is an existing UIKit screen, a control SwiftUI lacks, or an interop boundary.

## SwiftUI Architecture

### View = stateless render + an observable state holder

Same split as web container/presentation and Compose stateless/ViewModel:

- **View** — takes a state value + closures, renders. Previewable. No networking, no business logic in `body`.
- **State holder** — an `@Observable` (iOS 17+) or `ObservableObject` class owning the state, exposing it, handling events.

```swift
// State holder (iOS 17+ Observation)
@Observable
final class TaskListModel {
    private(set) var state: TaskListState = .loading
    private let repo: TaskRepository
    init(repo: TaskRepository) { self.repo = repo }

    func load() async {
        do {
            let tasks = try await repo.fetch()
            state = tasks.isEmpty ? .empty : .content(tasks)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    func toggle(_ id: String) { Task { try? await repo.toggle(id) } }
}

// Stateful entry — owns the model
struct TaskListScreen: View {
    @State private var model: TaskListModel
    var body: some View {
        TaskListContent(state: model.state, onToggle: model.toggle)
            .task { await model.load() }   // runs on appear, cancels on disappear
    }
}

// Stateless — previewable, no model
struct TaskListContent: View {
    let state: TaskListState
    let onToggle: (String) -> Void
    var body: some View {
        switch state {
        case .loading:            TaskListSkeleton()
        case .empty:              EmptyStateView(/* ... */)
        case .error(let msg):     ErrorStateView(message: msg, onRetry: { /* ... */ })
        case .content(let tasks): TaskList(tasks: tasks, onToggle: onToggle)
        }
    }
}
```

`.task {}` over `.onAppear {}` for async work — it auto-cancels when the view disappears (the SwiftUI analog of `collectAsStateWithLifecycle`).

### Model state as an enum — never scattered booleans

```swift
// Good: illegal states unrepresentable; switch is exhaustive
enum TaskListState {
    case loading
    case empty
    case error(String)
    case content([Task])
}

// Bad: isLoading + error + tasks can contradict; empty state forgotten
struct TaskListState { var isLoading: Bool; var error: String?; var tasks: [Task] }
```

Swift `switch` over an enum is exhaustive — the compiler forces every state branch, same guarantee as a Kotlin sealed interface.

### Composition — view builders & slots, not config flags

```swift
// Good: caller composes content into slots
struct Card<Header: View, Content: View>: View {
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content
}

// Avoid: a param per variation
struct Card: View { let title: String; let headerVariant: String; let bodyPadding: CGFloat }
```

### State ownership rules

- `@State` — value owned by this view (internal UI: expand toggle, text field). Private.
- `@Binding` — hoisted state passed down for two-way edit (`$value`). The SwiftUI form of state hoisting.
- `@Observable` + `@State` (iOS 17+) or `@StateObject`/`@ObservedObject` (older) — reference-type state holder. `@StateObject`/`@State(model)` where **owned**; `@ObservedObject`/passed-in where **injected**.
- `@Environment` — app-wide read-heavy values (theme, dependencies) — the Context analog.
- Never do side effects in `body`. Use `.task`, `.onAppear`, or push to the model.

## Lists — `List` / `LazyVStack`, always identify

```swift
List(tasks) { task in            // Identifiable → stable identity
    TaskRow(task: task, onToggle: { onToggle(task.id) })
}
// or, in a ScrollView:
LazyVStack(spacing: 12) {
    ForEach(tasks) { task in TaskRow(task: task) }   // Task: Identifiable
}
```

- Use `List` or `LazyVStack`/`LazyHStack` for long lists — not a plain `VStack` (renders everything eagerly).
- Items must be `Identifiable` (or pass `id:`). Missing/unstable identity breaks diffing, animation, and cell state — same failure as a missing React/Compose key.

## Design System — semantic tokens, no magic values

```swift
// Good: semantic + asset-catalog tokens
Text(title).foregroundStyle(.primary).font(.body)
Color("Surface")                       // named asset color, adapts light/dark
RoundedRectangle(cornerRadius: Spacing.radiusMedium)

// Bad: hardcoded
Text(title).foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))  // raw rgb, no token
.padding(13)                                                            // off the scale
.cornerRadius(24)                                                       // "rounded-everything" tell
```

- **Color** → semantic system colors (`.primary`, `.secondary`, `Color(.systemBackground)`) or **named asset-catalog colors** that carry light/dark variants automatically. Never inline RGB/hex.
- **Type** → system text styles (`.largeTitle`, `.title`, `.body`, `.caption`) — they scale with Dynamic Type. Don't hardcode `.font(.system(size: 17))`.
- **Spacing / radius** → a shared constants enum (`Spacing.sm/md/lg`, multiples of 4/8). Not scattered literals.
- **Elevation** → subtle. Prefer material backgrounds (`.background(.regularMaterial)`) / tint over heavy shadows. Shadow-heavy = AI tell.
- **Support dark mode** from the start — use semantic/asset colors so it's free; verify in the dark `.preview`.

The parent skill's **AI Aesthetic** table applies verbatim — purple-everything, max corner radius, gradient soup, oversized uniform padding, stock card grids, heavy shadows are just as wrong in SwiftUI. Use the app's real design system, not SwiftUI tutorial defaults.

## Accessibility (VoiceOver / Dynamic Type)

WCAG intent, SwiftUI form:

- **Labels** — every meaningful control/image needs an accessible label; decorative gets hidden:
  ```swift
  Image(systemName: "trash").accessibilityLabel("Delete task")     // meaningful
  Image("divider").accessibilityHidden(true)                        // decorative
  Button(action: close) { Image(systemName: "xmark") }
      .accessibilityLabel("Close")
  ```
- **Dynamic Type** — use system text styles (above) so text scales; test at the largest accessibility size. Don't clip or truncate essential content. Custom sizes: `@ScaledMetric var iconSize = 24`.
- **Touch targets ≥ 44×44pt** (Apple HIG). Don't shrink a `Button`'s hit area below it; pad small icon buttons with `.contentShape(Rectangle())` + frame.
- **Traits & state** — expose role/state so VoiceOver announces correctly:
  ```swift
  .accessibilityAddTraits(.isButton)
  .accessibilityValue(isSelected ? "Selected" : "Not selected")
  ```
- **Group related elements** — `.accessibilityElement(children: .combine)` so a card reads as one announcement, not five.
- **Don't rely on color alone** — error state needs icon + text, not just red tint. Same rule as web.
- **Live updates** — `.accessibilityAddTraits(.updatesFrequently)` / post `AccessibilityNotification.Announcement` for async results (the VoiceOver analog of `aria-live`).
- **Reduce Motion** — honor `@Environment(\.accessibilityReduceMotion)`; drop or simplify animations when set.
- **Test with VoiceOver** (Settings → Accessibility, or Xcode Accessibility Inspector). Automated: `XCUITest` + Accessibility Inspector audit. Automated catches a minority — a manual VoiceOver pass is mandatory.

## Adaptive / Responsive Layout

iPhone, iPad, split view, orientation. SwiftUI equivalents of breakpoints:

```swift
@Environment(\.horizontalSizeClass) private var sizeClass
var body: some View {
    if sizeClass == .compact {
        SinglePaneList()                         // iPhone portrait, slide-over
    } else {
        NavigationSplitView { Sidebar() } detail: { Detail() }   // iPad, regular width
    }
}
```

- Compact-first, then expand to `NavigationSplitView` / two-pane for regular width.
- `GeometryReader` for component-level sizing when a size class is too coarse (use sparingly — it can break layout composition).
- Prefer stacks + `Spacer()` + `.frame(maxWidth:)` over fixed widths so layouts reflow. Support landscape and iPad multitasking.

## Loading, Skeletons, Optimistic Updates

- **Skeletons over spinners** for content. Placeholder shapes tinted with `Color(.secondarySystemBackground)` + `.redacted(reason: .placeholder)` (SwiftUI has this built in) or a shimmer, gated behind the `.loading` branch.
- **Optimistic updates** — mutate the published state immediately, roll back on failure:
  ```swift
  func toggle(_ id: String) {
      let snapshot = state
      applyOptimistic(id)                        // update now
      Task {
          do { try await repo.toggle(id) }
          catch { state = snapshot }             // rollback
      }
  }
  ```

## UIKit (legacy / interop)

Reach for UIKit only when required. When you do, keep the same standards:

- **MVVM, not Massive View Controller** — the VC binds to a state holder; state is an enum; the VC just renders it. Same split as everywhere else.
- **Diffable data source + compositional layout** for lists — `UICollectionViewDiffableDataSource` with stable item identifiers (the UIKit form of "always key"). Don't hand-manage `insert/delete` index paths.
- **Auto Layout via constraints or `UIStackView`** — no magic frames; use layout guides and a spacing constant enum.
- **Dynamic Type** — `adjustsFontForContentSizeCategory = true` + text styles (`.preferredFont(forTextStyle:)`). **VoiceOver** — set `accessibilityLabel`, `accessibilityTraits`, `isAccessibilityElement`. Semantic colors via asset catalog / `UIColor.label` etc.
- **Bridge to SwiftUI** with `UIViewRepresentable` / `UIViewControllerRepresentable` (embed UIKit in SwiftUI) or `UIHostingController` (embed SwiftUI in UIKit). Keep new screens SwiftUI; wrap only the UIKit-only control.

## Interop — Swift ↔ KMP Compose

When the app is KMP but part of iOS is Swift-native:

- **KMP Compose inside SwiftUI** — the shared Compose UI is exposed as a `UIViewController` (`ComposeUIViewController { … }` in `iosMain`); embed it in SwiftUI via `UIViewControllerRepresentable`.
- **SwiftUI inside a KMP app** — surface a `UIHostingController` at the platform boundary; the KMP side calls into it via an `expect`/`actual` factory.
- **State** — keep a single source of truth. Either the KMP `StateFlow` drives both (collect into Swift via the shared module), or the Swift `@Observable` owns it — don't duplicate. Bridge at exactly one boundary.
- Prefer keeping a screen entirely in one toolkit (all Compose or all SwiftUI); interop per-component only when unavoidable.

## Red Flags (iOS)

- Networking / business logic inside a `View`'s `body` instead of `.task`/model.
- `.onAppear` for async work that should be a cancellable `.task`.
- Scattered `isLoading`/`error`/`data` booleans instead of a state enum; missing empty state.
- Plain `VStack` + `ForEach` for a long list (eager render) instead of `List`/`LazyVStack`.
- List items not `Identifiable` / unstable ids.
- Hardcoded RGB/hex color, `.padding(13)`, `.font(.system(size: 17))`, `.cornerRadius(24)` — bypassing tokens/text styles.
- Icon/image button with no `accessibilityLabel`; hit area under 44pt.
- No dark-mode / Dynamic Type verification.
- Massive View Controller doing layout + networking + state (UIKit).
- Duplicated source of truth across the Swift↔Compose boundary.

## Verification (iOS)

- [ ] `#Preview` renders each state (loading/empty/error/content) — no bare spinner, no blank screen.
- [ ] VoiceOver announces content, roles, state; every meaningful control/image has a label.
- [ ] Dynamic Type: layout holds at the largest accessibility text size.
- [ ] Dark mode verified (semantic/asset colors).
- [ ] Touch targets ≥ 44×44pt.
- [ ] Adaptive: verified in compact (iPhone) and regular (iPad / split view) size classes; landscape OK.
- [ ] Semantic/asset color + system text styles only — no hardcoded colors/sizes/radii.
- [ ] Lists are lazy and identity-stable.
- [ ] Reduce Motion honored.
- [ ] (Interop) single source of truth across the Swift↔Compose boundary.
