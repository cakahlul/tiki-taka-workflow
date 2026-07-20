# Native Mobile UI — Kotlin, Jetpack Compose & KMP

Reference for the `frontend-ui-engineering` skill. Android with Jetpack Compose, and iOS via Kotlin Multiplatform (KMP) + Compose Multiplatform. The parent `SKILL.md` standards (no AI aesthetic, design-token adherence, real loading/empty/error states, accessibility, adaptive layout) apply unchanged — this file is the Kotlin/Compose *how*.

Default to Compose. Only touch XML Views / UIKit / SwiftUI when the task is an existing non-Compose screen or an interop boundary.

## Composable Architecture

### One screen = stateless UI + a state holder

Split every screen the way web splits container vs presentation:

- **Stateless composable** — takes a `UiState` and event lambdas, renders. No ViewModel reference, no side effects fetching data. Previewable and testable in isolation.
- **State holder (`ViewModel`)** — owns the state, exposes it as `StateFlow<UiState>`, handles events.

```kotlin
// State holder
class TaskListViewModel(private val repo: TaskRepository) : ViewModel() {
    val uiState: StateFlow<TaskListUiState> = repo.observeTasks()
        .map { tasks -> if (tasks.isEmpty()) TaskListUiState.Empty else TaskListUiState.Content(tasks) }
        .catch { emit(TaskListUiState.Error(it.message ?: "Failed to load")) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), TaskListUiState.Loading)

    fun onToggle(id: String) = viewModelScope.launch { repo.toggle(id) }
}

// Stateful entry — the only place that touches the ViewModel
@Composable
fun TaskListRoute(viewModel: TaskListViewModel = viewModel()) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    TaskListScreen(state = state, onToggle = viewModel::onToggle)
}

// Stateless — previewable, no ViewModel
@Composable
fun TaskListScreen(state: TaskListUiState, onToggle: (String) -> Unit) {
    when (state) {
        TaskListUiState.Loading   -> TaskListSkeleton()
        TaskListUiState.Empty     -> EmptyState(/* ... */)
        is TaskListUiState.Error  -> ErrorState(state.message, onRetry = { /* ... */ })
        is TaskListUiState.Content -> TaskList(state.tasks, onToggle)
    }
}
```

`collectAsStateWithLifecycle()` (from `androidx.lifecycle:lifecycle-runtime-compose`) — use it, not plain `collectAsState()`, so collection stops when the app is backgrounded. In `commonMain` (KMP), it's available via the multiplatform lifecycle artifact.

### Model state as a sealed hierarchy — never booleans

```kotlin
// Good: illegal states unrepresentable, forces every branch to be handled
sealed interface TaskListUiState {
    data object Loading : TaskListUiState
    data object Empty : TaskListUiState
    data class Error(val message: String) : TaskListUiState
    data class Content(val tasks: List<Task>) : TaskListUiState
}

// Bad: isLoading + error + data can contradict; empty state gets forgotten
data class TaskListUiState(val isLoading: Boolean, val error: String?, val tasks: List<Task>)
```

This is the Compose enforcement of the parent skill's "every screen handles loading/empty/error." A `when` over a sealed interface is exhaustive — the compiler won't let you skip a state.

### Slot APIs > configuration flags

The Compose form of "composition over configuration":

```kotlin
// Good: caller composes content into slots
@Composable
fun Card(
    modifier: Modifier = Modifier,
    header: @Composable () -> Unit = {},
    content: @Composable ColumnScope.() -> Unit,
)

// Avoid: a flag/param per variation
@Composable
fun Card(title: String, headerVariant: String, bodyPadding: Dp, content: @Composable () -> Unit)
```

### Keep composables focused, hoist state

- State hoisting: a composable that needs a value takes it as a param + an `onXChange` lambda; it does **not** own `remember` unless the state is purely internal UI (e.g. an expand/collapse toggle with no external consumer).
- `remember { }` for state that survives recomposition; `rememberSaveable { }` for state that must survive config change / process death (scroll position via `rememberLazyListState`, form text, etc.).
- Never do side effects (network, DB, navigation) inline in the composable body. Use `LaunchedEffect`, `rememberCoroutineScope`, or push it to the ViewModel.

### `Modifier` order matters

Modifiers apply top-down. `padding` before `clickable` = smaller touch area; `clickable` before `padding` = ripple covers the padding. For touch targets, put `.clickable`/`.size` so the interactive region is ≥48dp (see Accessibility).

