# Implementation Tasks & Roadmap — ClairDocs

**Document Version:** 1.0.0  
**Current Status:** Phase 5 Complete / Phase 6 Polish Pending  
**Tracking Model:** Checkable Markdown Checklist (`- [ ]` pending, `- [/]` in-progress, `- [x]` completed)  

---

## Progress Overview

| Phase | Milestone Name | Status | Items Completed | Total Items |
| :--- | :--- | :--- | :--- | :--- |
| **Phase 1** | Dependencies & Core Architecture Setup | Complete | 7 | 7 |
| **Phase 2** | Design System, Viewport & PDF Viewers | In Progress | 6 | 7 |
| **Phase 3** | Gemini Service & Structured Schema Audit | Complete | 7 | 7 |
| **Phase 4** | Audit Diff Engine & Mathematical Variance | In Progress | 3 | 6 |
| **Phase 5** | Dispute Notice Generation & Multi-Format Export | Complete | 6 | 6 |
| **Phase 6** | Enterprise Polish, Themes & Verification | Pending | 0 | 6 |
| **Total** | | **74% Complete** | **29** | **39** |

---

## Phase 1: Dependency Injection & Core Architecture Setup
**Objective:** Establish core dependencies, lint rules, folder structure, design tokens, error models, and secure storage foundations.

- [x] **1.1 Configure `pubspec.yaml` with Required Packages**
  - Add `google_generative_ai` (Gemini SDK).
  - Add `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`.
  - Add `syncfusion_flutter_pdfviewer`.
  - Add `freezed`, `freezed_annotation`, `json_annotation`, `json_serializable`.
  - Add `flutter_secure_storage` (credential vault).
  - Add `file_picker` (desktop document selection).
  - Add `crypto` (SHA-256 file hashing).
  - Add `intl` and `decimal` (deterministic currency and fixed-point math).
  - Add `pdf` and `printing` (dispute letter PDF generation).
  - Add dev dependencies: `build_runner`, `flutter_lints`.
- [x] **1.2 Directory Structure Scaffolding**
  - Create feature folders: `lib/core/`, `lib/features/contracts/`, `lib/features/invoices/`, `lib/features/audit/`, `lib/features/disputes/`, `lib/features/settings/`.
- [x] **1.3 Design Token Implementation**
  - Implement `lib/core/theme/app_colors.dart` (Enterprise dark & light palettes, status colors).
  - Implement `lib/core/theme/app_typography.dart` (Inter and JetBrains Mono monospace styles).
  - Implement `lib/core/theme/app_spacing.dart` (4px grid system tokens, radii, elevation).
  - Implement `lib/core/theme/app_theme.dart` (ThemeData factories for Light and Dark modes).
- [x] **1.4 Centralized Strings & Constants**
  - Implement `lib/core/constants/app_strings.dart` (All button labels, tooltips, dialog text).
  - Implement `lib/core/constants/api_constants.dart` (Model names, timeouts, default thresholds).
  - Implement `lib/core/constants/legal_templates.dart` (Dispute letter boilerplate contracts).
- [x] **1.5 Security & Platform Credential Storage**
  - Implement `lib/core/security/secure_storage_service.dart` wrapping `flutter_secure_storage`.
  - Implement `SecureKeyRepository` to securely persist, retrieve, and delete Google AI Studio API keys.
- [x] **1.6 Error Handling & Failure Taxonomy**
  - Create typed domain failures in `lib/core/errors/failures.dart` (`ApiKeyMissingFailure`, `GeminiApiFailure`, `DocumentParseFailure`, `MalformedPayloadFailure`).
  - Create custom exceptions in `lib/core/errors/exceptions.dart`.
- [x] **1.7 Desktop Window Configuration**
  - Configure desktop window minimum size (1280x720) and initial title bar in `lib/main.dart`.
  - Wrap app in `ProviderScope`.

---

## Phase 2: Design System, Dual Split-Screen Viewport & PDF Viewers
**Objective:** Build the 3-column desktop layout with high-density enterprise theme, document toolbars, action studio, and PDF viewing.

- [x] **2.1 Enterprise Design Tokens & Dark Theme Setup**
  - Implement enterprise dark palette (`0xFF0B0F19` background, `0xFF111827` surface, `0xFF1E293B` hover, `0xFF1F2937` borders).
  - Configure typography scale with compact sizing and JetBrains Mono financial tokens.
  - Implement status accents: Emerald `0xFF10B981`, Crimson `0xFFEF4444`, Amber `0xFFF59E0B`, Sky `0xFF38BDF8`.
