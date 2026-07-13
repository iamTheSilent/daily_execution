import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'providers/settings_providers.dart';

class DailyExecutionApp extends ConsumerWidget {
  const DailyExecutionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final textScale = ref.watch(fontScaleProvider);
    return MaterialApp.router(
      title: 'Daily Execution',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      locale: ref.watch(localeProvider),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fa')],
      builder: (context, child) {
        final content = kIsWeb
            ? _PhoneFrame(child: child)
            : (child ?? const SizedBox.shrink());
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: content,
        );
      },
    );
  }
}

/// فقط روی مرورگر فعّاله: اپ رو اندازهٔ یه گوشی وسطِ صفحه نشون می‌ده.
/// (روی گوشیِ واقعی به خاطر kIsWeb غیرفعاله، پس نگران نباش.)
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const aspect = 390 / 844; // نسبتِ یه گوشی معمولی
            var h = constraints.maxHeight - 24;
            var w = h * aspect;
            if (w > 430) {
              w = 430;
              h = w / aspect;
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SizedBox(width: w, height: h, child: child),
            );
          },
        ),
      ),
    );
  }
}