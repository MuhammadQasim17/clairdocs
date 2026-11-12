# Project Memory & Living Context — ClairDocs

**Document Version:** 1.0.0  
**Last Updated:** November 10, 2026  
**Current Milestone:** Initial Project Bootstrapping & Blueprint Establishment  

---

## 1. Active Context

Phase 5 (Interactive Dispute Studio & Export Engine) is complete. `DisputeGeneratorService` compiles formal legal dispute letters using `gemini-3.8-flash` across three selectable tone profiles (`Firm Legal`, `Collaborative Partner`, `Strict Breach`) with automatic deterministic offline fallback. `DisputeStudioModal` provides an editable dark-fintech monospaced drafting studio with clipboard copy and native OS PDF export via `DisputePdfExporter` + `FilePicker.saveFile`.

### Current Milestone:
- **Phase 1: Dependencies & Core Architecture Setup:** [COMPLETED]
- **Phase 2: Design System, 3-Column Layout & Live PDF Viewers:** [COMPLETED (6/7 tasks)]
- **Phase 3: Gemini Service & Structured Schema Audit:** [COMPLETED (7/7 tasks)]
- **Phase 4: Audit Diff Engine & UI Binding:** [IN PROGRESS (3/6 tasks)]
- **Phase 5: Dispute Notice Generation & Multi-Format Export:** [COMPLETED (6/6 tasks)]
- **Phase 6: Enterprise Polish, Themes & Verification:** [NEXT]

### Next Immediate Action Items:
1. Implement deterministic client-side variance verification (`VarianceCalculator` using `Decimal`).
2. Add bidirectional document jump links (`[Jump to Clause]` / `[Jump to Line]`) and auditor waive/accept controls.
3. Add Light/Dark theme switching, desktop keyboard shortcuts, and local session caching.

---

## 2. Technical Stack & Dependency Landscape

| Component | Technology / Library | Version Constraint | Rationale / Purpose |
| :--- | :--- | :--- | :--- |
| **UI Framework** | Flutter Desktop | SDK ^3.13.7 (Dart 3.x) | Native multi-platform desktop rendering on Windows, macOS, Linux. |
| **State Management** | `flutter_riverpod` + `riverpod_annotation` | ^2.6.1 | Compile-time safe, reactive state management with code-gen. |
| **AI Reasoning Engine** | `google_generative_ai` | ^0.4.7 | Official Google SDK for Gemini 3.8 Flash and Gemini 3.5 Flash Lite with JSON Schema. |
| **Document Rendering** | `syncfusion_flutter_pdfviewer` | ^28.1.33 | High-performance desktop PDF rendering, continuous scroll, zooming, text search. |
| **Immutability & Models** | `freezed` + `json_serializable` | ^2.5.7 / ^4.9.0 | Strongly-typed, immutable models with boilerplate-free copyWith and JSON parsing. |
| **Credential Security** | `flutter_secure_storage` | ^9.2.2 | Hardware/OS-backed encrypted key storage (WinCred, Keychain, Secret Service). |
| **File Selection** | `file_picker` | ^8.1.7 | Native OS dialogs for multi-format document picking. |
| **Deterministic Math** | `decimal` | ^3.0.2 | Arbitrary-precision decimal arithmetic to prevent floating-point rounding errors. |
| **Document Generation** | `pdf` + `printing` | ^3.11.1 / ^5.13.3 | Client-side generation and rendering of formal dispute notice PDFs. |
| **Integrity Verification** | `crypto` | ^3.0.6 | SHA-256 cryptographic document checksum calculation. |

---

## 3. Architecture Decision Records (ADRs)

### ADR-001: Desktop-First Single-Tenant Local Architecture
- **Context:** Enterprise contracts and billing statements contain highly confidential trade secrets, executive rates, and strict NDA terms.
- **Decision:** Build ClairDocs as a standalone single-tenant desktop workstation. No multi-tenant backend server or intermediary telemetry proxy is introduced.
- **Consequences:** Documents and parsed tokens remain on the local machine. API requests flow directly from the client to Google AI Studio over TLS 1.3 using the customer's own API key.

### ADR-002: Direct Gemini Multi-Modal Ingestion with Native JSON Schema
- **Context:** Invoices and contracts have complex layouts, tables, and fine-print provisions. Traditional OCR plus regex extraction misses table structures and contextual relationships.
- **Decision:** Use Google's `google_generative_ai` SDK utilizing Gemini's native multi-modal document capabilities combined with strict JSON schema enforcement (`GenerationConfig(responseMimeType: 'application/json', responseSchema: ...)`).
- **Consequences:** Eliminates prompt formatting drift, guarantees deterministic JSON output structures, and drastically simplifies deserialization into typed Dart models.

### ADR-003: Riverpod 2.x Code-Gen with Strict Typing
- **Context:** Complex desktop layouts with dual PDF viewers, synchronized scrolling, filterable discrepancy panels, and modal letter generation require fine-grained reactive state without boilerplate.
- **Decision:** Mandate Riverpod 2.x with `@riverpod` annotations and `AsyncNotifier` patterns. Reject untyped maps and service locator singletons.
- **Consequences:** Predictable unidirectional data flow, automated disposal of document sessions, and type-safe compile-time verification.

### ADR-004: Syncfusion PDF Viewer for Dual-Pane Continuous Rendering
- **Context:** Users must cross-examine 100+ page contracts against itemized invoices with synchronized viewing and search capabilities.
- **Decision:** Adopt `syncfusion_flutter_pdfviewer` for both contract and invoice viewports.
- **Consequences:** Delivers 60 FPS continuous document scrolling, built-in zoom physics, native search navigation, and bookmark jumping.

### ADR-005: Client-Side Deterministic Mathematical Engine (`Decimal`)
- **Context:** LLMs are linguistic probabilistic reasoning engines and can occasionally make minor arithmetic mistakes on line totals or tax percentages.
- **Decision:** Gemini is tasked with clause matching, line mapping, and discrepancy identification. All mathematical totals, variance deltas, and withholding amounts are verified and recalculated on the client side using the `decimal` package.
- **Consequences:** Guarantees 100% mathematical accuracy and eliminates rounding hallucinations in legal dispute notices.

---

## 4. Key Entities & Domain Schemas

```dart
// Core domain entity overview for agent continuity
AuditReport
 ├── String id
 ├── String summary
 ├── ContractMetadata (vendorName, clientName, effectiveDate, contractId)
 ├── InvoiceMetadata (invoiceNumber, invoiceDate, dueDate, totalBilled)
 ├── Decimal calculatedTotalInvoiced
 ├── Decimal calculatedTotalExpected
 ├── Decimal calculatedTotalVariance
 └── List<DiscrepancyItem>
      ├── String id
      ├── DiscrepancyType (rateOvercharge, hoursOverage, policyViolation, etc.)
      ├── DiscrepancySeverity (match, warning, violation)
      ├── ContractCitation (clauseNumber, sectionTitle, pageNumber, quotedText)
      ├── InvoiceLineReference (lineNumber, pageNumber, description, billedQuantity, billedRate, billedTotal)
      ├── Decimal expectedRate
      ├── Decimal expectedTotal
      ├── Decimal varianceAmount
      ├── double confidenceScore
      └── String explanation
```

---

## 5. Known Issues, Workarounds & Technical Debt

