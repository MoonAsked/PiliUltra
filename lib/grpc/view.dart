import 'package:PiliUltra/grpc/bilibili/app/viewunite/v1.pb.dart'
    show ViewReq, ViewReply;
import 'package:PiliUltra/grpc/grpc_req.dart';
import 'package:PiliUltra/grpc/url.dart';
import 'package:PiliUltra/http/loading_state.dart';

abstract final class ViewGrpc {
  static Future<LoadingState<ViewReply>> view({
    required String bvid,
  }) {
    return GrpcReq.request(
      GrpcUrl.view,
      ViewReq(
        bvid: bvid,
      ),
      ViewReply.fromBuffer,
    );
  }
}
