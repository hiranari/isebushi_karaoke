---
applyTo: '**/presentation/**/*.dart'
description: 'UI implementation guidelines for Flutter widgets and screens'
---

# UI Implementation Guidelines

## Screen Navigation Patterns

### Standard Navigation Pattern
```dart
// ✅ Recommended Pattern
Navigator.pushNamed(context, '/karaoke', arguments: song);
```

### Back Navigation Control
```dart
// ✅ Recommended Pattern
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    // Process here
  },
  child: Scaffold(/* ... */),
)
```

## UI Component Templates

### Dialog Template
```dart
// ✅ Standard Confirmation Dialog
AlertDialog(
  title: const Text('確認'),
  content: const Text('実行してもよろしいですか？'),
  actions: [
    TextButton(
      onPressed: () => Navigator.of(context).pop(false),
      child: const Text('キャンセル'),
    ),
    ElevatedButton(
      onPressed: () => Navigator.of(context).pop(true),
      child: const Text('OK'),
    ),
  ],
)
```

### Screen Layout Template
```dart
// ✅ Standard Screen Layout
Scaffold(
  appBar: AppBar(title: const Text('画面タイトル')),
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Content
        ],
      ),
    ),
  ),
)
```

## Error Handling Patterns

### Loading State
```dart
// ✅ Standard Loading Display
if (isLoading) {
  return const Center(child: CircularProgressIndicator());
}
```

### Error State
```dart
// ✅ Standard Error Display
if (hasError) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(errorMessage),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('再試行'),
        ),
      ],
    ),
  );
}
```

## Animation Patterns

### Screen Transition Animation
```dart
// ✅ Custom Transition Animation
PageRouteBuilder(
  pageBuilder: (context, animation, secondaryAnimation) => const NextPage(),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  },
)
```

### UI Element Animation
```dart
// ✅ Standard Animation
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  // Properties
)
```
