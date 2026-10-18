import 'package:flutter/widgets.dart';

import '../content/models.dart';
import '../content/repository.dart';
import '../theme/theme.dart';
import 'blocks/block_view.dart';
import 'widgets/common.dart';
import 'widgets/icons.dart';

class TopicPage extends StatefulWidget {
  const TopicPage({super.key, required this.topic});

  final Topic topic;

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  final _scroll = ScrollController();
  final _progress = ValueNotifier<double>(0);
  final _showTitle = ValueNotifier<bool>(false);
  late final _sectionKeys = [for (final _ in widget.topic.sections) GlobalKey()];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final pos = _scroll.position;
      _progress.value = pos.maxScrollExtent <= 0 ? 0 : (pos.pixels / pos.maxScrollExtent).clamp(0, 1);
      _showTitle.value = pos.pixels > 140;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _progress.dispose();
    _showTitle.dispose();
    super.dispose();
  }

  void _jumpTo(int i) {
    final ctx = _sectionKeys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = widget.topic;
    final pad = MediaQuery.paddingOf(context);
    final repo = ContentScope.of(context);
    final next = repo.neighbor(t, 1);

    return ColoredBox(
      color: c.background,
      child: Column(
        children: [
          SizedBox(height: pad.top),
          _Header(title: t.title, progress: _progress, showTitle: _showTitle),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(20, 28, 20, pad.bottom + 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Badge(t.category, accent: true),
                      const SizedBox(width: 8),
                      Badge(t.level),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(t.title, style: AppText.display.copyWith(color: c.text)),
                  const SizedBox(height: 12),
                  Text(t.summary, style: AppText.body.copyWith(color: c.textSecondary, fontSize: 16.5)),
                  const SizedBox(height: 16),
                  Text(
                    '${t.minutes} min de leitura · atualizado ${t.updated}',
                    style: AppText.eyebrow.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: 28),
                  _Toc(sections: t.sections, onTap: _jumpTo),
                  for (final (i, s) in t.sections.indexed)
                    _SectionView(key: _sectionKeys[i], index: i, section: s),
                  const SizedBox(height: 48),
                  const Hairline(),
                  const SizedBox(height: 20),
                  if (next != null)
                    _NextTopic(topic: next)
                  else
                    Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(AppIconKind.arrowLeft, size: 15, color: c.textSecondary),
                            const SizedBox(width: 8),
                            Text('Voltar aos tópicos', style: AppText.label.copyWith(color: c.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.progress, required this.showTitle});

  final String title;
  final ValueNotifier<double> progress;
  final ValueNotifier<bool> showTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButtonBox(
                    icon: AppIconKind.arrowLeft,
                    label: 'Voltar',
                    bordered: false,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: showTitle,
                      builder: (context, show, _) => AnimatedOpacity(
                        opacity: show ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label.copyWith(color: c.text, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 1, color: c.border)),
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            child: ValueListenableBuilder(
              valueListenable: progress,
              builder: (context, p, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: p,
                child: Container(height: 1.5, color: c.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toc extends StatelessWidget {
  const _Toc({required this.sections, required this.onTap});

  final List<Section> sections;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 6),
            child: Text('NESTE GUIA', style: AppText.eyebrow.copyWith(color: c.textMuted)),
          ),
          for (final (i, s) in sections.indexed)
            Pressable(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        (i + 1).toString().padLeft(2, '0'),
                        style: AppText.eyebrow.copyWith(color: c.textMuted),
                      ),
                    ),
                    Expanded(
                      child: Text(s.title, style: AppText.small.copyWith(color: c.textSecondary, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({super.key, required this.index, required this.section});

  final int index;
  final Section section;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (index + 1).toString().padLeft(2, '0'),
            style: AppText.eyebrow.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 6),
          Text(section.title, style: AppText.h1.copyWith(color: c.text, fontSize: 25)),
          for (final b in section.blocks) ...[
            const SizedBox(height: 18),
            BlockView(b),
          ],
        ],
      ),
    );
  }
}

class _NextTopic extends StatelessWidget {
  const _NextTopic({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: () => Navigator.of(context).pushReplacement(FadeRoute<void>(builder: (_) => TopicPage(topic: topic))),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRÓXIMO', style: AppText.eyebrow.copyWith(color: c.textMuted)),
                  const SizedBox(height: 6),
                  Text(topic.title, style: AppText.h3.copyWith(color: c.text)),
                ],
              ),
            ),
            AppIcon(AppIconKind.arrowRight, size: 16, color: c.text),
          ],
        ),
      ),
    );
  }
}
