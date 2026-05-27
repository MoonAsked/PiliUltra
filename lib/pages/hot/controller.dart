import 'package:PiliUltra/http/loading_state.dart';
import 'package:PiliUltra/http/video.dart';
import 'package:PiliUltra/models/model_hot_video_item.dart';
import 'package:PiliUltra/pages/common/common_list_controller.dart';

class HotController
    extends CommonListController<List<HotVideoItemModel>, HotVideoItemModel> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState<List<HotVideoItemModel>>> customGetData() =>
      VideoHttp.hotVideoList(
        pn: page,
        ps: 20,
      );
}
