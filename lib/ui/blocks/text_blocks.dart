import 'package:flutter/widgets.dart';

import '../../content/models.dart';
import '../../theme/theme.dart';
import '../widgets/common.dart';

class SubheadingView extends StatelessWidget {
  const SubheadingView(this.block, {super.key});
  final SubheadingBlock block;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(block.text, style: AppText.h3.copyWith(color: context.colors.text)),
  );
}

class BulletListView extends StatelessWidget {
  const BulletListView(this.block, {super.key});
  final ListBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, item) in block.items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 26,
                  child: block.ordered
                      ? Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '${i + 1}.',
                            style: AppText.code.copyWith(color: c.textMuted, height: 1.6),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 11, left: 4),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(width: 5, height: 5, color: c.textMuted),
                          ),
                        ),
                ),
                Expanded(child: RichParagraph(item)),
              ],
            ),
          ),
      ],
    );
  }
}

class CalloutView extends StatelessWidget {
  const CalloutView(this.block, {super.key});
  final CalloutBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg, label) = switch (block.variant) {
      CalloutVariant.note => (c.accent, c.accentSoft, 'NOTA'),
      CalloutVariant.tip => (c.success, c.successSoft, 'DICA'),
      CalloutVariant.warning => (c.warning, c.warningSoft, 'ATENÇÃO'),
      CalloutVariant.danger => (c.danger, c.dangerSoft, 'CUIDADO'),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title == null ? label : '$label · ${block.title!.toUpperCase()}',
            style: AppText.eyebrow.copyWith(color: fg),
          ),
          const SizedBox(height: 6),
          RichParagraph(block.text, style: AppText.small.copyWith(color: c.text, height: 1.6)),
        ],
      ),
    );
  }
}

class TableView extends StatelessWidget {
  const TableView(this.block, {super.key});
  final TableBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cols = block.headers.length;
    // Primeira coluna mais estreita; o resto divide o espaço.
    final minWidth = 132.0 + (cols - 1) * 150;

    Widget cell(String text, {required bool header, required bool first}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: header
          ? Text(text.toUpperCase(), style: AppText.eyebrow.copyWith(color: c.textMuted))
          : RichParagraph(
              text,
              style: AppText.small.copyWith(
                color: first ? c.text : c.textSecondary,
                fontWeight: first ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
    );

    return LayoutBuilder(
      builder: (context, box) {
        // Em telas estreitas, 3+ colunas viram cartões: cada linha é um
        // bloco com a primeira célula como título e pares rótulo/valor.
        if (cols >= 3 && box.maxWidth < minWidth) return _stacked(c);
        final width = box.maxWidth < minWidth ? minWidth : box.maxWidth;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width - 2,
              child: Table(
                columnWidths: {
                  0: const FlexColumnWidth(.8),
                  for (var i = 1; i < cols; i++) i: const FlexColumnWidth(1),
                },
                border: TableBorder(horizontalInside: BorderSide(color: c.border)),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: c.surface),
                    children: [
                      for (final (i, h) in block.headers.indexed) cell(h, header: true, first: i == 0),
                    ],
                  ),
                  for (final row in block.rows)
                    TableRow(
                      children: [
                        for (final (i, v) in row.indexed) cell(v, header: false, first: i == 0),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stacked(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in block.rows.indexed)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: BorderSide(color: c.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RichParagraph(row[0], style: AppText.label.copyWith(color: c.text, fontSize: 14)),
                  for (var j = 1; j < row.length; j++) ...[
                    const SizedBox(height: 8),
                    Text(block.headers[j].toUpperCase(), style: AppText.eyebrow.copyWith(color: c.textMuted, fontSize: 10.5)),
                    const SizedBox(height: 2),
                    RichParagraph(row[j], style: AppText.small.copyWith(color: c.textSecondary)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class StepsView extends StatelessWidget {
  const StepsView(this.block, {super.key});
  final StepsBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = block.items.length;
    return Column(
      children: [
        for (final (i, s) in block.items.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.borderStrong),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: AppText.eyebrow.copyWith(color: c.text, fontSize: 11),
                        ),
                      ),
                      if (i < n - 1)
                        Expanded(child: Container(width: 1, color: c.border)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2, bottom: i < n - 1 ? 22 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: AppText.h3.copyWith(color: c.text, fontSize: 15)),
                        const SizedBox(height: 4),
                        RichParagraph(s.text, style: AppText.small.copyWith(color: c.textSecondary, height: 1.6)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class TermsView extends StatelessWidget {
  const TermsView(this.block, {super.key});
  final TermsBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (final (i, t) in block.items.indexed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: BorderSide(color: c.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: AppText.code.copyWith(color: c.text, fontWeight: FontWeight.w500, height: 1.4)),
                  const SizedBox(height: 3),
                  RichParagraph(t.text, style: AppText.small.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
