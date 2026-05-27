import 'package:PiliUltra/http/loading_state.dart';
import 'package:PiliUltra/http/video.dart';
import 'package:PiliUltra/models/model_hot_video_item.dart';
import 'package:PiliUltra/models_new/popular/popular_precious/data.dart';
import 'package:PiliUltra/pages/common/common_list_controller.dart';

class PopularPreciousController
    extends CommonListController<PopularPreciousData, HotVideoItemModel> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  int? mediaId;

  @override
  List<HotVideoItemModel>? getDataList(PopularPreciousData response) {
    mediaId = response.mediaId;
    return response.list;
  }

  @override
  Future<LoadingState<PopularPreciousData>> customGetData() =>
      VideoHttp.popularPrecious(page: page);
}