| ID | Module / Component | Description | Impact | Workaround / Mitigation | Target Fix Milestone |
| :--- | :--- | :--- | :--- | :--- | :--- |
| *None* | — | *No active known issues logged during initial bootstrap.* | — | — | — |

---

## 6. Change Log & Session History

### Session: November 10, 2026
- **Action:** Created foundational documentation blueprint suite under `docs/`:
  - `docs/prd.md`, `docs/architecture.md`, `docs/design.md`, `docs/rules.md`, `docs/tasks.md`, `docs/memory.md`.
- **Action:** Executed Phase 2: Design System, Tokens, and 3-Column Split Viewport Layout:
  - Updated `lib/core/theme/app_colors.dart` with enterprise dark-mode palette (`0xFF0B0F19`, `0xFF111827`, `0xFF1E293B`, `0xFF1F2937`) and semantic accents (Emerald `0xFF10B981`, Crimson `0xFFEF4444`, Amber `0xFFF59E0B`, Sky `0xFF38BDF8`).
  - Configured compact typography tokens in `lib/core/theme/app_typography.dart` and ThemeData in `lib/core/theme/app_theme.dart`.
  - Built `TopCommandBar` with brand badge, breadcrumbs, discrepancy counter pill, and action buttons.
  - Built `AuditWorkbenchScreen` featuring the 3-column desktop layout (40% Contract, 35% Invoice, 25% Action Studio) and bottom status bar.
  - Built Discrepancy & Action Studio widgets: `KpiSummaryCard`, `RateComparisonCard`, `DiscrepancyItemCard`, and `ActionStudioPanel`.
  - Built `ContractViewerPanel` and `InvoiceViewerPanel` with custom toolbars and highlighted prototype canvas cards.
  - Updated `lib/app.dart` to use `AuditWorkbenchScreen` as the default view.
  - Verified clean static analysis (`flutter analyze`: 0 issues) and desktop smoke tests (`flutter test`: All tests passed).
  - Updated `docs/tasks.md` and `docs/memory.md`.
- **Action:** Executed Real PDF Ingestion & Viewer Integration (`syncfusion_flutter_pdfviewer` & `file_picker`):
  - Upgraded `ContractDocument` and `InvoiceDocument` (plus `ContractState` / `InvoiceState`) to `@freezed` models (`abstract class ... with _$...`) with `fileSizeBytes`, `formattedSize`, `sha256Hash`, and `pageCount`, and generated code via `build_runner`.
  - Updated `ContractDocumentNotifier` and `InvoiceDocumentNotifier` to use `FilePicker.pickFile` (note: `file_picker` v13+ uses static `FilePicker.pickFile` directly rather than `.platform`), enforcing single-file `.pdf` selection with full validation, SHA-256 hashing, `setDemoMode`, and reset capabilities.
  - Built reusable `PdfEmptyDropzone` widget (`lib/core/widgets/pdf_empty_dropzone.dart`) with hover states, error alerts, file picker button, and sample preview toggle.
  - Bound `SfPdfViewer.file` and `PdfViewerController` inside `ContractViewerPanel` and `InvoiceViewerPanel` with a `Live PDF | Demo Sample` segmented toggle in the toolbar, live zoom (`-`, `+`, reset `100%`), active page tracking (`< Current / Total >`), and document closing.
  - Wired `TopCommandBar` buttons (`Upload Contract`, `Upload Invoice`) and `AuditWorkbenchScreen` status bar dynamically to loaded document names, loading indicators, and SHA-256 fingerprints.
  - Updated `test/widget_test.dart` to test upload buttons, dropzones, and header mode toggles. Verified `flutter analyze` (0 issues) and `flutter test` (All tests passed).
- **Action:** Executed Phase 4: Gemini Audit Engine & Typed Structured Output Integration:
  - Implemented Freezed `AuditResult` and `AuditFinding` models in `lib/features/audit/models/audit_models.dart` with `fromJson` / `toJson` generation via `build_runner` (and `invalid_annotation_target: ignore` in `analysis_options.yaml` per Freezed guidelines).
  - Built `GeminiAuditService` (`lib/features/audit/services/gemini_audit_service.dart`) using `gemini-3.8-flash`, `GenerationConfig(responseMimeType: 'application/json', responseSchema: ...)`, `DataPart('application/pdf', bytes)`, retry backoff, JSON sanitization, and multi-tier API key resolution (`--dart-define=GEMINI_API_KEY`, `SecureStorageService`, and `.env`).
  - Implemented `auditProvider` (`AsyncNotifier<AuditResult?>`) in `lib/features/audit/providers/audit_provider.dart` orchestrating real PDF audits, Demo Sample simulations, and actionable validation errors.
  - Bound `TopCommandBar` ("Run AI Audit" button + dynamic status pill), `ActionStudioPanel` (with `AuditSkeletonLoader`, idle/error/data states), `KpiSummaryCard`, `RateComparisonCard`, `DiscrepancyItemCard.fromFinding`, `ApiKeyDialog`, and dynamic Dispute Notice clipboard copy.
  - Verified `flutter analyze` (0 issues) and `flutter test` (2/2 tests passed). Updated `docs/tasks.md` (59% overall complete).
- **Action:** Executed Phase 5: Interactive Dispute Studio & Export Engine:
  - Implemented Freezed `DisputeState`, `DisputeTone` (`Firm Legal`, `Collaborative Partner`, `Strict Breach`), and `DisputeGenerationStatus` models in `lib/features/disputes/models/dispute_models.dart` (`dispute_models.freezed.dart` generated via `build_runner`).
  - Built `DisputeGeneratorService` (`lib/features/disputes/services/dispute_generator_service.dart`) utilizing `gemini-3.8-flash` with tailored legal tone prompts and automatic deterministic fallback generation (offline / missing API key / rate-limit resilient).
  - Built `DisputePdfExporter` (`lib/features/disputes/services/dispute_pdf_exporter.dart`) compiling formal multi-page PDF notices (`TableHelper.fromTextArray`, header banner, ASCII-safe text rendering, Procurement/AP signature blocks) and exporting via `FilePicker.saveFile` (`file_picker` v13 static API).
  - Implemented `disputeProvider` (`Notifier<DisputeState>`) in `lib/features/disputes/providers/dispute_provider.dart` and `DisputeStudioModal` (`lib/features/disputes/presentation/widgets/dispute_studio_modal.dart`) with editable dark-fintech monospaced `TextField`, tone chips, Regenerate, Copy to Clipboard, and Export PDF actions wired to `ActionStudioPanel`.
  - Added timeout resilience to `SecureStorageService` lookups in `GeminiAuditService.resolveApiKey` and expanded `test/widget_test.dart` with fallback letter, PDF compilation, and Dispute Studio UI flow tests. Verified `flutter analyze` (0 issues) and `flutter test` (3/3 tests passed). Updated `docs/tasks.md` (74% overall complete).
- **Action:** Configured Automatic `.env` Secret Loading (`flutter_dotenv`):
  - Added `flutter_dotenv: ^6.0.1` and declared `.env` under `flutter: assets:` in `pubspec.yaml`.
  - Created `.env` with `GEMINI_API_KEY` and ignored `.env` / `.env.*` in `.gitignore`.
  - Initialized `await dotenv.load(fileName: '.env')` in `lib/main.dart`.
  - Updated `GeminiAuditService.resolveApiKey` to read `dotenv.env['GEMINI_API_KEY']` first, falling back to `--dart-define=GEMINI_API_KEY`, in-app `apiKeyProvider`, and `SecureStorageService`.
  - Verified `flutter analyze` (0 issues) and `flutter test` (4/4 tests passed).
