import 'package:PiliUltra/models_new/history/data.dart';
import 'package:PiliUltra/models_new/history/list.dart';
import 'package:PiliUltra/pages/common/search/common_search_page.dart';
import 'package:PiliUltra/pages/history/widgets/item.dart';
import 'package:PiliUltra/pages/history_search/controller.dart';
import 'package:PiliUltra/utils/grid.dart';
import 'package:PiliUltra/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HistorySearchPage extends StatefulWidget {
  const HistorySearchPage({super.key});

  @override
  State<HistorySearchPage> createState() => _HistorySearchPageState();
}

class _HistorySearchPageState
    extends
        CommonSearchPageState<
          HistorySearchPage,
          HistoryData,
          HistoryItemModel
        > {
  @override
  final HistorySearchController controller = Get.put(
    HistorySearchController(),
    tag: Utils.generateRandomString(8),
  );

  late final gridDelegate = Grid.videoCardHDelegate(context, minHeight: 110);

  @override
  Widget buildList(List<HistoryItemModel> list) {
    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        final item = list[index];
        return HistoryItem(
          item: item,
          ctr: controller,
          onDelete: (kid, business) =>
              controller.onDelHistory(index, kid, business),
        );
      },
      itemCount: list.length,
    );
  }
}
