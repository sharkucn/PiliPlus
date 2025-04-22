import 'dart:async';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/common/widgets/network_img_layer.dart';
import 'package:PiliPlus/models/user/fav_folder.dart';
import 'package:PiliPlus/pages/media/index.dart';
import 'package:PiliPlus/utils/utils.dart';

class MediaPage extends CommonPage {
  const MediaPage({super.key});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends CommonPageState<MediaPage, MediaController>
    with AutomaticKeepAliveClientMixin {
  @override
  MediaController controller = Get.put(MediaController());
  late final MainController _mainController = Get.find<MainController>();

  @override
  bool get wantKeepAlive => true;

  @override
  void listener() {
    if (_mainController.navigationBars[0]['id'] != 2 &&
        _mainController.selectedIndex.value == 0) {
      return;
    }
    super.listener();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Color primary = Theme.of(context).colorScheme.primary;
    return MediaQuery.removePadding(
      context: context,
      removeLeft: context.orientation == Orientation.landscape,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 30,
        ),
        body: ListView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ListTile(
              leading: null,
              title: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  '媒体库',
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              trailing: IconButton(
                tooltip: '设置',
                onPressed: () {
                  Get.toNamed('/setting');
                },
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 20,
                ),
              ),
            ),
            for (var item in controller.list)
              ListTile(
                onTap: item['onTap'],
                dense: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Icon(
                    item['icon'],
                    color: primary,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.only(left: 15, top: 2, bottom: 2),
                minLeadingWidth: 0,
                title: Text(
                  item['title'],
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            Obx(
              () => controller.loadingState.value is Loading
                  ? const SizedBox.shrink()
                  : favFolder(),
            )
          ],
        ),
      ),
    );
  }

  Widget favFolder() {
    return Column(
      children: [
        Divider(
          height: 20,
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        ListTile(
          onTap: () async {
            await Get.toNamed('/fav');
            Future.delayed(const Duration(milliseconds: 150), () {
              controller.onRefresh();
            });
          },
          dense: true,
          title: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Obx(
              () => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '我的收藏  ',
                      style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.titleMedium!.fontSize,
                          fontWeight: FontWeight.bold),
                    ),
                    if (controller.count.value != -1)
                      TextSpan(
                        text: "${controller.count.value}  ",
                        style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.titleSmall!.fontSize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    WidgetSpan(
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          trailing: IconButton(
            tooltip: '刷新',
            onPressed: controller.onRefresh,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 200,
          child: Obx(() => _buildBody(controller.loadingState.value)),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildBody(LoadingState loadingState) {
    if (loadingState is Success) {
      List<FavFolderItemData>? favFolderList = loadingState.response.list;
      if (favFolderList.isNullOrEmpty) {
        return const SizedBox.shrink();
      }
      bool flag = controller.count.value > favFolderList!.length;
      return ListView.builder(
        itemCount: loadingState.response.list.length + (flag ? 1 : 0),
        itemBuilder: (context, index) {
          if (flag && index == favFolderList.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 14, bottom: 35),
              child: Center(
                child: IconButton(
                  tooltip: '查看更多',
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      return Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.5);
                    }),
                  ),
                  onPressed: () async {
                    await Get.toNamed('/fav');
                    Future.delayed(const Duration(milliseconds: 150), () {
                      controller.onRefresh();
                    });
                  },
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          } else {
            String heroTag =
                Utils.makeHeroTag(loadingState.response.list[index].fid);
            return FavFolderItem(
              heroTag: heroTag,
              item: loadingState.response.list[index],
              index: index,
              onTap: () async {
                await Get.toNamed(
                  '/favDetail',
                  arguments: loadingState.response.list[index],
                  parameters: {
                    'mediaId': loadingState.response.list[index].id.toString(),
                    'heroTag': heroTag,
                  },
                );
                Future.delayed(const Duration(milliseconds: 150), () {
                  controller.onRefresh();
                });
              },
            );
          }
        },
        scrollDirection: Axis.horizontal,
      );
    }
    if (loadingState is Error) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            loadingState.errMsg,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class FavFolderItem extends StatelessWidget {
  const FavFolderItem({
    super.key,
    this.item,
    this.index,
    required this.onTap,
    required this.heroTag,
  });

  final FavFolderItemData? item;
  final int? index;
  final GestureTapCallback onTap;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: index == 0 ? 20 : 0, right: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 180,
              height: 110,
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context)
                    .colorScheme
                    .onInverseSurface
                    .withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .onInverseSurface
                        .withOpacity(0.4),
                    offset: const Offset(4, -12),
                    blurRadius: 0.0,
                    spreadRadius: 0.0,
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, BoxConstraints box) {
                  return Hero(
                    tag: heroTag,
                    child: NetworkImgLayer(
                      src: item!.cover,
                      width: box.maxWidth,
                      height: box.maxHeight,
                    ),
                  );
                },
              ),
            ),
            Text(
              ' ${item!.title}',
              overflow: TextOverflow.fade,
              maxLines: 1,
            ),
            Text(
              ' 共${item!.mediaCount}条视频 · ${Utils.isPublicFavText(item?.attr ?? 0)}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(color: Theme.of(context).colorScheme.outline),
            )
          ],
        ),
      ),
    );
  }
}