- [x] **2.2 Top Command Bar Widget**
  - Build `TopCommandBar` with brand logo badge, interactive breadcrumb path, discrepancy counter pill, and action buttons.
- [x] **2.3 3-Column Desktop Viewport & Canvas Layout**
  - Build `AuditWorkbenchScreen` with 40% Contract Viewer, 35% Invoice Viewer, and 25% Action Studio panel.
  - Add enterprise desktop bottom status bar (AI Engine, Sync Scroll, SHA-256 fingerprint, app version).
- [x] **2.4 Discrepancy & Action Studio Components**
  - Build `KpiSummaryCard` (Total Disputed Variance `+$4,850.00`, Billed vs Base amount).
  - Build `RateComparisonCard` (Contract Cap `$185.00/hr` vs Invoiced `$210.00/hr`, breach delta badge).
  - Build `DiscrepancyItemCard` (severity badge, clause citation, line reference, variance impact).
  - Build `ActionStudioPanel` with scrollable findings list and bottom "Draft Dispute Notice" CTA dialog.
- [x] **2.5 Document Ingestion & File Picker Service**
  - Implement file picking via `file_picker` for PDF contracts and invoices.
  - Compute SHA-256 hash using `lib/core/utils/file_hasher.dart` upon file selection.
- [x] **2.6 Live Syncfusion PDF Viewer Integration**
  - Bind `syncfusion_flutter_pdfviewer` to `ContractViewerPanel` and `InvoiceViewerPanel`.
  - Wire page navigation, zoom in/out/fit, and in-document keyword search.
- [ ] **2.7 Synchronized Scrolling & Bounding Box Highlighting**
  - Add sync scroll controller between contract and invoice panes.
  - Render highlight overlays corresponding to cited clauses and line items.

---

## Phase 3: Gemini Service Integration & Structured Schema Audit
**Objective:** Connect the application to Google AI Studio Gemini API with strict JSON schema definitions for contract vs invoice audit.

- [x] **3.1 Google Generative AI Client Configuration**
  - Implement `GeminiAuditService` supporting `--dart-define=GEMINI_API_KEY`, `.env`, and `SecureStorageService` via `ApiKeyDialog`.
  - Configure `gemini-3.8-flash` (with `gemini-3.5-flash-lite` fallback).
- [x] **3.2 Structured Output Schema Definition**
  - Define `_auditResultSchema` in `lib/features/audit/services/gemini_audit_service.dart` using `Schema.object`.
  - Enforce required properties: `currency`, `totalVarianceAmount`, `invoicedTotal`, `verifiedContractBase`, `variancePercentage`, `findings`.
- [x] **3.3 Freezed Audit Domain Models**
  - Create `AuditResult` and `AuditFinding` in `lib/features/audit/models/audit_models.dart`.
  - Generate serialization logic with `build_runner`.
- [x] **3.4 Audit Repository / Service Implementation**
  - Build `GeminiAuditService.auditDocuments` passing inline PDF `DataPart('application/pdf', bytes)` with enterprise auditor system instructions.
- [x] **3.5 JSON Sanitization & Recovery Engine**
  - Integrate `JsonSanitizer.decodeSafe` to sanitize and parse responses safely into `AuditResult`.
- [x] **3.6 Network Resiliency & Exponential Backoff**
  - Integrate `RetryPolicy` with exponential backoff and jitter on Gemini API calls.
- [x] **3.7 Audit Riverpod Controller**
  - Implement `auditProvider` (`AsyncNotifier<AuditResult?>`) orchestrating document validation, Demo Sample mode execution, and Gemini execution.

---

## Phase 4: Audit Diff Engine & Mathematical Variance Calculation
**Objective:** Perform zero-hallucination deterministic calculations, discrepancy classification, and reactive UI card rendering.

- [ ] **4.1 Deterministic Variance Calculation Engine**
  - Implement `VarianceCalculator` using `Decimal` arithmetic.
  - Verify line total math (`Quantity * Agreed Rate = Expected Total`).
  - Calculate exact dollar delta (`Invoiced Total - Expected Total`) and percentage variance.
  - Compute aggregate figures: Total Invoiced, Total Contract Approved, Total Disputed Variance.
