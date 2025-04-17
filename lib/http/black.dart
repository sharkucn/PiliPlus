import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/utils/storage.dart';

import '../models/user/black.dart';
import 'index.dart';

class BlackHttp {
  static Future<LoadingState<BlackListDataModel>> blackList(
      {required int pn, int? ps}) async {
    var res = await Request().get(Api.blackLst, queryParameters: {
      'pn': pn,
      'ps': ps ?? 50,
      're_version': 0,
      'jsonp': 'jsonp',
      'csrf': Accounts.main.csrf,
    });
    if (res.data['code'] == 0) {
      BlackListDataModel data = BlackListDataModel.fromJson(res.data['data']);
      return LoadingState.success(data);
    } else {
      return LoadingState.error(res.data['message']);
    }
  }
}
