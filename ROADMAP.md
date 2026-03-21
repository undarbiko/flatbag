# FlatBag Roadmap

This document outlines the planned features and architectural improvements for FlatBag. It is a living document and subject to change based on community feedback and project needs.

## Core Features

- [ ] **Multi-Architecture Support:** Implement support for other architectures (e.g., `aarch64`, `ARM`) in addition to the currently supported `x86_64` flavor. This will involve dynamically checking the host architecture and fetching the appropriate AppStream data.
- [ ] **Sandbox Permissions Editor:** Build a visual editor (similar to Flatseal) allowing users to easily toggle and manage sandbox permissions (Network, Filesystem, Devices, Sockets) for installed applications directly from the details view.
- [ ] **Advanced Theming Engine:** Expand the current theming capabilities to support more advanced options, such as fully custom user-defined color palettes, distinct font choices, and contrast accessibility modes.

## Repository & Data Management

- [ ] **Remote Management:** Add a UI to view, add, and remove Flatpak remotes (e.g., adding `flathub-beta` or enterprise-specific repositories).
- [ ] **Backup & Restore:** Introduce a tool to export a list of currently installed applications (and optionally their local `~/.var/app/` user data) to easily migrate setups between different Linux machines.
- [ ] **Offline Mode:** Implement robust fallback mechanisms so the application can gracefully degrade and still manage installed apps when no internet connection is available or Flathub is unreachable.

## System Integration

- [ ] **System Tray & Notifications:** Create a system tray icon that runs in the background, periodically checks for Flatpak updates, and issues native desktop notifications when updates are available.
- [ ] **Localization (i18n):** Add support for multiple languages by extracting hardcoded English strings into localization bundles, making FlatBag accessible to a global audience.

## Codebase & Architecture

- [ ] **Feature-First Architecture Restructuring:** Migrate the current folder structure (`screens`, `models`, `state`) into a feature-based architecture (e.g., `features/installed_apps`, `features/remote_apps`) to better support horizontal scaling.
- [ ] **Automated Testing:** Increase unit and widget test coverage, specifically targeting the `HomeState` and `FlatpakService` layers using mock data.