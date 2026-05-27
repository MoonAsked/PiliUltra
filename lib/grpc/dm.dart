import 'package:PiliUltra/grpc/bilibili/community/service/dm/v1.pb.dart';
import 'package:PiliUltra/grpc/grpc_req.dart';
import 'package:PiliUltra/grpc/url.dart';
import 'package:PiliUltra/http/loading_state.dart';
import 'package:fixnum/fixnum.dart';

abstract final class DmGrpc {
  static Future<LoadingState<DmSegMobileReply>> dmSegMobile({
    required int cid,
    required int segmentIndex,
    int type = 1,
  }) {
    return GrpcReq.request(
      GrpcUrl.dmSegMobile,
      DmSegMobileReq(
        oid: Int64(cid),
        segmentIndex: Int64(segmentIndex),
        type: type,
      ),
      DmSegMobileReply.fromBuffer,
      isolate: true,
    );
  }
}
