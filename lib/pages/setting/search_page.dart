import 'package:PiliPlus/common/widgets/http_error.dart';
import 'package:PiliPlus/pages/setting/widgets/model.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

class SettingsSearchPage extends StatefulWidget {
  const SettingsSearchPage({super.key});

  @override
  State<SettingsSearchPage> createState() => _SettingsSearchPageState();
}

class _SettingsSearchPageState extends State<SettingsSearchPage> {
  final _textEditingController = TextEditingController();
  final RxList<SettingsModel> _list = <SettingsModel>[].obs;

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              if (_textEditingController.text.isNotEmpty) {
                _textEditingController.clear();
                _list.value = <SettingsModel>[];
              } else {
                Get.back();
              }
            },
            icon: const Icon(Icons.clear),
          ),
          const SizedBox(width: 10),
        ],
        title: TextField(
          autofocus: true,
          controller: _textEditingController,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) {
            if (value.isEmpty) {
              _list.value = <SettingsModel>[];
            } else {
              _list.value = [
                ...extraSettings,
                ...privacySettings,
                ...recommendSettings,
                ...videoSettings,
                ...playSettings,
                ...styleSettings,
              ]
                  .where((item) =>
                      item.settingsType != SettingsType.divider &&
                          (item.title ?? item.getTitle?.call())
                              ?.toLowerCase()
                              .contains(value.toLowerCase()) ||
                      item.subtitle
                              ?.toLowerCase()
                              .contains(value.toLowerCase()) ==
                          true)
                  .toList();
            }
          },
          decoration: InputDecoration(
            isDense: true,
            hintText: '搜索',
            border: InputBorder.none,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            Obx(
              () => _list.isEmpty
                  ? HttpError()
                  : SliverPadding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom + 80,
                      ),
                      sliver: SliverWaterfallFlow.extent(
                        maxCrossAxisExtent: Grid.smallCardWidth * 2,
                        children: [
                          ..._list.map((item) => item.widget),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
