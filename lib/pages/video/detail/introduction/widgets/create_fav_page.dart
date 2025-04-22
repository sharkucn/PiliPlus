import 'package:PiliPlus/common/widgets/http_error.dart';
import 'package:PiliPlus/http/msg.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class CreateFavPage extends StatefulWidget {
  const CreateFavPage({super.key});

  @override
  State<CreateFavPage> createState() => _CreateFavPageState();
}

class _CreateFavPageState extends State<CreateFavPage> {
  dynamic _mediaId;
  late final _titleController = TextEditingController();
  late final _introController = TextEditingController();
  String? _cover;
  bool _isPublic = true;
  late final _imagePicker = ImagePicker();
  String? _errMsg;
  int? _attr;

  @override
  void initState() {
    super.initState();
    _mediaId = Get.parameters['mediaId'];
    if (_mediaId != null) {
      _getFolderInfo();
    }
  }

  void _getFolderInfo() {
    UserHttp.folderInfo(mediaId: _mediaId).then((data) {
      if (data['status']) {
        _titleController.text = data['data']['title'];
        _introController.text = data['data']['intro'];
        _isPublic = Utils.isPublicFav(data['data']['attr']);
        _cover = data['data']['cover'];
        _attr = data['data']['attr'];
      } else {
        _errMsg = data['msg'];
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mediaId != null ? '编辑' : '创建'),
        actions: [
          TextButton(
            onPressed: () {
              if (_titleController.text.isEmpty) {
                SmartDialog.showToast('名称不能为空');
                return;
              }
              UserHttp.addOrEditFolder(
                isAdd: _mediaId == null,
                mediaId: _mediaId,
                title: _titleController.text,
                privacy: _isPublic ? 0 : 1,
                cover: _cover ?? '',
                intro: _introController.text,
              ).then((data) {
                if (data['status']) {
                  Get.back(result: data['data']);
                  SmartDialog.showToast('${_mediaId != null ? '编辑' : '创建'}成功');
                } else {
                  SmartDialog.showToast(data['msg']);
                }
              });
            },
            child: const Text('完成'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _mediaId != null
          ? _titleController.text.isNotEmpty
              ? _buildBody
              : _errMsg?.isNotEmpty == true
                  ? Center(
                      child: CustomScrollView(
                        shrinkWrap: true,
                        slivers: [
                          HttpError(
                            errMsg: _errMsg,
                            callback: _getFolderInfo,
                          ),
                        ],
                      ),
                    )
                  : Center(child: CircularProgressIndicator())
          : _buildBody,
    );
  }

  void _pickImg() async {
    try {
      XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (pickedFile != null && mounted) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '裁剪',
              toolbarColor: Theme.of(context).colorScheme.secondaryContainer,
              toolbarWidgetColor:
                  Theme.of(context).colorScheme.onSecondaryContainer,
              aspectRatioPresets: [
                CropAspectRatioPreset.ratio16x9,
              ],
              lockAspectRatio: true,
              hideBottomControls: true,
              initAspectRatio: CropAspectRatioPreset.ratio16x9,
            ),
            IOSUiSettings(
              title: '裁剪',
              aspectRatioPresets: [
                CropAspectRatioPreset.ratio16x9,
              ],
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
            ),
          ],
        );
        if (croppedFile != null) {
          MsgHttp.uploadImage(
            path: croppedFile.path,
            bucket: 'medialist',
            dir: 'cover',
          ).then((data) {
            if (data['status']) {
              _cover = data['data']['location'];
              setState(() {});
            } else {
              SmartDialog.showToast(data['msg']);
            }
          });
        }
      }
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  dynamic leadingStyle = TextStyle(fontSize: 14);

  Widget get _buildBody => SingleChildScrollView(
        child: Column(
          children: [
            if (_attr == null || !Utils.isDefaultFav(_attr!)) ...[
              ListTile(
                tileColor: Theme.of(context).colorScheme.onInverseSurface,
                onTap: () {
                  EasyThrottle.throttle(
                      'imagePicker', const Duration(milliseconds: 500),
                      () async {
                    if (_cover?.isNotEmpty == true) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            clipBehavior: Clip.hardEdge,
                            contentPadding:
                                const EdgeInsets.fromLTRB(0, 12, 0, 12),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  dense: true,
                                  onTap: () {
                                    Get.back();
                                    _pickImg();
                                  },
                                  title: const Text(
                                    '替换封面',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                ListTile(
                                  dense: true,
                                  onTap: () {
                                    Get.back();
                                    _cover = null;
                                    setState(() {});
                                  },
                                  title: const Text(
                                    '移除封面',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    } else {
                      _pickImg();
                    }
                  });
                },
                leading: Text(
                  '封面',
                  style: leadingStyle,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_cover?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: Utils.thumbnailImgUrl(_cover!),
                                height: constraints.maxHeight,
                                width: constraints.maxHeight * 16 / 9,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ListTile(
              tileColor: Theme.of(context).colorScheme.onInverseSurface,
              leading: Text.rich(
                style: TextStyle(
                  height: 1,
                  fontSize: 14,
                ),
                TextSpan(
                  children: [
                    TextSpan(
                      text: '*',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextSpan(
                      text: '名称',
                      style: TextStyle(
                        height: 1,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              title: TextField(
                autofocus: true,
                readOnly: _attr != null && Utils.isDefaultFav(_attr!),
                controller: _titleController,
                style: TextStyle(
                  fontSize: 14,
                  color: _attr != null && Utils.isDefaultFav(_attr!)
                      ? Theme.of(context).colorScheme.outline
                      : null,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '名称',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    gapPadding: 0,
                  ),
                  contentPadding: EdgeInsets.all(0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_attr == null || !Utils.isDefaultFav(_attr!)) ...[
              ListTile(
                tileColor: Theme.of(context).colorScheme.onInverseSurface,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '简介',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: '*',
                            style: TextStyle(color: Colors.transparent),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        minLines: 6,
                        maxLines: 6,
                        controller: _introController,
                        style: TextStyle(fontSize: 14),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(200),
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: '可填写简介',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            gapPadding: 0,
                          ),
                          contentPadding: EdgeInsets.all(0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ListTile(
              onTap: () {
                setState(() {
                  _isPublic = !_isPublic;
                });
              },
              tileColor: Theme.of(context).colorScheme.onInverseSurface,
              leading: Text(
                '公开',
                style: leadingStyle,
              ),
              trailing: Transform.scale(
                alignment: Alignment.centerRight,
                scale: 0.8,
                child: Switch(
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    }),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
}
