import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimaryScaffold extends StatelessWidget {
  const PrimaryScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final overlayStyle = SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: colors.surface,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: Text(title),
          actions: actions,
          systemOverlayStyle: overlayStyle,
        ),
        body: SafeArea(
          child: SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.surface,
                    Color.alphaBlend(
                      colors.primary.withValues(alpha: 0.07),
                      colors.surface,
                    ),
                    Color.alphaBlend(
                      colors.secondary.withValues(alpha: 0.045),
                      colors.surface,
                    ),
                    Color.alphaBlend(
                      colors.tertiary.withValues(alpha: 0.055),
                      colors.surface,
                    ),
                  ],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
