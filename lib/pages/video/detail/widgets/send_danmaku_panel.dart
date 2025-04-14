import 'dart:async';

import 'package:PiliPlus/common/widgets/icon_button.dart';
import 'package:PiliPlus/http/danmaku.dart';
import 'package:PiliPlus/main.dart';
import 'package:PiliPlus/pages/common/common_publish_page.dart';
import 'package:PiliPlus/pages/setting/slide_color_picker.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class SendDanmakuPanel extends CommonPublishPage {
  // video
  final dynamic cid;
  final dynamic bvid;
  final dynamic progress;

  final ValueChanged<DanmakuContentItem> callback;
  final bool darkVideoPage;

  // config
  final ({int? mode, int? fontsize, Color? color})? dmConfig;
  final ValueChanged<({int mode, int fontsize, Color color})>? onSaveDmConfig;

  const SendDanmakuPanel({
    super.key,
    super.initialValue,
    super.onSave,
    this.cid,
    this.bvid,
    this.progress,
    required this.callback,
    required this.darkVideoPage,
    this.dmConfig,
    this.onSaveDmConfig,
  });

  @override
  State<SendDanmakuPanel> createState() => _SendDanmakuPanelState();
}

class _SendDanmakuPanelState extends CommonPublishPageState<SendDanmakuPanel> {
  late final RxInt _mode;
  late final RxInt _fontsize;
  late final Rx<Color> _color;

  final List<Color> _colorList = [
    Colors.white,
    Color(0xFFFE0302),
    Color(0xFFFF7204),
    Color(0xFFFFAA02),
    Color(0xFFFFD302),
    Color(0xFFFFFF00),
    Color(0xFFA0EE00),
    Color(0xFF00CD00),
    Color(0xFF019899),
    Color(0xFF4266BE),
    Color(0xFF89D5FF),
    Color(0xFFCC0273),
    Color(0xFF222222),
    Color(0xFF9B9B9B),
  ];

