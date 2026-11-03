import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../platform/app_updater.dart';
import '../platform/web_links.dart';
import '../toast.dart';
import '../app_dialog.dart';

/// Looks for a newer release and offers it. [manual] (the menu item) also
/// says "up to date" / "couldn't check"; the automatic check on start stays
/// silent unless there is something to install.
Future<void> checkForUpdates(BuildContext context, {bool manual = false}) async {
  final UpdateInfo? info;
  try {
    info = await AppUpdater.check(manual: manual);
  } catch (_) {
    if (manual) AppToast.show(tr('Could not check for updates'));
    return;
  }
  if (!context.mounted) return;
  if (info == null) {
    if (manual) {
      final v = await AppUpdater.currentVersion();
      AppToast.show(AppUpdater.isDevVersion(v)
          ? tr('Development build: updates come from the computer, not from releases')
          : tr("You're up to date{v}", {'v': v == null ? '' : ' (v$v)'}));
    }
    return;
  }
  await showDialog<void>(context: context, builder: (_) => _UpdateDialog(info!));
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateDialog(this.info);

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  /// Null: asking; 0..1: downloading.
  double? _progress;
  String? _error;

  Future<void> _update() async {
    final info = widget.info;
    final navigator = Navigator.of(context);
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      final apk = await AppUpdater.download(info, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      final r = await AppUpdater.install(apk);
      if (!mounted) return;
      switch (r) {
        case InstallResult.started:
          navigator.pop();
        case InstallResult.needsPermission:
          navigator.pop();
          AppToast.show(
            tr('Allow installs from osuEdit in the settings that just opened, then check for updates again.'),
            duration: const Duration(seconds: 8),
          );
        case InstallResult.failed:
          setState(() {
            _progress = null;
            _error = tr('Could not start the installer.');
          });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progress = null;
        _error = e is HttpException ? e.message : tr('Download failed: {e}', {'e': e});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final downloading = _progress != null;
    return PopScope(
      canPop: !downloading,
      child: AppDialog(
        title: Text(tr('Update available: v{v}', {'v': info.version})),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (downloading) ...[
              Text(tr('Downloading… {p}%', {'p': (_progress! * 100).round()})),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            ] else ...[
              if (info.notes.isNotEmpty)
                Flexible(child: SingleChildScrollView(child: Text(info.notes, style: const TextStyle(fontSize: 13))))
              else
                Text(tr('A new version of osuEdit is available.')),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ]),
        ),
        actions: downloading
            ? const []
            : [
                TextButton(
                  onPressed: () {
                    AppUpdater.skip(info.version);
                    Navigator.pop(context);
                  },
                  child: Text(tr('Skip this version')),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Later'))),
                if (AppUpdater.supported)
                  FilledButton(onPressed: _update, child: Text(tr('Update')))
                else
                  FilledButton(
                    onPressed: () {
                      WebLinks.open(info.pageUrl);
                      Navigator.pop(context);
                    },
                    child: Text(tr('Open release page')),
                  ),
              ],
      ),
    );
  }
}
