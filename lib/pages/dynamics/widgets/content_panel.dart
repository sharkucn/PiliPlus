// 内容
import 'package:PiliPlus/common/widgets/image_view.dart';
import 'package:flutter/material.dart';

import 'rich_node_panel.dart';

Widget content(bool isSave, BuildContext context, item, source, callback) {
  InlineSpan picsNodes() {
    return WidgetSpan(
      child: LayoutBuilder(
        builder: (context, constraints) => imageView(
          constraints.maxWidth,
          (item.modules.moduleDynamic.major.opus.pics as List)
              .map(
                (item) => ImageModel(
                  width: item.width,
                  height: item.height,
                  url: item.url ?? '',
                  liveUrl: item.liveUrl,
                ),
              )
              .toList(),
          callback: callback,
        ),
      ),
    );
  }

  TextStyle authorStyle =
      TextStyle(color: Theme.of(context).colorScheme.primary);
  InlineSpan? richNodes = richNode(item, context);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.modules.moduleDynamic.topic != null) ...[
          GestureDetector(
            child: Text(
              '#${item.modules.moduleDynamic.topic.name}',
              style: authorStyle,
            ),
          ),
        ],
        if (richNodes != null)
          source == 'detail'
              ? SelectableRegion(
                  magnifierConfiguration: const TextMagnifierConfiguration(),
                  focusNode: FocusNode(),
                  selectionControls: MaterialTextSelectionControls(),
                  child: Text.rich(
                    style: TextStyle(fontSize: !isSave ? 16 : 15),
                    richNodes,
                  ),
                )
              : Text.rich(
                  style: const TextStyle(fontSize: 15),
                  richNodes,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
        if (item.modules.moduleDynamic.major != null &&
            item.modules.moduleDynamic.major.opus != null &&
            item.modules.moduleDynamic.major.opus.pics.isNotEmpty)
          Text.rich(
            picsNodes(),
          ),
      ],
    ),
  );
}
