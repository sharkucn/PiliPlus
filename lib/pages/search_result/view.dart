import 'package:PiliPlus/pages/search/controller.dart';
import 'package:PiliPlus/pages/search_panel/article/view.dart';
import 'package:PiliPlus/pages/search_panel/live/view.dart';
import 'package:PiliPlus/pages/search_panel/pgc/view.dart';
import 'package:PiliPlus/pages/search_panel/user/view.dart';
import 'package:PiliPlus/pages/search_panel/video/view.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/models/common/search_type.dart';
import 'controller.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({super.key});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  late SearchResultController _searchResultController;
  late TabController _tabController;
  final String _tag = DateTime.now().millisecondsSinceEpoch.toString();
  final bool? _isFromSearch = Get.arguments?['fromSearch'];
  SSearchController? sSearchController;

  @override
  void initState() {
    super.initState();
    _searchResultController = Get.put(
      SearchResultController(),
      tag: _tag,
    );

    _tabController = TabController(
      vsync: this,
      initialIndex: Get.arguments?['initIndex'] ?? 0,
      length: SearchType.values.length,
    );

    if (_isFromSearch == true) {
      try {
        sSearchController =
            Get.find<SSearchController>(tag: Get.parameters['tag']);
      } catch (_) {}
      _tabController.addListener(listener);
    }
  }

  void listener() {
    sSearchController?.initIndex = _tabController.index;
  }

  @override
  void dispose() {
    _tabController.removeListener(listener);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.08),
            width: 1,
          ),
        ),
        title: GestureDetector(
          onTap: () {
            if (_isFromSearch == true) {
              Get.back();
            } else {
              Get.offNamed(
                '/search',
                parameters: {'text': _searchResultController.keyword},
              );
            }
          },
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              _searchResultController.keyword,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: TabBar(
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                controller: _tabController,
                tabs: SearchType.values
                    .map(
                      (item) => Obx(
                        () {
                          int count = _searchResultController.count[item.index];
                          return Tab(
                              text:
                                  '${item.label}${count != -1 ? ' ${count > 99 ? '99+' : count}' : ''}');
                        },
                      ),
                    )
                    .toList(),
                isScrollable: true,
                indicatorWeight: 0,
                indicatorPadding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Theme.of(context).colorScheme.onSecondaryContainer,
                labelStyle: TabBarTheme.of(context)
                        .labelStyle
                        ?.copyWith(fontSize: 13) ??
                    const TextStyle(fontSize: 13),
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                unselectedLabelColor: Theme.of(context).colorScheme.outline,
                tabAlignment: TabAlignment.start,
                onTap: (index) {
                  if (_tabController.indexIsChanging.not) {
                    if (_searchResultController.toTopIndex.value == index) {
                      _searchResultController.toTopIndex.refresh();
                    } else {
                      _searchResultController.toTopIndex.value = index;
                    }
                  }
                },
              ),
            ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: tabBarView(
                  controller: _tabController,
                  children: SearchType.values
                      .map(
                        (item) => switch (item) {
                          // SearchType.all => SearchAllPanel(
                          //     tag: _tag,
                          //     searchType: item,
                          //     keyword: _searchResultController.keyword,
                          //   ),
                          SearchType.video => SearchVideoPanel(
                              tag: _tag,
                              searchType: item,
                              keyword: _searchResultController.keyword,
                            ),
                          SearchType.media_bangumi ||
                          SearchType.media_ft =>
                            SearchPgcPanel(
                              tag: _tag,
                              searchType: item,
                              keyword: _searchResultController.keyword,
                            ),
                          SearchType.live_room => SearchLivePanel(
                              tag: _tag,
                              searchType: item,
                              keyword: _searchResultController.keyword,
                            ),
                          SearchType.bili_user => SearchUserPanel(
                              tag: _tag,
                              searchType: item,
                              keyword: _searchResultController.keyword,
                            ),
                          SearchType.article => SearchArticlePanel(
                              tag: _tag,
                              searchType: item,
                              keyword: _searchResultController.keyword,
                            ),
                        },
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
