/// Season请求上下文
class RegionSeasonContext {
  final int? seasonId;
  final int? epId;
  final String accountId;
  final String source;

  const RegionSeasonContext({
    this.seasonId,
    this.epId,
    required this.accountId,
    this.source = 'pgc',
  });
}
