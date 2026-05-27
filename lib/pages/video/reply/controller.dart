import 'package:PiliUltra/grpc/bilibili/main/community/reply/v1.pb.dart'
    show MainListReply, ReplyInfo;
import 'package:PiliUltra/grpc/reply.dart';
import 'package:PiliUltra/http/loading_state.dart';
import 'package:PiliUltra/models/common/video/video_type.dart';
import 'package:PiliUltra/pages/common/reply_controller.dart';
import 'package:PiliUltra/pages/video/controller.dart';
import 'package:PiliUltra/utils/id_utils.dart';
import 'package:get/get.dart';

class VideoReplyController extends ReplyController<MainListReply> {
  VideoReplyController({
    required this.aid,
    required this.videoType,
    required this.heroTag,
  });
  int aid;
  final VideoType videoType;
  late final isPugv = videoType == VideoType.pugv;

  final String heroTag;
  late final videoCtr = Get.find<VideoDetailController>(tag: heroTag);

  @override
  dynamic get sourceId => IdUtils.av2bv(aid);

  @override
  List<ReplyInfo>? getDataList(MainListReply response) {
    return response.replies;
  }

  @override
  Future<LoadingState<MainListReply>> customGetData() => ReplyGrpc.mainList(
    oid: isPugv ? videoCtr.epId! : aid,
    type: videoType.replyType,
    mode: mode,
    cursorNext: cursorNext,
    offset: paginationReply?.nextOffset,
  );
}
