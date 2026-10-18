import 'package:flutter/widgets.dart';

import '../../content/models.dart';
import '../widgets/common.dart';
import 'chart_block.dart';
import 'code_block.dart';
import 'diagram_block.dart';
import 'text_blocks.dart';

class BlockView extends StatelessWidget {
  const BlockView(this.block, {super.key});

  final Block block;

  @override
  Widget build(BuildContext context) => switch (block) {
    final ParagraphBlock b => RichParagraph(b.text),
    final SubheadingBlock b => SubheadingView(b),
    final ListBlock b => BulletListView(b),
    final CodeBlock b => CodeBlockView(b),
    final CalloutBlock b => CalloutView(b),
    final TableBlock b => TableView(b),
    final StepsBlock b => StepsView(b),
    final TermsBlock b => TermsView(b),
    final DiagramBlock b => DiagramView(b),
    final ChartBlock b => ChartView(b),
  };
}
