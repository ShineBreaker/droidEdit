import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_fonts.dart';
import 'home/home_screen.dart';
import 'l10n/strings.dart';
import 'platform/app_settings.dart';
import 'platform/frame_stats.dart';
import 'toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The editor is landscape-only and uses the whole screen: system bars
  // stay hidden and only reappear transiently on an edge swipe.
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  FrameStats.install();
  // The saved UI language before the first frame (unreadable settings =
  // follow the system).
  try {
    applyUiLanguage((await SettingsStore.open()).ui.language);
  } catch (_) {}
  runApp(const OsuEditApp());
}

class OsuEditApp extends StatelessWidget {
  /// The start screen (desktop integration tests inject one with a temp library).
  final Widget home;

  const OsuEditApp({super.key, this.home = const HomeScreen()});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (context, locale, _) => MaterialApp(
        title: 'osu!Edit',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: const Color(0xFFFF66AA),
          useMaterial3: true,
          fontFamily: kUiFont,
        ),
        theme: ThemeData(colorSchemeSeed: const Color(0xFFFF66AA), useMaterial3: true, fontFamily: kUiFont),
        builder: (context, child) => ToastHost(child: child),
        home: home,
      ),
    );
  }
}
