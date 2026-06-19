import 'package:flutter/material.dart';
import 'morph_theme.dart';

class MorphScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? background;
  final bool grain;
  final Widget? floatingActionButton;
  final Widget? drawer;
  const MorphScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.background,
    this.grain = true,
    this.floatingActionButton,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? MorphColors.paper;
    Widget content = Scaffold(
      backgroundColor: bg,
      appBar: appBar,
      body: grain ? PaperGrain(child: SafeArea(child: body)) : SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      drawer: drawer,
    );
    return content;
  }
}

/// Standard masthead-style top bar.
class MorphTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? eyebrow;
  final List<Widget>? actions;
  final bool showBack;
  const MorphTopBar({super.key, required this.title, this.eyebrow, this.actions, this.showBack = true});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: const BoxDecoration(
          color: MorphColors.paper,
          border: Border(bottom: BorderSide(color: MorphColors.divider, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBack && Navigator.canPop(context))
              IconButton(
                icon: const Icon(Icons.arrow_back, color: MorphColors.ink, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (eyebrow != null)
                    Text(eyebrow!.toUpperCase(), style: MorphFonts.label(size: 10, color: MorphColors.inkMuted)),
                  Text(title, style: MorphFonts.display(size: 22), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}