- **Action:** Upgraded Gemini Model Configuration to `gemini-3.8-flash`:
  - Updated `ApiConstants.defaultGeminiModel` (`gemini-3.8-flash`), `defaultGeminiModelDisplayName` (`Gemini 3.8 Flash`), and `defaultGeminiModelShortBadge` (`GEMINI 3.8`) in `lib/core/constants/api_constants.dart`.
  - Exposed `activeModelName` and `activeModelDisplayName` on `GeminiAuditService` while preserving JSON schema and structured payload extraction (`DisputeGeneratorService` also inherits `ApiConstants.defaultGeminiModel`).
  - Updated status bar in `AuditWorkbenchScreen` (`AI Engine: Gemini 3.8 Flash`), `ActionStudioPanel` badge (`GEMINI 3.8`), `AuditSkeletonLoader`, and `DisputeStudioModal` badges.
  - Verified `flutter analyze` (0 issues) and `flutter test` (4/4 tests passed).
- **Action:** Implemented Graceful 429 Rate-Limit Handling & Audit Button Debouncing:
  - Added `GeminiRateLimitException` in `lib/core/errors/exceptions.dart`.
  - Implemented `executeWithRateLimitRetry` in `GeminiAuditService` (up to 2 retries, extracting `retry-after`/`retry in Xs` hints or applying 4s -> 8s exponential backoff) with live `onRetryStatus` status callbacks.
  - Added `auditStatusMessageProvider` and `auditCooldownProvider` (3-second post-audit cooldown timer) in `lib/features/audit/providers/audit_provider.dart`.
  - Updated `TopCommandBar`, `AuditSkeletonLoader`, and `ActionStudioPanel` to display live retry messages (`"Rate limit reached. Retrying automatically in X seconds..."`), enforce 3-second debouncing on Run/Retry buttons, and render a friendly Free Tier Limit Reached error card.
  - Added unit and widget tests covering 429 retry exhaustion/recovery and 3-second cooldown debouncing (`flutter test`: 5/5 passed; `flutter analyze`: 0 issues).
- **Action:** Configured Active Model Chain (`gemini-3.8-flash` -> `gemini-3.5-flash-lite`) & Removed All Legacy Identifiers:
  - Set `ApiConstants.defaultGeminiModel` to `gemini-3.8-flash`, `fallbackGeminiModel` to `gemini-3.5-flash-lite`, `geminiModelFallbackChain` to `[gemini-3.8-flash, gemini-3.5-flash-lite]`, and `maxRetryAttempts` to `2`.
  - Added `GeminiServerBusyException` in `lib/core/errors/exceptions.dart`.
  - Updated `GeminiAuditService` with `isServerBusyError`, `isModelNotFoundOrRetiredError`, 503 exponential retry backoff (`2s -> 4s`, up to 2 retries) emitting `"Google AI servers busy, retrying in Xs..."`, and `executeWithModelFallback` automatically falling back to `gemini-3.5-flash-lite` if `gemini-3.8-flash` stays unavailable.
  - Removed all legacy model identifiers across `lib/`, `test/`, and `docs/`.
  - Updated `TopCommandBar` and `ActionStudioPanel` for amber `"Google AI Servers Busy (503)"` error cards and `"Servers Busy (503)"` status pills.
- **Action:** Implemented Dual-Engine Failover (Gemini 3.8 + Groq Llama 3.3) & Local PDF Text Extraction:
  - Added `GROQ_API_KEY` to `.env` and declared `syncfusion_flutter_pdf: ^35.1.43` and `http: ^1.6.0` directly in `pubspec.yaml`.
  - Built `PdfExtractionService` (`lib/features/audit/services/pdf_extraction_service.dart`) using `PdfDocument` and `PdfTextExtractor` to extract compact, page-annotated plain text strings locally (minimal token footprint).
  - Built `GroqAuditService` (`lib/features/audit/services/groq_audit_service.dart`) targeting `POST https://api.groq.com/openai/v1/chat/completions` with `model: "llama-3.3-70b-versatile"` and `response_format: { "type": "json_object" }`.
  - Added `auditEngine` tracking field on `AuditResult` and `DualEngineAuditException` in `lib/core/errors/exceptions.dart`.
  - Orchestrated hybrid failover inside `GeminiAuditService`: local text extraction -> `gemini-3.8-flash` (with `gemini-3.5-flash-lite` retry/fallback) -> seamless automatic failover to `GroqAuditService` on 429/503/quota/key failures -> clear dual-engine diagnostic if both fail.
  - Updated status pills and chips in `TopCommandBar`, `ActionStudioPanel`, and `AuditWorkbenchScreen` bottom bar to display the active completing engine (`Gemini 3.8` or `Llama 3.3 (Groq)`).
  - Verified `flutter analyze` (0 issues) and `flutter test` (9/9 tests passed).
- **Action:** Upgraded Groq Fallback Engine to `openai/gpt-oss-120b` (with `openai/gpt-oss-20b` secondary fallback):
  - Updated `ApiConstants` (`groqModel = 'openai/gpt-oss-120b'`, `groqFallbackModel = 'openai/gpt-oss-20b'`, `groqModelFallbackChain`, `groqMaxTokens = 4096`, `groqEngineLabel = 'Engine: GPT-OSS 120B (Groq)'`, `groqFallbackEngineLabel = 'Engine: GPT-OSS 20B (Groq)'`).
  - Updated `GroqAuditService` (`lib/features/audit/services/groq_audit_service.dart`) to iterate `groqModelFallbackChain`, set `max_tokens: 4096`, keep `response_format: { "type": "json_object" }`, and format the extracted PDF user prompt as `"Contract Document Text:\n$contractText\n\nVendor Invoice Text:\n$invoiceText"`.
  - Updated UI engine badges in `ActionStudioPanel` and `AuditWorkbenchScreen` bottom status bar to display `Engine: GPT-OSS 120B (Groq)` (or `Engine: GPT-OSS 20B (Groq)` on fallback) without duplicate prefixes.
  - Updated unit tests in `test/widget_test.dart` covering `openai/gpt-oss-120b`, `max_tokens >= 2048`, prompt format, `404` -> `openai/gpt-oss-20b` fallback, and Gemini -> Groq hybrid failover.