## Lists — use lazy, always key

```kotlin
LazyColumn(
    contentPadding = PaddingValues(16.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp),
) {
    items(tasks, key = { it.id }) { task ->
        TaskItem(task, onToggle = { onToggle(task.id) })
    }
}
```

- Never render a large list by iterating inside a `Column` — use `LazyColumn`/`LazyRow`/`LazyVerticalGrid`.
- Always pass `key` — without it, Compose can't track item identity across reorders/removals (animations break, state mis-associates). Same failure mode as a missing React `key`.
- Hoist scroll state with `rememberLazyListState()` if you need to control or restore it.

## Design System — Material 3 tokens, no magic values

Mirror the parent skill's "semantic tokens, spacing scale, no invented values":

```kotlin
// Good: theme tokens
Text(color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodyMedium)
Surface(color = MaterialTheme.colorScheme.surface, shape = MaterialTheme.shapes.medium) { /* ... */ }

// Bad: hardcoded
Text(color = Color(0xFF6B7280))              // raw hex — no token
Box(Modifier.padding(13.dp))                  // off the spacing scale
Surface(shape = RoundedCornerShape(24.dp))    // "rounded-2xl on everything" — AI tell
```

- **Color** → `MaterialTheme.colorScheme` (`primary`, `surface`, `onSurface`, `error`, …). Define the palette once in a `Theme.kt`; support light + dark via `darkColorScheme()`/`lightColorScheme()`. On Android 12+, respect dynamic color (`dynamicDarkColorScheme`) only if the design system opts in.
- **Type** → `MaterialTheme.typography`. Don't inline `fontSize = 17.sp`.
- **Shape** → `MaterialTheme.shapes`. One radius scale, not `24.dp` everywhere.
- **Spacing** → a consistent `dp` scale (4/8/12/16/24…). Define spacing tokens in a small object if the design system has named spacings; otherwise stick to multiples of 4.
- **Elevation** → subtle. Material 3 prefers tonal elevation (color) over heavy drop shadows. Shadow-heavy = AI tell, same as web.

The **AI Aesthetic** table in the parent skill applies verbatim: purple-everything, max rounding, excessive gradients, oversized uniform padding, stock card grids, heavy shadows — all just as wrong in Compose. Use the app's actual Material theme, not Compose sample defaults.

## Accessibility (TalkBack / VoiceOver)

The WCAG intent from the parent skill, expressed in Compose semantics:

- **Content description** — every icon/image conveying meaning needs one; decorative ones get `null`:
  ```kotlin
  Icon(Icons.Default.Delete, contentDescription = "Delete task")   // meaningful
  Icon(Icons.Default.Star, contentDescription = null)               // decorative
  ```
