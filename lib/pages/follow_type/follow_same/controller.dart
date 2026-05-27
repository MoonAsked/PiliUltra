import 'package:PiliUltra/http/loading_state.dart';
import 'package:PiliUltra/http/user.dart';
import 'package:PiliUltra/models_new/follow/data.dart';
import 'package:PiliUltra/pages/follow_type/controller.dart';

class FollowSameController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.sameFollowing(mid: mid, pn: page);
}