- **Action:** Fixed Interactive Dispute Studio Infinite Hang with 8s Timeout, Groq Fallback & Instant Deterministic Template:
  - Added shared `_postWithFallback` + `generateDisputeDraft` (`openai/gpt-oss-120b` / `openai/gpt-oss-20b`) to `GroqAuditService` (`lib/features/audit/services/groq_audit_service.dart`) and exposed `groqAuditServiceProvider` in `lib/features/audit/providers/audit_provider.dart`.
  - Replaced blocking `RetryPolicy` (4x90s) in `DisputeGeneratorService` (`lib/features/disputes/services/dispute_generator_service.dart`) with a strict `8-second` LLM timeout (`defaultLlmTimeout = Duration(seconds: 8)`), automatic fallback to `GroqAuditService.generateDisputeDraft`, and instant deterministic `generateFallbackNotice(AuditResult result, DisputeTone tone)` with Formal Notice header, Vendor, Financial Summary, itemized flagged findings (clause ref, invoiced vs contract rate, disputed amount), tone-adjusted closing demand, and 14 Business Days deadline.
  - Updated `DisputeState` (via `build_runner`) and `DisputeNotifier.generateDraft` (`lib/features/disputes/providers/dispute_provider.dart`) to pre-fill `draftText` synchronously from `generateFallbackNotice` while refining asynchronously in the background (without overwriting manual edits).
  - Updated `DisputeStudioModal` (`lib/features/disputes/presentation/widgets/dispute_studio_modal.dart`) so the editable text area, Tone chips, `Copy to Clipboard`, and `Export PDF` buttons are immediately enabled once draft text is rendered.
- **Action:** Added Microsoft Word (`.docx` / `.doc`) Ingestion & Preview Support:
  - Added `archive: ^4.6.0` and `xml: ^7.0.1` to `pubspec.yaml`.
  - Created `DocumentFileHelper` (`lib/core/utils/document_file_helper.dart`) centralizing `supportedExtensions = ['pdf', 'docx', 'doc']`, `FilePicker.pickFile`, extension guards, and SHA-256 hashing across `ContractDocumentNotifier` and `InvoiceDocumentNotifier`.
  - Upgraded `PdfExtractionService` (`lib/features/audit/services/pdf_extraction_service.dart`) to dispatch by file extension: `.pdf` via Syncfusion PDF, `.docx` via `word/document.xml` (+ headers/footers) XML paragraph & table extraction, and `.doc` via OOXML/RTF/ASCII run extraction.
  - Created `WordDocumentPreview` (`lib/core/widgets/word_document_preview.dart`) and wired it into `ContractViewerPanel` and `InvoiceViewerPanel` so uploaded `.docx`/`.doc` documents preview cleanly with zoom support without invoking `SfPdfViewer`.
  - Guarded `GeminiAuditService.auditDocuments` multimodal binary fallback so non-PDF files are never labeled `application/pdf`, and added end-to-end `.docx` extraction -> Groq audit unit tests in `test/widget_test.dart`.
- **Action:** Added Spreadsheet Ingestion (`.csv`, `.xlsx`, `.xls`) Support Alongside PDF and Word:
  - Added `csv: ^6.0.0` to `pubspec.yaml` (`excel: ^4.0.6` could not be added due to a transitive pub version solver conflict: `excel >=2.0.1` requires `xml <7.0.0`, while `syncfusion_flutter_pdf: ^35.1.43` and `pdf: ^3.13.1` require `xml >=7.0.1 <8.0.0`; implemented native OpenXML `.xlsx` extraction via `archive` + `xml` instead).
  - Expanded `DocumentFileHelper.supportedExtensions` to `['pdf', 'docx', 'doc', 'csv', 'xlsx', 'xls']` across `Upload Contract` and `Upload Invoice` pickers and dropzones.
  - Added unified `extractDocumentText(File file)` router in `PdfExtractionService` supporting `.csv` (`CsvToListConverter` formatted as ` | ` rows), `.xlsx` (`xl/workbook.xml`, `xl/sharedStrings.xml`, `xl/worksheets/sheet*.xml` formatted with ` | ` columns), and text/XML/ZIP `.xls`.
  - Updated `GeminiAuditService` and `GroqAuditService` to label spreadsheet invoices with `"Invoice Spreadsheet Data:\n$spreadsheetText"` in LLM prompts and updated `WordDocumentPreview` to display spreadsheet previews cleanly.
  - Added `.csv` and `.xlsx` extraction + end-to-end LLM audit tests in `test/widget_test.dart`.
- **Action:** Offloaded PDF Extraction to Background Isolate (`compute`) & Fixed Audit Status Hang:
  - Updated `PdfExtractionService` (`lib/features/audit/services/pdf_extraction_service.dart`) to run Syncfusion `PdfDocument`/`PdfTextExtractor` parsing in top-level `_extractPdfBytesInIsolate` via `compute(...)` with a strict `5-second` timeout (`extractTextFromPdf`).
  - Added `isExtractionFailureOrEmpty` and `_buildDocumentDescriptor` fallback in `GeminiAuditService` (`lib/features/audit/services/gemini_audit_service.dart`) so timed-out, failed, or scanned/empty PDFs immediately proceed to `'Auditing with Gemini 3.8 / Groq...'` with direct binary `DataPart` / document descriptor fallback instead of hanging or failing on Groq.
  - Updated `AuditNotifier.runAudit` (`lib/features/audit/providers/audit_provider.dart`) to wrap concurrent extraction in `try/catch` and promptly transition status from `'Extracting text locally from documents...'` to `'Auditing with Gemini 3.8 / Groq...'`.
  - Added background isolate PDF extraction, 5s timeout fallback, and status-transition unit tests in `test/widget_test.dart`.
- **Action:** Optimized Sub-15s Hybrid Audit Latency (`Gemini 8s Timeout` -> `Groq openai/gpt-oss-20b` Ultra-Fast LPU Failover):
  - Reduced Gemini audit timeout from 90s down to strict `8 seconds` (`ApiConstants.geminiAuditTimeout`) with single-shot execution (no slow Gemini retry loops) and instant failover on timeout, `429`, `503`, `404`, key, or network errors.
  - Added 4-second slow-response `Timer` (`ApiConstants.geminiSlowStatusDelay`) inside `GeminiAuditService.executeHybridAudit` emitting `"Routing to Groq ultra-fast engine..."` into `auditStatusMessageProvider` for live Top Command Bar status chip feedback.
  - Configured `GroqAuditService` (`lib/features/audit/services/groq_audit_service.dart`) to prioritize `openai/gpt-oss-20b` (`~1000 tok/s` LPU primary) with fallback to `openai/gpt-oss-120b`, using `temperature: 0.1`, `max_tokens: 1500`, `response_format: { "type": "json_object" }`, and `10s` timeout (`ApiConstants.groqAuditTimeout`).
  - Streamlined system/user prompts to skip verbose chain-of-thought reasoning and added `truncatePromptText` (`12,000` char cap per document) across both engines.
  - Updated unit tests in `test/widget_test.dart` covering 8s/4s/10s timing guarantees, `12,000`-char prompt truncation, `openai/gpt-oss-20b` -> `openai/gpt-oss-120b` fallback, and `"Routing to Groq ultra-fast engine..."` status transition.
- **Action:** Implemented Document Dismiss Buttons, Auto-Reset on New Uploads, & Instant Dispute Tone Switching:
  - Placed visible `Icons.close` dismiss buttons (`tooltip: 'Remove file'`) directly in the Contract and Invoice viewer headers next to the mode switcher, clearing the loaded file/demo, unmounting extracted previews, and resetting `auditProvider` + `disputeProvider`.
  - Added reactive listeners in `AuditNotifier.build()` and `DisputeNotifier.build()` so uploading a new document or toggling Demo Sample mode automatically invalidates stale audit metrics/findings and dispute state, and hid the `Draft Dispute Notice` CTA whenever no active variances exist.
  - Updated `DisputeNotifier` (`switchTone`) and `DisputeStudioModal` (`_syncControllerIfNeeded`) for synchronous `0 ms` local tone switching (`Firm Legal`, `Collaborative Partner`, `Strict Breach`) without hitting live LLM endpoints, reserving LLM generation for explicit `Regenerate` clicks covered by an inline loading overlay over the text field.
