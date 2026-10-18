import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'content/repository.dart';
import 'theme/theme.dart';
import 'ui/home_page.dart';
import 'ui/widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await ContentRepository.load(rootBundle);
  runApp(LearnApp(repository: repository));
}

class LearnApp extends StatefulWidget {
  const LearnApp({super.key, required this.repository});

  final ContentRepository repository;

  @override
  State<LearnApp> createState() => _LearnAppState();
}

class _LearnAppState extends State<LearnApp> {
  ThemePreference _preference = ThemePreference.system;

  @override
  Widget build(BuildContext context) {
    return ContentScope(
      repository: widget.repository,
      child: WidgetsApp(
        title: 'LearnApp',
        color: const Color(0xFF000000),
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
            FadeRoute<T>(builder: builder),
        home: const HomePage(),
        builder: (context, child) {
          final system = MediaQuery.platformBrightnessOf(context);
          final dark = switch (_preference) {
            ThemePreference.system => system == Brightness.dark,
            ThemePreference.light => false,
            ThemePreference.dark => true,
          };
          final colors = dark ? AppColors.dark : AppColors.light;
          return AppTheme(
            colors: colors,
            preference: _preference,
            onPreferenceChanged: (p) => setState(() => _preference = p),
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              child: ScrollConfiguration(
                behavior: const _Scroll(),
                child: DefaultTextStyle(
                  style: AppText.body.copyWith(color: colors.text),
                  child: ColoredBox(color: colors.background, child: child!),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Rolagem com bounce e sem o brilho de overscroll do Android.
class _Scroll extends ScrollBehavior {
  const _Scroll();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}