- **Touch targets ≥ 48dp** — Material components handle this; custom clickables must not shrink below it. Use `Modifier.minimumInteractiveComponentSize()` or size the clickable region explicitly. (Web checklist says 44/24px CSS; Android's guideline is 48dp.)
- **Semantics for custom widgets** — expose role and state so screen readers announce correctly:
  ```kotlin
  Modifier.semantics {
      role = Role.Button
      stateDescription = if (selected) "Selected" else "Not selected"
  }
  // toggle/checkbox: use Modifier.toggleable(...) / .selectable(...) which set state automatically
  ```
- **Merge related nodes** — `Modifier.semantics(mergeDescendants = true) {}` so a card reads as one announcement, not five fragments.
- **Don't rely on color alone** — error state needs an icon + text, not just `colorScheme.error` tint. Same rule as web.
- **Live updates** — `Modifier.semantics { liveRegion = LiveRegionMode.Polite }` for async results/toasts (the TalkBack analog of `aria-live`).
- **Respect reduced motion / large font** — never hardcode text as image; let type scale with the system font size (using `sp`, which you already are). Check layouts at the largest accessibility font scale.
- **Test with TalkBack** (Android) and VoiceOver (iOS, for KMP screens). Automated: `androidx.compose.ui.test` + Accessibility Scanner. Automated tooling catches a minority — a manual TalkBack pass is mandatory, same caveat as the web checklist.

## Adaptive / Responsive Layout

Mobile has form factors too (phone, foldable, tablet). The Compose equivalent of breakpoints is `WindowSizeClass`:

```kotlin
val windowSizeClass = calculateWindowSizeClass(activity)   // material3-window-size-class
when (windowSizeClass.widthSizeClass) {
    WindowWidthSizeClass.Compact  -> SinglePaneList(...)          // phone portrait
    WindowWidthSizeClass.Medium,
    WindowWidthSizeClass.Expanded -> ListDetailTwoPane(...)       // foldable/tablet
}
```

- Design compact-first (the mobile analog of "mobile-first"), then expand to two-pane / list-detail for medium/expanded.
- Use `BoxWithConstraints` for component-level responsiveness when a full window class is overkill.
- Prefer `Arrangement`, `weight()`, and `fillMaxWidth()` over fixed `dp` widths so layouts reflow.
- For KMP shared UI, the same `WindowSizeClass` logic runs on both Android and iOS.

## Loading, Skeletons, Optimistic Updates

- **Skeletons over spinners** for content (parent skill rule). A shimmer/placeholder box using `MaterialTheme.colorScheme.surfaceVariant` + a pulse animation, gated behind the `Loading` state branch.
- **Optimistic updates** — update the emitted `UiState` immediately in the ViewModel, roll back on failure:
  ```kotlin
  fun onToggle(id: String) = viewModelScope.launch {
      val snapshot = current()            // keep for rollback
      applyOptimistic(id)                 // emit new state now
      runCatching { repo.toggle(id) }.onFailure { restore(snapshot); emitError(it) }
  }
  ```

## KMP (iOS) Structure

Compose Multiplatform lets one Compose UI run on Android and iOS.

```
composeApp/
  commonMain/    # shared UI (@Composable screens), UiState, ViewModels, repositories interfaces
  androidMain/   # Android entry (Activity), android-only actuals
  iosMain/       # iOS actuals; UI surfaced to Swift via a ComposeUIViewController
```

- Put **UI, state holders, and domain logic in `commonMain`.** They compile for both targets.
- Anything platform-specific (secure storage, biometrics, camera, exact date formatting, haptics) goes behind `expect`/`actual`:
  ```kotlin
  // commonMain
  expect fun formatCurrency(amount: Long, currency: String): String
  // androidMain / iosMain provide the actual
  ```
- **ViewModels** — use the KMP-friendly `androidx.lifecycle.ViewModel` (now multiplatform) or a shared `StateFlow`-based holder; expose `StateFlow<UiState>` from common code.
- On iOS, the Compose UI is embedded as a `UIViewController`. If part of the app is SwiftUI, bridge at that boundary — keep the shared screens in Compose.
- Test shared UI once in `commonTest` with `androidx.compose.ui.test`; it covers both platforms' logic.

## Red Flags (native)

- Composable > ~150 lines, or one composable both fetching data and rendering — split state holder from UI.
- `collectAsState()` instead of `collectAsStateWithLifecycle()`.
- `LazyColumn`/`items` without a `key`.
- Hardcoded `Color(0xFF…)`, `13.dp`, `17.sp`, `RoundedCornerShape(24.dp)` — bypassing `MaterialTheme`.
- Booleans (`isLoading`/`error`/`data`) instead of a sealed `UiState`; missing empty state.
- Icon/image with no `contentDescription`, or a custom clickable under 48dp.
- Side effects (network, navigation) run directly in a composable body instead of `LaunchedEffect`/ViewModel.
- Platform-specific API called from `commonMain` without `expect`/`actual`.
- Iterating a large list inside a plain `Column` instead of a lazy list.

## Verification (native)

- [ ] Screen renders in `@Preview` for each `UiState` branch (Loading/Empty/Error/Content).
- [ ] All four states are reachable and visually distinct — no bare spinner, no blank screen.
- [ ] TalkBack (Android) / VoiceOver (iOS) announces content, roles, and state; every meaningful icon has a `contentDescription`.
- [ ] Touch targets ≥ 48dp.
- [ ] Layout holds at largest system font scale and in dark theme.
- [ ] Adaptive: verified in compact and expanded `WindowSizeClass` (phone + tablet/foldable).
- [ ] Uses `MaterialTheme` tokens only — no hardcoded colors/spacing/type/shape.
- [ ] Lists are lazy and keyed.
- [ ] (KMP) Shared screen compiles for Android and iOS; platform bits behind `expect`/`actual`.