- **Action:** Fixed Party Extraction, Executive PDF Notice Redesign & UI Polish:
  - Added optional `vendorName`, `clientName`, `invoiceNumber`, and `contractReference` fields to `AuditResult` (and `clientName` to `DisputeState`), updated Gemini & Groq schemas/prompts, and added deterministic `PdfExtractionService.extractPartyMetadata` header extraction so real vendor/client/ref values override filename fallbacks across Dispute Studio and generated notices.
  - Redesigned `DisputePdfExporter` into an executive 1-to-2 page PDF with a single header banner (`FORMAL NOTICE OF INVOICE DISCREPANCY & CONDITIONAL REMITTANCE`), 2-column metadata grid, 3-metric financial callout bar, 6-column non-breaking discrepancy table (`Item #`, `Description & Finding`, `Violated Clause`, `Agreed Rate`, `Billed Rate`, `Withheld Amount`), tone-specific legal rectification terms, and dual-signature execution block (without dumping duplicate raw draft text).
  - Compacted the `ActionStudioPanel` Engine badge (`Engine: GPT-OSS 20B`) so `'Discrepancy & Action Studio'` renders untruncated; customized dropzone CTA labels (`Select Governing Contract`, `Select Vendor Invoice`); and added `'Awaiting Documents'` neutral Top Bar chip with disabled `'Run AI Audit'` when no documents are selected.
- **Action:** Hardened PDF Unicode & Dash Sanitization in `DisputePdfExporter`:
  - Upgraded `_sanitizeForPdf` into `DisputePdfExporter.sanitizePdfText` (`lib/features/disputes/services/dispute_pdf_exporter.dart`) replacing all Unicode dashes (`\u2010`–`\u2015`, including `\u2011` non-breaking hyphen, en-dash, em-dash, figure dash, horizontal bar, and `\u2212` minus) with regular `-`, stripping soft hyphens/zero-width formatters, normalizing spaces/quotes/bullets/arrows/currencies (`€` -> `EUR `), and stripping stray non-WinAnsi glyphs across every text element (`todayDate`, `deadlineDate`, `tone.label`, financial metrics, metadata cells, table cells, and legal terms).
  - Added PDF Unicode dash normalization and zero-glyph-fallback tests in `test/widget_test.dart`.
