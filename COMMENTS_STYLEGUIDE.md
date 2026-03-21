# FlatBag Code Commenting Styleguide

This document outlines the standard practices for writing comments and documenting code in the FlatBag project. Following these guidelines ensures our codebase remains clean, readable, and easy for new contributors to understand.

## 1. Centralize Workflow Documentation (Avoid Distributed Numbering)
Do not scatter numbered steps (e.g., `// 1. Do this`, `// 2. Do that`) across dozens of lines inside a function. If a function contains a complex sequence of operations, document the **entire flow** at the beginning of the function or block. Use brief, unnumbered action comments inline to mark where those steps occur.

**Don't do this:**
```dart
void processMigration() {
  // 1. Fetch the old app data
  final oldData = getOldData();
  // ... 20 lines of code ...
  
  // 2. Transform to new format
  final newData = transform(oldData);
  // ... 20 lines of code ...
}
```

**Do this:**
```dart
/// Executes the migration process.
/// Flow:
/// 1. Fetch the old app data from the cache.
/// 2. Transform the payload to the new V2 format.
/// 3. Save the new payload and delete the legacy cache.
void processMigration() {
  // Fetch legacy data
  final oldData = getOldData();
  // ... 20 lines of code ...
  
  // Transform to V2 format
  final newData = transform(oldData);
  // ... 20 lines of code ...
}
```

## 2. Explain the "Why", Not the "What"
Assume the reader understands Dart and Flutter. The code itself explains *what* is happening; the comment should explain *why* it is happening or document non-obvious business logic and edge cases.

**Don't do this:** (Redundant)
```dart
// Check if count is greater than 0
if (count > 0) {
  // Loop through items
  for (var item in items) { ... }
}
```

**Do this:** (Adds context)
```dart
// Proceed only if the user has active downloads queued to avoid empty background isolates.
if (count > 0) {
  for (var item in items) { ... }
}
```

## 3. Use `///` for Public APIs and `//` for Implementation Details
In Dart, triple slashes (`///`) generate documentation tooltips in IDEs. Use them exclusively above class declarations, public methods, and properties. Use double slashes (`//`) for internal implementation details inside the method body.

## 4. Standardize Section Dividers
When a single file is large, use a consistent visual divider to group related methods, properties, or overrides. A simple, clean line is preferred over large ASCII boxes:

```dart
  // --- State Variables ---
  bool isLoading = true;
```

## 5. Format `TODO` and `FIXME` Tags Consistently
Always use the capitalized `TODO` or `FIXME` keyword so IDE parsers can aggregate them. Include brief context or an issue tracker reference if applicable. Example: `// TODO: Add fallback for offline mode.`

## 6. No Comment Graveyards (Delete Dead Code)
Do not leave large blocks of commented-out code. Version control remembers the history. Dead code creates visual noise and confuses readers.

## 7. Update Comments Alongside Code
A stale, incorrect comment is significantly worse than no comment at all. Whenever you alter the behavior of a function, you **must** review the comments associated with it and update them to reflect the new reality.