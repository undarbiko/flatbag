# FlatBag Code Style Guide

This document outlines the standard coding practices, architecture choices, and conventions used in the FlatBag project. Adhering to these guidelines ensures our codebase remains maintainable, testable, and easy to navigate.

## 1. Data Models: Named Parameters & Immutability
When constructing data models, prefer named parameters and immutability.
* **Use Named Parameters:** For constructors with more than two properties, always use named parameters with the `required` keyword to prevent silent ordering bugs.
* **Immutability:** Data classes should be immutable. If a model needs to be updated, provide a `copyWith()` method to generate a new instance with the altered fields.
* *Future Consideration:* As models grow, consider using code-generation packages like `freezed` or `equatable` to reduce boilerplate.

## 2. UI Widgets: Classes vs. Helper Methods
Flutter's rendering engine is highly optimized for `const` Widget classes. 
* **Avoid Helper Methods:** Do not use helper methods that return complex UI components (e.g., `Widget _buildActionButton(...)`). Every time the parent rebuilds, these methods re-execute completely.
* **Extract to StatelessWidgets:** Extract reusable or complex sub-components into their own private or public `StatelessWidget` classes. This allows Flutter to cache them and selectively rebuild them, keeping the main `build` method clean.
* **Shared Components:** If a widget (like an action button) is duplicated across multiple views, extract it into a shared file in a `components/` directory.

## 3. Business Logic: Services over Global Functions
Avoid placing complex business logic or system interactions in top-level global functions.
* **Use Service Classes:** Wrap system calls (like executing `flatpak` commands) or network requests inside Service classes (e.g., `FlatpakService` or `FlathubService`).
* **Why?** Passing services as dependencies makes testing significantly easier. You can inject a `MockFlatpakService` during automated tests to avoid executing real system commands on the host machine.

## 4. File Structure & Splitting
Keeping files focused and reasonably sized is critical for a healthy project.
* **File Size Rule of Thumb:** If a single file exceeds 300-400 lines, it is likely doing too much. Break it down.
* **Split Distinct Layouts:** If a view file contains multiple complex layouts (e.g., list view, grid view, icon view), split those layouts into separate files (e.g., `layouts/list_layout.dart`).
* **Feature-First Architecture (Future Goal):** Group files by feature rather than type. Instead of having global `models/`, `screens/`, and `state/` folders, group related files together:
  ```
  features/
    installed_apps/
      models/
      views/
      controllers/
    system_updates/
      ...
  ```

## 5. Theming & UI Constants
Avoid hardcoding aesthetic values directly into UI components.
* **Colors:** Do not use hardcoded hex codes (e.g., `Color(0xFF7AE190)`) in your widgets. Always use `Theme.of(context).colorScheme`.
* **Custom Semantic Colors:** If you need specific semantic colors (like "success green" or "warning orange") that don't fit in the default Material palette, define them as a `ThemeExtension` in your application theme setup.
* **Spacing & Sizes:** Rely on consistent padding and margin constants rather than arbitrary numeric values scattered throughout the code.

## 6. Managing Application State
* **Centralize Logic:** Keep UI components dumb. All heavy filtering, sorting, and state mutation should happen inside state controllers (like `HomeState`).
* **Targeted Rebuilds:** When using `ChangeNotifier` and `notifyListeners()`, ensure that you aren't forcing the entire application to rebuild unnecessarily. Use specific sub-states or targeted `ListenableBuilder` / `ValueListenableBuilder` widgets where appropriate.