- [x] **4.2 Severity Categorization System**
  - Map finding severities (`high`, `medium`, `low`) and categories (`rate_breach`, `unapproved_expense`, `hour_cap_exceeded`, `term_mismatch`) to color-coded badges.
- [x] **4.3 Audit Discrepancy Panel UI**
  - Bind `ActionStudioPanel` and `TopCommandBar` dynamically to `auditProvider` with `AuditSkeletonLoader`, empty/idle states, and actionable error states.
- [x] **4.4 Discrepancy Card & Diff Chips**
  - Bind `KpiSummaryCard`, `RateComparisonCard`, and `DiscrepancyItemCard.fromFinding` directly to `AuditResult` and `AuditFinding`.
- [ ] **4.5 Bidirectional Document Jump Links**
  - Wire `[Jump to Clause]` button to jump `ContractPdfViewer` to cited page.
  - Wire `[Jump to Line]` button to jump `InvoicePdfViewer` to cited page.
- [ ] **4.6 User Discrepancy Override & Acceptance Actions**
  - Allow auditor to mark individual discrepancies as `Dispute` or `Waive / Approve Exception`.

---

## Phase 5: Dispute Notice Generation & Multi-Format Export
**Objective:** Transform detected variances into formal, legally structured dispute letters with multi-format export capabilities.

- [x] **5.1 Dispute Notice Generation Service**
  - Implement `DisputeGeneratorService` using `gemini-3.8-flash` with tailored tone prompts (`Firm Legal`, `Collaborative Partner`, `Strict Breach`) and deterministic offline fallback generator.
  - Embed itemized Discrepancy Schedule table with citations, invoice numbers, approved payment release, and 14-business-day deadline.
- [x] **5.2 Dispute Domain Models**
  - Create Freezed `DisputeState`, `DisputeTone`, and `DisputeGenerationStatus` models in `lib/features/disputes/models/dispute_models.dart`.
- [x] **5.3 Dispute Notice Draft Modal UI**
  - Build `DisputeStudioModal` displaying header metadata (vendor, invoice, withheld badge), tone selector pills, and dark-fintech monospaced editable `TextField`.
- [x] **5.4 Formal PDF Letter Generator**
  - Implement `DisputePdfExporter` using `pdf` package to compile corporate header, multi-page financial discrepancy breakdown table (`TableHelper.fromTextArray`), letter body, and Procurement/AP signature blocks.
  - Trigger native OS Save File dialog via `FilePicker.saveFile`.
- [x] **5.5 Clipboard & Export Actions**
  - Implement one-click copy to system clipboard with confirmation snackbar and native PDF save export.
- [x] **5.6 Dispute Riverpod Controller**
  - Implement `disputeProvider` (`Notifier<DisputeState>`) managing draft generation, tone regeneration, text editing, and PDF export state, wired to "Draft Dispute Notice" in `ActionStudioPanel`.

---

## Phase 6: Polish, Theme Adjustments & Verification
**Objective:** Complete comprehensive styling, keyboard shortcuts, offline caching, and end-to-end integration testing.

- [ ] **6.1 Settings & API Key Configuration Dialog**
  - Build settings dialog allowing users to enter, test, and save their Google AI Studio API key.
  - Add model switcher (`Gemini 3.8 Flash` vs `Gemini 3.5 Flash Lite`).
- [ ] **6.2 Theme Switching (Dark & Light Mode)**
  - Implement dynamic theme toggle supporting Dark, Light, and System modes.
  - Ensure high-contrast legibility across all panels in both modes.
- [ ] **6.3 Desktop Keyboard Shortcuts**
  - Add shortcuts: `Ctrl+O` / `Cmd+O` (Open files), `Ctrl+R` / `Cmd+R` (Run audit), `Ctrl+D` / `Cmd+D` (Generate dispute), `Ctrl+B` / `Cmd+B` (Toggle audit drawer).
- [ ] **6.4 Local Session Caching & Offline Fallback**
  - Cache loaded documents and completed audit reports in local app support directory.
  - Allow offline viewing and dispute re-export of past audits.
- [ ] **6.5 Static Analysis & Lint Enforcement**
  - Run `flutter analyze` and resolve all warnings.
  - Run `dart format .` across all created source files.
- [ ] **6.6 End-to-End Verification with Sample PDF Pair**
  - Verify complete workflow: Load contract + invoice -> Run audit -> Inspect variances -> Jump to pages -> Generate dispute letter -> Export PDF.
