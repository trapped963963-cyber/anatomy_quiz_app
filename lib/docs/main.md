# Documentation: main.dart

## Overview
This file serves as the primary entry point for the entire Flutter application. It is responsible for initializing the app, setting up core services and themes, and defining the root `MyApp` widget.

## Key Responsibilities

* **App Initialization:** It contains the `main()` function, which is the first code to execute. It ensures that the Flutter framework is properly initialized before running the app.
* **State Management Scope:** It wraps the entire application in a `ProviderScope`, which makes the Riverpod state management system available to all widgets.
* **Responsive UI Setup:** It initializes the `flutter_screenutil` package, setting the design baseline size to ensure the UI scales correctly across different devices.
* **Global Theming:** It defines the global `ThemeData` for the application. This includes the color scheme, typography (using Google Fonts), default button styles, and the overall look and feel.
* **Localization & RTL:** It configures the `MaterialApp` to be exclusively in Arabic (`ar`) and forces a Right-to-Left (`RTL`) layout globally using the `Directionality` widget.
* **Navigation:** It connects the app to the navigation system by passing the `routerConfig` from our `AppRouter`.

## Dependencies

* **`app_router.dart`:** Provides the navigation routes for the app.
* **`app_colors.dart`:** Provides the custom color palette for the theme.
* **`app_strings.dart`:** Provides the centralized text for UI elements like the app's title.
* **Packages:** `flutter_riverpod`, `flutter_screenutil`, `go_router`, `google_fonts`.