  @override
  void initState() {
    super.initState();
    _mode = (widget.dmConfig?.mode ?? 1).obs;
    _fontsize = (widget.dmConfig?.fontsize ?? 25).obs;
    _color = (widget.dmConfig?.color ?? Colors.white).obs;
    try {
      final userInfo = GStorage.userInfo.get('userInfoCache');
      if (userInfo?.vipStatus == 1) {
        _colorList.add(Colors.transparent);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    widget.onSaveDmConfig?.call(
        (mode: _mode.value, fontsize: _fontsize.value, color: _color.value));
    super.dispose();
  }

  get _buildColorPanel => Expanded(
        child: Obx(
          () => Builder(
            key: ValueKey(_color.value),
            builder: (context) {
              final bool isCustomColor = _colorList.contains(_color.value).not;
              final int length =
                  _colorList.length + (isCustomColor ? 1 : 0) + 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 40,
                  mainAxisExtent: 40,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: length,
                itemBuilder: (context, index) {
                  if (index == length - 1) {
                    return GestureDetector(
                      onTap: () {
                        _showColorPicker();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: themeData.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(2),
                        child: Icon(
                          size: 22,
                          Icons.edit,
                          color: themeData.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    );
                  } else if (index == length - 2 && isCustomColor) {
                    return _buildColorItem(_color.value);
                  }
                  return _buildColorItem(_colorList[index]);
                },
              );
            },
          ),
        ),
      );

  Widget get child => MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: GestureDetector(
          onTap: Get.back,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isH = constraints.maxWidth > constraints.maxHeight;
              late double padding = constraints.maxWidth * 0.12;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: isH ? padding : 0),
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  backgroundColor: Colors.transparent,
                  body: GestureDetector(
                    onTap: () {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildInputView(),
                        buildPanelContainer(themeData.colorScheme.surface),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeData = widget.darkVideoPage
        ? MyApp.darkThemeData ?? Theme.of(context)
        : Theme.of(context);
  }

  late ThemeData themeData;

  @override
  Widget build(BuildContext context) {
    return widget.darkVideoPage ? Theme(data: themeData, child: child) : child;
  }

  @override
  Widget? customPanel(double height) => Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: themeData.colorScheme.outline.withOpacity(0.1),
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('弹幕字号', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 16),
                  _buildFontSizeItem(18, '小'),
                  const SizedBox(width: 5),
                  _buildFontSizeItem(25, '标准'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('弹幕样式', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 16),
                  _buildPositionItem(1, '滚动'),
                  const SizedBox(width: 5),
                  _buildPositionItem(5, '顶部'),
                  const SizedBox(width: 5),
                  _buildPositionItem(4, '底部'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('弹幕颜色', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 16),
                  _buildColorPanel,
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );

  Widget _buildColorItem(Color color) {
    return GestureDetector(
      onTap: () {
        _color.value = color;
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: _color.value != color
              ? null
              : Border.all(
                  width: 2,
                  color: themeData.colorScheme.primary,
                ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: color == Colors.transparent
              ? Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFDD94DA),
                            Color(0xFF72B2EA),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildPositionItem(int mode, String title) {
    return Obx(
      () => Expanded(
        child: GestureDetector(
          onTap: () {
            _mode.value = mode;
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _mode.value == mode
                  ? themeData.colorScheme.secondaryContainer
                  : themeData.colorScheme.onInverseSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              title,
              style: TextStyle(
                color: _mode.value == mode
                    ? themeData.colorScheme.onSecondaryContainer
                    : themeData.colorScheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeItem(int fontsize, String title) {
    return Obx(
      () => Expanded(
        child: GestureDetector(
          onTap: () {
            _fontsize.value = fontsize;
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _fontsize.value == fontsize
                  ? themeData.colorScheme.secondaryContainer
                  : themeData.colorScheme.onInverseSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              title,
              style: TextStyle(
                color: _fontsize.value == fontsize
                    ? themeData.colorScheme.onSecondaryContainer
                    : themeData.colorScheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputView() {
    return Container(
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      padding: const EdgeInsets.only(left: 8, top: 2, right: 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        color: themeData.colorScheme.surface,
      ),
      child: Row(
        children: [
          Obx(
            () => iconButton(
              context: context,
              tooltip: '弹幕样式',
              onPressed: () {
                if (selectKeyboard.value) {
                  selectKeyboard.value = false;
                  updatePanelType(PanelType.emoji);
                } else {
                  selectKeyboard.value = true;
                  updatePanelType(PanelType.keyboard);
                }
              },
              bgColor: Colors.transparent,
              iconSize: 24,
              icon: Icons.text_format,
              iconColor: selectKeyboard.value.not
                  ? themeData.colorScheme.primary
                  : themeData.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Listener(
                onPointerUp: (event) {
                  if (readOnly.value) {
                    updatePanelType(PanelType.keyboard);
                    selectKeyboard.value = true;
                  }
                },
                child: Obx(
                  () => TextField(
                    controller: editController,
                    autofocus: false,
                    readOnly: readOnly.value,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(100),
                    ],
                    onChanged: (value) {
                      bool isEmpty = value.trim().isEmpty;
                      if (!isEmpty && !enablePublish.value) {
                        enablePublish.value = true;
                      } else if (isEmpty && enablePublish.value) {
                        enablePublish.value = false;
                      }
                      widget.onSave?.call(value);
                    },
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        onPublish();
                      }
                    },
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: "输入弹幕内容",
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: themeData.colorScheme.outline,
                      ),
                    ),
                    style: themeData.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () => enablePublish.value
                ? iconButton(
                    context: context,
                    bgColor: Colors.transparent,
                    iconSize: 22,
                    iconColor: themeData.colorScheme.onSurfaceVariant,
                    onPressed: () {
                      editController.clear();
                      enablePublish.value = false;
                    },
                    icon: Icons.clear,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          Obx(
            () => iconButton(
              context: context,
              tooltip: '发送',
              bgColor: Colors.transparent,
              iconSize: 22,
              iconColor: enablePublish.value
                  ? themeData.colorScheme.primary
                  : themeData.colorScheme.outline,
              onPressed: enablePublish.value ? onPublish : null,
              icon: Icons.send,
            ),
          )
        ],
      ),
    );
  }

  void _showColorPicker() {
    controller.keepChatPanel();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        clipBehavior: Clip.hardEdge,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        title: Text('Color Picker'),
        content: SlideColorPicker(
          showResetBtn: false,
          color: _color.value,
          callback: (Color? color) {
            if (color != null) {
              _color.value = color;
            }
          },
        ),
      ),
    );
  }

  @override
  Future onCustomPublish({required String message, List? pictures}) async {
    SmartDialog.showLoading(msg: '发送中...');
    bool isColorful = _color.value == Colors.transparent;
    final res = await DanmakuHttp.shootDanmaku(
      oid: widget.cid,
      bvid: widget.bvid,
      progress: widget.progress,
      msg: editController.text,
      mode: _mode.value,
      fontsize: _fontsize.value,
      color: isColorful ? null : _color.value.value & 0xFFFFFF,
      colorful: isColorful,
    );
    SmartDialog.dismiss();
    if (res['status']) {
      Get.back();
      SmartDialog.showToast('发送成功');
      widget.callback(
        DanmakuContentItem(
          editController.text,
          color: _color.value,
          type: switch (_mode.value) {
            5 => DanmakuItemType.top,
            4 => DanmakuItemType.bottom,
            _ => DanmakuItemType.scroll,
          },
          selfSend: true,
          isColorful: isColorful,
        ),
      );
    } else {
      SmartDialog.showToast('发送失败: ${res['msg']}');
    }
  }
}
