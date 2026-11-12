# Developer & Agent Guardrails — ClairDocs

**Document Version:** 1.0.0  
**Enforcement Level:** Mandatory  
**Audience:** Human Engineers, AI Pair Programmers, Code Reviewers  

---

## 1. Core Engineering Commandments

1. **Zero Dynamic Typings:** Every boundary between layers (network, storage, domain, presentation) must be bridged by explicit, typed Dart classes. Passing untyped `Map<String, dynamic>` into UI widgets or controllers is strictly forbidden.
2. **Deterministic Arithmetic:** Never use floating-point `double` arithmetic for financial totals, rates, or variances. Always use fixed-point arithmetic (`Decimal` or integer cents) to eliminate rounding errors in audit reports.
3. **Decoupled Architecture:** Widgets are strictly view templates. No database operations, API calls, or math engines may be invoked directly inside Flutter `build()` methods.
4. **Native Code Isolation:** Platform-specific directories (`windows/`, `macos/`, `linux/`, `android/`, `ios/`, `web/`) are immutable unless a user explicitly instructs native configuration changes.
5. **Living Context Maintenance:** Every architectural decision, schema modification, or completed milestone must be documented in `docs/tasks.md` and `docs/memory.md` upon completion of the task.

---

## 2. Type Safety & Model Rules

### 2.1 Freezed & JSON Serialization
- All domain and data models must use `@freezed` with `@JsonSerializable(explicitToJson: true)`.
- Use `build_runner` to generate code (`.freezed.dart` and `.g.dart`).
- Never write manual `fromJson` parsing logic inside UI or business logic files.

```dart
// CORRECT: Typed Freezed Model
@freezed
class DiscrepancyItem with _$DiscrepancyItem {
  const factory DiscrepancyItem({
    required String id,
    required DiscrepancyType type,
    required DiscrepancySeverity severity,
    required ContractCitation citation,
    required InvoiceLineReference lineRef,
    required double invoicedRate,
    required double contractedRate,
    required double varianceAmount,
    required String explanation,
  }) = _DiscrepancyItem;

  factory DiscrepancyItem.fromJson(Map<String, dynamic> json) =>
      _$DiscrepancyItemFromJson(json);
}

// FORBIDDEN: Passing loose untyped maps into widgets or state
void displayError(Map<String, dynamic> rawDiscrepancy) { ... } // VIOLATION!
```

### 2.2 Gemini Schema Adherence
- When querying Gemini models via `google_generative_ai`, always configure `GenerationConfig` with `responseMimeType: 'application/json'` and supply a strict `Schema.object(...)`.
- Validate deserialized JSON against expected domain models at the repository boundary before passing data to Riverpod controllers.

---

## 3. Platform Native Directory Protections

- **Platform Native Directories:**
  - `windows/`
  - `macos/`
  - `linux/`
  - `android/`
  - `ios/`
  - `web/`
- **Rule:** Do NOT modify native runner files (e.g., `windows/runner/main.cpp`, `CMakeLists.txt`, `Info.plist`, `MainActivity.kt`) unless the task specifically requires configuring native desktop window behaviors (such as window frame sizing, native titles, or platform channel bridges).
- If native changes are required, use standard Flutter plugins (`window_manager`, `flutter_secure_storage`) rather than editing C++/Objective-C scaffolding by hand.

---

## 4. State Management Guardrails (Riverpod 2.x)

### 4.1 Notifier & AsyncNotifier Standards
- Use code-gen annotations: `@riverpod` or `@Riverpod(keepAlive: true)`.
- State mutation must be performed exclusively within Notifier methods, never directly in the UI.
- Handle all asynchronous calls with `AsyncValue.guard()` to guarantee safe capture of errors and loading states.

```dart
// CORRECT: Safe AsyncNotifier pattern
@riverpod
class InvoiceController extends _$InvoiceController {
  @override
  FutureOr<InvoiceDocument?> build() => null;

  Future<void> loadInvoice(String filePath) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(invoiceRepositoryProvider);
      return repo.parseInvoice(filePath);
    });
  }
}

// FORBIDDEN: Mutating state directly inside a Flutter widget
onPressed: () {
  ref.read(invoiceStateProvider.notifier).state = rawData; // VIOLATION!
}
```

### 4.2 Widget Consumption Guidelines
- Extend `ConsumerWidget` or `ConsumerStatefulWidget`.
- Never use `ref.read` inside a `build()` method; use `ref.watch` to subscribe to reactive state changes.
- Reserve `ref.read` strictly for event callbacks (`onPressed`, `onChanged`).

---

## 5. UI & Design Token Guardrails

### 5.1 No Hardcoded Design Values
- **Colors:** Hardcoded color literals (`Color(0xFF10B981)`) inside widget trees are strictly prohibited. Always reference tokens from `AppColors` or `Theme.of(context).colorScheme`.
- **Dimensions & Spacing:** Use `AppSpacing.xs`, `AppSpacing.md`, `AppSpacing.lg`, etc. Do not write arbitrary numbers like `SizedBox(height: 19.3)`.
- **Border Radii:** Use `AppRadius.sm`, `AppRadius.md`, `AppRadius.lg`.
- **Strings:** All user-visible strings, button labels, and error messages must be defined in `AppStrings` or a designated localization asset.

```dart
// CORRECT: Using design tokens
Container(
  padding: const EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.surfacePrimaryDark,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: AppColors.borderSubtleDark),
  ),
  child: Text(AppStrings.auditSummaryTitle, style: AppTypography.titleMedium),
)

// FORBIDDEN: Hardcoded magic values
Container(
  padding: const EdgeInsets.all(14.0), // VIOLATION!
  color: Color(0xFF1F2937),           // VIOLATION!
  child: Text("Audit Summary"),        // VIOLATION!
)
```

---

## 6. Workflow, Documentation & Git Hygiene

1. **Task Tracking:**
   - Before beginning any milestone, mark the relevant task as in-progress in `docs/tasks.md`.
   - When a task or sub-item is completed and verified, immediately check the box (`- [x]`) in `docs/tasks.md`.
2. **Context Memory Logging:**
   - Record all key architectural tradeoffs, API model adjustments, or newly discovered edge cases in `docs/memory.md`.
   - If an issue or workaround is identified, append it immediately to the Known Issues table in `docs/memory.md`.
3. **Static Analysis Compliance:**
   - Every commit or pull request must pass `flutter analyze` with **zero warnings and zero errors**.
   - Code must be formatted using `dart format .` before commit.

