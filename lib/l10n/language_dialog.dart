import 'package:flutter/material.dart';

import '../app_dialog.dart';
import '../platform/app_settings.dart';
import 'strings.dart';

/// "Language…": system default, English or 中文. Applied right away and
/// saved (the editor menus and toasts follow the new language on the next
/// rebuild / message).
Future<void> pickUiLanguage(BuildContext context) async {
  var language = 'system';
  SettingsStore? store;
  try {
    store = await SettingsStore.open();
    language = store.ui.language;
  } catch (_) {}
  if (!context.mounted) return;
  final picked = await showDialog<String>(
    context: context,
    builder: (ctx) => AppDialog(
      title: Text(tr('Language')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label) in [
            ('system', tr('System default')),
            ('en', 'English'),
            ('zh', '中文'),
          ])
            ListTile(
              dense: true,
              leading: Icon(
                language == value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: language == value ? Theme.of(ctx).colorScheme.primary : null,
              ),
              title: Text(label),
              onTap: () => Navigator.pop(ctx, value),
            ),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel')))],
    ),
  );
  if (picked == null) return;
  applyUiLanguage(picked);
  if (store != null) {
    store.ui.language = picked;
    await store.save();
  }
}
