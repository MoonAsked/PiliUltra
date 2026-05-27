import 'package:PiliUltra/pages/common/common_list_controller.dart';
import 'package:PiliUltra/pages/common/multi_select/base.dart';

abstract class MultiSelectController<
  R,
  T extends MultiSelectData
> = CommonListController<R, T>
    with CommonMultiSelectMixin<T>, DeleteItemMixin;
