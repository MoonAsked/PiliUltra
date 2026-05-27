import 'package:PiliUltra/http/loading_state.dart';
import 'package:PiliUltra/http/user.dart';
import 'package:PiliUltra/models_new/follow/data.dart';
import 'package:PiliUltra/pages/follow_type/controller.dart';

class FollowedController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.followedUp(mid: mid, pn: page);
}
