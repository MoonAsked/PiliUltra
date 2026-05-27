/// PGC playurl请求上下文
class RegionPlayUrlContext {
  final int? aid;
  final int cid;
  final int? epId;
  final int? seasonId;
  final int qn;
  final int fnval;
  final int fourk;
  final String? seasonTitle;
  final String accountId;

  const RegionPlayUrlContext({
    this.aid,
    required this.cid,
    this.epId,
    this.seasonId,
    this.qn = 80,
    this.fnval = 4048,
    this.fourk = 1,
    this.seasonTitle,
    required this.accountId,
  });
}
