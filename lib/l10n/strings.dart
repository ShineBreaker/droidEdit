import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'zh.dart';

/// The languages the UI ships with (English is the source: every string is
/// written in English and translated through [tr]).
const supportedLocales = [ui.Locale('en'), ui.Locale('zh')];

/// The app's chosen UI locale; null = follow the system. Kept outside
/// MaterialApp so strings can be resolved without a BuildContext (toasts,
/// undo labels) — the app rebuilds itself when it changes.
final ValueNotifier<ui.Locale?> appLocale = ValueNotifier(null);

/// Applies a saved `UiSettings.language` ('system', 'en', 'zh').
void applyUiLanguage(String language) => appLocale.value = switch (language) {
      'zh' => const ui.Locale('zh'),
      'en' => const ui.Locale('en'),
      _ => null,
    };

/// Whether Chinese strings are served.
bool get _zh =>
    (appLocale.value ?? ui.PlatformDispatcher.instance.locale).languageCode == 'zh';

/// [en] in the active UI language. `{name}` placeholders in it (and its
/// translation) are filled from [args] afterwards, so they can sit anywhere
/// in either language's sentence.
///
/// The English text is the lookup key: a missing translation shows it.
String tr(String en, [Map<String, Object?>? args]) {
  var s = _zh ? (zhStrings[en] ?? en) : en;
  if (args != null) {
    for (final e in args.entries) {
      s = s.replaceAll('{${e.key}}', '${e.value}');
    }
  }
  return s;
}

/// A stored English undo/redo label for display. History keeps labels in
/// English (commands compare on them); this translates them when shown:
/// map entries first, then "Change X" labels built from setting names.
String trLabel(String label) {
  final direct = tr(label);
  if (direct != label) return direct;
  const change = 'Change ';
  if (label.startsWith(change)) {
    return tr('Change {name}', {'name': tr(label.substring(change.length))});
  }
  return label;
}