- **Action:** Equalized Split Document Frame Sizes, Unified High-Resolution PDF Rasterization & Cleaned Exported Discrepancy Table:
  - Updated `AuditWorkbenchScreen` (`lib/features/audit/presentation/screens/audit_workbench_screen.dart`) to house `ContractViewerPanel` and `InvoiceViewerPanel` inside exact equal `Expanded(flex: 1, child: SizedBox.expand(...))` panes (balanced 37.5% / 37.5% document split + 25% `ActionStudioPanel`), removing the earlier 40%/35% asymmetry.
  - Created shared [`ClairPdfViewer`](file:///e:/Projects/clairdocs/lib/core/widgets/clair_pdf_viewer.dart) (`lib/core/widgets/clair_pdf_viewer.dart`) enforcing `minRasterScale = 2.5` via `MediaQuery.devicePixelRatio` multiplier and `maxZoomLevel: 3.0`, and wired both `ContractViewerPanel` and `InvoiceViewerPanel` to render via this identical viewport.
  - Updated `DisputePdfExporter` (`lib/features/disputes/services/dispute_pdf_exporter.dart`) with `cleanFindingText` to strip raw technical enum tags (`[RATE_BREACH]`, `[UNAPPROVED_EXPENSE]`, etc.), tuned table column widths (`36 | Flex(2.75) | Flex(1.25) | 64 | 64 | 74`), `headerAlignments`, `cellPadding`, and `lineSpacing: 1.4`.
- **Action:** Cleaned Up Document Pane Header Bar & Discrepancy Card Title Wrapping:
  - Extracted shared [`DocumentPaneHeader`](file:///e:/Projects/clairdocs/lib/core/widgets/document_pane_header.dart) (`lib/core/widgets/document_pane_header.dart`) used by both `ContractViewerPanel` and `InvoiceViewerPanel`, replacing rigid single-line `Row` + clipped `SingleChildScrollView` toolbars with responsive `Wrap` rows and `24x24` compact buttons so filenames, `Live Doc`/`Demo Sample` pills, `Remove file` (`X`), zoom/page controls, and the green `SHA-256 Verified` checksum badge never crowd or clip off-screen.
  - Updated `DiscrepancyItemCard` (`lib/features/audit/presentation/widgets/discrepancy_item_card.dart`) and `RateComparisonCard` (`lib/features/audit/presentation/widgets/rate_comparison_card.dart`) to wrap finding titles cleanly (`maxLines: 2`, `overflow: TextOverflow.ellipsis`) with constrained badges and single-line ellipsized citations/line refs.
  - Added layout regression widget tests in `test/widget_test.dart`.
- **Action:** Added Enterprise Animated Splash Screen & Custom App Logo Branding:
  - Generated custom `512x512` PNG app icon saved at `assets/logo.png` and registered it in `pubspec.yaml`.
  - Created shared [`ClairLogoBadge`](file:///e:/Projects/clairdocs/lib/core/widgets/clair_logo_badge.dart) (`lib/core/widgets/clair_logo_badge.dart`) rendering `assets/logo.png` cleanly across both startup splash and workbench header.
  - Created [`SplashScreen`](file:///e:/Projects/clairdocs/lib/features/splash/splash_screen.dart) (`lib/features/splash/splash_screen.dart`) with a dark radial backdrop, `1.5s` `AnimationController` fade + `0.85 -> 1.0` scale entrance, continuous halo pulse around the central badge, and automatic `2.0s` crossfade transition into `AuditWorkbenchScreen` wired in `lib/app.dart`.
  - Replaced the static header `Icons.gavel_rounded` badge in `TopCommandBar` (`lib/features/audit/presentation/widgets/top_command_bar.dart`) with `ClairLogoBadge`, and updated startup & branding assertions in `test/widget_test.dart`.
- **Action:** Implemented Interactive PDF Line Highlighter & Finding-to-Document State Sync:
  - Added optional `searchKeyword` field to `AuditFinding` (`lib/features/audit/models/audit_models.dart`, regenerated via `build_runner`), populated demo `searchKeyword`s (`Lead Cloud Architect`, `First-Class`, `Volume Rebate`), and updated `GeminiAuditService` & `GroqAuditService` schemas/prompts to extract exact searchable keywords.
  - Added `activeSelectedFindingProvider` and `findingHighlightSequenceProvider` in `lib/features/audit/providers/audit_provider.dart` (auto-cleared on `resetAudit()` and audit runs).
  - Created [`DocumentViewerPane`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/document_viewer_pane.dart) (`lib/features/audit/presentation/widgets/document_viewer_pane.dart`) computing pane-role prioritized search candidates, invoking `PdfViewerController.searchText(...)` with automatic candidate fallback, displaying a 2.2s glowing pulse perimeter highlight + match occurrence pill (`previousInstance`/`nextInstance`/`clear`), highlighting inline matches in `WordDocumentPreview`, and scrolling + pulsing Demo clauses/invoice rows cleanly in `ContractViewerPanel` and `InvoiceViewerPanel`.
  - Wired `DiscrepancyItemCard` & `RateComparisonCard` selection highlights and tap callbacks inside `ActionStudioPanel`, and added end-to-end search controller + provider tests in `test/widget_test.dart`.
- **Action:** Implemented Local SQLite Audit History Persistence (`Audit Vault`):
  - Added `sqflite: ^2.3.2`, `sqflite_common_ffi: ^2.3.4`, and `path: ^1.9.0` to `pubspec.yaml`.
  - Created [`AuditRecord`](file:///e:/Projects/clairdocs/lib/features/history/models/audit_record.dart) (`lib/features/history/models/audit_record.dart`) and [`AuditDatabaseService`](file:///e:/Projects/clairdocs/lib/features/history/services/audit_database_service.dart) (`lib/features/history/services/audit_database_service.dart`) managing `clairdocs_vault.db` (`audits` table with `saveAuditRecord`, `fetchAllAudits`, and `deleteAuditRecord` via FFI on Windows/Linux).
  - Created `auditHistoryProvider` (`lib/features/history/providers/audit_history_provider.dart`), wired background auto-save on audit completion and `loadHistoricalAudit` into `AuditNotifier`, and preserved saved `notice_text` via `DisputeNotifier.loadHistoricalDispute`.
  - Added `Audit Vault` button in `TopCommandBar` opening [`AuditVaultDialog`](file:///e:/Projects/clairdocs/lib/features/history/presentation/widgets/audit_vault_dialog.dart) (`lib/features/history/presentation/widgets/audit_vault_dialog.dart`) with vendor/document search, record deletion, `Reload Past Audit`, and `Export PDF`.
  - Added SQLite disk CRUD and Audit Vault UI workflow tests in `test/widget_test.dart`.
- **Action:** Implemented Analytics & Savings Dashboard (`fl_chart`):
  - Added `fl_chart: ^0.68.0` to `pubspec.yaml`.
  - Created [`AnalyticsSummary`](file:///e:/Projects/clairdocs/lib/features/analytics/models/analytics_summary.dart) (`lib/features/analytics/models/analytics_summary.dart`) and `auditAnalyticsProvider` (`lib/features/analytics/providers/analytics_provider.dart`) computing Total Audits Performed, Total Dollars Withheld / Recovered, Average Variance Percentage, Top 5 Overcharging Vendors, and Category Variance Breakdown reactively from `auditHistoryProvider` / `clairdocs_vault.db`.
  - Created [`AnalyticsDashboardScreen`](file:///e:/Projects/clairdocs/lib/features/analytics/presentation/analytics_dashboard_screen.dart) (`lib/features/analytics/presentation/analytics_dashboard_screen.dart`) displaying KPI metric cards, an interactive `fl_chart` `BarChart` (Top 5 Vendors), and a `PieChart` donut chart (Category Variance Breakdown) with live refresh and empty states.
  - Added `'Analytics & Savings'` navigation triggers right beside `'Audit Vault'` in `TopCommandBar` and inside `AuditVaultDialog`, and added aggregation + chart dashboard tests in `test/widget_test.dart`.
- **Direct Vendor Email & Webhook Dispatch (v1.9)**:
  - Added `mailer: ^6.1.0` in [`pubspec.yaml`](file:///e:/Projects/clairdocs/pubspec.yaml) alongside existing `http: ^1.6.0`, and extended [`PdfExtractionService`](file:///e:/Projects/clairdocs/lib/features/audit/services/pdf_extraction_service.dart), [`AuditResult`](file:///e:/Projects/clairdocs/lib/features/audit/models/audit_models.dart), [`GeminiAuditService`](file:///e:/Projects/clairdocs/lib/features/audit/services/gemini_audit_service.dart), [`GroqAuditService`](file:///e:/Projects/clairdocs/lib/features/audit/services/groq_audit_service.dart), and [`DisputeState`](file:///e:/Projects/clairdocs/lib/features/disputes/models/dispute_models.dart) to extract and pass optional `vendorEmail`.
  - Created [`DisputeDispatchService`](file:///e:/Projects/clairdocs/lib/features/disputes/services/dispute_dispatch_service.dart) (`lib/features/disputes/services/dispute_dispatch_service.dart`) supporting SMTP email dispatch (`dispatchEmail`, attaching `ClairDocs_Dispute_Notice.pdf`) and structured 7-key enterprise JSON webhook dispatch (`dispatchWebhook`).
  - Created [`DispatchNoticeDialog`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispatch_notice_dialog.dart) (`lib/features/disputes/presentation/widgets/dispatch_notice_dialog.dart`) and wired the `'Dispatch Notice'` toolbar action inside [`DisputeStudioModal`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispute_studio_modal.dart), showing `'Dispute Notice Dispatched to Vendor'` upon successful delivery, covered by unit and widget tests in `test/widget_test.dart`.
- **Windows MSIX Packaging (v1.10)**:
  - Added `msix: ^3.16.7` (resolved `3.18.0`) under `dev_dependencies` and configured `msix_config` in [`pubspec.yaml`](file:///e:/Projects/clairdocs/pubspec.yaml) (`display_name: 'ClairDocs Enterprise'`, `publisher_display_name: 'ClairDocs Corporation'`, `identity_name: 'com.clairdocs.desktop'`, `msix_version: '1.0.0.0'`, `logo_path: 'assets/logo.png'`, `protocol_activation: 'clairdocs'`, `capabilities: 'internetClient'`).
  - Created [`scripts/build_msix.ps1`](file:///e:/Projects/clairdocs/scripts/build_msix.ps1) and documented Windows installer build instructions (`flutter pub run msix:create`) in [`README.md`](file:///e:/Projects/clairdocs/README.md).
- **Windows SQLite Native Library Bundling Fix (v1.11)**:
  - Added `sqlite3_flutter_libs: ^0.5.25` (resolved `0.5.42`) in [`pubspec.yaml`](file:///e:/Projects/clairdocs/pubspec.yaml) to compile and bundle `sqlite3.dll` into the Windows runner directory (`build\windows\x64\runner\Debug\sqlite3.dll`).
  - Updated [`AuditDatabaseService`](file:///e:/Projects/clairdocs/lib/features/history/services/audit_database_service.dart) with `ensureInitialized()` (invoked at startup in [`main.dart`](file:///e:/Projects/clairdocs/lib/main.dart) and before opening DBs) calling `applyWorkaroundToOpenSqlite3OnOldAndroidVersions()`, preloading bundled `sqlite3.dll` from the executable directory on Windows, and initializing `sqfliteFfiInit()`.
- **Equal 50/50 Dual-Document Split & Restore Down Responsive Constraints (v1.12)**:
  - Updated [`AuditWorkbenchScreen`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/screens/audit_workbench_screen.dart) so the outer 3-column `Row` and inner dual-document `Row` enforce `mainAxisSize: MainAxisSize.max`, `crossAxisAlignment: CrossAxisAlignment.stretch`, and wrap both [`ContractViewerPanel`](file:///e:/Projects/clairdocs/lib/features/contracts/presentation/widgets/contract_viewer_panel.dart) and [`InvoiceViewerPanel`](file:///e:/Projects/clairdocs/lib/features/invoices/presentation/widgets/invoice_viewer_panel.dart) directly in `Expanded(flex: 1, child: ...)` without fixed `SizedBox` width wrappers.
  - Made inner rows/columns overflow-safe across narrow `"Restore Down"` window states (`1280x720`, `960x640`, `800x560`) in [`contract_viewer_panel.dart`](file:///e:/Projects/clairdocs/lib/features/contracts/presentation/widgets/contract_viewer_panel.dart), [`invoice_viewer_panel.dart`](file:///e:/Projects/clairdocs/lib/features/invoices/presentation/widgets/invoice_viewer_panel.dart), [`pdf_empty_dropzone.dart`](file:///e:/Projects/clairdocs/lib/core/widgets/pdf_empty_dropzone.dart), [`document_pane_header.dart`](file:///e:/Projects/clairdocs/lib/core/widgets/document_pane_header.dart), [`action_studio_panel.dart`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/action_studio_panel.dart), and [`top_command_bar.dart`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/top_command_bar.dart), verified with resize tests in [`test/widget_test.dart`](file:///e:/Projects/clairdocs/test/widget_test.dart).
- **Secure SMTP Credentials Storage (v1.13)**:
  - Extended [`SecureStorageService`](file:///e:/Projects/clairdocs/lib/core/security/secure_storage_service.dart) with `StoredSmtpCredentials`, `saveSmtpCredentials`, `getSmtpCredentials`, and `deleteSmtpCredentials` using `flutter_secure_storage`, wired via `secureStorageServiceProvider` in [`dispute_provider.dart`](file:///e:/Projects/clairdocs/lib/features/disputes/providers/dispute_provider.dart).
  - Updated [`DisputeDispatchService.dispatchEmail`](file:///e:/Projects/clairdocs/lib/features/disputes/services/dispute_dispatch_service.dart) to persist SMTP credentials automatically on successful dispatch when `persistCredentials` is enabled, and added `initState` credential loading + `"Remember SMTP Credentials"` checkbox in [`DispatchNoticeDialog`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispatch_notice_dialog.dart).
- **Top Command Bar Priority, Document Header Parity & SMTP Credential Manager (v1.14)**:
  - Rebalanced flex weights in [`TopCommandBar`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/top_command_bar.dart) (`flex: 2` left, `flex: 3` center status pill, `flex: 4` right controls), removed the clipping horizontal `SingleChildScrollView` around `_buildStatusPill`, and added shared `_buildPillChip` + `TextOverflow.ellipsis` support across all status states so `"N Discrepancies Detected"` renders cleanly without clipping on `1280x720`+ screens.
  - Updated [`DocumentPaneHeader`](file:///e:/Projects/clairdocs/lib/core/widgets/document_pane_header.dart) to use a symmetrical two-tier structure (`minHeight: 72`: fixed `28px` Row 1 + `minHeight: 26px` Row 2), wrapped `'TOTAL DISPUTED VARIANCE'` with `Expanded` + `TextOverflow.ellipsis` in [`kpi_summary_card.dart`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/kpi_summary_card.dart), and gave all 3 panes matching `Expanded(flex: ...)` + `ClipRect` symmetry in [`AuditWorkbenchScreen`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/screens/audit_workbench_screen.dart).
  - Upgraded [`DispatchNoticeDialog`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispatch_notice_dialog.dart) into a full SMTP Credential Manager with eye visibility toggle, copy icon buttons on both username and password fields, explicit **`Save Credentials`** and **`Clear`** buttons backed by `FlutterSecureStorage`, and inline status confirmation banners, covered in [`test/widget_test.dart`](file:///e:/Projects/clairdocs/test/widget_test.dart).
- **Dedicated Settings Credential Store, Header Reordering, Flexible Top Bar & Modal Polish (v1.15)**:
  - Extracted shared modal chrome (`EnterpriseDialogHeader`, `EnterpriseSectionCard`, `EnterpriseFeedbackBanner`, `buildEnterpriseFieldDecoration`) in [`enterprise_dialog_chrome.dart`](file:///e:/Projects/clairdocs/lib/core/widgets/enterprise_dialog_chrome.dart).
  - Created [`SettingsDialog`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/settings_dialog.dart) as a dedicated **"Store Room"** accessible via `TopCommandBar`'s `Settings & Credential Store` (`Icons.settings_outlined`) icon button to save, toggle visibility, copy (`Copy saved password`), and clear encrypted SMTP Host, Port, Username, and Google App Password plus `GEMINI_API_KEY` via `FlutterSecureStorage`.
  - Cleaned up and redesigned [`DispatchNoticeDialog`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispatch_notice_dialog.dart) by removing inline `Save Credentials`, `Clear`, `Remember SMTP Credentials`, and copy buttons so it auto-fills directly from the Store Room, while adding segmented channel tabs, elevated card framing, and clear CTA contrast.
  - Reordered [`DocumentPaneHeader`](file:///e:/Projects/clairdocs/lib/core/widgets/document_pane_header.dart) Row 1 so `Live Doc` / `Demo Sample` mode pills appear on the left and the `Remove file` Close `(X)` button sits on the extreme right (`tapTargetSize: MaterialTapTargetSize.shrinkWrap`), keeping symmetrical height parity.
  - Replaced `TopCommandBar`'s right-side horizontal scroll container in [`top_command_bar.dart`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/top_command_bar.dart) with flexible action buttons (`Flexible` + `TextOverflow.ellipsis` + `Tooltip`) and responsive breadcrumb thresholds, and wrapped `'FLAGGED FINDINGS'` in `Expanded` + `TextOverflow.ellipsis` in [`action_studio_panel.dart`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/action_studio_panel.dart) for zero overflow across `1920x1080`, `1280x720`, `960x640`, and `800x560`, verified in [`test/widget_test.dart`](file:///e:/Projects/clairdocs/test/widget_test.dart).
- **Document Header Revert, Neutral Studio/Preview Card Default State & Credential Vault Polish (v1.16)**:
  - Reverted [`DocumentPaneHeader`](file:///e:/Projects/clairdocs/lib/core/widgets/document_pane_header.dart) Row 1 back to clean uncrowded titles (`Governing Contract` / `Vendor Invoice`) with the `Remove file` Close `(X)` button flush on the far right, moving `Live Doc` / `Demo Sample` mode pills back to Row 2 cleanly.
  - Created shared [`SelectableAuditCard`](file:///e:/Projects/clairdocs/lib/core/widgets/selectable_audit_card.dart) and wired it into [`DiscrepancyItemCard`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/discrepancy_item_card.dart), [`RateComparisonCard`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/rate_comparison_card.dart), [`ContractViewerPanel`](file:///e:/Projects/clairdocs/lib/features/contracts/presentation/widgets/contract_viewer_panel.dart) (Clauses 4.2, 9.1, 12.3), and [`InvoiceViewerPanel`](file:///e:/Projects/clairdocs/lib/features/invoices/presentation/widgets/invoice_viewer_panel.dart) (Lines 01–05) so all cards and text blocks default to neutral non-highlighted surfaces/borders before interaction and highlight only on explicit pointer hover or selection; added toggle-off click behavior in [`ActionStudioPanel`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/action_studio_panel.dart) and neutral unfocused editor framing in [`DisputeStudioModal`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispute_studio_modal.dart).
  - Enhanced [`SettingsDialog`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/settings_dialog.dart) to pre-load both stored SMTP credentials (including Google App Password with eye toggle & copy button) and stored `GEMINI_API_KEY`, keeping [`DispatchNoticeDialog`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispatch_notice_dialog.dart) free of inline save/clear/delete clutter.
- **Top Bar `"Audit Vault"` Anti-Clipping & High-Contrast Modal Typography/Icons (v1.17)**:
  - Updated [`TopCommandBar`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/top_command_bar.dart) using responsive outer `LayoutBuilder` flex allocation (`3:4:9` at `>= 1220px`, `2:3:9` below) and an inner `LayoutBuilder` on the action cluster (`isCompactBar < 680px`) driven by shared `_TopBarActionSpec` metadata so `'Audit Vault'`, `'Analytics & Savings'`, `'Upload Contract'`, `'Upload Invoice'`, and `'Run AI Audit'` render completely untruncated at desktop widths (`1920x1080`, `1280x720`) while keeping `'Audit Vault'` unclipped down to `800x560`; upgraded the `Settings & Credential Store` icon button to crisp `Colors.white`.
  - Upgraded modal subtitles, close (`X`) icons, section headers, input text styles, labels, prefix/suffix eye toggle icons, hints, status pills, tab buttons, footer metadata, and secondary action buttons across [`EnterpriseDialogHeader` / `EnterpriseSectionCard` / `buildEnterpriseFieldDecoration`](file:///e:/Projects/clairdocs/lib/core/widgets/enterprise_dialog_chrome.dart), [`DispatchNoticeDialog`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispatch_notice_dialog.dart), [`SettingsDialog`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/settings_dialog.dart), and [`DisputeStudioModal`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispute_studio_modal.dart) from muted secondary greys to high-contrast `Colors.white` / `AppColors.textPrimary`.
- **Top Command Bar Upload Button Removal, Full Breadcrumb Trail & Unclipped Engine Label (v1.18)**:
  - Removed the redundant `'Upload Contract'` and `'Upload Invoice'` buttons from [`TopCommandBar`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/top_command_bar.dart) (`lib/features/audit/presentation/widgets/top_command_bar.dart`), dedicating the freed horizontal width to the unified breadcrumb-to-status trail (`ClairDocs > [Contract Filename] > [Invoice Filename / No Invoice] > [Discrepancy Status]`) and full engine pill alongside `[Settings] [Audit Vault] [Analytics & Savings] [Run AI Audit]`.
  - Removed the `< 255px` invoice-filename hiding threshold and `TextOverflow.ellipsis` / `Flexible(flex: 1)` squishing on `engineBadge` so both document names (`No Invoice` fallback included) and full engine labels (e.g., `'Engine: GPT-OSS 20B (Groq)'`, `'Gemini 3.8'`) display clearly without `"Engine: G..."` truncation.
  - Updated [`widget_test.dart`](file:///e:/Projects/clairdocs/test/widget_test.dart) assertions for removed upload buttons, `'No Invoice'` breadcrumb visibility, and unclipped `'Engine: GPT-OSS 20B (Groq)'` display.
- **Interactive Manage in Settings Link, Standardized Breadcrumbs & Modal Contrast Polish (v1.19)**:
  - Wired the Store Room header pill (`'Manage in Settings'` / `'Auto-filled from Store Room'`) inside [`DispatchNoticeDialog`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispatch_notice_dialog.dart) (`lib/features/disputes/presentation/widgets/dispatch_notice_dialog.dart`) so clicking it overlays [`SettingsDialog`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/settings_dialog.dart) and reloads Store Room SMTP credentials on return while preserving the open dispatch draft.
  - Standardized the Contract and Invoice breadcrumb segments in [`TopCommandBar`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/top_command_bar.dart) so both states (`ClairDocs > No Contract > No Invoice > Awaiting Documents` and `ClairDocs > [Contract Filename] > [Invoice Filename] > [Status]`) share uniform typography (`fontSize: 11.5`, `height: 1.25`), weight, and contrast, with crisp `Colors.white` text on the `'Awaiting Documents'` status pill.
  - Introduced `enterpriseModalBorderColor` (`0xFF475569`) in [`enterprise_dialog_chrome.dart`](file:///e:/Projects/clairdocs/lib/core/widgets/enterprise_dialog_chrome.dart) and applied it consistently across modal frames, input borders, section cards, and button outlines in [`DispatchNoticeDialog`](file:///e:/Projects/clairdocs/lib/features/disputes/presentation/widgets/dispatch_notice_dialog.dart) and [`SettingsDialog`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/settings_dialog.dart).
  - Expanded [`widget_test.dart`](file:///e:/Projects/clairdocs/test/widget_test.dart) to verify standardized breadcrumb styling, crisp modal input border contrast, and end-to-end `'Manage in Settings'` -> `SettingsDialog` save -> live credential reload into `DispatchNoticeDialog`.
- **Restored Accent Blue Active Breadcrumb Filename Styling (v1.20)**:
  - Updated `_buildBreadcrumbFileSegment` in [`TopCommandBar`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/top_command_bar.dart) (`lib/features/audit/presentation/widgets/top_command_bar.dart`) so loaded/uploaded Contract and Invoice filenames display in vibrant accent blue (`AppColors.sky`) at proportional `12.5px` (`FontWeight.w600`), while unuploaded `'No Contract'` and `'No Invoice'` placeholders remain in standard neutral styling (`12.0px`, `FontWeight.w500`, `AppColors.textPrimary.withValues(alpha: 0.78)`), covered by [`widget_test.dart`](file:///e:/Projects/clairdocs/test/widget_test.dart).
- **Status-Badge Matched Breadcrumbs & Clean CSV / Spreadsheet Preview Body (v1.21)**:
  - Extracted shared `_badgeBaseTextStyle` (`AppTypography.fontFamilySans`, `fontSize: 11`, `FontWeight.w600`, default line height) in [`TopCommandBar`](file:///e:/Projects/clairdocs/lib/features/audit/presentation/widgets/top_command_bar.dart) so loaded breadcrumb filenames match the exact typography, height, and boldness of status pills (`'1 Discrepancy Detected'`) in `AppColors.sky` while placeholders remain neutral (`FontWeight.w500`).
  - Removed the redundant header block (`'SPREADSHEET CSV'` / `'WORD DOCX'` badge, duplicate `fileName`, `formattedSize`, and divider) plus unused constructor params from [`WordDocumentPreview`](file:///e:/Projects/clairdocs/lib/core/widgets/word_document_preview.dart) (and its callers [`ContractViewerPanel`](file:///e:/Projects/clairdocs/lib/features/contracts/presentation/widgets/contract_viewer_panel.dart) / [`InvoiceViewerPanel`](file:///e:/Projects/clairdocs/lib/features/invoices/presentation/widgets/invoice_viewer_panel.dart)) so spreadsheets and Word documents render sleekly beneath [`DocumentPaneHeader`](file:///e:/Projects/clairdocs/lib/core/widgets/document_pane_header.dart) just like PDFs, covered in [`widget_test.dart`](file:///e:/Projects/clairdocs/test/widget_test.dart).




