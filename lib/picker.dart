import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'dart:async';
import 'picker_localizations.dart';

/// Picker selected callback.
typedef PickerSelectedCallback = void Function(
    Picker picker, int index, List<int> selected);

/// Picker confirm callback.
typedef PickerConfirmCallback = void Function(
    Picker picker, List<int> selected);

/// Picker confirm before callback.
typedef PickerConfirmBeforeCallback = Future<bool> Function(
    Picker picker, List<int> selected);

/// Picker value format callback.
typedef PickerValueFormat<T> = String Function(T value);

/// Picker widget builder
typedef PickerWidgetBuilder = Widget Function(
    BuildContext context, Widget pickerWidget);

/// Picker widget builder
typedef PickerBuilder = Widget Function(BuildContext context, Picker picker);

/// Picker build item, If 'null' is returned, the default build is used
typedef PickerItemBuilder = Widget? Function(BuildContext context, String? text,
    Widget? child, bool selected, int col, int index);

/// Picker
class Picker {
  static const double defaultTextSize = 18.0;

  /// Index of currently selected items
  late List<int> selecteds;

  /// Picker adapter, Used to provide data and generate widgets
  late PickerAdapter adapter;

  /// insert separator before picker columns
  final List<PickerDelimiter>? delimiter;

  final VoidCallback? onCancel;
  final PickerSelectedCallback? onSelect;
  final PickerConfirmCallback? onConfirm;
  final PickerConfirmBeforeCallback? onConfirmBefore;

  /// When the previous level selection changes, scroll the child to the first item.
  final bool changeToFirst;

  /// Specify flex for each column
  final List<int>? columnFlex;

  final Widget? title;
  final Widget? cancel;
  final Widget? confirm;
  final String? cancelText;
  final String? confirmText;

  final double height;
  final double? cancelHeight;
  final double? confirmHeight;

  /// Height of list item
  final double itemExtent;

  final TextStyle? textStyle,
      cancelTextStyle,
      confirmTextStyle,
      selectedTextStyle;
  final TextAlign textAlign;
  final IconThemeData? selectedIconTheme;

  /// Text scaling factor
  final TextScaler? textScaler;

  final EdgeInsetsGeometry? columnPadding;
  final Color? backgroundColor, headerColor, containerColor;

  /// Hide head
  final bool hideHeader;

  /// Show pickers in reversed order
  final bool reversedOrder;

  /// Generate a custom header， [hideHeader] = true
  final PickerBuilder? builderHeader;

  /// Generate a custom item widget, If 'null' is returned, the default builder is used
  final PickerItemBuilder? onBuilderItem;

  /// List item loop
  final bool looping;

  /// Delay generation for smoother animation, This is the number of milliseconds to wait. It is recommended to > = 200
  final int smooth;

  final Widget? footer;

  /// A widget overlaid on the picker to highlight the currently selected entry.
  final Widget selectionOverlay;

  final Decoration? headerDecoration;

  final double magnification;
  final double diameterRatio;
  final double squeeze;

  final bool printDebug;

  Widget? _widget;
  PickerWidgetState? _state;

  Picker(
      {required this.adapter,
      this.delimiter,
      List<int>? selecteds,
      this.height = 150.0,
      this.cancelHeight,
      this.confirmHeight,
      this.itemExtent = 28.0,
      this.columnPadding,
      this.textStyle,
      this.cancelTextStyle,
      this.confirmTextStyle,
      this.selectedTextStyle,
      this.selectedIconTheme,
      this.textAlign = TextAlign.start,
      this.textScaler,
      this.title,
      this.cancel,
      this.confirm,
      this.cancelText,
      this.confirmText,
      this.backgroundColor,
      this.containerColor,
      this.headerColor,
      this.builderHeader,
      this.changeToFirst = false,
      this.hideHeader = false,
      this.looping = false,
      this.reversedOrder = false,
      this.headerDecoration,
      this.columnFlex,
      this.footer,
      this.smooth = 0,
      this.magnification = 1.0,
      this.diameterRatio = 1.1,
      this.squeeze = 1.45,
      this.selectionOverlay = const CupertinoPickerDefaultSelectionOverlay(),
      this.onBuilderItem,
      this.onCancel,
      this.onSelect,
      this.onConfirmBefore,
      this.onConfirm,
      this.printDebug = false}) {
    this.selecteds = selecteds ?? <int>[];
  }

  Widget? get widget => _widget;
  PickerWidgetState? get state => _state;
  int _maxLevel = 1;

  /// 生成picker控件
  ///
  /// Build picker control
  Widget makePicker(
      [material.ThemeData? themeData, bool isModal = false, Key? key]) {
    _maxLevel = adapter.maxLevel;
    adapter.picker = this;
    adapter.initSelects();
    _widget = PickerWidget(
      key: key ?? ValueKey(this),
      data: this,
      child:
          _PickerWidget(picker: this, themeData: themeData, isModal: isModal),
    );
    return _widget!;
  }

  /// show picker bottom sheet
  void show(
    material.ScaffoldState state, {
    material.ThemeData? themeData,
    Color? backgroundColor,
    PickerWidgetBuilder? builder,
  }) {
    state.showBottomSheet((BuildContext context) {
      final picker = makePicker(themeData);
      return builder == null ? picker : builder(context, picker);
    }, backgroundColor: backgroundColor);
  }

  /// show picker bottom sheet
  void showBottomSheet(
    BuildContext context, {
    material.ThemeData? themeData,
    Color? backgroundColor,
    PickerWidgetBuilder? builder,
  }) {
    material.Scaffold.of(context).showBottomSheet((BuildContext context) {
      final picker = makePicker(themeData);
      return builder == null ? picker : builder(context, picker);
    }, backgroundColor: backgroundColor);
  }

  /// Display modal picker
  Future<T?> showModal<T>(BuildContext context,
      {material.ThemeData? themeData,
      bool isScrollControlled = false,
      bool useRootNavigator = false,
      Color? backgroundColor,
      PickerWidgetBuilder? builder}) async {
    return await material.showModalBottomSheet<T>(
        context: context, //state.context,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        backgroundColor: backgroundColor,
        builder: (BuildContext context) {
          final picker = makePicker(themeData, true);
          return builder == null ? picker : builder(context, picker);
        });
  }

  /// show dialog picker
  Future<List<int>?> showDialog(BuildContext context,
      {bool barrierDismissible = true,
      Color? backgroundColor,
      PickerWidgetBuilder? builder,
      Key? key}) {
    return material.showDialog<List<int>>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (BuildContext context) {
          final actions = <Widget>[];
          final theme = material.Theme.of(context);
          final cancelWidget = PickerWidgetState._buildButton(
              context,
              cancelText,
              cancel,
              cancelTextStyle,
              true,
              cancelHeight,
              theme, () {
            Navigator.pop<List<int>>(context, null);
            if (onCancel != null) {
              onCancel!();
            }
          });
          if (cancelWidget != null) {
            actions.add(cancelWidget);
          }
          final confirmWidget = PickerWidgetState._buildButton(
              context,
              confirmText,
              confirm,
              confirmTextStyle,
              false,
              confirmHeight,
              theme, () async {
            if (onConfirmBefore != null &&
                !(await onConfirmBefore!(this, selecteds))) {
              return; // Cancel;
            }
            if (context.mounted) {
              Navigator.pop<List<int>>(context, selecteds);
            }
            if (onConfirm != null) {
              onConfirm!(this, selecteds);
            }
          });
          if (confirmWidget != null) {
            actions.add(confirmWidget);
          }
          return material.AlertDialog(
            key: key ?? const Key('picker-dialog'),
            title: title,
            backgroundColor: backgroundColor,
            actions: actions,
            content: builder == null
                ? makePicker(theme)
                : builder(context, makePicker(theme)),
          );
        });
  }

  /// 获取当前选择的值
  /// Get the value of the current selection
  List getSelectedValues() {
    return adapter.getSelectedValues();
  }

  /// 取消
  void doCancel(BuildContext context) {
    Navigator.of(context).pop<List<int>>(null);
    if (onCancel != null) onCancel!();
    _widget = null;
  }

  /// 确定
  void doConfirm(BuildContext context) async {
    if (onConfirmBefore != null && !(await onConfirmBefore!(this, selecteds))) {
      return; // Cancel;
    }
    if (context.mounted) {
      Navigator.of(context).pop<List<int>>(selecteds);
    }
    if (onConfirm != null) onConfirm!(this, selecteds);
    _widget = null;
  }

  /// 弹制更新指定列的内容
  /// 当 onSelect 事件中，修改了当前列前面的列的内容时，可以调用此方法来更新显示
  void updateColumn(int index, [bool all = false]) {
    if (all) {
      _state?.update();
      return;
    }
    if (_state?._keys[index] != null) {
      adapter.setColumn(index - 1);
      _state?._keys[index]!(() {});
    }
  }

  static material.ButtonStyle _getButtonStyle(material.ButtonThemeData? theme,
          [isCancelButton = false]) =>
      material.TextButton.styleFrom(
          minimumSize: Size(theme?.minWidth ?? 0.0, 42),
          textStyle: TextStyle(
            fontSize: Picker.defaultTextSize,
            color: isCancelButton ? null : theme?.colorScheme?.secondary,
          ),
          padding: theme?.padding);
}

/// 分隔符
class PickerDelimiter {
  final Widget? child;
  final int column;
  PickerDelimiter({required this.child, this.column = 1});
}

/// picker data list item
class PickerItem<T> {
  /// 显示内容
  Widget? text;

  /// 数据值
  T? value;

  /// 子项
  List<PickerItem<T>>? children;

  PickerItem({this.text, this.value, this.children});
}

class PickerWidget<T> extends InheritedWidget {
  final Picker data;
  const PickerWidget({super.key, required this.data, required super.child});
  @override
  bool updateShouldNotify(covariant PickerWidget oldWidget) =>
      oldWidget.data != data;

  static PickerWidget of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PickerWidget>()
        as PickerWidget;
  }
}

class _PickerWidget<T> extends StatefulWidget {
  final Picker picker;
  final material.ThemeData? themeData;
  final bool isModal;
  const _PickerWidget(
      {super.key, required this.picker, this.themeData, required this.isModal});

  @override
  PickerWidgetState createState() => PickerWidgetState<T>();
}

class PickerWidgetState<T> extends State<_PickerWidget> {
  Picker get picker => widget.picker;
  material.ThemeData? get themeData => widget.themeData;

  material.ThemeData? theme;
  final List<FixedExtentScrollController> scrollController = [];
  final List<StateSetter?> _keys = [];

  @override
  void initState() {
    super.initState();
    picker._state = this;
    picker.adapter.doShow();

    if (scrollController.isEmpty) {
      for (int i = 0;
          i < picker._maxLevel && i < picker.selecteds.length;
          i++) {
        scrollController
            .add(FixedExtentScrollController(initialItem: picker.selecteds[i]));
        _keys.add(null);
      }
    }
  }

  void update() {
    setState(() {});
  }

  // var ref = 0;
  @override
  Widget build(BuildContext context) {
    // print("picker build ${ref++}");
    theme = themeData ?? material.Theme.of(context);

    if (_wait && picker.smooth > 0) {
      Future.delayed(Duration(milliseconds: picker.smooth), () {
        if (!_wait) return;
        setState(() {
          _wait = false;
        });
      });
    } else {
      _wait = false;
    }

    final bodyWidgets = <Widget>[];
    if (!picker.hideHeader) {
      if (picker.builderHeader != null) {
        bodyWidgets.add(picker.headerDecoration == null
            ? picker.builderHeader!(context, picker)
            : DecoratedBox(
                decoration: picker.headerDecoration!,
                child: picker.builderHeader!(context, picker)));
      } else {
        bodyWidgets.add(DecoratedBox(
          decoration: picker.headerDecoration ??
              BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme!.dividerColor, width: 0.5),
                  bottom: BorderSide(color: theme!.dividerColor, width: 0.5),
                ),
                color: picker.headerColor ?? theme?.bottomAppBarTheme.color,
              ),
          child: Row(
            children: _buildHeaderViews(context),
          ),
        ));
      }
    }

    bodyWidgets.add(_wait
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildViews(),
          )
        : AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildViews(),
            ),
          ));

    if (picker.footer != null) bodyWidgets.add(picker.footer!);
    Widget v = Column(
      mainAxisSize: MainAxisSize.min,
      children: bodyWidgets,
    );
    if (widget.isModal) {
      return GestureDetector(
        onTap: () {},
        child: v,
      );
    }
    return v;
  }

  List<Widget>? _headerItems;

  List<Widget> _buildHeaderViews(BuildContext context) {
    if (_headerItems != null) {
      return _headerItems!;
    }
    theme ??= material.Theme.of(context);
    List<Widget> items = [];

    final cancelWidget = _buildButton(
        context,
        picker.cancelText,
        picker.cancel,
        picker.cancelTextStyle,
        true,
        picker.cancelHeight,
        theme,
        () => picker.doCancel(context));
    if (cancelWidget != null) {
      items.add(cancelWidget);
    }

    items.add(Expanded(
      child: picker.title == null
          ? const SizedBox()
          : DefaultTextStyle(
              style: theme!.textTheme.titleLarge?.copyWith(
                    fontSize: Picker.defaultTextSize,
                  ) ??
                  const TextStyle(fontSize: Picker.defaultTextSize),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              child: picker.title!),
    ));

    final confirmWidget = _buildButton(
        context,
        picker.confirmText,
        picker.confirm,
        picker.confirmTextStyle,
        false,
        picker.confirmHeight,
        theme,
        () => picker.doConfirm(context));
    if (confirmWidget != null) {
      items.add(confirmWidget);
    }

    _headerItems = items;
    return items;
  }

  static Widget? _buildButton(
      BuildContext context,
      String? text,
      Widget? widget,
      TextStyle? textStyle,
      bool isCancel,
      double? height,
      material.ThemeData? theme,
      VoidCallback? onPressed) {
    if (widget == null) {
      String? txt = text ??
          (isCancel
              ? PickerLocalizations.of(context).cancelText
              : PickerLocalizations.of(context).confirmText);
      if (txt == null || txt.isEmpty) {
        return null;
      }
      return SizedBox(
          height: height,
          child: material.TextButton(
              style: Picker._getButtonStyle(
                  material.ButtonTheme.of(context), isCancel),
              onPressed: onPressed,
              child: Text(txt,
                  overflow: TextOverflow.ellipsis,
                  textScaler: MediaQuery.of(context).textScaler,
                  style: textStyle)));
    } else {
      if (widget is Text) {
        widget = material.InkWell(onTap: onPressed, child: widget);
      }
      return textStyle == null
          ? widget
          : DefaultTextStyle(style: textStyle, child: widget);
    }
  }

  bool _changing = false;
  bool _wait = true;
  final Map<int, int> lastData = {};

  List<Widget> _buildViews() {
    // ignore: avoid_print
    if (picker.printDebug) print("_buildViews");
    theme ??= material.Theme.of(context);
    for (int j = 0; j < _keys.length; j++) {
      _keys[j] = null;
    }

    List<Widget> items = [];
    PickerAdapter? adapter = picker.adapter;
    adapter.setColumn(-1);

    final decoration = BoxDecoration(
      color: picker.containerColor ?? theme!.dialogBackgroundColor,
    );

    if (adapter.length > 0) {
      for (int i = 0;
          i < picker._maxLevel && i < picker.selecteds.length;
          i++) {
        Widget view = Expanded(
          flex: adapter.getColumnFlex(i),
          child: Container(
            padding: picker.columnPadding,
            height: picker.height,
            decoration: decoration,
            child: _wait
                ? null
                : StatefulBuilder(
                    builder: (context, state) {
                      _keys[i] = state;
                      adapter.setColumn(i - 1);
                      // ignore: avoid_print
                      if (picker.printDebug) print("builder. col: $i");

                      // 上一次是空列表
                      final lastIsEmpty = scrollController[i].hasClients &&
                          !scrollController[i].position.hasContentDimensions;

                      final length = adapter.length;
                      final viewWidget = _buildCupertinoPicker(
                          context,
                          i,
                          length,
                          adapter,
                          lastIsEmpty ? ValueKey(length) : null);

                      if (lastIsEmpty ||
                          (!picker.changeToFirst &&
                              picker.selecteds[i] >= length)) {
                        Timer(const Duration(milliseconds: 100), () {
                          if (!mounted) return;
                          // ignore: avoid_print
                          if (picker.printDebug) print("timer last");
                          var len = adapter.length;
                          var idx = (len < length ? len : length) - 1;
                          if (scrollController[i]
                              .position
                              .hasContentDimensions) {
                            scrollController[i].jumpToItem(idx);
                          } else {
                            scrollController[i] =
                                FixedExtentScrollController(initialItem: idx);
                            if (_keys[i] != null) {
                              _keys[i]!(() {});
                            }
                          }
                        });
                      }

                      return viewWidget;
                    },
                  ),
          ),
        );
        items.add(view);
      }
    }

    if (picker.delimiter != null && !_wait) {
      for (int i = 0; i < picker.delimiter!.length; i++) {
        var o = picker.delimiter![i];
        if (o.child == null) continue;
        var item = SizedBox(
            height: picker.height,
            child: DecoratedBox(
              decoration: decoration,
              child: o.child,
            ));
        if (o.column < 0) {
          items.insert(0, item);
        } else if (o.column >= items.length) {
          items.add(item);
        } else {
          items.insert(o.column, item);
        }
      }
    }

    if (picker.reversedOrder) return items.reversed.toList();

    return items;
  }

  Widget _buildCupertinoPicker(BuildContext context, int i, int length,
      PickerAdapter adapter, Key? key) {
    return CupertinoPicker.builder(
      key: key,
      backgroundColor: picker.backgroundColor,
      scrollController: scrollController[i],
      itemExtent: picker.itemExtent,
      // looping: picker.looping,
      magnification: picker.magnification,
      diameterRatio: picker.diameterRatio,
      squeeze: picker.squeeze,
      selectionOverlay: picker.selectionOverlay,
      childCount: picker.looping ? null : length,
      itemBuilder: (context, index) {
        adapter.setColumn(i - 1);
        return adapter.buildItem(context, index % length);
      },
      onSelectedItemChanged: (int idx) {
        if (length <= 0) return;
        var index = idx % length;
        if (picker.printDebug) {
          // ignore: avoid_print
          print("onSelectedItemChanged. col: $i, row: $index");
        }
        picker.selecteds[i] = index;
        updateScrollController(i);
        adapter.doSelect(i, index);
        if (picker.changeToFirst) {
          for (int j = i + 1; j < picker.selecteds.length; j++) {
            picker.selecteds[j] = 0;
            scrollController[j].jumpTo(0.0);
          }
        }
        if (picker.onSelect != null) {
          picker.onSelect!(picker, i, picker.selecteds);
        }

        if (adapter.needUpdatePrev(i)) {
          for (int j = 0; j < picker.selecteds.length; j++) {
            if (j != i && _keys[j] != null) {
              adapter.setColumn(j - 1);
              _keys[j]!(() {});
            }
          }
          // setState(() {});
        } else {
          if (_keys[i] != null) _keys[i]!(() {});
          if (adapter.isLinkage) {
            for (int j = i + 1; j < picker.selecteds.length; j++) {
              if (j == i) continue;
              adapter.setColumn(j - 1);
              if (_keys.length > j) {
                _keys[j]?.call(() {});
              }
            }
          }
        }
      },
    );
  }

  void updateScrollController(int col) {
    if (_changing || picker.adapter.isLinkage == false) return;
    _changing = true;
    for (int j = 0; j < picker.selecteds.length; j++) {
      if (j != col) {
        if (scrollController.length > j &&
            scrollController[j].hasClients &&
            scrollController[j].position.hasContentDimensions) {
          scrollController[j].position.notifyListeners();
        }
      }
    }
    _changing = false;
  }

  @override
  void debugFillProperties(properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('_changing', _changing));
  }
}

/// 选择器数据适配器
abstract class PickerAdapter<T> {
  Picker? picker;

  int getLength();
  int getMaxLevel();
  void setColumn(int index);
  void initSelects();
  Widget buildItem(BuildContext context, int index);

  /// 是否需要更新前面的列
  /// Need to update previous columns
  bool needUpdatePrev(int curIndex) {
    return false;
  }

  Widget makeText(Widget? child, String? text, bool isSel) {
    final theme = picker!.textStyle != null || picker!.state?.context == null
        ? null
        : material.Theme.of(picker!.state!.context);
    return Center(
        child: DefaultTextStyle(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: picker!.textAlign,
            style: picker!.textStyle ??
                TextStyle(
                    color: theme?.brightness == Brightness.dark
                        ? material.Colors.white
                        : material.Colors.black87,
                    fontFamily: theme == null
                        ? ""
                        : theme.textTheme.titleLarge?.fontFamily,
                    fontSize: Picker.defaultTextSize),
            child: child != null
                ? (isSel && picker!.selectedIconTheme != null
                    ? IconTheme(
                        data: picker!.selectedIconTheme!,
                        child: child,
                      )
                    : child)
                : Text(text ?? "",
                    textScaler: picker!.textScaler,
                    style: (isSel ? picker!.selectedTextStyle : null))));
  }

  Widget makeTextEx(
      Widget? child, String text, Widget? postfix, Widget? suffix, bool isSel) {
    List<Widget> items = [];
    if (postfix != null) items.add(postfix);
    items.add(
        child ?? Text(text, style: (isSel ? picker!.selectedTextStyle : null)));
    if (suffix != null) items.add(suffix);
    final theme = picker!.textStyle != null || picker!.state?.context == null
        ? null
        : material.Theme.of(picker!.state!.context);
    Color? txtColor = theme?.brightness == Brightness.dark
        ? material.Colors.white
        : material.Colors.black87;
    double? txtSize = Picker.defaultTextSize;
    if (isSel && picker!.selectedTextStyle != null) {
      if (picker!.selectedTextStyle!.color != null) {
        txtColor = picker!.selectedTextStyle!.color;
      }
      if (picker!.selectedTextStyle!.fontSize != null) {
        txtSize = picker!.selectedTextStyle!.fontSize;
      }
    }

    return Center(
        child: DefaultTextStyle(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: picker!.textAlign,
            style: picker!.textStyle ??
                TextStyle(
                    color: txtColor,
                    fontSize: txtSize,
                    fontFamily: theme == null
                        ? ""
                        : theme.textTheme.titleLarge?.fontFamily),
            child: Wrap(
              children: items,
            )));
  }

  String getText() {
    return getSelectedValues().toString();
  }

  List<T> getSelectedValues() {
    return [];
  }

  void doShow() {}
  void doSelect(int column, int index) {}

  int getColumnFlex(int column) {
    if (picker!.columnFlex != null && column < picker!.columnFlex!.length) {
      return picker!.columnFlex![column];
    }
    return 1;
  }

  int get maxLevel => getMaxLevel();

  /// Content length of current column
  int get length => getLength();

  String get text => getText();

  // 是否联动，即后面的列受前面列数据影响
  bool get isLinkage => getIsLinkage();

  @override
  String toString() {
    return getText();
  }

  bool getIsLinkage() {
    return true;
  }

  /// 通知适配器数据改变
  void notifyDataChanged() {
    if (picker?.state != null) {
      picker!.adapter.doShow();
      picker!.adapter.initSelects();
      for (int j = 0; j < picker!.selecteds.length; j++) {
        picker!.state!.scrollController[j].jumpToItem(picker!.selecteds[j]);
      }
    }
  }
}

/// 数据适配器
class PickerDataAdapter<T> extends PickerAdapter<T> {
  late List<PickerItem<T>> data;
  List<PickerItem<dynamic>>? _datas;
  int _maxLevel = -1;
  int _col = 0;
  final bool isArray;

  PickerDataAdapter(
      {List? pickerData, List<PickerItem<T>>? data, this.isArray = false}) {
    this.data = data ?? <PickerItem<T>>[];
    _parseData(pickerData);
  }

  @override
  bool getIsLinkage() {
    return !isArray;
  }

  void _parseData(List? pickerData) {
    if (pickerData != null && pickerData.isNotEmpty && (data.isEmpty)) {
      if (isArray) {
        _parseArrayPickerDataItem(pickerData, data);
      } else {
        _parsePickerDataItem(pickerData, data);
      }
    }
  }

  _parseArrayPickerDataItem(List? pickerData, List<PickerItem> data) {
    if (pickerData == null) return;
    var len = pickerData.length;
    for (int i = 0; i < len; i++) {
      var v = pickerData[i];
      if (v is! List) continue;
      List lv = v;
      if (lv.isEmpty) continue;

      PickerItem item = PickerItem<T>(children: <PickerItem<T>>[]);
      data.add(item);

      for (int j = 0; j < lv.length; j++) {
        var o = lv[j];
        if (o is T) {
          item.children!.add(PickerItem<T>(value: o));
        } else if (T == String) {
          String str = o.toString();
          item.children!.add(PickerItem<T>(value: str as T));
        }
      }
    }
    // ignore: avoid_print
    if (picker?.printDebug == true) print("data.length: ${data.length}");
  }

  _parsePickerDataItem(List? pickerData, List<PickerItem> data) {
    if (pickerData == null) return;
    var len = pickerData.length;
    for (int i = 0; i < len; i++) {
      var item = pickerData[i];
      if (item is T) {
        data.add(PickerItem<T>(value: item));
      } else if (item is Map) {
        final Map map = item;
        if (map.isEmpty) continue;

        List<T> mapList = map.keys.toList().cast();
        for (int j = 0; j < mapList.length; j++) {
          var o = map[mapList[j]];
          if (o is List && o.isNotEmpty) {
            List<PickerItem<T>> children = <PickerItem<T>>[];
            //print('add: ${data.runtimeType.toString()}');
            data.add(PickerItem<T>(value: mapList[j], children: children));
            _parsePickerDataItem(o, children);
          }
        }
      } else if (T == String && item is! List) {
        String v = item.toString();
        //print('add: $_v');
        data.add(PickerItem<T>(value: v as T));
      }
    }
  }

  @override
  void setColumn(int index) {
    if (_datas != null && _col == index + 1) return;
    _col = index + 1;
    if (isArray) {
      // ignore: avoid_print
      if (picker!.printDebug) print("index: $index");
      if (_col < data.length) {
        _datas = data[_col].children;
      } else {
        _datas = null;
      }
      return;
    }
    if (index < 0) {
      _datas = data;
    } else {
      _datas = data;
      // 列数过多会有性能问题
      for (int i = 0; i <= index && i < picker!.selecteds.length; i++) {
        var j = picker!.selecteds[i];
        if (_datas != null && _datas!.length > j) {
          _datas = _datas![j].children;
        } else {
          _datas = null;
          break;
        }
      }
    }
  }

  @override
  int getLength() => _datas?.length ?? 0;

  @override
  getMaxLevel() {
    if (_maxLevel == -1) _checkPickerDataLevel(data, 1);
    return _maxLevel;
  }

  @override
  Widget buildItem(BuildContext context, int index) {
    final PickerItem item = _datas![index];
    final isSel = index == picker!.selecteds[_col];
    if (picker!.onBuilderItem != null) {
      final v = picker!.onBuilderItem!(
          context, item.value.toString(), item.text, isSel, _col, index);
      if (v != null) return makeText(v, null, isSel);
    }
    if (item.text != null) {
      return isSel && picker!.selectedTextStyle != null
          ? DefaultTextStyle(
              style: picker!.selectedTextStyle!,
              textAlign: picker!.textAlign,
              child: picker!.selectedIconTheme != null
                  ? IconTheme(
                      data: picker!.selectedIconTheme!,
                      child: item.text!,
                    )
                  : item.text!)
          : item.text!;
    }
    return makeText(
        item.text, item.text != null ? null : item.value.toString(), isSel);
  }

  @override
  void initSelects() {
    // ignore: unnecessary_null_comparison
    if (picker!.selecteds == null) picker!.selecteds = <int>[];
    if (picker!.selecteds.isEmpty) {
      for (int i = 0; i < _maxLevel; i++) {
        picker!.selecteds.add(0);
      }
    }
  }

  @override
  List<T> getSelectedValues() {
    List<T> items = [];
    var sLen = picker!.selecteds.length;
    if (isArray) {
      for (int i = 0; i < sLen; i++) {
        int j = picker!.selecteds[i];
        if (j < 0 ||
            data[i].children == null ||
            j >= data[i].children!.length) {
          break;
        }
        T val = data[i].children![j].value as T;
        if (val != null) {
          items.add(val);
        }
      }
    } else {
      List<PickerItem<dynamic>>? datas = data;
      for (int i = 0; i < sLen; i++) {
        int j = picker!.selecteds[i];
        if (j < 0 || j >= datas!.length) break;
        items.add(datas[j].value);
        datas = datas[j].children;
        if (datas == null || datas.isEmpty) break;
      }
    }
    return items;
  }

  _checkPickerDataLevel(List<PickerItem>? data, int level) {
    if (data == null) return;
    if (isArray) {
      _maxLevel = data.length;
      return;
    }
    for (int i = 0; i < data.length; i++) {
      if (data[i].children != null && data[i].children!.isNotEmpty) {
        _checkPickerDataLevel(data[i].children, level + 1);
      }
    }
    if (_maxLevel < level) _maxLevel = level;
  }
}

enum PickerChinaAddressEnum {
  province,
  provinceAndCity,
  provinceAndCityAndArea,
}

class PickerAddressItem<T> {
  String area;
  String code;

  PickerAddressItem({required this.area, required this.code});

  @override
  String toString() {
    return area;
  }
}

class PickerChinaAddressAdapter extends PickerDataAdapter<PickerAddressItem> {
  final List<Map<String, dynamic>> address = [
    {
      "province": "北京市",
      "code": "110000",
      "citys": [
        {
          "city": "北京市",
          "code": "110100000000",
          "areas": [
            {"area": "东城区", "code": "110101000000"},
            {"area": "西城区", "code": "110102000000"},
            {"area": "朝阳区", "code": "110105000000"},
            {"area": "丰台区", "code": "110106000000"},
            {"area": "石景山区", "code": "110107000000"},
            {"area": "海淀区", "code": "110108000000"},
            {"area": "门头沟区", "code": "110109000000"},
            {"area": "房山区", "code": "110111000000"},
            {"area": "通州区", "code": "110112000000"},
            {"area": "顺义区", "code": "110113000000"},
            {"area": "昌平区", "code": "110114000000"},
            {"area": "大兴区", "code": "110115000000"},
            {"area": "怀柔区", "code": "110116000000"},
            {"area": "平谷区", "code": "110117000000"},
            {"area": "密云区", "code": "110118000000"},
            {"area": "延庆区", "code": "110119000000"}
          ]
        }
      ]
    },
    {
      "province": "天津市",
      "code": "120000",
      "citys": [
        {
          "city": "天津市",
          "code": "120100000000",
          "areas": [
            {"area": "和平区", "code": "120101000000"},
            {"area": "河东区", "code": "120102000000"},
            {"area": "河西区", "code": "120103000000"},
            {"area": "南开区", "code": "120104000000"},
            {"area": "河北区", "code": "120105000000"},
            {"area": "红桥区", "code": "120106000000"},
            {"area": "东丽区", "code": "120110000000"},
            {"area": "西青区", "code": "120111000000"},
            {"area": "津南区", "code": "120112000000"},
            {"area": "北辰区", "code": "120113000000"},
            {"area": "武清区", "code": "120114000000"},
            {"area": "宝坻区", "code": "120115000000"},
            {"area": "滨海新区", "code": "120116000000"},
            {"area": "宁河区", "code": "120117000000"},
            {"area": "静海区", "code": "120118000000"},
            {"area": "蓟州区", "code": "120119000000"}
          ]
        }
      ]
    },
    {
      "province": "河北省",
      "code": "130000",
      "citys": [
        {
          "city": "石家庄市",
          "code": "130100000000",
          "areas": [
            {"area": "长安区", "code": "130102000000"},
            {"area": "桥西区", "code": "130104000000"},
            {"area": "新华区", "code": "130105000000"},
            {"area": "井陉矿区", "code": "130107000000"},
            {"area": "裕华区", "code": "130108000000"},
            {"area": "藁城区", "code": "130109000000"},
            {"area": "鹿泉区", "code": "130110000000"},
            {"area": "栾城区", "code": "130111000000"},
            {"area": "井陉县", "code": "130121000000"},
            {"area": "正定县", "code": "130123000000"},
            {"area": "行唐县", "code": "130125000000"},
            {"area": "灵寿县", "code": "130126000000"},
            {"area": "高邑县", "code": "130127000000"},
            {"area": "深泽县", "code": "130128000000"},
            {"area": "赞皇县", "code": "130129000000"},
            {"area": "无极县", "code": "130130000000"},
            {"area": "平山县", "code": "130131000000"},
            {"area": "元氏县", "code": "130132000000"},
            {"area": "赵县", "code": "130133000000"},
            {"area": "石家庄高新技术产业开发区", "code": "130171000000"},
            {"area": "石家庄循环化工园区", "code": "130172000000"},
            {"area": "辛集市", "code": "130181000000"},
            {"area": "晋州市", "code": "130183000000"},
            {"area": "新乐市", "code": "130184000000"}
          ]
        },
        {
          "city": "唐山市",
          "code": "130200000000",
          "areas": [
            {"area": "路南区", "code": "130202000000"},
            {"area": "路北区", "code": "130203000000"},
            {"area": "古冶区", "code": "130204000000"},
            {"area": "开平区", "code": "130205000000"},
            {"area": "丰南区", "code": "130207000000"},
            {"area": "丰润区", "code": "130208000000"},
            {"area": "曹妃甸区", "code": "130209000000"},
            {"area": "滦南县", "code": "130224000000"},
            {"area": "乐亭县", "code": "130225000000"},
            {"area": "迁西县", "code": "130227000000"},
            {"area": "玉田县", "code": "130229000000"},
            {"area": "河北唐山芦台经济开发区", "code": "130271000000"},
            {"area": "唐山市汉沽管理区", "code": "130272000000"},
            {"area": "唐山高新技术产业开发区", "code": "130273000000"},
            {"area": "河北唐山海港经济开发区", "code": "130274000000"},
            {"area": "遵化市", "code": "130281000000"},
            {"area": "迁安市", "code": "130283000000"},
            {"area": "滦州市", "code": "130284000000"}
          ]
        },
        {
          "city": "秦皇岛市",
          "code": "130300000000",
          "areas": [
            {"area": "海港区", "code": "130302000000"},
            {"area": "山海关区", "code": "130303000000"},
            {"area": "北戴河区", "code": "130304000000"},
            {"area": "抚宁区", "code": "130306000000"},
            {"area": "青龙满族自治县", "code": "130321000000"},
            {"area": "昌黎县", "code": "130322000000"},
            {"area": "卢龙县", "code": "130324000000"},
            {"area": "秦皇岛市经济技术开发区", "code": "130371000000"},
            {"area": "北戴河新区", "code": "130372000000"}
          ]
        },
        {
          "city": "邯郸市",
          "code": "130400000000",
          "areas": [
            {"area": "邯山区", "code": "130402000000"},
            {"area": "丛台区", "code": "130403000000"},
            {"area": "复兴区", "code": "130404000000"},
            {"area": "峰峰矿区", "code": "130406000000"},
            {"area": "肥乡区", "code": "130407000000"},
            {"area": "永年区", "code": "130408000000"},
            {"area": "临漳县", "code": "130423000000"},
            {"area": "成安县", "code": "130424000000"},
            {"area": "大名县", "code": "130425000000"},
            {"area": "涉县", "code": "130426000000"},
            {"area": "磁县", "code": "130427000000"},
            {"area": "邱县", "code": "130430000000"},
            {"area": "鸡泽县", "code": "130431000000"},
            {"area": "广平县", "code": "130432000000"},
            {"area": "馆陶县", "code": "130433000000"},
            {"area": "魏县", "code": "130434000000"},
            {"area": "曲周县", "code": "130435000000"},
            {"area": "邯郸经济技术开发区", "code": "130471000000"},
            {"area": "邯郸冀南新区", "code": "130473000000"},
            {"area": "武安市", "code": "130481000000"}
          ]
        },
        {
          "city": "邢台市",
          "code": "130500000000",
          "areas": [
            {"area": "襄都区", "code": "130502000000"},
            {"area": "信都区", "code": "130503000000"},
            {"area": "任泽区", "code": "130505000000"},
            {"area": "南和区", "code": "130506000000"},
            {"area": "临城县", "code": "130522000000"},
            {"area": "内丘县", "code": "130523000000"},
            {"area": "柏乡县", "code": "130524000000"},
            {"area": "隆尧县", "code": "130525000000"},
            {"area": "宁晋县", "code": "130528000000"},
            {"area": "巨鹿县", "code": "130529000000"},
            {"area": "新河县", "code": "130530000000"},
            {"area": "广宗县", "code": "130531000000"},
            {"area": "平乡县", "code": "130532000000"},
            {"area": "威县", "code": "130533000000"},
            {"area": "清河县", "code": "130534000000"},
            {"area": "临西县", "code": "130535000000"},
            {"area": "河北邢台经济开发区", "code": "130571000000"},
            {"area": "南宫市", "code": "130581000000"},
            {"area": "沙河市", "code": "130582000000"}
          ]
        },
        {
          "city": "保定市",
          "code": "130600000000",
          "areas": [
            {"area": "竞秀区", "code": "130602000000"},
            {"area": "莲池区", "code": "130606000000"},
            {"area": "满城区", "code": "130607000000"},
            {"area": "清苑区", "code": "130608000000"},
            {"area": "徐水区", "code": "130609000000"},
            {"area": "涞水县", "code": "130623000000"},
            {"area": "阜平县", "code": "130624000000"},
            {"area": "定兴县", "code": "130626000000"},
            {"area": "唐县", "code": "130627000000"},
            {"area": "高阳县", "code": "130628000000"},
            {"area": "容城县", "code": "130629000000"},
            {"area": "涞源县", "code": "130630000000"},
            {"area": "望都县", "code": "130631000000"},
            {"area": "安新县", "code": "130632000000"},
            {"area": "易县", "code": "130633000000"},
            {"area": "曲阳县", "code": "130634000000"},
            {"area": "蠡县", "code": "130635000000"},
            {"area": "顺平县", "code": "130636000000"},
            {"area": "博野县", "code": "130637000000"},
            {"area": "雄县", "code": "130638000000"},
            {"area": "保定高新技术产业开发区", "code": "130671000000"},
            {"area": "保定白沟新城", "code": "130672000000"},
            {"area": "涿州市", "code": "130681000000"},
            {"area": "定州市", "code": "130682000000"},
            {"area": "安国市", "code": "130683000000"},
            {"area": "高碑店市", "code": "130684000000"}
          ]
        },
        {
          "city": "张家口市",
          "code": "130700000000",
          "areas": [
            {"area": "桥东区", "code": "130702000000"},
            {"area": "桥西区", "code": "130703000000"},
            {"area": "宣化区", "code": "130705000000"},
            {"area": "下花园区", "code": "130706000000"},
            {"area": "万全区", "code": "130708000000"},
            {"area": "崇礼区", "code": "130709000000"},
            {"area": "张北县", "code": "130722000000"},
            {"area": "康保县", "code": "130723000000"},
            {"area": "沽源县", "code": "130724000000"},
            {"area": "尚义县", "code": "130725000000"},
            {"area": "蔚县", "code": "130726000000"},
            {"area": "阳原县", "code": "130727000000"},
            {"area": "怀安县", "code": "130728000000"},
            {"area": "怀来县", "code": "130730000000"},
            {"area": "涿鹿县", "code": "130731000000"},
            {"area": "赤城县", "code": "130732000000"},
            {"area": "张家口经济开发区", "code": "130771000000"},
            {"area": "张家口市察北管理区", "code": "130772000000"},
            {"area": "张家口市塞北管理区", "code": "130773000000"}
          ]
        },
        {
          "city": "承德市",
          "code": "130800000000",
          "areas": [
            {"area": "双桥区", "code": "130802000000"},
            {"area": "双滦区", "code": "130803000000"},
            {"area": "鹰手营子矿区", "code": "130804000000"},
            {"area": "承德县", "code": "130821000000"},
            {"area": "兴隆县", "code": "130822000000"},
            {"area": "滦平县", "code": "130824000000"},
            {"area": "隆化县", "code": "130825000000"},
            {"area": "丰宁满族自治县", "code": "130826000000"},
            {"area": "宽城满族自治县", "code": "130827000000"},
            {"area": "围场满族蒙古族自治县", "code": "130828000000"},
            {"area": "承德高新技术产业开发区", "code": "130871000000"},
            {"area": "平泉市", "code": "130881000000"}
          ]
        },
        {
          "city": "沧州市",
          "code": "130900000000",
          "areas": [
            {"area": "新华区", "code": "130902000000"},
            {"area": "运河区", "code": "130903000000"},
            {"area": "沧县", "code": "130921000000"},
            {"area": "青县", "code": "130922000000"},
            {"area": "东光县", "code": "130923000000"},
            {"area": "海兴县", "code": "130924000000"},
            {"area": "盐山县", "code": "130925000000"},
            {"area": "肃宁县", "code": "130926000000"},
            {"area": "南皮县", "code": "130927000000"},
            {"area": "吴桥县", "code": "130928000000"},
            {"area": "献县", "code": "130929000000"},
            {"area": "孟村回族自治县", "code": "130930000000"},
            {"area": "河北沧州经济开发区", "code": "130971000000"},
            {"area": "沧州高新技术产业开发区", "code": "130972000000"},
            {"area": "沧州渤海新区", "code": "130973000000"},
            {"area": "泊头市", "code": "130981000000"},
            {"area": "任丘市", "code": "130982000000"},
            {"area": "黄骅市", "code": "130983000000"},
            {"area": "河间市", "code": "130984000000"}
          ]
        },
        {
          "city": "廊坊市",
          "code": "131000000000",
          "areas": [
            {"area": "安次区", "code": "131002000000"},
            {"area": "广阳区", "code": "131003000000"},
            {"area": "固安县", "code": "131022000000"},
            {"area": "永清县", "code": "131023000000"},
            {"area": "香河县", "code": "131024000000"},
            {"area": "大城县", "code": "131025000000"},
            {"area": "文安县", "code": "131026000000"},
            {"area": "大厂回族自治县", "code": "131028000000"},
            {"area": "廊坊经济技术开发区", "code": "131071000000"},
            {"area": "霸州市", "code": "131081000000"},
            {"area": "三河市", "code": "131082000000"}
          ]
        },
        {
          "city": "衡水市",
          "code": "131100000000",
          "areas": [
            {"area": "桃城区", "code": "131102000000"},
            {"area": "冀州区", "code": "131103000000"},
            {"area": "枣强县", "code": "131121000000"},
            {"area": "武邑县", "code": "131122000000"},
            {"area": "武强县", "code": "131123000000"},
            {"area": "饶阳县", "code": "131124000000"},
            {"area": "安平县", "code": "131125000000"},
            {"area": "故城县", "code": "131126000000"},
            {"area": "景县", "code": "131127000000"},
            {"area": "阜城县", "code": "131128000000"},
            {"area": "河北衡水高新技术产业开发区", "code": "131171000000"},
            {"area": "衡水滨湖新区", "code": "131172000000"},
            {"area": "深州市", "code": "131182000000"}
          ]
        },
        {
          "city": "雄安新区",
          "code": "133100000000",
          "areas": [
            {"area": "雄安新区", "code": "133100000000"}
          ]
        }
      ]
    },
    {
      "province": "山西省",
      "code": "140000",
      "citys": [
        {
          "city": "太原市",
          "code": "140100000000",
          "areas": [
            {"area": "小店区", "code": "140105000000"},
            {"area": "迎泽区", "code": "140106000000"},
            {"area": "杏花岭区", "code": "140107000000"},
            {"area": "尖草坪区", "code": "140108000000"},
            {"area": "万柏林区", "code": "140109000000"},
            {"area": "晋源区", "code": "140110000000"},
            {"area": "清徐县", "code": "140121000000"},
            {"area": "阳曲县", "code": "140122000000"},
            {"area": "娄烦县", "code": "140123000000"},
            {"area": "山西转型综合改革示范区", "code": "140171000000"},
            {"area": "古交市", "code": "140181000000"}
          ]
        },
        {
          "city": "大同市",
          "code": "140200000000",
          "areas": [
            {"area": "新荣区", "code": "140212000000"},
            {"area": "平城区", "code": "140213000000"},
            {"area": "云冈区", "code": "140214000000"},
            {"area": "云州区", "code": "140215000000"},
            {"area": "阳高县", "code": "140221000000"},
            {"area": "天镇县", "code": "140222000000"},
            {"area": "广灵县", "code": "140223000000"},
            {"area": "灵丘县", "code": "140224000000"},
            {"area": "浑源县", "code": "140225000000"},
            {"area": "左云县", "code": "140226000000"},
            {"area": "山西大同经济开发区", "code": "140271000000"}
          ]
        },
        {
          "city": "阳泉市",
          "code": "140300000000",
          "areas": [
            {"area": "城区", "code": "140302000000"},
            {"area": "矿区", "code": "140303000000"},
            {"area": "郊区", "code": "140311000000"},
            {"area": "平定县", "code": "140321000000"},
            {"area": "盂县", "code": "140322000000"}
          ]
        },
        {
          "city": "长治市",
          "code": "140400000000",
          "areas": [
            {"area": "潞州区", "code": "140403000000"},
            {"area": "上党区", "code": "140404000000"},
            {"area": "屯留区", "code": "140405000000"},
            {"area": "潞城区", "code": "140406000000"},
            {"area": "襄垣县", "code": "140423000000"},
            {"area": "平顺县", "code": "140425000000"},
            {"area": "黎城县", "code": "140426000000"},
            {"area": "壶关县", "code": "140427000000"},
            {"area": "长子县", "code": "140428000000"},
            {"area": "武乡县", "code": "140429000000"},
            {"area": "沁县", "code": "140430000000"},
            {"area": "沁源县", "code": "140431000000"}
          ]
        },
        {
          "city": "晋城市",
          "code": "140500000000",
          "areas": [
            {"area": "城区", "code": "140502000000"},
            {"area": "沁水县", "code": "140521000000"},
            {"area": "阳城县", "code": "140522000000"},
            {"area": "陵川县", "code": "140524000000"},
            {"area": "泽州县", "code": "140525000000"},
            {"area": "高平市", "code": "140581000000"}
          ]
        },
        {
          "city": "朔州市",
          "code": "140600000000",
          "areas": [
            {"area": "朔城区", "code": "140602000000"},
            {"area": "平鲁区", "code": "140603000000"},
            {"area": "山阴县", "code": "140621000000"},
            {"area": "应县", "code": "140622000000"},
            {"area": "右玉县", "code": "140623000000"},
            {"area": "山西朔州经济开发区", "code": "140671000000"},
            {"area": "怀仁市", "code": "140681000000"}
          ]
        },
        {
          "city": "晋中市",
          "code": "140700000000",
          "areas": [
            {"area": "榆次区", "code": "140702000000"},
            {"area": "太谷区", "code": "140703000000"},
            {"area": "榆社县", "code": "140721000000"},
            {"area": "左权县", "code": "140722000000"},
            {"area": "和顺县", "code": "140723000000"},
            {"area": "昔阳县", "code": "140724000000"},
            {"area": "寿阳县", "code": "140725000000"},
            {"area": "祁县", "code": "140727000000"},
            {"area": "平遥县", "code": "140728000000"},
            {"area": "灵石县", "code": "140729000000"},
            {"area": "介休市", "code": "140781000000"}
          ]
        },
        {
          "city": "运城市",
          "code": "140800000000",
          "areas": [
            {"area": "盐湖区", "code": "140802000000"},
            {"area": "临猗县", "code": "140821000000"},
            {"area": "万荣县", "code": "140822000000"},
            {"area": "闻喜县", "code": "140823000000"},
            {"area": "稷山县", "code": "140824000000"},
            {"area": "新绛县", "code": "140825000000"},
            {"area": "绛县", "code": "140826000000"},
            {"area": "垣曲县", "code": "140827000000"},
            {"area": "夏县", "code": "140828000000"},
            {"area": "平陆县", "code": "140829000000"},
            {"area": "芮城县", "code": "140830000000"},
            {"area": "永济市", "code": "140881000000"},
            {"area": "河津市", "code": "140882000000"}
          ]
        },
        {
          "city": "忻州市",
          "code": "140900000000",
          "areas": [
            {"area": "忻府区", "code": "140902000000"},
            {"area": "定襄县", "code": "140921000000"},
            {"area": "五台县", "code": "140922000000"},
            {"area": "代县", "code": "140923000000"},
            {"area": "繁峙县", "code": "140924000000"},
            {"area": "宁武县", "code": "140925000000"},
            {"area": "静乐县", "code": "140926000000"},
            {"area": "神池县", "code": "140927000000"},
            {"area": "五寨县", "code": "140928000000"},
            {"area": "岢岚县", "code": "140929000000"},
            {"area": "河曲县", "code": "140930000000"},
            {"area": "保德县", "code": "140931000000"},
            {"area": "偏关县", "code": "140932000000"},
            {"area": "五台山风景名胜区", "code": "140971000000"},
            {"area": "原平市", "code": "140981000000"}
          ]
        },
        {
          "city": "临汾市",
          "code": "141000000000",
          "areas": [
            {"area": "尧都区", "code": "141002000000"},
            {"area": "曲沃县", "code": "141021000000"},
            {"area": "翼城县", "code": "141022000000"},
            {"area": "襄汾县", "code": "141023000000"},
            {"area": "洪洞县", "code": "141024000000"},
            {"area": "古县", "code": "141025000000"},
            {"area": "安泽县", "code": "141026000000"},
            {"area": "浮山县", "code": "141027000000"},
            {"area": "吉县", "code": "141028000000"},
            {"area": "乡宁县", "code": "141029000000"},
            {"area": "大宁县", "code": "141030000000"},
            {"area": "隰县", "code": "141031000000"},
            {"area": "永和县", "code": "141032000000"},
            {"area": "蒲县", "code": "141033000000"},
            {"area": "汾西县", "code": "141034000000"},
            {"area": "侯马市", "code": "141081000000"},
            {"area": "霍州市", "code": "141082000000"}
          ]
        },
        {
          "city": "吕梁市",
          "code": "141100000000",
          "areas": [
            {"area": "离石区", "code": "141102000000"},
            {"area": "文水县", "code": "141121000000"},
            {"area": "交城县", "code": "141122000000"},
            {"area": "兴县", "code": "141123000000"},
            {"area": "临县", "code": "141124000000"},
            {"area": "柳林县", "code": "141125000000"},
            {"area": "石楼县", "code": "141126000000"},
            {"area": "岚县", "code": "141127000000"},
            {"area": "方山县", "code": "141128000000"},
            {"area": "中阳县", "code": "141129000000"},
            {"area": "交口县", "code": "141130000000"},
            {"area": "孝义市", "code": "141181000000"},
            {"area": "汾阳市", "code": "141182000000"}
          ]
        }
      ]
    },
    {
      "province": "内蒙古自治区",
      "code": "150000",
      "citys": [
        {
          "city": "呼和浩特市",
          "code": "150100000000",
          "areas": [
            {"area": "新城区", "code": "150102000000"},
            {"area": "回民区", "code": "150103000000"},
            {"area": "玉泉区", "code": "150104000000"},
            {"area": "赛罕区", "code": "150105000000"},
            {"area": "土默特左旗", "code": "150121000000"},
            {"area": "托克托县", "code": "150122000000"},
            {"area": "和林格尔县", "code": "150123000000"},
            {"area": "清水河县", "code": "150124000000"},
            {"area": "武川县", "code": "150125000000"},
            {"area": "呼和浩特经济技术开发区", "code": "150172000000"}
          ]
        },
        {
          "city": "包头市",
          "code": "150200000000",
          "areas": [
            {"area": "东河区", "code": "150202000000"},
            {"area": "昆都仑区", "code": "150203000000"},
            {"area": "青山区", "code": "150204000000"},
            {"area": "石拐区", "code": "150205000000"},
            {"area": "白云鄂博矿区", "code": "150206000000"},
            {"area": "九原区", "code": "150207000000"},
            {"area": "土默特右旗", "code": "150221000000"},
            {"area": "固阳县", "code": "150222000000"},
            {"area": "达尔罕茂明安联合旗", "code": "150223000000"},
            {"area": "包头稀土高新技术产业开发区", "code": "150271000000"}
          ]
        },
        {
          "city": "乌海市",
          "code": "150300000000",
          "areas": [
            {"area": "海勃湾区", "code": "150302000000"},
            {"area": "海南区", "code": "150303000000"},
            {"area": "乌达区", "code": "150304000000"}
          ]
        },
        {
          "city": "赤峰市",
          "code": "150400000000",
          "areas": [
            {"area": "红山区", "code": "150402000000"},
            {"area": "元宝山区", "code": "150403000000"},
            {"area": "松山区", "code": "150404000000"},
            {"area": "阿鲁科尔沁旗", "code": "150421000000"},
            {"area": "巴林左旗", "code": "150422000000"},
            {"area": "巴林右旗", "code": "150423000000"},
            {"area": "林西县", "code": "150424000000"},
            {"area": "克什克腾旗", "code": "150425000000"},
            {"area": "翁牛特旗", "code": "150426000000"},
            {"area": "喀喇沁旗", "code": "150428000000"},
            {"area": "宁城县", "code": "150429000000"},
            {"area": "敖汉旗", "code": "150430000000"}
          ]
        },
        {
          "city": "通辽市",
          "code": "150500000000",
          "areas": [
            {"area": "科尔沁区", "code": "150502000000"},
            {"area": "科尔沁左翼中旗", "code": "150521000000"},
            {"area": "科尔沁左翼后旗", "code": "150522000000"},
            {"area": "开鲁县", "code": "150523000000"},
            {"area": "库伦旗", "code": "150524000000"},
            {"area": "奈曼旗", "code": "150525000000"},
            {"area": "扎鲁特旗", "code": "150526000000"},
            {"area": "通辽经济技术开发区", "code": "150571000000"},
            {"area": "霍林郭勒市", "code": "150581000000"}
          ]
        },
        {
          "city": "鄂尔多斯市",
          "code": "150600000000",
          "areas": [
            {"area": "东胜区", "code": "150602000000"},
            {"area": "康巴什区", "code": "150603000000"},
            {"area": "达拉特旗", "code": "150621000000"},
            {"area": "准格尔旗", "code": "150622000000"},
            {"area": "鄂托克前旗", "code": "150623000000"},
            {"area": "鄂托克旗", "code": "150624000000"},
            {"area": "杭锦旗", "code": "150625000000"},
            {"area": "乌审旗", "code": "150626000000"},
            {"area": "伊金霍洛旗", "code": "150627000000"}
          ]
        },
        {
          "city": "呼伦贝尔市",
          "code": "150700000000",
          "areas": [
            {"area": "海拉尔区", "code": "150702000000"},
            {"area": "扎赉诺尔区", "code": "150703000000"},
            {"area": "阿荣旗", "code": "150721000000"},
            {"area": "莫力达瓦达斡尔族自治旗", "code": "150722000000"},
            {"area": "鄂伦春自治旗", "code": "150723000000"},
            {"area": "鄂温克族自治旗", "code": "150724000000"},
            {"area": "陈巴尔虎旗", "code": "150725000000"},
            {"area": "新巴尔虎左旗", "code": "150726000000"},
            {"area": "新巴尔虎右旗", "code": "150727000000"},
            {"area": "满洲里市", "code": "150781000000"},
            {"area": "牙克石市", "code": "150782000000"},
            {"area": "扎兰屯市", "code": "150783000000"},
            {"area": "额尔古纳市", "code": "150784000000"},
            {"area": "根河市", "code": "150785000000"}
          ]
        },
        {
          "city": "巴彦淖尔市",
          "code": "150800000000",
          "areas": [
            {"area": "临河区", "code": "150802000000"},
            {"area": "五原县", "code": "150821000000"},
            {"area": "磴口县", "code": "150822000000"},
            {"area": "乌拉特前旗", "code": "150823000000"},
            {"area": "乌拉特中旗", "code": "150824000000"},
            {"area": "乌拉特后旗", "code": "150825000000"},
            {"area": "杭锦后旗", "code": "150826000000"}
          ]
        },
        {
          "city": "乌兰察布市",
          "code": "150900000000",
          "areas": [
            {"area": "集宁区", "code": "150902000000"},
            {"area": "卓资县", "code": "150921000000"},
            {"area": "化德县", "code": "150922000000"},
            {"area": "商都县", "code": "150923000000"},
            {"area": "兴和县", "code": "150924000000"},
            {"area": "凉城县", "code": "150925000000"},
            {"area": "察哈尔右翼前旗", "code": "150926000000"},
            {"area": "察哈尔右翼中旗", "code": "150927000000"},
            {"area": "察哈尔右翼后旗", "code": "150928000000"},
            {"area": "四子王旗", "code": "150929000000"},
            {"area": "丰镇市", "code": "150981000000"}
          ]
        },
        {
          "city": "兴安盟",
          "code": "152200000000",
          "areas": [
            {"area": "乌兰浩特市", "code": "152201000000"},
            {"area": "阿尔山市", "code": "152202000000"},
            {"area": "科尔沁右翼前旗", "code": "152221000000"},
            {"area": "科尔沁右翼中旗", "code": "152222000000"},
            {"area": "扎赉特旗", "code": "152223000000"},
            {"area": "突泉县", "code": "152224000000"}
          ]
        },
        {
          "city": "锡林郭勒盟",
          "code": "152500000000",
          "areas": [
            {"area": "二连浩特市", "code": "152501000000"},
            {"area": "锡林浩特市", "code": "152502000000"},
            {"area": "阿巴嘎旗", "code": "152522000000"},
            {"area": "苏尼特左旗", "code": "152523000000"},
            {"area": "苏尼特右旗", "code": "152524000000"},
            {"area": "东乌珠穆沁旗", "code": "152525000000"},
            {"area": "西乌珠穆沁旗", "code": "152526000000"},
            {"area": "太仆寺旗", "code": "152527000000"},
            {"area": "镶黄旗", "code": "152528000000"},
            {"area": "正镶白旗", "code": "152529000000"},
            {"area": "正蓝旗", "code": "152530000000"},
            {"area": "多伦县", "code": "152531000000"},
            {"area": "乌拉盖管理区管委会", "code": "152571000000"}
          ]
        },
        {
          "city": "阿拉善盟",
          "code": "152900000000",
          "areas": [
            {"area": "阿拉善左旗", "code": "152921000000"},
            {"area": "阿拉善右旗", "code": "152922000000"},
            {"area": "额济纳旗", "code": "152923000000"},
            {"area": "内蒙古阿拉善高新技术产业开发区", "code": "152971000000"}
          ]
        }
      ]
    },
    {
      "province": "辽宁省",
      "code": "210000",
      "citys": [
        {
          "city": "沈阳市",
          "code": "210100000000",
          "areas": [
            {"area": "和平区", "code": "210102000000"},
            {"area": "沈河区", "code": "210103000000"},
            {"area": "大东区", "code": "210104000000"},
            {"area": "皇姑区", "code": "210105000000"},
            {"area": "铁西区", "code": "210106000000"},
            {"area": "苏家屯区", "code": "210111000000"},
            {"area": "浑南区", "code": "210112000000"},
            {"area": "沈北新区", "code": "210113000000"},
            {"area": "于洪区", "code": "210114000000"},
            {"area": "辽中区", "code": "210115000000"},
            {"area": "康平县", "code": "210123000000"},
            {"area": "法库县", "code": "210124000000"},
            {"area": "新民市", "code": "210181000000"}
          ]
        },
        {
          "city": "大连市",
          "code": "210200000000",
          "areas": [
            {"area": "中山区", "code": "210202000000"},
            {"area": "西岗区", "code": "210203000000"},
            {"area": "沙河口区", "code": "210204000000"},
            {"area": "甘井子区", "code": "210211000000"},
            {"area": "旅顺口区", "code": "210212000000"},
            {"area": "金州区", "code": "210213000000"},
            {"area": "普兰店区", "code": "210214000000"},
            {"area": "长海县", "code": "210224000000"},
            {"area": "瓦房店市", "code": "210281000000"},
            {"area": "庄河市", "code": "210283000000"}
          ]
        },
        {
          "city": "鞍山市",
          "code": "210300000000",
          "areas": [
            {"area": "铁东区", "code": "210302000000"},
            {"area": "铁西区", "code": "210303000000"},
            {"area": "立山区", "code": "210304000000"},
            {"area": "千山区", "code": "210311000000"},
            {"area": "台安县", "code": "210321000000"},
            {"area": "岫岩满族自治县", "code": "210323000000"},
            {"area": "海城市", "code": "210381000000"}
          ]
        },
        {
          "city": "抚顺市",
          "code": "210400000000",
          "areas": [
            {"area": "新抚区", "code": "210402000000"},
            {"area": "东洲区", "code": "210403000000"},
            {"area": "望花区", "code": "210404000000"},
            {"area": "顺城区", "code": "210411000000"},
            {"area": "抚顺县", "code": "210421000000"},
            {"area": "新宾满族自治县", "code": "210422000000"},
            {"area": "清原满族自治县", "code": "210423000000"}
          ]
        },
        {
          "city": "本溪市",
          "code": "210500000000",
          "areas": [
            {"area": "平山区", "code": "210502000000"},
            {"area": "溪湖区", "code": "210503000000"},
            {"area": "明山区", "code": "210504000000"},
            {"area": "南芬区", "code": "210505000000"},
            {"area": "本溪满族自治县", "code": "210521000000"},
            {"area": "桓仁满族自治县", "code": "210522000000"}
          ]
        },
        {
          "city": "丹东市",
          "code": "210600000000",
          "areas": [
            {"area": "元宝区", "code": "210602000000"},
            {"area": "振兴区", "code": "210603000000"},
            {"area": "振安区", "code": "210604000000"},
            {"area": "宽甸满族自治县", "code": "210624000000"},
            {"area": "东港市", "code": "210681000000"},
            {"area": "凤城市", "code": "210682000000"}
          ]
        },
        {
          "city": "锦州市",
          "code": "210700000000",
          "areas": [
            {"area": "古塔区", "code": "210702000000"},
            {"area": "凌河区", "code": "210703000000"},
            {"area": "太和区", "code": "210711000000"},
            {"area": "黑山县", "code": "210726000000"},
            {"area": "义县", "code": "210727000000"},
            {"area": "凌海市", "code": "210781000000"},
            {"area": "北镇市", "code": "210782000000"}
          ]
        },
        {
          "city": "营口市",
          "code": "210800000000",
          "areas": [
            {"area": "站前区", "code": "210802000000"},
            {"area": "西市区", "code": "210803000000"},
            {"area": "鲅鱼圈区", "code": "210804000000"},
            {"area": "老边区", "code": "210811000000"},
            {"area": "盖州市", "code": "210881000000"},
            {"area": "大石桥市", "code": "210882000000"}
          ]
        },
        {
          "city": "阜新市",
          "code": "210900000000",
          "areas": [
            {"area": "海州区", "code": "210902000000"},
            {"area": "新邱区", "code": "210903000000"},
            {"area": "太平区", "code": "210904000000"},
            {"area": "清河门区", "code": "210905000000"},
            {"area": "细河区", "code": "210911000000"},
            {"area": "阜新蒙古族自治县", "code": "210921000000"},
            {"area": "彰武县", "code": "210922000000"}
          ]
        },
        {
          "city": "辽阳市",
          "code": "211000000000",
          "areas": [
            {"area": "白塔区", "code": "211002000000"},
            {"area": "文圣区", "code": "211003000000"},
            {"area": "宏伟区", "code": "211004000000"},
            {"area": "弓长岭区", "code": "211005000000"},
            {"area": "太子河区", "code": "211011000000"},
            {"area": "辽阳县", "code": "211021000000"},
            {"area": "灯塔市", "code": "211081000000"}
          ]
        },
        {
          "city": "盘锦市",
          "code": "211100000000",
          "areas": [
            {"area": "双台子区", "code": "211102000000"},
            {"area": "兴隆台区", "code": "211103000000"},
            {"area": "大洼区", "code": "211104000000"},
            {"area": "盘山县", "code": "211122000000"}
          ]
        },
        {
          "city": "铁岭市",
          "code": "211200000000",
          "areas": [
            {"area": "银州区", "code": "211202000000"},
            {"area": "清河区", "code": "211204000000"},
            {"area": "铁岭县", "code": "211221000000"},
            {"area": "西丰县", "code": "211223000000"},
            {"area": "昌图县", "code": "211224000000"},
            {"area": "调兵山市", "code": "211281000000"},
            {"area": "开原市", "code": "211282000000"}
          ]
        },
        {
          "city": "朝阳市",
          "code": "211300000000",
          "areas": [
            {"area": "双塔区", "code": "211302000000"},
            {"area": "龙城区", "code": "211303000000"},
            {"area": "朝阳县", "code": "211321000000"},
            {"area": "建平县", "code": "211322000000"},
            {"area": "喀喇沁左翼蒙古族自治县", "code": "211324000000"},
            {"area": "北票市", "code": "211381000000"},
            {"area": "凌源市", "code": "211382000000"}
          ]
        },
        {
          "city": "葫芦岛市",
          "code": "211400000000",
          "areas": [
            {"area": "连山区", "code": "211402000000"},
            {"area": "龙港区", "code": "211403000000"},
            {"area": "南票区", "code": "211404000000"},
            {"area": "绥中县", "code": "211421000000"},
            {"area": "建昌县", "code": "211422000000"},
            {"area": "兴城市", "code": "211481000000"}
          ]
        }
      ]
    },
    {
      "province": "吉林省",
      "code": "220000",
      "citys": [
        {
          "city": "长春市",
          "code": "220100000000",
          "areas": [
            {"area": "南关区", "code": "220102000000"},
            {"area": "宽城区", "code": "220103000000"},
            {"area": "朝阳区", "code": "220104000000"},
            {"area": "二道区", "code": "220105000000"},
            {"area": "绿园区", "code": "220106000000"},
            {"area": "双阳区", "code": "220112000000"},
            {"area": "九台区", "code": "220113000000"},
            {"area": "农安县", "code": "220122000000"},
            {"area": "长春经济技术开发区", "code": "220171000000"},
            {"area": "长春净月高新技术产业开发区", "code": "220172000000"},
            {"area": "长春高新技术产业开发区", "code": "220173000000"},
            {"area": "长春汽车经济技术开发区", "code": "220174000000"},
            {"area": "榆树市", "code": "220182000000"},
            {"area": "德惠市", "code": "220183000000"},
            {"area": "公主岭市", "code": "220184000000"}
          ]
        },
        {
          "city": "吉林市",
          "code": "220200000000",
          "areas": [
            {"area": "昌邑区", "code": "220202000000"},
            {"area": "龙潭区", "code": "220203000000"},
            {"area": "船营区", "code": "220204000000"},
            {"area": "丰满区", "code": "220211000000"},
            {"area": "永吉县", "code": "220221000000"},
            {"area": "吉林经济开发区", "code": "220271000000"},
            {"area": "吉林高新技术产业开发区", "code": "220272000000"},
            {"area": "吉林中国新加坡食品区", "code": "220273000000"},
            {"area": "蛟河市", "code": "220281000000"},
            {"area": "桦甸市", "code": "220282000000"},
            {"area": "舒兰市", "code": "220283000000"},
            {"area": "磐石市", "code": "220284000000"}
          ]
        },
        {
          "city": "四平市",
          "code": "220300000000",
          "areas": [
            {"area": "铁西区", "code": "220302000000"},
            {"area": "铁东区", "code": "220303000000"},
            {"area": "梨树县", "code": "220322000000"},
            {"area": "伊通满族自治县", "code": "220323000000"},
            {"area": "双辽市", "code": "220382000000"}
          ]
        },
        {
          "city": "辽源市",
          "code": "220400000000",
          "areas": [
            {"area": "龙山区", "code": "220402000000"},
            {"area": "西安区", "code": "220403000000"},
            {"area": "东丰县", "code": "220421000000"},
            {"area": "东辽县", "code": "220422000000"}
          ]
        },
        {
          "city": "通化市",
          "code": "220500000000",
          "areas": [
            {"area": "东昌区", "code": "220502000000"},
            {"area": "二道江区", "code": "220503000000"},
            {"area": "通化县", "code": "220521000000"},
            {"area": "辉南县", "code": "220523000000"},
            {"area": "柳河县", "code": "220524000000"},
            {"area": "梅河口市", "code": "220581000000"},
            {"area": "集安市", "code": "220582000000"}
          ]
        },
        {
          "city": "白山市",
          "code": "220600000000",
          "areas": [
            {"area": "浑江区", "code": "220602000000"},
            {"area": "江源区", "code": "220605000000"},
            {"area": "抚松县", "code": "220621000000"},
            {"area": "靖宇县", "code": "220622000000"},
            {"area": "长白朝鲜族自治县", "code": "220623000000"},
            {"area": "临江市", "code": "220681000000"}
          ]
        },
        {
          "city": "松原市",
          "code": "220700000000",
          "areas": [
            {"area": "宁江区", "code": "220702000000"},
            {"area": "前郭尔罗斯蒙古族自治县", "code": "220721000000"},
            {"area": "长岭县", "code": "220722000000"},
            {"area": "乾安县", "code": "220723000000"},
            {"area": "吉林松原经济开发区", "code": "220771000000"},
            {"area": "扶余市", "code": "220781000000"}
          ]
        },
        {
          "city": "白城市",
          "code": "220800000000",
          "areas": [
            {"area": "洮北区", "code": "220802000000"},
            {"area": "镇赉县", "code": "220821000000"},
            {"area": "通榆县", "code": "220822000000"},
            {"area": "吉林白城经济开发区", "code": "220871000000"},
            {"area": "洮南市", "code": "220881000000"},
            {"area": "大安市", "code": "220882000000"}
          ]
        },
        {
          "city": "延边朝鲜族自治州",
          "code": "222400000000",
          "areas": [
            {"area": "延吉市", "code": "222401000000"},
            {"area": "图们市", "code": "222402000000"},
            {"area": "敦化市", "code": "222403000000"},
            {"area": "珲春市", "code": "222404000000"},
            {"area": "龙井市", "code": "222405000000"},
            {"area": "和龙市", "code": "222406000000"},
            {"area": "汪清县", "code": "222424000000"},
            {"area": "安图县", "code": "222426000000"}
          ]
        }
      ]
    },
    {
      "province": "黑龙江省",
      "code": "230000",
      "citys": [
        {
          "city": "哈尔滨市",
          "code": "230100000000",
          "areas": [
            {"area": "道里区", "code": "230102000000"},
            {"area": "南岗区", "code": "230103000000"},
            {"area": "道外区", "code": "230104000000"},
            {"area": "平房区", "code": "230108000000"},
            {"area": "松北区", "code": "230109000000"},
            {"area": "香坊区", "code": "230110000000"},
            {"area": "呼兰区", "code": "230111000000"},
            {"area": "阿城区", "code": "230112000000"},
            {"area": "双城区", "code": "230113000000"},
            {"area": "依兰县", "code": "230123000000"},
            {"area": "方正县", "code": "230124000000"},
            {"area": "宾县", "code": "230125000000"},
            {"area": "巴彦县", "code": "230126000000"},
            {"area": "木兰县", "code": "230127000000"},
            {"area": "通河县", "code": "230128000000"},
            {"area": "延寿县", "code": "230129000000"},
            {"area": "尚志市", "code": "230183000000"},
            {"area": "五常市", "code": "230184000000"}
          ]
        },
        {
          "city": "齐齐哈尔市",
          "code": "230200000000",
          "areas": [
            {"area": "龙沙区", "code": "230202000000"},
            {"area": "建华区", "code": "230203000000"},
            {"area": "铁锋区", "code": "230204000000"},
            {"area": "昂昂溪区", "code": "230205000000"},
            {"area": "富拉尔基区", "code": "230206000000"},
            {"area": "碾子山区", "code": "230207000000"},
            {"area": "梅里斯达斡尔族区", "code": "230208000000"},
            {"area": "龙江县", "code": "230221000000"},
            {"area": "依安县", "code": "230223000000"},
            {"area": "泰来县", "code": "230224000000"},
            {"area": "甘南县", "code": "230225000000"},
            {"area": "富裕县", "code": "230227000000"},
            {"area": "克山县", "code": "230229000000"},
            {"area": "克东县", "code": "230230000000"},
            {"area": "拜泉县", "code": "230231000000"},
            {"area": "讷河市", "code": "230281000000"}
          ]
        },
        {
          "city": "鸡西市",
          "code": "230300000000",
          "areas": [
            {"area": "鸡冠区", "code": "230302000000"},
            {"area": "恒山区", "code": "230303000000"},
            {"area": "滴道区", "code": "230304000000"},
            {"area": "梨树区", "code": "230305000000"},
            {"area": "城子河区", "code": "230306000000"},
            {"area": "麻山区", "code": "230307000000"},
            {"area": "鸡东县", "code": "230321000000"},
            {"area": "虎林市", "code": "230381000000"},
            {"area": "密山市", "code": "230382000000"}
          ]
        },
        {
          "city": "鹤岗市",
          "code": "230400000000",
          "areas": [
            {"area": "向阳区", "code": "230402000000"},
            {"area": "工农区", "code": "230403000000"},
            {"area": "南山区", "code": "230404000000"},
            {"area": "兴安区", "code": "230405000000"},
            {"area": "东山区", "code": "230406000000"},
            {"area": "兴山区", "code": "230407000000"},
            {"area": "萝北县", "code": "230421000000"},
            {"area": "绥滨县", "code": "230422000000"}
          ]
        },
        {
          "city": "双鸭山市",
          "code": "230500000000",
          "areas": [
            {"area": "尖山区", "code": "230502000000"},
            {"area": "岭东区", "code": "230503000000"},
            {"area": "四方台区", "code": "230505000000"},
            {"area": "宝山区", "code": "230506000000"},
            {"area": "集贤县", "code": "230521000000"},
            {"area": "友谊县", "code": "230522000000"},
            {"area": "宝清县", "code": "230523000000"},
            {"area": "饶河县", "code": "230524000000"}
          ]
        },
        {
          "city": "大庆市",
          "code": "230600000000",
          "areas": [
            {"area": "萨尔图区", "code": "230602000000"},
            {"area": "龙凤区", "code": "230603000000"},
            {"area": "让胡路区", "code": "230604000000"},
            {"area": "红岗区", "code": "230605000000"},
            {"area": "大同区", "code": "230606000000"},
            {"area": "肇州县", "code": "230621000000"},
            {"area": "肇源县", "code": "230622000000"},
            {"area": "林甸县", "code": "230623000000"},
            {"area": "杜尔伯特蒙古族自治县", "code": "230624000000"},
            {"area": "大庆高新技术产业开发区", "code": "230671000000"}
          ]
        },
        {
          "city": "伊春市",
          "code": "230700000000",
          "areas": [
            {"area": "伊美区", "code": "230717000000"},
            {"area": "乌翠区", "code": "230718000000"},
            {"area": "友好区", "code": "230719000000"},
            {"area": "嘉荫县", "code": "230722000000"},
            {"area": "汤旺县", "code": "230723000000"},
            {"area": "丰林县", "code": "230724000000"},
            {"area": "大箐山县", "code": "230725000000"},
            {"area": "南岔县", "code": "230726000000"},
            {"area": "金林区", "code": "230751000000"},
            {"area": "铁力市", "code": "230781000000"}
          ]
        },
        {
          "city": "佳木斯市",
          "code": "230800000000",
          "areas": [
            {"area": "向阳区", "code": "230803000000"},
            {"area": "前进区", "code": "230804000000"},
            {"area": "东风区", "code": "230805000000"},
            {"area": "郊区", "code": "230811000000"},
            {"area": "桦南县", "code": "230822000000"},
            {"area": "桦川县", "code": "230826000000"},
            {"area": "汤原县", "code": "230828000000"},
            {"area": "同江市", "code": "230881000000"},
            {"area": "富锦市", "code": "230882000000"},
            {"area": "抚远市", "code": "230883000000"}
          ]
        },
        {
          "city": "七台河市",
          "code": "230900000000",
          "areas": [
            {"area": "新兴区", "code": "230902000000"},
            {"area": "桃山区", "code": "230903000000"},
            {"area": "茄子河区", "code": "230904000000"},
            {"area": "勃利县", "code": "230921000000"}
          ]
        },
        {
          "city": "牡丹江市",
          "code": "231000000000",
          "areas": [
            {"area": "东安区", "code": "231002000000"},
            {"area": "阳明区", "code": "231003000000"},
            {"area": "爱民区", "code": "231004000000"},
            {"area": "西安区", "code": "231005000000"},
            {"area": "林口县", "code": "231025000000"},
            {"area": "绥芬河市", "code": "231081000000"},
            {"area": "海林市", "code": "231083000000"},
            {"area": "宁安市", "code": "231084000000"},
            {"area": "穆棱市", "code": "231085000000"},
            {"area": "东宁市", "code": "231086000000"}
          ]
        },
        {
          "city": "黑河市",
          "code": "231100000000",
          "areas": [
            {"area": "爱辉区", "code": "231102000000"},
            {"area": "逊克县", "code": "231123000000"},
            {"area": "孙吴县", "code": "231124000000"},
            {"area": "北安市", "code": "231181000000"},
            {"area": "五大连池市", "code": "231182000000"},
            {"area": "嫩江市", "code": "231183000000"}
          ]
        },
        {
          "city": "绥化市",
          "code": "231200000000",
          "areas": [
            {"area": "北林区", "code": "231202000000"},
            {"area": "望奎县", "code": "231221000000"},
            {"area": "兰西县", "code": "231222000000"},
            {"area": "青冈县", "code": "231223000000"},
            {"area": "庆安县", "code": "231224000000"},
            {"area": "明水县", "code": "231225000000"},
            {"area": "绥棱县", "code": "231226000000"},
            {"area": "安达市", "code": "231281000000"},
            {"area": "肇东市", "code": "231282000000"},
            {"area": "海伦市", "code": "231283000000"}
          ]
        },
        {
          "city": "大兴安岭地区",
          "code": "232700000000",
          "areas": [
            {"area": "漠河市", "code": "232701000000"},
            {"area": "呼玛县", "code": "232721000000"},
            {"area": "塔河县", "code": "232722000000"},
            {"area": "加格达奇区", "code": "232761000000"},
            {"area": "松岭区", "code": "232762000000"},
            {"area": "新林区", "code": "232763000000"},
            {"area": "呼中区", "code": "232764000000"}
          ]
        }
      ]
    },
    {
      "province": "上海市",
      "code": "310000",
      "citys": [
        {
          "city": "上海市",
          "code": "310100000000",
          "areas": [
            {"area": "黄浦区", "code": "310101000000"},
            {"area": "徐汇区", "code": "310104000000"},
            {"area": "长宁区", "code": "310105000000"},
            {"area": "静安区", "code": "310106000000"},
            {"area": "普陀区", "code": "310107000000"},
            {"area": "虹口区", "code": "310109000000"},
            {"area": "杨浦区", "code": "310110000000"},
            {"area": "闵行区", "code": "310112000000"},
            {"area": "宝山区", "code": "310113000000"},
            {"area": "嘉定区", "code": "310114000000"},
            {"area": "浦东新区", "code": "310115000000"},
            {"area": "金山区", "code": "310116000000"},
            {"area": "松江区", "code": "310117000000"},
            {"area": "青浦区", "code": "310118000000"},
            {"area": "奉贤区", "code": "310120000000"},
            {"area": "崇明区", "code": "310151000000"}
          ]
        }
      ]
    },
    {
      "province": "江苏省",
      "code": "320000",
      "citys": [
        {
          "city": "南京市",
          "code": "320100000000",
          "areas": [
            {"area": "玄武区", "code": "320102000000"},
            {"area": "秦淮区", "code": "320104000000"},
            {"area": "建邺区", "code": "320105000000"},
            {"area": "鼓楼区", "code": "320106000000"},
            {"area": "浦口区", "code": "320111000000"},
            {"area": "栖霞区", "code": "320113000000"},
            {"area": "雨花台区", "code": "320114000000"},
            {"area": "江宁区", "code": "320115000000"},
            {"area": "六合区", "code": "320116000000"},
            {"area": "溧水区", "code": "320117000000"},
            {"area": "高淳区", "code": "320118000000"}
          ]
        },
        {
          "city": "无锡市",
          "code": "320200000000",
          "areas": [
            {"area": "锡山区", "code": "320205000000"},
            {"area": "惠山区", "code": "320206000000"},
            {"area": "滨湖区", "code": "320211000000"},
            {"area": "梁溪区", "code": "320213000000"},
            {"area": "新吴区", "code": "320214000000"},
            {"area": "江阴市", "code": "320281000000"},
            {"area": "宜兴市", "code": "320282000000"}
          ]
        },
        {
          "city": "徐州市",
          "code": "320300000000",
          "areas": [
            {"area": "鼓楼区", "code": "320302000000"},
            {"area": "云龙区", "code": "320303000000"},
            {"area": "贾汪区", "code": "320305000000"},
            {"area": "泉山区", "code": "320311000000"},
            {"area": "铜山区", "code": "320312000000"},
            {"area": "丰县", "code": "320321000000"},
            {"area": "沛县", "code": "320322000000"},
            {"area": "睢宁县", "code": "320324000000"},
            {"area": "徐州经济技术开发区", "code": "320371000000"},
            {"area": "新沂市", "code": "320381000000"},
            {"area": "邳州市", "code": "320382000000"}
          ]
        },
        {
          "city": "常州市",
          "code": "320400000000",
          "areas": [
            {"area": "天宁区", "code": "320402000000"},
            {"area": "钟楼区", "code": "320404000000"},
            {"area": "新北区", "code": "320411000000"},
            {"area": "武进区", "code": "320412000000"},
            {"area": "金坛区", "code": "320413000000"},
            {"area": "溧阳市", "code": "320481000000"}
          ]
        },
        {
          "city": "苏州市",
          "code": "320500000000",
          "areas": [
            {"area": "虎丘区", "code": "320505000000"},
            {"area": "吴中区", "code": "320506000000"},
            {"area": "相城区", "code": "320507000000"},
            {"area": "姑苏区", "code": "320508000000"},
            {"area": "吴江区", "code": "320509000000"},
            {"area": "苏州工业园区", "code": "320576000000"},
            {"area": "常熟市", "code": "320581000000"},
            {"area": "张家港市", "code": "320582000000"},
            {"area": "昆山市", "code": "320583000000"},
            {"area": "太仓市", "code": "320585000000"}
          ]
        },
        {
          "city": "南通市",
          "code": "320600000000",
          "areas": [
            {"area": "通州区", "code": "320612000000"},
            {"area": "崇川区", "code": "320613000000"},
            {"area": "海门区", "code": "320614000000"},
            {"area": "如东县", "code": "320623000000"},
            {"area": "南通经济技术开发区", "code": "320671000000"},
            {"area": "启东市", "code": "320681000000"},
            {"area": "如皋市", "code": "320682000000"},
            {"area": "海安市", "code": "320685000000"}
          ]
        },
        {
          "city": "连云港市",
          "code": "320700000000",
          "areas": [
            {"area": "连云区", "code": "320703000000"},
            {"area": "海州区", "code": "320706000000"},
            {"area": "赣榆区", "code": "320707000000"},
            {"area": "东海县", "code": "320722000000"},
            {"area": "灌云县", "code": "320723000000"},
            {"area": "灌南县", "code": "320724000000"},
            {"area": "连云港经济技术开发区", "code": "320771000000"}
          ]
        },
        {
          "city": "淮安市",
          "code": "320800000000",
          "areas": [
            {"area": "淮安区", "code": "320803000000"},
            {"area": "淮阴区", "code": "320804000000"},
            {"area": "清江浦区", "code": "320812000000"},
            {"area": "洪泽区", "code": "320813000000"},
            {"area": "涟水县", "code": "320826000000"},
            {"area": "盱眙县", "code": "320830000000"},
            {"area": "金湖县", "code": "320831000000"},
            {"area": "淮安经济技术开发区", "code": "320871000000"}
          ]
        },
        {
          "city": "盐城市",
          "code": "320900000000",
          "areas": [
            {"area": "亭湖区", "code": "320902000000"},
            {"area": "盐都区", "code": "320903000000"},
            {"area": "大丰区", "code": "320904000000"},
            {"area": "响水县", "code": "320921000000"},
            {"area": "滨海县", "code": "320922000000"},
            {"area": "阜宁县", "code": "320923000000"},
            {"area": "射阳县", "code": "320924000000"},
            {"area": "建湖县", "code": "320925000000"},
            {"area": "盐城经济技术开发区", "code": "320971000000"},
            {"area": "东台市", "code": "320981000000"}
          ]
        },
        {
          "city": "扬州市",
          "code": "321000000000",
          "areas": [
            {"area": "广陵区", "code": "321002000000"},
            {"area": "邗江区", "code": "321003000000"},
            {"area": "江都区", "code": "321012000000"},
            {"area": "宝应县", "code": "321023000000"},
            {"area": "扬州经济技术开发区", "code": "321071000000"},
            {"area": "仪征市", "code": "321081000000"},
            {"area": "高邮市", "code": "321084000000"}
          ]
        },
        {
          "city": "镇江市",
          "code": "321100000000",
          "areas": [
            {"area": "京口区", "code": "321102000000"},
            {"area": "润州区", "code": "321111000000"},
            {"area": "丹徒区", "code": "321112000000"},
            {"area": "镇江新区", "code": "321171000000"},
            {"area": "丹阳市", "code": "321181000000"},
            {"area": "扬中市", "code": "321182000000"},
            {"area": "句容市", "code": "321183000000"}
          ]
        },
        {
          "city": "泰州市",
          "code": "321200000000",
          "areas": [
            {"area": "海陵区", "code": "321202000000"},
            {"area": "高港区", "code": "321203000000"},
            {"area": "姜堰区", "code": "321204000000"},
            {"area": "兴化市", "code": "321281000000"},
            {"area": "靖江市", "code": "321282000000"},
            {"area": "泰兴市", "code": "321283000000"}
          ]
        },
        {
          "city": "宿迁市",
          "code": "321300000000",
          "areas": [
            {"area": "宿城区", "code": "321302000000"},
            {"area": "宿豫区", "code": "321311000000"},
            {"area": "沭阳县", "code": "321322000000"},
            {"area": "泗阳县", "code": "321323000000"},
            {"area": "泗洪县", "code": "321324000000"},
            {"area": "宿迁经济技术开发区", "code": "321371000000"}
          ]
        }
      ]
    },
    {
      "province": "浙江省",
      "code": "330000",
      "citys": [
        {
          "city": "杭州市",
          "code": "330100000000",
          "areas": [
            {"area": "上城区", "code": "330102000000"},
            {"area": "拱墅区", "code": "330105000000"},
            {"area": "西湖区", "code": "330106000000"},
            {"area": "滨江区", "code": "330108000000"},
            {"area": "萧山区", "code": "330109000000"},
            {"area": "余杭区", "code": "330110000000"},
            {"area": "富阳区", "code": "330111000000"},
            {"area": "临安区", "code": "330112000000"},
            {"area": "临平区", "code": "330113000000"},
            {"area": "钱塘区", "code": "330114000000"},
            {"area": "桐庐县", "code": "330122000000"},
            {"area": "淳安县", "code": "330127000000"},
            {"area": "建德市", "code": "330182000000"}
          ]
        },
        {
          "city": "宁波市",
          "code": "330200000000",
          "areas": [
            {"area": "海曙区", "code": "330203000000"},
            {"area": "江北区", "code": "330205000000"},
            {"area": "北仑区", "code": "330206000000"},
            {"area": "镇海区", "code": "330211000000"},
            {"area": "鄞州区", "code": "330212000000"},
            {"area": "奉化区", "code": "330213000000"},
            {"area": "象山县", "code": "330225000000"},
            {"area": "宁海县", "code": "330226000000"},
            {"area": "余姚市", "code": "330281000000"},
            {"area": "慈溪市", "code": "330282000000"}
          ]
        },
        {
          "city": "温州市",
          "code": "330300000000",
          "areas": [
            {"area": "鹿城区", "code": "330302000000"},
            {"area": "龙湾区", "code": "330303000000"},
            {"area": "瓯海区", "code": "330304000000"},
            {"area": "洞头区", "code": "330305000000"},
            {"area": "永嘉县", "code": "330324000000"},
            {"area": "平阳县", "code": "330326000000"},
            {"area": "苍南县", "code": "330327000000"},
            {"area": "文成县", "code": "330328000000"},
            {"area": "泰顺县", "code": "330329000000"},
            {"area": "瑞安市", "code": "330381000000"},
            {"area": "乐清市", "code": "330382000000"},
            {"area": "龙港市", "code": "330383000000"}
          ]
        },
        {
          "city": "嘉兴市",
          "code": "330400000000",
          "areas": [
            {"area": "南湖区", "code": "330402000000"},
            {"area": "秀洲区", "code": "330411000000"},
            {"area": "嘉善县", "code": "330421000000"},
            {"area": "海盐县", "code": "330424000000"},
            {"area": "海宁市", "code": "330481000000"},
            {"area": "平湖市", "code": "330482000000"},
            {"area": "桐乡市", "code": "330483000000"}
          ]
        },
        {
          "city": "湖州市",
          "code": "330500000000",
          "areas": [
            {"area": "吴兴区", "code": "330502000000"},
            {"area": "南浔区", "code": "330503000000"},
            {"area": "德清县", "code": "330521000000"},
            {"area": "长兴县", "code": "330522000000"},
            {"area": "安吉县", "code": "330523000000"}
          ]
        },
        {
          "city": "绍兴市",
          "code": "330600000000",
          "areas": [
            {"area": "越城区", "code": "330602000000"},
            {"area": "柯桥区", "code": "330603000000"},
            {"area": "上虞区", "code": "330604000000"},
            {"area": "新昌县", "code": "330624000000"},
            {"area": "诸暨市", "code": "330681000000"},
            {"area": "嵊州市", "code": "330683000000"}
          ]
        },
        {
          "city": "金华市",
          "code": "330700000000",
          "areas": [
            {"area": "婺城区", "code": "330702000000"},
            {"area": "金东区", "code": "330703000000"},
            {"area": "武义县", "code": "330723000000"},
            {"area": "浦江县", "code": "330726000000"},
            {"area": "磐安县", "code": "330727000000"},
            {"area": "兰溪市", "code": "330781000000"},
            {"area": "义乌市", "code": "330782000000"},
            {"area": "东阳市", "code": "330783000000"},
            {"area": "永康市", "code": "330784000000"}
          ]
        },
        {
          "city": "衢州市",
          "code": "330800000000",
          "areas": [
            {"area": "柯城区", "code": "330802000000"},
            {"area": "衢江区", "code": "330803000000"},
            {"area": "常山县", "code": "330822000000"},
            {"area": "开化县", "code": "330824000000"},
            {"area": "龙游县", "code": "330825000000"},
            {"area": "江山市", "code": "330881000000"}
          ]
        },
        {
          "city": "舟山市",
          "code": "330900000000",
          "areas": [
            {"area": "定海区", "code": "330902000000"},
            {"area": "普陀区", "code": "330903000000"},
            {"area": "岱山县", "code": "330921000000"},
            {"area": "嵊泗县", "code": "330922000000"}
          ]
        },
        {
          "city": "台州市",
          "code": "331000000000",
          "areas": [
            {"area": "椒江区", "code": "331002000000"},
            {"area": "黄岩区", "code": "331003000000"},
            {"area": "路桥区", "code": "331004000000"},
            {"area": "三门县", "code": "331022000000"},
            {"area": "天台县", "code": "331023000000"},
            {"area": "仙居县", "code": "331024000000"},
            {"area": "温岭市", "code": "331081000000"},
            {"area": "临海市", "code": "331082000000"},
            {"area": "玉环市", "code": "331083000000"}
          ]
        },
        {
          "city": "丽水市",
          "code": "331100000000",
          "areas": [
            {"area": "莲都区", "code": "331102000000"},
            {"area": "青田县", "code": "331121000000"},
            {"area": "缙云县", "code": "331122000000"},
            {"area": "遂昌县", "code": "331123000000"},
            {"area": "松阳县", "code": "331124000000"},
            {"area": "云和县", "code": "331125000000"},
            {"area": "庆元县", "code": "331126000000"},
            {"area": "景宁畲族自治县", "code": "331127000000"},
            {"area": "龙泉市", "code": "331181000000"}
          ]
        }
      ]
    },
    {
      "province": "安徽省",
      "code": "340000",
      "citys": [
        {
          "city": "合肥市",
          "code": "340100000000",
          "areas": [
            {"area": "瑶海区", "code": "340102000000"},
            {"area": "庐阳区", "code": "340103000000"},
            {"area": "蜀山区", "code": "340104000000"},
            {"area": "包河区", "code": "340111000000"},
            {"area": "长丰县", "code": "340121000000"},
            {"area": "肥东县", "code": "340122000000"},
            {"area": "肥西县", "code": "340123000000"},
            {"area": "庐江县", "code": "340124000000"},
            {"area": "合肥高新技术产业开发区", "code": "340176000000"},
            {"area": "合肥经济技术开发区", "code": "340177000000"},
            {"area": "合肥新站高新技术产业开发区", "code": "340178000000"},
            {"area": "巢湖市", "code": "340181000000"}
          ]
        },
        {
          "city": "芜湖市",
          "code": "340200000000",
          "areas": [
            {"area": "镜湖区", "code": "340202000000"},
            {"area": "鸠江区", "code": "340207000000"},
            {"area": "弋江区", "code": "340209000000"},
            {"area": "湾沚区", "code": "340210000000"},
            {"area": "繁昌区", "code": "340212000000"},
            {"area": "南陵县", "code": "340223000000"},
            {"area": "芜湖经济技术开发区", "code": "340271000000"},
            {"area": "安徽芜湖三山经济开发区", "code": "340272000000"},
            {"area": "无为市", "code": "340281000000"}
          ]
        },
        {
          "city": "蚌埠市",
          "code": "340300000000",
          "areas": [
            {"area": "龙子湖区", "code": "340302000000"},
            {"area": "蚌山区", "code": "340303000000"},
            {"area": "禹会区", "code": "340304000000"},
            {"area": "淮上区", "code": "340311000000"},
            {"area": "怀远县", "code": "340321000000"},
            {"area": "五河县", "code": "340322000000"},
            {"area": "固镇县", "code": "340323000000"},
            {"area": "蚌埠市高新技术开发区", "code": "340371000000"},
            {"area": "蚌埠市经济开发区", "code": "340372000000"}
          ]
        },
        {
          "city": "淮南市",
          "code": "340400000000",
          "areas": [
            {"area": "大通区", "code": "340402000000"},
            {"area": "田家庵区", "code": "340403000000"},
            {"area": "谢家集区", "code": "340404000000"},
            {"area": "八公山区", "code": "340405000000"},
            {"area": "潘集区", "code": "340406000000"},
            {"area": "凤台县", "code": "340421000000"},
            {"area": "寿县", "code": "340422000000"}
          ]
        },
        {
          "city": "马鞍山市",
          "code": "340500000000",
          "areas": [
            {"area": "花山区", "code": "340503000000"},
            {"area": "雨山区", "code": "340504000000"},
            {"area": "博望区", "code": "340506000000"},
            {"area": "当涂县", "code": "340521000000"},
            {"area": "含山县", "code": "340522000000"},
            {"area": "和县", "code": "340523000000"}
          ]
        },
        {
          "city": "淮北市",
          "code": "340600000000",
          "areas": [
            {"area": "杜集区", "code": "340602000000"},
            {"area": "相山区", "code": "340603000000"},
            {"area": "烈山区", "code": "340604000000"},
            {"area": "濉溪县", "code": "340621000000"}
          ]
        },
        {
          "city": "铜陵市",
          "code": "340700000000",
          "areas": [
            {"area": "铜官区", "code": "340705000000"},
            {"area": "义安区", "code": "340706000000"},
            {"area": "郊区", "code": "340711000000"},
            {"area": "枞阳县", "code": "340722000000"}
          ]
        },
        {
          "city": "安庆市",
          "code": "340800000000",
          "areas": [
            {"area": "迎江区", "code": "340802000000"},
            {"area": "大观区", "code": "340803000000"},
            {"area": "宜秀区", "code": "340811000000"},
            {"area": "怀宁县", "code": "340822000000"},
            {"area": "太湖县", "code": "340825000000"},
            {"area": "宿松县", "code": "340826000000"},
            {"area": "望江县", "code": "340827000000"},
            {"area": "岳西县", "code": "340828000000"},
            {"area": "安徽安庆经济开发区", "code": "340871000000"},
            {"area": "桐城市", "code": "340881000000"},
            {"area": "潜山市", "code": "340882000000"}
          ]
        },
        {
          "city": "黄山市",
          "code": "341000000000",
          "areas": [
            {"area": "屯溪区", "code": "341002000000"},
            {"area": "黄山区", "code": "341003000000"},
            {"area": "徽州区", "code": "341004000000"},
            {"area": "歙县", "code": "341021000000"},
            {"area": "休宁县", "code": "341022000000"},
            {"area": "黟县", "code": "341023000000"},
            {"area": "祁门县", "code": "341024000000"}
          ]
        },
        {
          "city": "滁州市",
          "code": "341100000000",
          "areas": [
            {"area": "琅琊区", "code": "341102000000"},
            {"area": "南谯区", "code": "341103000000"},
            {"area": "来安县", "code": "341122000000"},
            {"area": "全椒县", "code": "341124000000"},
            {"area": "定远县", "code": "341125000000"},
            {"area": "凤阳县", "code": "341126000000"},
            {"area": "中新苏滁高新技术产业开发区", "code": "341171000000"},
            {"area": "滁州经济技术开发区", "code": "341172000000"},
            {"area": "天长市", "code": "341181000000"},
            {"area": "明光市", "code": "341182000000"}
          ]
        },
        {
          "city": "阜阳市",
          "code": "341200000000",
          "areas": [
            {"area": "颍州区", "code": "341202000000"},
            {"area": "颍东区", "code": "341203000000"},
            {"area": "颍泉区", "code": "341204000000"},
            {"area": "临泉县", "code": "341221000000"},
            {"area": "太和县", "code": "341222000000"},
            {"area": "阜南县", "code": "341225000000"},
            {"area": "颍上县", "code": "341226000000"},
            {"area": "阜阳合肥现代产业园区", "code": "341271000000"},
            {"area": "阜阳经济技术开发区", "code": "341272000000"},
            {"area": "界首市", "code": "341282000000"}
          ]
        },
        {
          "city": "宿州市",
          "code": "341300000000",
          "areas": [
            {"area": "埇桥区", "code": "341302000000"},
            {"area": "砀山县", "code": "341321000000"},
            {"area": "萧县", "code": "341322000000"},
            {"area": "灵璧县", "code": "341323000000"},
            {"area": "泗县", "code": "341324000000"},
            {"area": "宿州马鞍山现代产业园区", "code": "341371000000"},
            {"area": "宿州经济技术开发区", "code": "341372000000"}
          ]
        },
        {
          "city": "六安市",
          "code": "341500000000",
          "areas": [
            {"area": "金安区", "code": "341502000000"},
            {"area": "裕安区", "code": "341503000000"},
            {"area": "叶集区", "code": "341504000000"},
            {"area": "霍邱县", "code": "341522000000"},
            {"area": "舒城县", "code": "341523000000"},
            {"area": "金寨县", "code": "341524000000"},
            {"area": "霍山县", "code": "341525000000"}
          ]
        },
        {
          "city": "亳州市",
          "code": "341600000000",
          "areas": [
            {"area": "谯城区", "code": "341602000000"},
            {"area": "涡阳县", "code": "341621000000"},
            {"area": "蒙城县", "code": "341622000000"},
            {"area": "利辛县", "code": "341623000000"}
          ]
        },
        {
          "city": "池州市",
          "code": "341700000000",
          "areas": [
            {"area": "贵池区", "code": "341702000000"},
            {"area": "东至县", "code": "341721000000"},
            {"area": "石台县", "code": "341722000000"},
            {"area": "青阳县", "code": "341723000000"}
          ]
        },
        {
          "city": "宣城市",
          "code": "341800000000",
          "areas": [
            {"area": "宣州区", "code": "341802000000"},
            {"area": "郎溪县", "code": "341821000000"},
            {"area": "泾县", "code": "341823000000"},
            {"area": "绩溪县", "code": "341824000000"},
            {"area": "旌德县", "code": "341825000000"},
            {"area": "宣城市经济开发区", "code": "341871000000"},
            {"area": "宁国市", "code": "341881000000"},
            {"area": "广德市", "code": "341882000000"}
          ]
        }
      ]
    },
    {
      "province": "福建省",
      "code": "350000",
      "citys": [
        {
          "city": "福州市",
          "code": "350100000000",
          "areas": [
            {"area": "鼓楼区", "code": "350102000000"},
            {"area": "台江区", "code": "350103000000"},
            {"area": "仓山区", "code": "350104000000"},
            {"area": "马尾区", "code": "350105000000"},
            {"area": "晋安区", "code": "350111000000"},
            {"area": "长乐区", "code": "350112000000"},
            {"area": "闽侯县", "code": "350121000000"},
            {"area": "连江县", "code": "350122000000"},
            {"area": "罗源县", "code": "350123000000"},
            {"area": "闽清县", "code": "350124000000"},
            {"area": "永泰县", "code": "350125000000"},
            {"area": "平潭县", "code": "350128000000"},
            {"area": "福清市", "code": "350181000000"}
          ]
        },
        {
          "city": "厦门市",
          "code": "350200000000",
          "areas": [
            {"area": "思明区", "code": "350203000000"},
            {"area": "海沧区", "code": "350205000000"},
            {"area": "湖里区", "code": "350206000000"},
            {"area": "集美区", "code": "350211000000"},
            {"area": "同安区", "code": "350212000000"},
            {"area": "翔安区", "code": "350213000000"}
          ]
        },
        {
          "city": "莆田市",
          "code": "350300000000",
          "areas": [
            {"area": "城厢区", "code": "350302000000"},
            {"area": "涵江区", "code": "350303000000"},
            {"area": "荔城区", "code": "350304000000"},
            {"area": "秀屿区", "code": "350305000000"},
            {"area": "仙游县", "code": "350322000000"}
          ]
        },
        {
          "city": "三明市",
          "code": "350400000000",
          "areas": [
            {"area": "三元区", "code": "350404000000"},
            {"area": "沙县区", "code": "350405000000"},
            {"area": "明溪县", "code": "350421000000"},
            {"area": "清流县", "code": "350423000000"},
            {"area": "宁化县", "code": "350424000000"},
            {"area": "大田县", "code": "350425000000"},
            {"area": "尤溪县", "code": "350426000000"},
            {"area": "将乐县", "code": "350428000000"},
            {"area": "泰宁县", "code": "350429000000"},
            {"area": "建宁县", "code": "350430000000"},
            {"area": "永安市", "code": "350481000000"}
          ]
        },
        {
          "city": "泉州市",
          "code": "350500000000",
          "areas": [
            {"area": "鲤城区", "code": "350502000000"},
            {"area": "丰泽区", "code": "350503000000"},
            {"area": "洛江区", "code": "350504000000"},
            {"area": "泉港区", "code": "350505000000"},
            {"area": "惠安县", "code": "350521000000"},
            {"area": "安溪县", "code": "350524000000"},
            {"area": "永春县", "code": "350525000000"},
            {"area": "德化县", "code": "350526000000"},
            {"area": "金门县", "code": "350527000000"},
            {"area": "石狮市", "code": "350581000000"},
            {"area": "晋江市", "code": "350582000000"},
            {"area": "南安市", "code": "350583000000"}
          ]
        },
        {
          "city": "漳州市",
          "code": "350600000000",
          "areas": [
            {"area": "芗城区", "code": "350602000000"},
            {"area": "龙文区", "code": "350603000000"},
            {"area": "龙海区", "code": "350604000000"},
            {"area": "长泰区", "code": "350605000000"},
            {"area": "云霄县", "code": "350622000000"},
            {"area": "漳浦县", "code": "350623000000"},
            {"area": "诏安县", "code": "350624000000"},
            {"area": "东山县", "code": "350626000000"},
            {"area": "南靖县", "code": "350627000000"},
            {"area": "平和县", "code": "350628000000"},
            {"area": "华安县", "code": "350629000000"}
          ]
        },
        {
          "city": "南平市",
          "code": "350700000000",
          "areas": [
            {"area": "延平区", "code": "350702000000"},
            {"area": "建阳区", "code": "350703000000"},
            {"area": "顺昌县", "code": "350721000000"},
            {"area": "浦城县", "code": "350722000000"},
            {"area": "光泽县", "code": "350723000000"},
            {"area": "松溪县", "code": "350724000000"},
            {"area": "政和县", "code": "350725000000"},
            {"area": "邵武市", "code": "350781000000"},
            {"area": "武夷山市", "code": "350782000000"},
            {"area": "建瓯市", "code": "350783000000"}
          ]
        },
        {
          "city": "龙岩市",
          "code": "350800000000",
          "areas": [
            {"area": "新罗区", "code": "350802000000"},
            {"area": "永定区", "code": "350803000000"},
            {"area": "长汀县", "code": "350821000000"},
            {"area": "上杭县", "code": "350823000000"},
            {"area": "武平县", "code": "350824000000"},
            {"area": "连城县", "code": "350825000000"},
            {"area": "漳平市", "code": "350881000000"}
          ]
        },
        {
          "city": "宁德市",
          "code": "350900000000",
          "areas": [
            {"area": "蕉城区", "code": "350902000000"},
            {"area": "霞浦县", "code": "350921000000"},
            {"area": "古田县", "code": "350922000000"},
            {"area": "屏南县", "code": "350923000000"},
            {"area": "寿宁县", "code": "350924000000"},
            {"area": "周宁县", "code": "350925000000"},
            {"area": "柘荣县", "code": "350926000000"},
            {"area": "福安市", "code": "350981000000"},
            {"area": "福鼎市", "code": "350982000000"}
          ]
        }
      ]
    },
    {
      "province": "江西省",
      "code": "360000",
      "citys": [
        {
          "city": "南昌市",
          "code": "360100000000",
          "areas": [
            {"area": "东湖区", "code": "360102000000"},
            {"area": "西湖区", "code": "360103000000"},
            {"area": "青云谱区", "code": "360104000000"},
            {"area": "青山湖区", "code": "360111000000"},
            {"area": "新建区", "code": "360112000000"},
            {"area": "红谷滩区", "code": "360113000000"},
            {"area": "南昌县", "code": "360121000000"},
            {"area": "安义县", "code": "360123000000"},
            {"area": "进贤县", "code": "360124000000"}
          ]
        },
        {
          "city": "景德镇市",
          "code": "360200000000",
          "areas": [
            {"area": "昌江区", "code": "360202000000"},
            {"area": "珠山区", "code": "360203000000"},
            {"area": "浮梁县", "code": "360222000000"},
            {"area": "乐平市", "code": "360281000000"}
          ]
        },
        {
          "city": "萍乡市",
          "code": "360300000000",
          "areas": [
            {"area": "安源区", "code": "360302000000"},
            {"area": "湘东区", "code": "360313000000"},
            {"area": "莲花县", "code": "360321000000"},
            {"area": "上栗县", "code": "360322000000"},
            {"area": "芦溪县", "code": "360323000000"}
          ]
        },
        {
          "city": "九江市",
          "code": "360400000000",
          "areas": [
            {"area": "濂溪区", "code": "360402000000"},
            {"area": "浔阳区", "code": "360403000000"},
            {"area": "柴桑区", "code": "360404000000"},
            {"area": "武宁县", "code": "360423000000"},
            {"area": "修水县", "code": "360424000000"},
            {"area": "永修县", "code": "360425000000"},
            {"area": "德安县", "code": "360426000000"},
            {"area": "都昌县", "code": "360428000000"},
            {"area": "湖口县", "code": "360429000000"},
            {"area": "彭泽县", "code": "360430000000"},
            {"area": "瑞昌市", "code": "360481000000"},
            {"area": "共青城市", "code": "360482000000"},
            {"area": "庐山市", "code": "360483000000"}
          ]
        },
        {
          "city": "新余市",
          "code": "360500000000",
          "areas": [
            {"area": "渝水区", "code": "360502000000"},
            {"area": "分宜县", "code": "360521000000"}
          ]
        },
        {
          "city": "鹰潭市",
          "code": "360600000000",
          "areas": [
            {"area": "月湖区", "code": "360602000000"},
            {"area": "余江区", "code": "360603000000"},
            {"area": "贵溪市", "code": "360681000000"}
          ]
        },
        {
          "city": "赣州市",
          "code": "360700000000",
          "areas": [
            {"area": "章贡区", "code": "360702000000"},
            {"area": "南康区", "code": "360703000000"},
            {"area": "赣县区", "code": "360704000000"},
            {"area": "信丰县", "code": "360722000000"},
            {"area": "大余县", "code": "360723000000"},
            {"area": "上犹县", "code": "360724000000"},
            {"area": "崇义县", "code": "360725000000"},
            {"area": "安远县", "code": "360726000000"},
            {"area": "定南县", "code": "360728000000"},
            {"area": "全南县", "code": "360729000000"},
            {"area": "宁都县", "code": "360730000000"},
            {"area": "于都县", "code": "360731000000"},
            {"area": "兴国县", "code": "360732000000"},
            {"area": "会昌县", "code": "360733000000"},
            {"area": "寻乌县", "code": "360734000000"},
            {"area": "石城县", "code": "360735000000"},
            {"area": "瑞金市", "code": "360781000000"},
            {"area": "龙南市", "code": "360783000000"}
          ]
        },
        {
          "city": "吉安市",
          "code": "360800000000",
          "areas": [
            {"area": "吉州区", "code": "360802000000"},
            {"area": "青原区", "code": "360803000000"},
            {"area": "吉安县", "code": "360821000000"},
            {"area": "吉水县", "code": "360822000000"},
            {"area": "峡江县", "code": "360823000000"},
            {"area": "新干县", "code": "360824000000"},
            {"area": "永丰县", "code": "360825000000"},
            {"area": "泰和县", "code": "360826000000"},
            {"area": "遂川县", "code": "360827000000"},
            {"area": "万安县", "code": "360828000000"},
            {"area": "安福县", "code": "360829000000"},
            {"area": "永新县", "code": "360830000000"},
            {"area": "井冈山市", "code": "360881000000"}
          ]
        },
        {
          "city": "宜春市",
          "code": "360900000000",
          "areas": [
            {"area": "袁州区", "code": "360902000000"},
            {"area": "奉新县", "code": "360921000000"},
            {"area": "万载县", "code": "360922000000"},
            {"area": "上高县", "code": "360923000000"},
            {"area": "宜丰县", "code": "360924000000"},
            {"area": "靖安县", "code": "360925000000"},
            {"area": "铜鼓县", "code": "360926000000"},
            {"area": "丰城市", "code": "360981000000"},
            {"area": "樟树市", "code": "360982000000"},
            {"area": "高安市", "code": "360983000000"}
          ]
        },
        {
          "city": "抚州市",
          "code": "361000000000",
          "areas": [
            {"area": "临川区", "code": "361002000000"},
            {"area": "东乡区", "code": "361003000000"},
            {"area": "南城县", "code": "361021000000"},
            {"area": "黎川县", "code": "361022000000"},
            {"area": "南丰县", "code": "361023000000"},
            {"area": "崇仁县", "code": "361024000000"},
            {"area": "乐安县", "code": "361025000000"},
            {"area": "宜黄县", "code": "361026000000"},
            {"area": "金溪县", "code": "361027000000"},
            {"area": "资溪县", "code": "361028000000"},
            {"area": "广昌县", "code": "361030000000"}
          ]
        },
        {
          "city": "上饶市",
          "code": "361100000000",
          "areas": [
            {"area": "信州区", "code": "361102000000"},
            {"area": "广丰区", "code": "361103000000"},
            {"area": "广信区", "code": "361104000000"},
            {"area": "玉山县", "code": "361123000000"},
            {"area": "铅山县", "code": "361124000000"},
            {"area": "横峰县", "code": "361125000000"},
            {"area": "弋阳县", "code": "361126000000"},
            {"area": "余干县", "code": "361127000000"},
            {"area": "鄱阳县", "code": "361128000000"},
            {"area": "万年县", "code": "361129000000"},
            {"area": "婺源县", "code": "361130000000"},
            {"area": "德兴市", "code": "361181000000"}
          ]
        }
      ]
    },
    {
      "province": "山东省",
      "code": "370000",
      "citys": [
        {
          "city": "济南市",
          "code": "370100000000",
          "areas": [
            {"area": "历下区", "code": "370102000000"},
            {"area": "市中区", "code": "370103000000"},
            {"area": "槐荫区", "code": "370104000000"},
            {"area": "天桥区", "code": "370105000000"},
            {"area": "历城区", "code": "370112000000"},
            {"area": "长清区", "code": "370113000000"},
            {"area": "章丘区", "code": "370114000000"},
            {"area": "济阳区", "code": "370115000000"},
            {"area": "莱芜区", "code": "370116000000"},
            {"area": "钢城区", "code": "370117000000"},
            {"area": "平阴县", "code": "370124000000"},
            {"area": "商河县", "code": "370126000000"},
            {"area": "济南高新技术产业开发区", "code": "370176000000"}
          ]
        },
        {
          "city": "青岛市",
          "code": "370200000000",
          "areas": [
            {"area": "市南区", "code": "370202000000"},
            {"area": "市北区", "code": "370203000000"},
            {"area": "黄岛区", "code": "370211000000"},
            {"area": "崂山区", "code": "370212000000"},
            {"area": "李沧区", "code": "370213000000"},
            {"area": "城阳区", "code": "370214000000"},
            {"area": "即墨区", "code": "370215000000"},
            {"area": "胶州市", "code": "370281000000"},
            {"area": "平度市", "code": "370283000000"},
            {"area": "莱西市", "code": "370285000000"}
          ]
        },
        {
          "city": "淄博市",
          "code": "370300000000",
          "areas": [
            {"area": "淄川区", "code": "370302000000"},
            {"area": "张店区", "code": "370303000000"},
            {"area": "博山区", "code": "370304000000"},
            {"area": "临淄区", "code": "370305000000"},
            {"area": "周村区", "code": "370306000000"},
            {"area": "桓台县", "code": "370321000000"},
            {"area": "高青县", "code": "370322000000"},
            {"area": "沂源县", "code": "370323000000"}
          ]
        },
        {
          "city": "枣庄市",
          "code": "370400000000",
          "areas": [
            {"area": "市中区", "code": "370402000000"},
            {"area": "薛城区", "code": "370403000000"},
            {"area": "峄城区", "code": "370404000000"},
            {"area": "台儿庄区", "code": "370405000000"},
            {"area": "山亭区", "code": "370406000000"},
            {"area": "滕州市", "code": "370481000000"}
          ]
        },
        {
          "city": "东营市",
          "code": "370500000000",
          "areas": [
            {"area": "东营区", "code": "370502000000"},
            {"area": "河口区", "code": "370503000000"},
            {"area": "垦利区", "code": "370505000000"},
            {"area": "利津县", "code": "370522000000"},
            {"area": "广饶县", "code": "370523000000"},
            {"area": "东营经济技术开发区", "code": "370571000000"},
            {"area": "东营港经济开发区", "code": "370572000000"}
          ]
        },
        {
          "city": "烟台市",
          "code": "370600000000",
          "areas": [
            {"area": "芝罘区", "code": "370602000000"},
            {"area": "福山区", "code": "370611000000"},
            {"area": "牟平区", "code": "370612000000"},
            {"area": "莱山区", "code": "370613000000"},
            {"area": "蓬莱区", "code": "370614000000"},
            {"area": "烟台高新技术产业开发区", "code": "370671000000"},
            {"area": "烟台经济技术开发区", "code": "370676000000"},
            {"area": "龙口市", "code": "370681000000"},
            {"area": "莱阳市", "code": "370682000000"},
            {"area": "莱州市", "code": "370683000000"},
            {"area": "招远市", "code": "370685000000"},
            {"area": "栖霞市", "code": "370686000000"},
            {"area": "海阳市", "code": "370687000000"}
          ]
        },
        {
          "city": "潍坊市",
          "code": "370700000000",
          "areas": [
            {"area": "潍城区", "code": "370702000000"},
            {"area": "寒亭区", "code": "370703000000"},
            {"area": "坊子区", "code": "370704000000"},
            {"area": "奎文区", "code": "370705000000"},
            {"area": "临朐县", "code": "370724000000"},
            {"area": "昌乐县", "code": "370725000000"},
            {"area": "潍坊滨海经济技术开发区", "code": "370772000000"},
            {"area": "青州市", "code": "370781000000"},
            {"area": "诸城市", "code": "370782000000"},
            {"area": "寿光市", "code": "370783000000"},
            {"area": "安丘市", "code": "370784000000"},
            {"area": "高密市", "code": "370785000000"},
            {"area": "昌邑市", "code": "370786000000"}
          ]
        },
        {
          "city": "济宁市",
          "code": "370800000000",
          "areas": [
            {"area": "任城区", "code": "370811000000"},
            {"area": "兖州区", "code": "370812000000"},
            {"area": "微山县", "code": "370826000000"},
            {"area": "鱼台县", "code": "370827000000"},
            {"area": "金乡县", "code": "370828000000"},
            {"area": "嘉祥县", "code": "370829000000"},
            {"area": "汶上县", "code": "370830000000"},
            {"area": "泗水县", "code": "370831000000"},
            {"area": "梁山县", "code": "370832000000"},
            {"area": "济宁高新技术产业开发区", "code": "370871000000"},
            {"area": "曲阜市", "code": "370881000000"},
            {"area": "邹城市", "code": "370883000000"}
          ]
        },
        {
          "city": "泰安市",
          "code": "370900000000",
          "areas": [
            {"area": "泰山区", "code": "370902000000"},
            {"area": "岱岳区", "code": "370911000000"},
            {"area": "宁阳县", "code": "370921000000"},
            {"area": "东平县", "code": "370923000000"},
            {"area": "新泰市", "code": "370982000000"},
            {"area": "肥城市", "code": "370983000000"}
          ]
        },
        {
          "city": "威海市",
          "code": "371000000000",
          "areas": [
            {"area": "环翠区", "code": "371002000000"},
            {"area": "文登区", "code": "371003000000"},
            {"area": "威海火炬高技术产业开发区", "code": "371071000000"},
            {"area": "威海经济技术开发区", "code": "371072000000"},
            {"area": "威海临港经济技术开发区", "code": "371073000000"},
            {"area": "荣成市", "code": "371082000000"},
            {"area": "乳山市", "code": "371083000000"}
          ]
        },
        {
          "city": "日照市",
          "code": "371100000000",
          "areas": [
            {"area": "东港区", "code": "371102000000"},
            {"area": "岚山区", "code": "371103000000"},
            {"area": "五莲县", "code": "371121000000"},
            {"area": "莒县", "code": "371122000000"},
            {"area": "日照经济技术开发区", "code": "371171000000"}
          ]
        },
        {
          "city": "临沂市",
          "code": "371300000000",
          "areas": [
            {"area": "兰山区", "code": "371302000000"},
            {"area": "罗庄区", "code": "371311000000"},
            {"area": "河东区", "code": "371312000000"},
            {"area": "沂南县", "code": "371321000000"},
            {"area": "郯城县", "code": "371322000000"},
            {"area": "沂水县", "code": "371323000000"},
            {"area": "兰陵县", "code": "371324000000"},
            {"area": "费县", "code": "371325000000"},
            {"area": "平邑县", "code": "371326000000"},
            {"area": "莒南县", "code": "371327000000"},
            {"area": "蒙阴县", "code": "371328000000"},
            {"area": "临沭县", "code": "371329000000"},
            {"area": "临沂高新技术产业开发区", "code": "371371000000"}
          ]
        },
        {
          "city": "德州市",
          "code": "371400000000",
          "areas": [
            {"area": "德城区", "code": "371402000000"},
            {"area": "陵城区", "code": "371403000000"},
            {"area": "宁津县", "code": "371422000000"},
            {"area": "庆云县", "code": "371423000000"},
            {"area": "临邑县", "code": "371424000000"},
            {"area": "齐河县", "code": "371425000000"},
            {"area": "平原县", "code": "371426000000"},
            {"area": "夏津县", "code": "371427000000"},
            {"area": "武城县", "code": "371428000000"},
            {"area": "德州天衢新区", "code": "371471000000"},
            {"area": "乐陵市", "code": "371481000000"},
            {"area": "禹城市", "code": "371482000000"}
          ]
        },
        {
          "city": "聊城市",
          "code": "371500000000",
          "areas": [
            {"area": "东昌府区", "code": "371502000000"},
            {"area": "茌平区", "code": "371503000000"},
            {"area": "阳谷县", "code": "371521000000"},
            {"area": "莘县", "code": "371522000000"},
            {"area": "东阿县", "code": "371524000000"},
            {"area": "冠县", "code": "371525000000"},
            {"area": "高唐县", "code": "371526000000"},
            {"area": "临清市", "code": "371581000000"}
          ]
        },
        {
          "city": "滨州市",
          "code": "371600000000",
          "areas": [
            {"area": "滨城区", "code": "371602000000"},
            {"area": "沾化区", "code": "371603000000"},
            {"area": "惠民县", "code": "371621000000"},
            {"area": "阳信县", "code": "371622000000"},
            {"area": "无棣县", "code": "371623000000"},
            {"area": "博兴县", "code": "371625000000"},
            {"area": "邹平市", "code": "371681000000"}
          ]
        },
        {
          "city": "菏泽市",
          "code": "371700000000",
          "areas": [
            {"area": "牡丹区", "code": "371702000000"},
            {"area": "定陶区", "code": "371703000000"},
            {"area": "曹县", "code": "371721000000"},
            {"area": "单县", "code": "371722000000"},
            {"area": "成武县", "code": "371723000000"},
            {"area": "巨野县", "code": "371724000000"},
            {"area": "郓城县", "code": "371725000000"},
            {"area": "鄄城县", "code": "371726000000"},
            {"area": "东明县", "code": "371728000000"},
            {"area": "菏泽经济技术开发区", "code": "371771000000"},
            {"area": "菏泽高新技术开发区", "code": "371772000000"}
          ]
        }
      ]
    },
    {
      "province": "河南省",
      "code": "410000",
      "citys": [
        {
          "city": "郑州市",
          "code": "410100000000",
          "areas": [
            {"area": "中原区", "code": "410102000000"},
            {"area": "二七区", "code": "410103000000"},
            {"area": "管城回族区", "code": "410104000000"},
            {"area": "金水区", "code": "410105000000"},
            {"area": "上街区", "code": "410106000000"},
            {"area": "惠济区", "code": "410108000000"},
            {"area": "中牟县", "code": "410122000000"},
            {"area": "郑州经济技术开发区", "code": "410171000000"},
            {"area": "郑州高新技术产业开发区", "code": "410172000000"},
            {"area": "郑州航空港经济综合实验区", "code": "410173000000"},
            {"area": "巩义市", "code": "410181000000"},
            {"area": "荥阳市", "code": "410182000000"},
            {"area": "新密市", "code": "410183000000"},
            {"area": "新郑市", "code": "410184000000"},
            {"area": "登封市", "code": "410185000000"}
          ]
        },
        {
          "city": "开封市",
          "code": "410200000000",
          "areas": [
            {"area": "龙亭区", "code": "410202000000"},
            {"area": "顺河回族区", "code": "410203000000"},
            {"area": "鼓楼区", "code": "410204000000"},
            {"area": "禹王台区", "code": "410205000000"},
            {"area": "祥符区", "code": "410212000000"},
            {"area": "杞县", "code": "410221000000"},
            {"area": "通许县", "code": "410222000000"},
            {"area": "尉氏县", "code": "410223000000"},
            {"area": "兰考县", "code": "410225000000"}
          ]
        },
        {
          "city": "洛阳市",
          "code": "410300000000",
          "areas": [
            {"area": "老城区", "code": "410302000000"},
            {"area": "西工区", "code": "410303000000"},
            {"area": "瀍河回族区", "code": "410304000000"},
            {"area": "涧西区", "code": "410305000000"},
            {"area": "偃师区", "code": "410307000000"},
            {"area": "孟津区", "code": "410308000000"},
            {"area": "洛龙区", "code": "410311000000"},
            {"area": "新安县", "code": "410323000000"},
            {"area": "栾川县", "code": "410324000000"},
            {"area": "嵩县", "code": "410325000000"},
            {"area": "汝阳县", "code": "410326000000"},
            {"area": "宜阳县", "code": "410327000000"},
            {"area": "洛宁县", "code": "410328000000"},
            {"area": "伊川县", "code": "410329000000"},
            {"area": "洛阳高新技术产业开发区", "code": "410371000000"}
          ]
        },
        {
          "city": "平顶山市",
          "code": "410400000000",
          "areas": [
            {"area": "新华区", "code": "410402000000"},
            {"area": "卫东区", "code": "410403000000"},
            {"area": "石龙区", "code": "410404000000"},
            {"area": "湛河区", "code": "410411000000"},
            {"area": "宝丰县", "code": "410421000000"},
            {"area": "叶县", "code": "410422000000"},
            {"area": "鲁山县", "code": "410423000000"},
            {"area": "郏县", "code": "410425000000"},
            {"area": "平顶山高新技术产业开发区", "code": "410471000000"},
            {"area": "平顶山市城乡一体化示范区", "code": "410472000000"},
            {"area": "舞钢市", "code": "410481000000"},
            {"area": "汝州市", "code": "410482000000"}
          ]
        },
        {
          "city": "安阳市",
          "code": "410500000000",
          "areas": [
            {"area": "文峰区", "code": "410502000000"},
            {"area": "北关区", "code": "410503000000"},
            {"area": "殷都区", "code": "410505000000"},
            {"area": "龙安区", "code": "410506000000"},
            {"area": "安阳县", "code": "410522000000"},
            {"area": "汤阴县", "code": "410523000000"},
            {"area": "滑县", "code": "410526000000"},
            {"area": "内黄县", "code": "410527000000"},
            {"area": "安阳高新技术产业开发区", "code": "410571000000"},
            {"area": "林州市", "code": "410581000000"}
          ]
        },
        {
          "city": "鹤壁市",
          "code": "410600000000",
          "areas": [
            {"area": "鹤山区", "code": "410602000000"},
            {"area": "山城区", "code": "410603000000"},
            {"area": "淇滨区", "code": "410611000000"},
            {"area": "浚县", "code": "410621000000"},
            {"area": "淇县", "code": "410622000000"},
            {"area": "鹤壁经济技术开发区", "code": "410671000000"}
          ]
        },
        {
          "city": "新乡市",
          "code": "410700000000",
          "areas": [
            {"area": "红旗区", "code": "410702000000"},
            {"area": "卫滨区", "code": "410703000000"},
            {"area": "凤泉区", "code": "410704000000"},
            {"area": "牧野区", "code": "410711000000"},
            {"area": "新乡县", "code": "410721000000"},
            {"area": "获嘉县", "code": "410724000000"},
            {"area": "原阳县", "code": "410725000000"},
            {"area": "延津县", "code": "410726000000"},
            {"area": "封丘县", "code": "410727000000"},
            {"area": "新乡高新技术产业开发区", "code": "410771000000"},
            {"area": "新乡经济技术开发区", "code": "410772000000"},
            {"area": "新乡市平原城乡一体化示范区", "code": "410773000000"},
            {"area": "卫辉市", "code": "410781000000"},
            {"area": "辉县市", "code": "410782000000"},
            {"area": "长垣市", "code": "410783000000"}
          ]
        },
        {
          "city": "焦作市",
          "code": "410800000000",
          "areas": [
            {"area": "解放区", "code": "410802000000"},
            {"area": "中站区", "code": "410803000000"},
            {"area": "马村区", "code": "410804000000"},
            {"area": "山阳区", "code": "410811000000"},
            {"area": "修武县", "code": "410821000000"},
            {"area": "博爱县", "code": "410822000000"},
            {"area": "武陟县", "code": "410823000000"},
            {"area": "温县", "code": "410825000000"},
            {"area": "焦作城乡一体化示范区", "code": "410871000000"},
            {"area": "沁阳市", "code": "410882000000"},
            {"area": "孟州市", "code": "410883000000"}
          ]
        },
        {
          "city": "濮阳市",
          "code": "410900000000",
          "areas": [
            {"area": "华龙区", "code": "410902000000"},
            {"area": "清丰县", "code": "410922000000"},
            {"area": "南乐县", "code": "410923000000"},
            {"area": "范县", "code": "410926000000"},
            {"area": "台前县", "code": "410927000000"},
            {"area": "濮阳县", "code": "410928000000"},
            {"area": "河南濮阳工业园区", "code": "410971000000"},
            {"area": "濮阳经济技术开发区", "code": "410972000000"}
          ]
        },
        {
          "city": "许昌市",
          "code": "411000000000",
          "areas": [
            {"area": "魏都区", "code": "411002000000"},
            {"area": "建安区", "code": "411003000000"},
            {"area": "鄢陵县", "code": "411024000000"},
            {"area": "襄城县", "code": "411025000000"},
            {"area": "许昌经济技术开发区", "code": "411071000000"},
            {"area": "禹州市", "code": "411081000000"},
            {"area": "长葛市", "code": "411082000000"}
          ]
        },
        {
          "city": "漯河市",
          "code": "411100000000",
          "areas": [
            {"area": "源汇区", "code": "411102000000"},
            {"area": "郾城区", "code": "411103000000"},
            {"area": "召陵区", "code": "411104000000"},
            {"area": "舞阳县", "code": "411121000000"},
            {"area": "临颍县", "code": "411122000000"},
            {"area": "漯河经济技术开发区", "code": "411171000000"}
          ]
        },
        {
          "city": "三门峡市",
          "code": "411200000000",
          "areas": [
            {"area": "湖滨区", "code": "411202000000"},
            {"area": "陕州区", "code": "411203000000"},
            {"area": "渑池县", "code": "411221000000"},
            {"area": "卢氏县", "code": "411224000000"},
            {"area": "河南三门峡经济开发区", "code": "411271000000"},
            {"area": "义马市", "code": "411281000000"},
            {"area": "灵宝市", "code": "411282000000"}
          ]
        },
        {
          "city": "南阳市",
          "code": "411300000000",
          "areas": [
            {"area": "宛城区", "code": "411302000000"},
            {"area": "卧龙区", "code": "411303000000"},
            {"area": "南召县", "code": "411321000000"},
            {"area": "方城县", "code": "411322000000"},
            {"area": "西峡县", "code": "411323000000"},
            {"area": "镇平县", "code": "411324000000"},
            {"area": "内乡县", "code": "411325000000"},
            {"area": "淅川县", "code": "411326000000"},
            {"area": "社旗县", "code": "411327000000"},
            {"area": "唐河县", "code": "411328000000"},
            {"area": "新野县", "code": "411329000000"},
            {"area": "桐柏县", "code": "411330000000"},
            {"area": "南阳高新技术产业开发区", "code": "411371000000"},
            {"area": "南阳市城乡一体化示范区", "code": "411372000000"},
            {"area": "邓州市", "code": "411381000000"}
          ]
        },
        {
          "city": "商丘市",
          "code": "411400000000",
          "areas": [
            {"area": "梁园区", "code": "411402000000"},
            {"area": "睢阳区", "code": "411403000000"},
            {"area": "民权县", "code": "411421000000"},
            {"area": "睢县", "code": "411422000000"},
            {"area": "宁陵县", "code": "411423000000"},
            {"area": "柘城县", "code": "411424000000"},
            {"area": "虞城县", "code": "411425000000"},
            {"area": "夏邑县", "code": "411426000000"},
            {"area": "豫东综合物流产业聚集区", "code": "411471000000"},
            {"area": "河南商丘经济开发区", "code": "411472000000"},
            {"area": "永城市", "code": "411481000000"}
          ]
        },
        {
          "city": "信阳市",
          "code": "411500000000",
          "areas": [
            {"area": "浉河区", "code": "411502000000"},
            {"area": "平桥区", "code": "411503000000"},
            {"area": "罗山县", "code": "411521000000"},
            {"area": "光山县", "code": "411522000000"},
            {"area": "新县", "code": "411523000000"},
            {"area": "商城县", "code": "411524000000"},
            {"area": "固始县", "code": "411525000000"},
            {"area": "潢川县", "code": "411526000000"},
            {"area": "淮滨县", "code": "411527000000"},
            {"area": "息县", "code": "411528000000"},
            {"area": "信阳高新技术产业开发区", "code": "411571000000"}
          ]
        },
        {
          "city": "周口市",
          "code": "411600000000",
          "areas": [
            {"area": "川汇区", "code": "411602000000"},
            {"area": "淮阳区", "code": "411603000000"},
            {"area": "扶沟县", "code": "411621000000"},
            {"area": "西华县", "code": "411622000000"},
            {"area": "商水县", "code": "411623000000"},
            {"area": "沈丘县", "code": "411624000000"},
            {"area": "郸城县", "code": "411625000000"},
            {"area": "太康县", "code": "411627000000"},
            {"area": "鹿邑县", "code": "411628000000"},
            {"area": "周口临港开发区", "code": "411671000000"},
            {"area": "项城市", "code": "411681000000"}
          ]
        },
        {
          "city": "驻马店市",
          "code": "411700000000",
          "areas": [
            {"area": "驿城区", "code": "411702000000"},
            {"area": "西平县", "code": "411721000000"},
            {"area": "上蔡县", "code": "411722000000"},
            {"area": "平舆县", "code": "411723000000"},
            {"area": "正阳县", "code": "411724000000"},
            {"area": "确山县", "code": "411725000000"},
            {"area": "泌阳县", "code": "411726000000"},
            {"area": "汝南县", "code": "411727000000"},
            {"area": "遂平县", "code": "411728000000"},
            {"area": "新蔡县", "code": "411729000000"},
            {"area": "河南驻马店经济开发区", "code": "411771000000"}
          ]
        },
        {
          "city": "省直辖县级行政区划",
          "code": "419000000000",
          "areas": [
            {"area": "济源市", "code": "419001000000"}
          ]
        }
      ]
    },
    {
      "province": "湖北省",
      "code": "420000",
      "citys": [
        {
          "city": "武汉市",
          "code": "420100000000",
          "areas": [
            {"area": "江岸区", "code": "420102000000"},
            {"area": "江汉区", "code": "420103000000"},
            {"area": "硚口区", "code": "420104000000"},
            {"area": "汉阳区", "code": "420105000000"},
            {"area": "武昌区", "code": "420106000000"},
            {"area": "青山区", "code": "420107000000"},
            {"area": "洪山区", "code": "420111000000"},
            {"area": "东西湖区", "code": "420112000000"},
            {"area": "汉南区", "code": "420113000000"},
            {"area": "蔡甸区", "code": "420114000000"},
            {"area": "江夏区", "code": "420115000000"},
            {"area": "黄陂区", "code": "420116000000"},
            {"area": "新洲区", "code": "420117000000"}
          ]
        },
        {
          "city": "黄石市",
          "code": "420200000000",
          "areas": [
            {"area": "黄石港区", "code": "420202000000"},
            {"area": "西塞山区", "code": "420203000000"},
            {"area": "下陆区", "code": "420204000000"},
            {"area": "铁山区", "code": "420205000000"},
            {"area": "阳新县", "code": "420222000000"},
            {"area": "大冶市", "code": "420281000000"}
          ]
        },
        {
          "city": "十堰市",
          "code": "420300000000",
          "areas": [
            {"area": "茅箭区", "code": "420302000000"},
            {"area": "张湾区", "code": "420303000000"},
            {"area": "郧阳区", "code": "420304000000"},
            {"area": "郧西县", "code": "420322000000"},
            {"area": "竹山县", "code": "420323000000"},
            {"area": "竹溪县", "code": "420324000000"},
            {"area": "房县", "code": "420325000000"},
            {"area": "丹江口市", "code": "420381000000"}
          ]
        },
        {
          "city": "宜昌市",
          "code": "420500000000",
          "areas": [
            {"area": "西陵区", "code": "420502000000"},
            {"area": "伍家岗区", "code": "420503000000"},
            {"area": "点军区", "code": "420504000000"},
            {"area": "猇亭区", "code": "420505000000"},
            {"area": "夷陵区", "code": "420506000000"},
            {"area": "远安县", "code": "420525000000"},
            {"area": "兴山县", "code": "420526000000"},
            {"area": "秭归县", "code": "420527000000"},
            {"area": "长阳土家族自治县", "code": "420528000000"},
            {"area": "五峰土家族自治县", "code": "420529000000"},
            {"area": "宜都市", "code": "420581000000"},
            {"area": "当阳市", "code": "420582000000"},
            {"area": "枝江市", "code": "420583000000"}
          ]
        },
        {
          "city": "襄阳市",
          "code": "420600000000",
          "areas": [
            {"area": "襄城区", "code": "420602000000"},
            {"area": "樊城区", "code": "420606000000"},
            {"area": "襄州区", "code": "420607000000"},
            {"area": "南漳县", "code": "420624000000"},
            {"area": "谷城县", "code": "420625000000"},
            {"area": "保康县", "code": "420626000000"},
            {"area": "老河口市", "code": "420682000000"},
            {"area": "枣阳市", "code": "420683000000"},
            {"area": "宜城市", "code": "420684000000"}
          ]
        },
        {
          "city": "鄂州市",
          "code": "420700000000",
          "areas": [
            {"area": "梁子湖区", "code": "420702000000"},
            {"area": "华容区", "code": "420703000000"},
            {"area": "鄂城区", "code": "420704000000"}
          ]
        },
        {
          "city": "荆门市",
          "code": "420800000000",
          "areas": [
            {"area": "东宝区", "code": "420802000000"},
            {"area": "掇刀区", "code": "420804000000"},
            {"area": "沙洋县", "code": "420822000000"},
            {"area": "钟祥市", "code": "420881000000"},
            {"area": "京山市", "code": "420882000000"}
          ]
        },
        {
          "city": "孝感市",
          "code": "420900000000",
          "areas": [
            {"area": "孝南区", "code": "420902000000"},
            {"area": "孝昌县", "code": "420921000000"},
            {"area": "大悟县", "code": "420922000000"},
            {"area": "云梦县", "code": "420923000000"},
            {"area": "应城市", "code": "420981000000"},
            {"area": "安陆市", "code": "420982000000"},
            {"area": "汉川市", "code": "420984000000"}
          ]
        },
        {
          "city": "荆州市",
          "code": "421000000000",
          "areas": [
            {"area": "沙市区", "code": "421002000000"},
            {"area": "荆州区", "code": "421003000000"},
            {"area": "公安县", "code": "421022000000"},
            {"area": "江陵县", "code": "421024000000"},
            {"area": "荆州经济技术开发区", "code": "421071000000"},
            {"area": "石首市", "code": "421081000000"},
            {"area": "洪湖市", "code": "421083000000"},
            {"area": "松滋市", "code": "421087000000"},
            {"area": "监利市", "code": "421088000000"}
          ]
        },
        {
          "city": "黄冈市",
          "code": "421100000000",
          "areas": [
            {"area": "黄州区", "code": "421102000000"},
            {"area": "团风县", "code": "421121000000"},
            {"area": "红安县", "code": "421122000000"},
            {"area": "罗田县", "code": "421123000000"},
            {"area": "英山县", "code": "421124000000"},
            {"area": "浠水县", "code": "421125000000"},
            {"area": "蕲春县", "code": "421126000000"},
            {"area": "黄梅县", "code": "421127000000"},
            {"area": "龙感湖管理区", "code": "421171000000"},
            {"area": "麻城市", "code": "421181000000"},
            {"area": "武穴市", "code": "421182000000"}
          ]
        },
        {
          "city": "咸宁市",
          "code": "421200000000",
          "areas": [
            {"area": "咸安区", "code": "421202000000"},
            {"area": "嘉鱼县", "code": "421221000000"},
            {"area": "通城县", "code": "421222000000"},
            {"area": "崇阳县", "code": "421223000000"},
            {"area": "通山县", "code": "421224000000"},
            {"area": "赤壁市", "code": "421281000000"}
          ]
        },
        {
          "city": "随州市",
          "code": "421300000000",
          "areas": [
            {"area": "曾都区", "code": "421303000000"},
            {"area": "随县", "code": "421321000000"},
            {"area": "广水市", "code": "421381000000"}
          ]
        },
        {
          "city": "恩施土家族苗族自治州",
          "code": "422800000000",
          "areas": [
            {"area": "恩施市", "code": "422801000000"},
            {"area": "利川市", "code": "422802000000"},
            {"area": "建始县", "code": "422822000000"},
            {"area": "巴东县", "code": "422823000000"},
            {"area": "宣恩县", "code": "422825000000"},
            {"area": "咸丰县", "code": "422826000000"},
            {"area": "来凤县", "code": "422827000000"},
            {"area": "鹤峰县", "code": "422828000000"}
          ]
        },
        {
          "city": "省直辖县级行政区划",
          "code": "429000000000",
          "areas": [
            {"area": "仙桃市", "code": "429004000000"},
            {"area": "潜江市", "code": "429005000000"},
            {"area": "天门市", "code": "429006000000"},
            {"area": "神农架林区", "code": "429021000000"}
          ]
        }
      ]
    },
    {
      "province": "湖南省",
      "code": "430000",
      "citys": [
        {
          "city": "长沙市",
          "code": "430100000000",
          "areas": [
            {"area": "芙蓉区", "code": "430102000000"},
            {"area": "天心区", "code": "430103000000"},
            {"area": "岳麓区", "code": "430104000000"},
            {"area": "开福区", "code": "430105000000"},
            {"area": "雨花区", "code": "430111000000"},
            {"area": "望城区", "code": "430112000000"},
            {"area": "长沙县", "code": "430121000000"},
            {"area": "浏阳市", "code": "430181000000"},
            {"area": "宁乡市", "code": "430182000000"}
          ]
        },
        {
          "city": "株洲市",
          "code": "430200000000",
          "areas": [
            {"area": "荷塘区", "code": "430202000000"},
            {"area": "芦淞区", "code": "430203000000"},
            {"area": "石峰区", "code": "430204000000"},
            {"area": "天元区", "code": "430211000000"},
            {"area": "渌口区", "code": "430212000000"},
            {"area": "攸县", "code": "430223000000"},
            {"area": "茶陵县", "code": "430224000000"},
            {"area": "炎陵县", "code": "430225000000"},
            {"area": "醴陵市", "code": "430281000000"}
          ]
        },
        {
          "city": "湘潭市",
          "code": "430300000000",
          "areas": [
            {"area": "雨湖区", "code": "430302000000"},
            {"area": "岳塘区", "code": "430304000000"},
            {"area": "湘潭县", "code": "430321000000"},
            {"area": "湖南湘潭高新技术产业园区", "code": "430371000000"},
            {"area": "湘潭昭山示范区", "code": "430372000000"},
            {"area": "湘潭九华示范区", "code": "430373000000"},
            {"area": "湘乡市", "code": "430381000000"},
            {"area": "韶山市", "code": "430382000000"}
          ]
        },
        {
          "city": "衡阳市",
          "code": "430400000000",
          "areas": [
            {"area": "珠晖区", "code": "430405000000"},
            {"area": "雁峰区", "code": "430406000000"},
            {"area": "石鼓区", "code": "430407000000"},
            {"area": "蒸湘区", "code": "430408000000"},
            {"area": "南岳区", "code": "430412000000"},
            {"area": "衡阳县", "code": "430421000000"},
            {"area": "衡南县", "code": "430422000000"},
            {"area": "衡山县", "code": "430423000000"},
            {"area": "衡东县", "code": "430424000000"},
            {"area": "祁东县", "code": "430426000000"},
            {"area": "湖南衡阳松木经济开发区", "code": "430473000000"},
            {"area": "湖南衡阳高新技术产业园区", "code": "430476000000"},
            {"area": "耒阳市", "code": "430481000000"},
            {"area": "常宁市", "code": "430482000000"}
          ]
        },
        {
          "city": "邵阳市",
          "code": "430500000000",
          "areas": [
            {"area": "双清区", "code": "430502000000"},
            {"area": "大祥区", "code": "430503000000"},
            {"area": "北塔区", "code": "430511000000"},
            {"area": "新邵县", "code": "430522000000"},
            {"area": "邵阳县", "code": "430523000000"},
            {"area": "隆回县", "code": "430524000000"},
            {"area": "洞口县", "code": "430525000000"},
            {"area": "绥宁县", "code": "430527000000"},
            {"area": "新宁县", "code": "430528000000"},
            {"area": "城步苗族自治县", "code": "430529000000"},
            {"area": "武冈市", "code": "430581000000"},
            {"area": "邵东市", "code": "430582000000"}
          ]
        },
        {
          "city": "岳阳市",
          "code": "430600000000",
          "areas": [
            {"area": "岳阳楼区", "code": "430602000000"},
            {"area": "云溪区", "code": "430603000000"},
            {"area": "君山区", "code": "430611000000"},
            {"area": "岳阳县", "code": "430621000000"},
            {"area": "华容县", "code": "430623000000"},
            {"area": "湘阴县", "code": "430624000000"},
            {"area": "平江县", "code": "430626000000"},
            {"area": "岳阳市屈原管理区", "code": "430671000000"},
            {"area": "汨罗市", "code": "430681000000"},
            {"area": "临湘市", "code": "430682000000"}
          ]
        },
        {
          "city": "常德市",
          "code": "430700000000",
          "areas": [
            {"area": "武陵区", "code": "430702000000"},
            {"area": "鼎城区", "code": "430703000000"},
            {"area": "安乡县", "code": "430721000000"},
            {"area": "汉寿县", "code": "430722000000"},
            {"area": "澧县", "code": "430723000000"},
            {"area": "临澧县", "code": "430724000000"},
            {"area": "桃源县", "code": "430725000000"},
            {"area": "石门县", "code": "430726000000"},
            {"area": "常德市西洞庭管理区", "code": "430771000000"},
            {"area": "津市市", "code": "430781000000"}
          ]
        },
        {
          "city": "张家界市",
          "code": "430800000000",
          "areas": [
            {"area": "永定区", "code": "430802000000"},
            {"area": "武陵源区", "code": "430811000000"},
            {"area": "慈利县", "code": "430821000000"},
            {"area": "桑植县", "code": "430822000000"}
          ]
        },
        {
          "city": "益阳市",
          "code": "430900000000",
          "areas": [
            {"area": "资阳区", "code": "430902000000"},
            {"area": "赫山区", "code": "430903000000"},
            {"area": "南县", "code": "430921000000"},
            {"area": "桃江县", "code": "430922000000"},
            {"area": "安化县", "code": "430923000000"},
            {"area": "益阳市大通湖管理区", "code": "430971000000"},
            {"area": "湖南益阳高新技术产业园区", "code": "430972000000"},
            {"area": "沅江市", "code": "430981000000"}
          ]
        },
        {
          "city": "郴州市",
          "code": "431000000000",
          "areas": [
            {"area": "北湖区", "code": "431002000000"},
            {"area": "苏仙区", "code": "431003000000"},
            {"area": "桂阳县", "code": "431021000000"},
            {"area": "宜章县", "code": "431022000000"},
            {"area": "永兴县", "code": "431023000000"},
            {"area": "嘉禾县", "code": "431024000000"},
            {"area": "临武县", "code": "431025000000"},
            {"area": "汝城县", "code": "431026000000"},
            {"area": "桂东县", "code": "431027000000"},
            {"area": "安仁县", "code": "431028000000"},
            {"area": "资兴市", "code": "431081000000"}
          ]
        },
        {
          "city": "永州市",
          "code": "431100000000",
          "areas": [
            {"area": "零陵区", "code": "431102000000"},
            {"area": "冷水滩区", "code": "431103000000"},
            {"area": "东安县", "code": "431122000000"},
            {"area": "双牌县", "code": "431123000000"},
            {"area": "道县", "code": "431124000000"},
            {"area": "江永县", "code": "431125000000"},
            {"area": "宁远县", "code": "431126000000"},
            {"area": "蓝山县", "code": "431127000000"},
            {"area": "新田县", "code": "431128000000"},
            {"area": "江华瑶族自治县", "code": "431129000000"},
            {"area": "永州经济技术开发区", "code": "431171000000"},
            {"area": "永州市回龙圩管理区", "code": "431173000000"},
            {"area": "祁阳市", "code": "431181000000"}
          ]
        },
        {
          "city": "怀化市",
          "code": "431200000000",
          "areas": [
            {"area": "鹤城区", "code": "431202000000"},
            {"area": "中方县", "code": "431221000000"},
            {"area": "沅陵县", "code": "431222000000"},
            {"area": "辰溪县", "code": "431223000000"},
            {"area": "溆浦县", "code": "431224000000"},
            {"area": "会同县", "code": "431225000000"},
            {"area": "麻阳苗族自治县", "code": "431226000000"},
            {"area": "新晃侗族自治县", "code": "431227000000"},
            {"area": "芷江侗族自治县", "code": "431228000000"},
            {"area": "靖州苗族侗族自治县", "code": "431229000000"},
            {"area": "通道侗族自治县", "code": "431230000000"},
            {"area": "怀化市洪江管理区", "code": "431271000000"},
            {"area": "洪江市", "code": "431281000000"}
          ]
        },
        {
          "city": "娄底市",
          "code": "431300000000",
          "areas": [
            {"area": "娄星区", "code": "431302000000"},
            {"area": "双峰县", "code": "431321000000"},
            {"area": "新化县", "code": "431322000000"},
            {"area": "冷水江市", "code": "431381000000"},
            {"area": "涟源市", "code": "431382000000"}
          ]
        },
        {
          "city": "湘西土家族苗族自治州",
          "code": "433100000000",
          "areas": [
            {"area": "吉首市", "code": "433101000000"},
            {"area": "泸溪县", "code": "433122000000"},
            {"area": "凤凰县", "code": "433123000000"},
            {"area": "花垣县", "code": "433124000000"},
            {"area": "保靖县", "code": "433125000000"},
            {"area": "古丈县", "code": "433126000000"},
            {"area": "永顺县", "code": "433127000000"},
            {"area": "龙山县", "code": "433130000000"}
          ]
        }
      ]
    },
    {
      "province": "广东省",
      "code": "440000",
      "citys": [
        {
          "city": "广州市",
          "code": "440100000000",
          "areas": [
            {"area": "荔湾区", "code": "440103000000"},
            {"area": "越秀区", "code": "440104000000"},
            {"area": "海珠区", "code": "440105000000"},
            {"area": "天河区", "code": "440106000000"},
            {"area": "白云区", "code": "440111000000"},
            {"area": "黄埔区", "code": "440112000000"},
            {"area": "番禺区", "code": "440113000000"},
            {"area": "花都区", "code": "440114000000"},
            {"area": "南沙区", "code": "440115000000"},
            {"area": "从化区", "code": "440117000000"},
            {"area": "增城区", "code": "440118000000"}
          ]
        },
        {
          "city": "韶关市",
          "code": "440200000000",
          "areas": [
            {"area": "武江区", "code": "440203000000"},
            {"area": "浈江区", "code": "440204000000"},
            {"area": "曲江区", "code": "440205000000"},
            {"area": "始兴县", "code": "440222000000"},
            {"area": "仁化县", "code": "440224000000"},
            {"area": "翁源县", "code": "440229000000"},
            {"area": "乳源瑶族自治县", "code": "440232000000"},
            {"area": "新丰县", "code": "440233000000"},
            {"area": "乐昌市", "code": "440281000000"},
            {"area": "南雄市", "code": "440282000000"}
          ]
        },
        {
          "city": "深圳市",
          "code": "440300000000",
          "areas": [
            {"area": "罗湖区", "code": "440303000000"},
            {"area": "福田区", "code": "440304000000"},
            {"area": "南山区", "code": "440305000000"},
            {"area": "宝安区", "code": "440306000000"},
            {"area": "龙岗区", "code": "440307000000"},
            {"area": "盐田区", "code": "440308000000"},
            {"area": "龙华区", "code": "440309000000"},
            {"area": "坪山区", "code": "440310000000"},
            {"area": "光明区", "code": "440311000000"}
          ]
        },
        {
          "city": "珠海市",
          "code": "440400000000",
          "areas": [
            {"area": "香洲区", "code": "440402000000"},
            {"area": "斗门区", "code": "440403000000"},
            {"area": "金湾区", "code": "440404000000"}
          ]
        },
        {
          "city": "汕头市",
          "code": "440500000000",
          "areas": [
            {"area": "龙湖区", "code": "440507000000"},
            {"area": "金平区", "code": "440511000000"},
            {"area": "濠江区", "code": "440512000000"},
            {"area": "潮阳区", "code": "440513000000"},
            {"area": "潮南区", "code": "440514000000"},
            {"area": "澄海区", "code": "440515000000"},
            {"area": "南澳县", "code": "440523000000"}
          ]
        },
        {
          "city": "佛山市",
          "code": "440600000000",
          "areas": [
            {"area": "禅城区", "code": "440604000000"},
            {"area": "南海区", "code": "440605000000"},
            {"area": "顺德区", "code": "440606000000"},
            {"area": "三水区", "code": "440607000000"},
            {"area": "高明区", "code": "440608000000"}
          ]
        },
        {
          "city": "江门市",
          "code": "440700000000",
          "areas": [
            {"area": "蓬江区", "code": "440703000000"},
            {"area": "江海区", "code": "440704000000"},
            {"area": "新会区", "code": "440705000000"},
            {"area": "台山市", "code": "440781000000"},
            {"area": "开平市", "code": "440783000000"},
            {"area": "鹤山市", "code": "440784000000"},
            {"area": "恩平市", "code": "440785000000"}
          ]
        },
        {
          "city": "湛江市",
          "code": "440800000000",
          "areas": [
            {"area": "赤坎区", "code": "440802000000"},
            {"area": "霞山区", "code": "440803000000"},
            {"area": "坡头区", "code": "440804000000"},
            {"area": "麻章区", "code": "440811000000"},
            {"area": "遂溪县", "code": "440823000000"},
            {"area": "徐闻县", "code": "440825000000"},
            {"area": "廉江市", "code": "440881000000"},
            {"area": "雷州市", "code": "440882000000"},
            {"area": "吴川市", "code": "440883000000"}
          ]
        },
        {
          "city": "茂名市",
          "code": "440900000000",
          "areas": [
            {"area": "茂南区", "code": "440902000000"},
            {"area": "电白区", "code": "440904000000"},
            {"area": "高州市", "code": "440981000000"},
            {"area": "化州市", "code": "440982000000"},
            {"area": "信宜市", "code": "440983000000"}
          ]
        },
        {
          "city": "肇庆市",
          "code": "441200000000",
          "areas": [
            {"area": "端州区", "code": "441202000000"},
            {"area": "鼎湖区", "code": "441203000000"},
            {"area": "高要区", "code": "441204000000"},
            {"area": "广宁县", "code": "441223000000"},
            {"area": "怀集县", "code": "441224000000"},
            {"area": "封开县", "code": "441225000000"},
            {"area": "德庆县", "code": "441226000000"},
            {"area": "四会市", "code": "441284000000"}
          ]
        },
        {
          "city": "惠州市",
          "code": "441300000000",
          "areas": [
            {"area": "惠城区", "code": "441302000000"},
            {"area": "惠阳区", "code": "441303000000"},
            {"area": "博罗县", "code": "441322000000"},
            {"area": "惠东县", "code": "441323000000"},
            {"area": "龙门县", "code": "441324000000"}
          ]
        },
        {
          "city": "梅州市",
          "code": "441400000000",
          "areas": [
            {"area": "梅江区", "code": "441402000000"},
            {"area": "梅县区", "code": "441403000000"},
            {"area": "大埔县", "code": "441422000000"},
            {"area": "丰顺县", "code": "441423000000"},
            {"area": "五华县", "code": "441424000000"},
            {"area": "平远县", "code": "441426000000"},
            {"area": "蕉岭县", "code": "441427000000"},
            {"area": "兴宁市", "code": "441481000000"}
          ]
        },
        {
          "city": "汕尾市",
          "code": "441500000000",
          "areas": [
            {"area": "城区", "code": "441502000000"},
            {"area": "海丰县", "code": "441521000000"},
            {"area": "陆河县", "code": "441523000000"},
            {"area": "陆丰市", "code": "441581000000"}
          ]
        },
        {
          "city": "河源市",
          "code": "441600000000",
          "areas": [
            {"area": "源城区", "code": "441602000000"},
            {"area": "紫金县", "code": "441621000000"},
            {"area": "龙川县", "code": "441622000000"},
            {"area": "连平县", "code": "441623000000"},
            {"area": "和平县", "code": "441624000000"},
            {"area": "东源县", "code": "441625000000"}
          ]
        },
        {
          "city": "阳江市",
          "code": "441700000000",
          "areas": [
            {"area": "江城区", "code": "441702000000"},
            {"area": "阳东区", "code": "441704000000"},
            {"area": "阳西县", "code": "441721000000"},
            {"area": "阳春市", "code": "441781000000"}
          ]
        },
        {
          "city": "清远市",
          "code": "441800000000",
          "areas": [
            {"area": "清城区", "code": "441802000000"},
            {"area": "清新区", "code": "441803000000"},
            {"area": "佛冈县", "code": "441821000000"},
            {"area": "阳山县", "code": "441823000000"},
            {"area": "连山壮族瑶族自治县", "code": "441825000000"},
            {"area": "连南瑶族自治县", "code": "441826000000"},
            {"area": "英德市", "code": "441881000000"},
            {"area": "连州市", "code": "441882000000"}
          ]
        },
        {
          "city": "东莞市",
          "code": "441900000000",
          "areas": [
            {"area": "东城街道", "code": "441900003000"},
            {"area": "南城街道", "code": "441900004000"},
            {"area": "万江街道", "code": "441900005000"},
            {"area": "莞城街道", "code": "441900006000"},
            {"area": "石碣镇", "code": "441900101000"},
            {"area": "石龙镇", "code": "441900102000"},
            {"area": "茶山镇", "code": "441900103000"},
            {"area": "石排镇", "code": "441900104000"},
            {"area": "企石镇", "code": "441900105000"},
            {"area": "横沥镇", "code": "441900106000"},
            {"area": "桥头镇", "code": "441900107000"},
            {"area": "谢岗镇", "code": "441900108000"},
            {"area": "东坑镇", "code": "441900109000"},
            {"area": "常平镇", "code": "441900110000"},
            {"area": "寮步镇", "code": "441900111000"},
            {"area": "樟木头镇", "code": "441900112000"},
            {"area": "大朗镇", "code": "441900113000"},
            {"area": "黄江镇", "code": "441900114000"},
            {"area": "清溪镇", "code": "441900115000"},
            {"area": "塘厦镇", "code": "441900116000"},
            {"area": "凤岗镇", "code": "441900117000"},
            {"area": "大岭山镇", "code": "441900118000"},
            {"area": "长安镇", "code": "441900119000"},
            {"area": "虎门镇", "code": "441900121000"},
            {"area": "厚街镇", "code": "441900122000"},
            {"area": "沙田镇", "code": "441900123000"},
            {"area": "道滘镇", "code": "441900124000"},
            {"area": "洪梅镇", "code": "441900125000"},
            {"area": "麻涌镇", "code": "441900126000"},
            {"area": "望牛墩镇", "code": "441900127000"},
            {"area": "中堂镇", "code": "441900128000"},
            {"area": "高埗镇", "code": "441900129000"},
            {"area": "松山湖", "code": "441900401000"},
            {"area": "东莞港", "code": "441900402000"},
            {"area": "东莞生态园", "code": "441900403000"},
            {"area": "东莞滨海湾新区", "code": "441900404000"}
          ]
        },
        {
          "city": "中山市",
          "code": "442000000000",
          "areas": [
            {"area": "石岐街道", "code": "442000001000"},
            {"area": "东区街道", "code": "442000002000"},
            {"area": "中山港街道", "code": "442000003000"},
            {"area": "西区街道", "code": "442000004000"},
            {"area": "南区街道", "code": "442000005000"},
            {"area": "五桂山街道", "code": "442000006000"},
            {"area": "民众街道", "code": "442000007000"},
            {"area": "南朗街道", "code": "442000008000"},
            {"area": "黄圃镇", "code": "442000101000"},
            {"area": "东凤镇", "code": "442000103000"},
            {"area": "古镇镇", "code": "442000105000"},
            {"area": "沙溪镇", "code": "442000106000"},
            {"area": "坦洲镇", "code": "442000107000"},
            {"area": "港口镇", "code": "442000108000"},
            {"area": "三角镇", "code": "442000109000"},
            {"area": "横栏镇", "code": "442000110000"},
            {"area": "南头镇", "code": "442000111000"},
            {"area": "阜沙镇", "code": "442000112000"},
            {"area": "三乡镇", "code": "442000114000"},
            {"area": "板芙镇", "code": "442000115000"},
            {"area": "大涌镇", "code": "442000116000"},
            {"area": "神湾镇", "code": "442000117000"},
            {"area": "小榄镇", "code": "442000118000"}
          ]
        },
        {
          "city": "潮州市",
          "code": "445100000000",
          "areas": [
            {"area": "湘桥区", "code": "445102000000"},
            {"area": "潮安区", "code": "445103000000"},
            {"area": "饶平县", "code": "445122000000"}
          ]
        },
        {
          "city": "揭阳市",
          "code": "445200000000",
          "areas": [
            {"area": "榕城区", "code": "445202000000"},
            {"area": "揭东区", "code": "445203000000"},
            {"area": "揭西县", "code": "445222000000"},
            {"area": "惠来县", "code": "445224000000"},
            {"area": "普宁市", "code": "445281000000"}
          ]
        },
        {
          "city": "云浮市",
          "code": "445300000000",
          "areas": [
            {"area": "云城区", "code": "445302000000"},
            {"area": "云安区", "code": "445303000000"},
            {"area": "新兴县", "code": "445321000000"},
            {"area": "郁南县", "code": "445322000000"},
            {"area": "罗定市", "code": "445381000000"}
          ]
        }
      ]
    },
    {
      "province": "广西壮族自治区",
      "code": "450000",
      "citys": [
        {
          "city": "南宁市",
          "code": "450100000000",
          "areas": [
            {"area": "兴宁区", "code": "450102000000"},
            {"area": "青秀区", "code": "450103000000"},
            {"area": "江南区", "code": "450105000000"},
            {"area": "西乡塘区", "code": "450107000000"},
            {"area": "良庆区", "code": "450108000000"},
            {"area": "邕宁区", "code": "450109000000"},
            {"area": "武鸣区", "code": "450110000000"},
            {"area": "隆安县", "code": "450123000000"},
            {"area": "马山县", "code": "450124000000"},
            {"area": "上林县", "code": "450125000000"},
            {"area": "宾阳县", "code": "450126000000"},
            {"area": "横州市", "code": "450181000000"}
          ]
        },
        {
          "city": "柳州市",
          "code": "450200000000",
          "areas": [
            {"area": "城中区", "code": "450202000000"},
            {"area": "鱼峰区", "code": "450203000000"},
            {"area": "柳南区", "code": "450204000000"},
            {"area": "柳北区", "code": "450205000000"},
            {"area": "柳江区", "code": "450206000000"},
            {"area": "柳城县", "code": "450222000000"},
            {"area": "鹿寨县", "code": "450223000000"},
            {"area": "融安县", "code": "450224000000"},
            {"area": "融水苗族自治县", "code": "450225000000"},
            {"area": "三江侗族自治县", "code": "450226000000"}
          ]
        },
        {
          "city": "桂林市",
          "code": "450300000000",
          "areas": [
            {"area": "秀峰区", "code": "450302000000"},
            {"area": "叠彩区", "code": "450303000000"},
            {"area": "象山区", "code": "450304000000"},
            {"area": "七星区", "code": "450305000000"},
            {"area": "雁山区", "code": "450311000000"},
            {"area": "临桂区", "code": "450312000000"},
            {"area": "阳朔县", "code": "450321000000"},
            {"area": "灵川县", "code": "450323000000"},
            {"area": "全州县", "code": "450324000000"},
            {"area": "兴安县", "code": "450325000000"},
            {"area": "永福县", "code": "450326000000"},
            {"area": "灌阳县", "code": "450327000000"},
            {"area": "龙胜各族自治县", "code": "450328000000"},
            {"area": "资源县", "code": "450329000000"},
            {"area": "平乐县", "code": "450330000000"},
            {"area": "恭城瑶族自治县", "code": "450332000000"},
            {"area": "荔浦市", "code": "450381000000"}
          ]
        },
        {
          "city": "梧州市",
          "code": "450400000000",
          "areas": [
            {"area": "万秀区", "code": "450403000000"},
            {"area": "长洲区", "code": "450405000000"},
            {"area": "龙圩区", "code": "450406000000"},
            {"area": "苍梧县", "code": "450421000000"},
            {"area": "藤县", "code": "450422000000"},
            {"area": "蒙山县", "code": "450423000000"},
            {"area": "岑溪市", "code": "450481000000"}
          ]
        },
        {
          "city": "北海市",
          "code": "450500000000",
          "areas": [
            {"area": "海城区", "code": "450502000000"},
            {"area": "银海区", "code": "450503000000"},
            {"area": "铁山港区", "code": "450512000000"},
            {"area": "合浦县", "code": "450521000000"}
          ]
        },
        {
          "city": "防城港市",
          "code": "450600000000",
          "areas": [
            {"area": "港口区", "code": "450602000000"},
            {"area": "防城区", "code": "450603000000"},
            {"area": "上思县", "code": "450621000000"},
            {"area": "东兴市", "code": "450681000000"}
          ]
        },
        {
          "city": "钦州市",
          "code": "450700000000",
          "areas": [
            {"area": "钦南区", "code": "450702000000"},
            {"area": "钦北区", "code": "450703000000"},
            {"area": "灵山县", "code": "450721000000"},
            {"area": "浦北县", "code": "450722000000"}
          ]
        },
        {
          "city": "贵港市",
          "code": "450800000000",
          "areas": [
            {"area": "港北区", "code": "450802000000"},
            {"area": "港南区", "code": "450803000000"},
            {"area": "覃塘区", "code": "450804000000"},
            {"area": "平南县", "code": "450821000000"},
            {"area": "桂平市", "code": "450881000000"}
          ]
        },
        {
          "city": "玉林市",
          "code": "450900000000",
          "areas": [
            {"area": "玉州区", "code": "450902000000"},
            {"area": "福绵区", "code": "450903000000"},
            {"area": "容县", "code": "450921000000"},
            {"area": "陆川县", "code": "450922000000"},
            {"area": "博白县", "code": "450923000000"},
            {"area": "兴业县", "code": "450924000000"},
            {"area": "北流市", "code": "450981000000"}
          ]
        },
        {
          "city": "百色市",
          "code": "451000000000",
          "areas": [
            {"area": "右江区", "code": "451002000000"},
            {"area": "田阳区", "code": "451003000000"},
            {"area": "田东县", "code": "451022000000"},
            {"area": "德保县", "code": "451024000000"},
            {"area": "那坡县", "code": "451026000000"},
            {"area": "凌云县", "code": "451027000000"},
            {"area": "乐业县", "code": "451028000000"},
            {"area": "田林县", "code": "451029000000"},
            {"area": "西林县", "code": "451030000000"},
            {"area": "隆林各族自治县", "code": "451031000000"},
            {"area": "靖西市", "code": "451081000000"},
            {"area": "平果市", "code": "451082000000"}
          ]
        },
        {
          "city": "贺州市",
          "code": "451100000000",
          "areas": [
            {"area": "八步区", "code": "451102000000"},
            {"area": "平桂区", "code": "451103000000"},
            {"area": "昭平县", "code": "451121000000"},
            {"area": "钟山县", "code": "451122000000"},
            {"area": "富川瑶族自治县", "code": "451123000000"}
          ]
        },
        {
          "city": "河池市",
          "code": "451200000000",
          "areas": [
            {"area": "金城江区", "code": "451202000000"},
            {"area": "宜州区", "code": "451203000000"},
            {"area": "南丹县", "code": "451221000000"},
            {"area": "天峨县", "code": "451222000000"},
            {"area": "凤山县", "code": "451223000000"},
            {"area": "东兰县", "code": "451224000000"},
            {"area": "罗城仫佬族自治县", "code": "451225000000"},
            {"area": "环江毛南族自治县", "code": "451226000000"},
            {"area": "巴马瑶族自治县", "code": "451227000000"},
            {"area": "都安瑶族自治县", "code": "451228000000"},
            {"area": "大化瑶族自治县", "code": "451229000000"}
          ]
        },
        {
          "city": "来宾市",
          "code": "451300000000",
          "areas": [
            {"area": "兴宾区", "code": "451302000000"},
            {"area": "忻城县", "code": "451321000000"},
            {"area": "象州县", "code": "451322000000"},
            {"area": "武宣县", "code": "451323000000"},
            {"area": "金秀瑶族自治县", "code": "451324000000"},
            {"area": "合山市", "code": "451381000000"}
          ]
        },
        {
          "city": "崇左市",
          "code": "451400000000",
          "areas": [
            {"area": "江州区", "code": "451402000000"},
            {"area": "扶绥县", "code": "451421000000"},
            {"area": "宁明县", "code": "451422000000"},
            {"area": "龙州县", "code": "451423000000"},
            {"area": "大新县", "code": "451424000000"},
            {"area": "天等县", "code": "451425000000"},
            {"area": "凭祥市", "code": "451481000000"}
          ]
        }
      ]
    },
    {
      "province": "海南省",
      "code": "460000",
      "citys": [
        {
          "city": "海口市",
          "code": "460100000000",
          "areas": [
            {"area": "秀英区", "code": "460105000000"},
            {"area": "龙华区", "code": "460106000000"},
            {"area": "琼山区", "code": "460107000000"},
            {"area": "美兰区", "code": "460108000000"}
          ]
        },
        {
          "city": "三亚市",
          "code": "460200000000",
          "areas": [
            {"area": "海棠区", "code": "460202000000"},
            {"area": "吉阳区", "code": "460203000000"},
            {"area": "天涯区", "code": "460204000000"},
            {"area": "崖州区", "code": "460205000000"}
          ]
        },
        {
          "city": "三沙市",
          "code": "460300000000",
          "areas": [
            {"area": "西沙群岛", "code": "460321000000"},
            {"area": "南沙群岛", "code": "460322000000"},
            {"area": "中沙群岛的岛礁及其海域", "code": "460323000000"}
          ]
        },
        {
          "city": "儋州市",
          "code": "460400000000",
          "areas": [
            {"area": "那大镇", "code": "460400100000"},
            {"area": "和庆镇", "code": "460400101000"},
            {"area": "南丰镇", "code": "460400102000"},
            {"area": "大成镇", "code": "460400103000"},
            {"area": "雅星镇", "code": "460400104000"},
            {"area": "兰洋镇", "code": "460400105000"},
            {"area": "光村镇", "code": "460400106000"},
            {"area": "木棠镇", "code": "460400107000"},
            {"area": "海头镇", "code": "460400108000"},
            {"area": "峨蔓镇", "code": "460400109000"},
            {"area": "王五镇", "code": "460400111000"},
            {"area": "白马井镇", "code": "460400112000"},
            {"area": "中和镇", "code": "460400113000"},
            {"area": "排浦镇", "code": "460400114000"},
            {"area": "东成镇", "code": "460400115000"},
            {"area": "新州镇", "code": "460400116000"},
            {"area": "洋浦经济开发区", "code": "460400499000"},
            {"area": "华南热作学院", "code": "460400500000"}
          ]
        },
        {
          "city": "省直辖县级行政区划",
          "code": "469000000000",
          "areas": [
            {"area": "五指山市", "code": "469001000000"},
            {"area": "琼海市", "code": "469002000000"},
            {"area": "文昌市", "code": "469005000000"},
            {"area": "万宁市", "code": "469006000000"},
            {"area": "东方市", "code": "469007000000"},
            {"area": "定安县", "code": "469021000000"},
            {"area": "屯昌县", "code": "469022000000"},
            {"area": "澄迈县", "code": "469023000000"},
            {"area": "临高县", "code": "469024000000"},
            {"area": "白沙黎族自治县", "code": "469025000000"},
            {"area": "昌江黎族自治县", "code": "469026000000"},
            {"area": "乐东黎族自治县", "code": "469027000000"},
            {"area": "陵水黎族自治县", "code": "469028000000"},
            {"area": "保亭黎族苗族自治县", "code": "469029000000"},
            {"area": "琼中黎族苗族自治县", "code": "469030000000"}
          ]
        }
      ]
    },
    {
      "province": "重庆市",
      "code": "500000",
      "citys": [
        {
          "city": "市辖区",
          "code": "500100000000",
          "areas": [
            {"area": "万州区", "code": "500101000000"},
            {"area": "涪陵区", "code": "500102000000"},
            {"area": "渝中区", "code": "500103000000"},
            {"area": "大渡口区", "code": "500104000000"},
            {"area": "江北区", "code": "500105000000"},
            {"area": "沙坪坝区", "code": "500106000000"},
            {"area": "九龙坡区", "code": "500107000000"},
            {"area": "南岸区", "code": "500108000000"},
            {"area": "北碚区", "code": "500109000000"},
            {"area": "綦江区", "code": "500110000000"},
            {"area": "大足区", "code": "500111000000"},
            {"area": "渝北区", "code": "500112000000"},
            {"area": "巴南区", "code": "500113000000"},
            {"area": "黔江区", "code": "500114000000"},
            {"area": "长寿区", "code": "500115000000"},
            {"area": "江津区", "code": "500116000000"},
            {"area": "合川区", "code": "500117000000"},
            {"area": "永川区", "code": "500118000000"},
            {"area": "南川区", "code": "500119000000"},
            {"area": "璧山区", "code": "500120000000"},
            {"area": "铜梁区", "code": "500151000000"},
            {"area": "潼南区", "code": "500152000000"},
            {"area": "荣昌区", "code": "500153000000"},
            {"area": "开州区", "code": "500154000000"},
            {"area": "梁平区", "code": "500155000000"},
            {"area": "武隆区", "code": "500156000000"}
          ]
        },
        {
          "city": "县",
          "code": "500200000000",
          "areas": [
            {"area": "城口县", "code": "500229000000"},
            {"area": "丰都县", "code": "500230000000"},
            {"area": "垫江县", "code": "500231000000"},
            {"area": "忠县", "code": "500233000000"},
            {"area": "云阳县", "code": "500235000000"},
            {"area": "奉节县", "code": "500236000000"},
            {"area": "巫山县", "code": "500237000000"},
            {"area": "巫溪县", "code": "500238000000"},
            {"area": "石柱土家族自治县", "code": "500240000000"},
            {"area": "秀山土家族苗族自治县", "code": "500241000000"},
            {"area": "酉阳土家族苗族自治县", "code": "500242000000"},
            {"area": "彭水苗族土家族自治县", "code": "500243000000"}
          ]
        }
      ]
    },
    {
      "province": "四川省",
      "code": "510000",
      "citys": [
        {
          "city": "成都市",
          "code": "510100000000",
          "areas": [
            {"area": "锦江区", "code": "510104000000"},
            {"area": "青羊区", "code": "510105000000"},
            {"area": "金牛区", "code": "510106000000"},
            {"area": "武侯区", "code": "510107000000"},
            {"area": "成华区", "code": "510108000000"},
            {"area": "龙泉驿区", "code": "510112000000"},
            {"area": "青白江区", "code": "510113000000"},
            {"area": "新都区", "code": "510114000000"},
            {"area": "温江区", "code": "510115000000"},
            {"area": "双流区", "code": "510116000000"},
            {"area": "郫都区", "code": "510117000000"},
            {"area": "新津区", "code": "510118000000"},
            {"area": "金堂县", "code": "510121000000"},
            {"area": "大邑县", "code": "510129000000"},
            {"area": "蒲江县", "code": "510131000000"},
            {"area": "都江堰市", "code": "510181000000"},
            {"area": "彭州市", "code": "510182000000"},
            {"area": "邛崃市", "code": "510183000000"},
            {"area": "崇州市", "code": "510184000000"},
            {"area": "简阳市", "code": "510185000000"}
          ]
        },
        {
          "city": "自贡市",
          "code": "510300000000",
          "areas": [
            {"area": "自流井区", "code": "510302000000"},
            {"area": "贡井区", "code": "510303000000"},
            {"area": "大安区", "code": "510304000000"},
            {"area": "沿滩区", "code": "510311000000"},
            {"area": "荣县", "code": "510321000000"},
            {"area": "富顺县", "code": "510322000000"}
          ]
        },
        {
          "city": "攀枝花市",
          "code": "510400000000",
          "areas": [
            {"area": "东区", "code": "510402000000"},
            {"area": "西区", "code": "510403000000"},
            {"area": "仁和区", "code": "510411000000"},
            {"area": "米易县", "code": "510421000000"},
            {"area": "盐边县", "code": "510422000000"}
          ]
        },
        {
          "city": "泸州市",
          "code": "510500000000",
          "areas": [
            {"area": "江阳区", "code": "510502000000"},
            {"area": "纳溪区", "code": "510503000000"},
            {"area": "龙马潭区", "code": "510504000000"},
            {"area": "泸县", "code": "510521000000"},
            {"area": "合江县", "code": "510522000000"},
            {"area": "叙永县", "code": "510524000000"},
            {"area": "古蔺县", "code": "510525000000"}
          ]
        },
        {
          "city": "德阳市",
          "code": "510600000000",
          "areas": [
            {"area": "旌阳区", "code": "510603000000"},
            {"area": "罗江区", "code": "510604000000"},
            {"area": "中江县", "code": "510623000000"},
            {"area": "广汉市", "code": "510681000000"},
            {"area": "什邡市", "code": "510682000000"},
            {"area": "绵竹市", "code": "510683000000"}
          ]
        },
        {
          "city": "绵阳市",
          "code": "510700000000",
          "areas": [
            {"area": "涪城区", "code": "510703000000"},
            {"area": "游仙区", "code": "510704000000"},
            {"area": "安州区", "code": "510705000000"},
            {"area": "三台县", "code": "510722000000"},
            {"area": "盐亭县", "code": "510723000000"},
            {"area": "梓潼县", "code": "510725000000"},
            {"area": "北川羌族自治县", "code": "510726000000"},
            {"area": "平武县", "code": "510727000000"},
            {"area": "江油市", "code": "510781000000"}
          ]
        },
        {
          "city": "广元市",
          "code": "510800000000",
          "areas": [
            {"area": "利州区", "code": "510802000000"},
            {"area": "昭化区", "code": "510811000000"},
            {"area": "朝天区", "code": "510812000000"},
            {"area": "旺苍县", "code": "510821000000"},
            {"area": "青川县", "code": "510822000000"},
            {"area": "剑阁县", "code": "510823000000"},
            {"area": "苍溪县", "code": "510824000000"}
          ]
        },
        {
          "city": "遂宁市",
          "code": "510900000000",
          "areas": [
            {"area": "船山区", "code": "510903000000"},
            {"area": "安居区", "code": "510904000000"},
            {"area": "蓬溪县", "code": "510921000000"},
            {"area": "大英县", "code": "510923000000"},
            {"area": "射洪市", "code": "510981000000"}
          ]
        },
        {
          "city": "内江市",
          "code": "511000000000",
          "areas": [
            {"area": "市中区", "code": "511002000000"},
            {"area": "东兴区", "code": "511011000000"},
            {"area": "威远县", "code": "511024000000"},
            {"area": "资中县", "code": "511025000000"},
            {"area": "隆昌市", "code": "511083000000"}
          ]
        },
        {
          "city": "乐山市",
          "code": "511100000000",
          "areas": [
            {"area": "市中区", "code": "511102000000"},
            {"area": "沙湾区", "code": "511111000000"},
            {"area": "五通桥区", "code": "511112000000"},
            {"area": "金口河区", "code": "511113000000"},
            {"area": "犍为县", "code": "511123000000"},
            {"area": "井研县", "code": "511124000000"},
            {"area": "夹江县", "code": "511126000000"},
            {"area": "沐川县", "code": "511129000000"},
            {"area": "峨边彝族自治县", "code": "511132000000"},
            {"area": "马边彝族自治县", "code": "511133000000"},
            {"area": "峨眉山市", "code": "511181000000"}
          ]
        },
        {
          "city": "南充市",
          "code": "511300000000",
          "areas": [
            {"area": "顺庆区", "code": "511302000000"},
            {"area": "高坪区", "code": "511303000000"},
            {"area": "嘉陵区", "code": "511304000000"},
            {"area": "南部县", "code": "511321000000"},
            {"area": "营山县", "code": "511322000000"},
            {"area": "蓬安县", "code": "511323000000"},
            {"area": "仪陇县", "code": "511324000000"},
            {"area": "西充县", "code": "511325000000"},
            {"area": "阆中市", "code": "511381000000"}
          ]
        },
        {
          "city": "眉山市",
          "code": "511400000000",
          "areas": [
            {"area": "东坡区", "code": "511402000000"},
            {"area": "彭山区", "code": "511403000000"},
            {"area": "仁寿县", "code": "511421000000"},
            {"area": "洪雅县", "code": "511423000000"},
            {"area": "丹棱县", "code": "511424000000"},
            {"area": "青神县", "code": "511425000000"}
          ]
        },
        {
          "city": "宜宾市",
          "code": "511500000000",
          "areas": [
            {"area": "翠屏区", "code": "511502000000"},
            {"area": "南溪区", "code": "511503000000"},
            {"area": "叙州区", "code": "511504000000"},
            {"area": "江安县", "code": "511523000000"},
            {"area": "长宁县", "code": "511524000000"},
            {"area": "高县", "code": "511525000000"},
            {"area": "珙县", "code": "511526000000"},
            {"area": "筠连县", "code": "511527000000"},
            {"area": "兴文县", "code": "511528000000"},
            {"area": "屏山县", "code": "511529000000"}
          ]
        },
        {
          "city": "广安市",
          "code": "511600000000",
          "areas": [
            {"area": "广安区", "code": "511602000000"},
            {"area": "前锋区", "code": "511603000000"},
            {"area": "岳池县", "code": "511621000000"},
            {"area": "武胜县", "code": "511622000000"},
            {"area": "邻水县", "code": "511623000000"},
            {"area": "华蓥市", "code": "511681000000"}
          ]
        },
        {
          "city": "达州市",
          "code": "511700000000",
          "areas": [
            {"area": "通川区", "code": "511702000000"},
            {"area": "达川区", "code": "511703000000"},
            {"area": "宣汉县", "code": "511722000000"},
            {"area": "开江县", "code": "511723000000"},
            {"area": "大竹县", "code": "511724000000"},
            {"area": "渠县", "code": "511725000000"},
            {"area": "万源市", "code": "511781000000"}
          ]
        },
        {
          "city": "雅安市",
          "code": "511800000000",
          "areas": [
            {"area": "雨城区", "code": "511802000000"},
            {"area": "名山区", "code": "511803000000"},
            {"area": "荥经县", "code": "511822000000"},
            {"area": "汉源县", "code": "511823000000"},
            {"area": "石棉县", "code": "511824000000"},
            {"area": "天全县", "code": "511825000000"},
            {"area": "芦山县", "code": "511826000000"},
            {"area": "宝兴县", "code": "511827000000"}
          ]
        },
        {
          "city": "巴中市",
          "code": "511900000000",
          "areas": [
            {"area": "巴州区", "code": "511902000000"},
            {"area": "恩阳区", "code": "511903000000"},
            {"area": "通江县", "code": "511921000000"},
            {"area": "南江县", "code": "511922000000"},
            {"area": "平昌县", "code": "511923000000"}
          ]
        },
        {
          "city": "资阳市",
          "code": "512000000000",
          "areas": [
            {"area": "雁江区", "code": "512002000000"},
            {"area": "安岳县", "code": "512021000000"},
            {"area": "乐至县", "code": "512022000000"}
          ]
        },
        {
          "city": "阿坝藏族羌族自治州",
          "code": "513200000000",
          "areas": [
            {"area": "马尔康市", "code": "513201000000"},
            {"area": "汶川县", "code": "513221000000"},
            {"area": "理县", "code": "513222000000"},
            {"area": "茂县", "code": "513223000000"},
            {"area": "松潘县", "code": "513224000000"},
            {"area": "九寨沟县", "code": "513225000000"},
            {"area": "金川县", "code": "513226000000"},
            {"area": "小金县", "code": "513227000000"},
            {"area": "黑水县", "code": "513228000000"},
            {"area": "壤塘县", "code": "513230000000"},
            {"area": "阿坝县", "code": "513231000000"},
            {"area": "若尔盖县", "code": "513232000000"},
            {"area": "红原县", "code": "513233000000"}
          ]
        },
        {
          "city": "甘孜藏族自治州",
          "code": "513300000000",
          "areas": [
            {"area": "康定市", "code": "513301000000"},
            {"area": "泸定县", "code": "513322000000"},
            {"area": "丹巴县", "code": "513323000000"},
            {"area": "九龙县", "code": "513324000000"},
            {"area": "雅江县", "code": "513325000000"},
            {"area": "道孚县", "code": "513326000000"},
            {"area": "炉霍县", "code": "513327000000"},
            {"area": "甘孜县", "code": "513328000000"},
            {"area": "新龙县", "code": "513329000000"},
            {"area": "德格县", "code": "513330000000"},
            {"area": "白玉县", "code": "513331000000"},
            {"area": "石渠县", "code": "513332000000"},
            {"area": "色达县", "code": "513333000000"},
            {"area": "理塘县", "code": "513334000000"},
            {"area": "巴塘县", "code": "513335000000"},
            {"area": "乡城县", "code": "513336000000"},
            {"area": "稻城县", "code": "513337000000"},
            {"area": "得荣县", "code": "513338000000"}
          ]
        },
        {
          "city": "凉山彝族自治州",
          "code": "513400000000",
          "areas": [
            {"area": "西昌市", "code": "513401000000"},
            {"area": "会理市", "code": "513402000000"},
            {"area": "木里藏族自治县", "code": "513422000000"},
            {"area": "盐源县", "code": "513423000000"},
            {"area": "德昌县", "code": "513424000000"},
            {"area": "会东县", "code": "513426000000"},
            {"area": "宁南县", "code": "513427000000"},
            {"area": "普格县", "code": "513428000000"},
            {"area": "布拖县", "code": "513429000000"},
            {"area": "金阳县", "code": "513430000000"},
            {"area": "昭觉县", "code": "513431000000"},
            {"area": "喜德县", "code": "513432000000"},
            {"area": "冕宁县", "code": "513433000000"},
            {"area": "越西县", "code": "513434000000"},
            {"area": "甘洛县", "code": "513435000000"},
            {"area": "美姑县", "code": "513436000000"},
            {"area": "雷波县", "code": "513437000000"}
          ]
        }
      ]
    },
    {
      "province": "贵州省",
      "code": "520000",
      "citys": [
        {
          "city": "贵阳市",
          "code": "520100000000",
          "areas": [
            {"area": "南明区", "code": "520102000000"},
            {"area": "云岩区", "code": "520103000000"},
            {"area": "花溪区", "code": "520111000000"},
            {"area": "乌当区", "code": "520112000000"},
            {"area": "白云区", "code": "520113000000"},
            {"area": "观山湖区", "code": "520115000000"},
            {"area": "开阳县", "code": "520121000000"},
            {"area": "息烽县", "code": "520122000000"},
            {"area": "修文县", "code": "520123000000"},
            {"area": "清镇市", "code": "520181000000"}
          ]
        },
        {
          "city": "六盘水市",
          "code": "520200000000",
          "areas": [
            {"area": "钟山区", "code": "520201000000"},
            {"area": "六枝特区", "code": "520203000000"},
            {"area": "水城区", "code": "520204000000"},
            {"area": "盘州市", "code": "520281000000"}
          ]
        },
        {
          "city": "遵义市",
          "code": "520300000000",
          "areas": [
            {"area": "红花岗区", "code": "520302000000"},
            {"area": "汇川区", "code": "520303000000"},
            {"area": "播州区", "code": "520304000000"},
            {"area": "桐梓县", "code": "520322000000"},
            {"area": "绥阳县", "code": "520323000000"},
            {"area": "正安县", "code": "520324000000"},
            {"area": "道真仡佬族苗族自治县", "code": "520325000000"},
            {"area": "务川仡佬族苗族自治县", "code": "520326000000"},
            {"area": "凤冈县", "code": "520327000000"},
            {"area": "湄潭县", "code": "520328000000"},
            {"area": "余庆县", "code": "520329000000"},
            {"area": "习水县", "code": "520330000000"},
            {"area": "赤水市", "code": "520381000000"},
            {"area": "仁怀市", "code": "520382000000"}
          ]
        },
        {
          "city": "安顺市",
          "code": "520400000000",
          "areas": [
            {"area": "西秀区", "code": "520402000000"},
            {"area": "平坝区", "code": "520403000000"},
            {"area": "普定县", "code": "520422000000"},
            {"area": "镇宁布依族苗族自治县", "code": "520423000000"},
            {"area": "关岭布依族苗族自治县", "code": "520424000000"},
            {"area": "紫云苗族布依族自治县", "code": "520425000000"}
          ]
        },
        {
          "city": "毕节市",
          "code": "520500000000",
          "areas": [
            {"area": "七星关区", "code": "520502000000"},
            {"area": "大方县", "code": "520521000000"},
            {"area": "金沙县", "code": "520523000000"},
            {"area": "织金县", "code": "520524000000"},
            {"area": "纳雍县", "code": "520525000000"},
            {"area": "威宁彝族回族苗族自治县", "code": "520526000000"},
            {"area": "赫章县", "code": "520527000000"},
            {"area": "黔西市", "code": "520581000000"}
          ]
        },
        {
          "city": "铜仁市",
          "code": "520600000000",
          "areas": [
            {"area": "碧江区", "code": "520602000000"},
            {"area": "万山区", "code": "520603000000"},
            {"area": "江口县", "code": "520621000000"},
            {"area": "玉屏侗族自治县", "code": "520622000000"},
            {"area": "石阡县", "code": "520623000000"},
            {"area": "思南县", "code": "520624000000"},
            {"area": "印江土家族苗族自治县", "code": "520625000000"},
            {"area": "德江县", "code": "520626000000"},
            {"area": "沿河土家族自治县", "code": "520627000000"},
            {"area": "松桃苗族自治县", "code": "520628000000"}
          ]
        },
        {
          "city": "黔西南布依族苗族自治州",
          "code": "522300000000",
          "areas": [
            {"area": "兴义市", "code": "522301000000"},
            {"area": "兴仁市", "code": "522302000000"},
            {"area": "普安县", "code": "522323000000"},
            {"area": "晴隆县", "code": "522324000000"},
            {"area": "贞丰县", "code": "522325000000"},
            {"area": "望谟县", "code": "522326000000"},
            {"area": "册亨县", "code": "522327000000"},
            {"area": "安龙县", "code": "522328000000"}
          ]
        },
        {
          "city": "黔东南苗族侗族自治州",
          "code": "522600000000",
          "areas": [
            {"area": "凯里市", "code": "522601000000"},
            {"area": "黄平县", "code": "522622000000"},
            {"area": "施秉县", "code": "522623000000"},
            {"area": "三穗县", "code": "522624000000"},
            {"area": "镇远县", "code": "522625000000"},
            {"area": "岑巩县", "code": "522626000000"},
            {"area": "天柱县", "code": "522627000000"},
            {"area": "锦屏县", "code": "522628000000"},
            {"area": "剑河县", "code": "522629000000"},
            {"area": "台江县", "code": "522630000000"},
            {"area": "黎平县", "code": "522631000000"},
            {"area": "榕江县", "code": "522632000000"},
            {"area": "从江县", "code": "522633000000"},
            {"area": "雷山县", "code": "522634000000"},
            {"area": "麻江县", "code": "522635000000"},
            {"area": "丹寨县", "code": "522636000000"}
          ]
        },
        {
          "city": "黔南布依族苗族自治州",
          "code": "522700000000",
          "areas": [
            {"area": "都匀市", "code": "522701000000"},
            {"area": "福泉市", "code": "522702000000"},
            {"area": "荔波县", "code": "522722000000"},
            {"area": "贵定县", "code": "522723000000"},
            {"area": "瓮安县", "code": "522725000000"},
            {"area": "独山县", "code": "522726000000"},
            {"area": "平塘县", "code": "522727000000"},
            {"area": "罗甸县", "code": "522728000000"},
            {"area": "长顺县", "code": "522729000000"},
            {"area": "龙里县", "code": "522730000000"},
            {"area": "惠水县", "code": "522731000000"},
            {"area": "三都水族自治县", "code": "522732000000"}
          ]
        }
      ]
    },
    {
      "province": "云南省",
      "code": "530000",
      "citys": [
        {
          "city": "昆明市",
          "code": "530100000000",
          "areas": [
            {"area": "五华区", "code": "530102000000"},
            {"area": "盘龙区", "code": "530103000000"},
            {"area": "官渡区", "code": "530111000000"},
            {"area": "西山区", "code": "530112000000"},
            {"area": "东川区", "code": "530113000000"},
            {"area": "呈贡区", "code": "530114000000"},
            {"area": "晋宁区", "code": "530115000000"},
            {"area": "富民县", "code": "530124000000"},
            {"area": "宜良县", "code": "530125000000"},
            {"area": "石林彝族自治县", "code": "530126000000"},
            {"area": "嵩明县", "code": "530127000000"},
            {"area": "禄劝彝族苗族自治县", "code": "530128000000"},
            {"area": "寻甸回族彝族自治县", "code": "530129000000"},
            {"area": "安宁市", "code": "530181000000"}
          ]
        },
        {
          "city": "曲靖市",
          "code": "530300000000",
          "areas": [
            {"area": "麒麟区", "code": "530302000000"},
            {"area": "沾益区", "code": "530303000000"},
            {"area": "马龙区", "code": "530304000000"},
            {"area": "陆良县", "code": "530322000000"},
            {"area": "师宗县", "code": "530323000000"},
            {"area": "罗平县", "code": "530324000000"},
            {"area": "富源县", "code": "530325000000"},
            {"area": "会泽县", "code": "530326000000"},
            {"area": "宣威市", "code": "530381000000"}
          ]
        },
        {
          "city": "玉溪市",
          "code": "530400000000",
          "areas": [
            {"area": "红塔区", "code": "530402000000"},
            {"area": "江川区", "code": "530403000000"},
            {"area": "通海县", "code": "530423000000"},
            {"area": "华宁县", "code": "530424000000"},
            {"area": "易门县", "code": "530425000000"},
            {"area": "峨山彝族自治县", "code": "530426000000"},
            {"area": "新平彝族傣族自治县", "code": "530427000000"},
            {"area": "元江哈尼族彝族傣族自治县", "code": "530428000000"},
            {"area": "澄江市", "code": "530481000000"}
          ]
        },
        {
          "city": "保山市",
          "code": "530500000000",
          "areas": [
            {"area": "隆阳区", "code": "530502000000"},
            {"area": "施甸县", "code": "530521000000"},
            {"area": "龙陵县", "code": "530523000000"},
            {"area": "昌宁县", "code": "530524000000"},
            {"area": "腾冲市", "code": "530581000000"}
          ]
        },
        {
          "city": "昭通市",
          "code": "530600000000",
          "areas": [
            {"area": "昭阳区", "code": "530602000000"},
            {"area": "鲁甸县", "code": "530621000000"},
            {"area": "巧家县", "code": "530622000000"},
            {"area": "盐津县", "code": "530623000000"},
            {"area": "大关县", "code": "530624000000"},
            {"area": "永善县", "code": "530625000000"},
            {"area": "绥江县", "code": "530626000000"},
            {"area": "镇雄县", "code": "530627000000"},
            {"area": "彝良县", "code": "530628000000"},
            {"area": "威信县", "code": "530629000000"},
            {"area": "水富市", "code": "530681000000"}
          ]
        },
        {
          "city": "丽江市",
          "code": "530700000000",
          "areas": [
            {"area": "古城区", "code": "530702000000"},
            {"area": "玉龙纳西族自治县", "code": "530721000000"},
            {"area": "永胜县", "code": "530722000000"},
            {"area": "华坪县", "code": "530723000000"},
            {"area": "宁蒗彝族自治县", "code": "530724000000"}
          ]
        },
        {
          "city": "普洱市",
          "code": "530800000000",
          "areas": [
            {"area": "思茅区", "code": "530802000000"},
            {"area": "宁洱哈尼族彝族自治县", "code": "530821000000"},
            {"area": "墨江哈尼族自治县", "code": "530822000000"},
            {"area": "景东彝族自治县", "code": "530823000000"},
            {"area": "景谷傣族彝族自治县", "code": "530824000000"},
            {"area": "镇沅彝族哈尼族拉祜族自治县", "code": "530825000000"},
            {"area": "江城哈尼族彝族自治县", "code": "530826000000"},
            {"area": "孟连傣族拉祜族佤族自治县", "code": "530827000000"},
            {"area": "澜沧拉祜族自治县", "code": "530828000000"},
            {"area": "西盟佤族自治县", "code": "530829000000"}
          ]
        },
        {
          "city": "临沧市",
          "code": "530900000000",
          "areas": [
            {"area": "临翔区", "code": "530902000000"},
            {"area": "凤庆县", "code": "530921000000"},
            {"area": "云县", "code": "530922000000"},
            {"area": "永德县", "code": "530923000000"},
            {"area": "镇康县", "code": "530924000000"},
            {"area": "双江拉祜族佤族布朗族傣族自治县", "code": "530925000000"},
            {"area": "耿马傣族佤族自治县", "code": "530926000000"},
            {"area": "沧源佤族自治县", "code": "530927000000"}
          ]
        },
        {
          "city": "楚雄彝族自治州",
          "code": "532300000000",
          "areas": [
            {"area": "楚雄市", "code": "532301000000"},
            {"area": "禄丰市", "code": "532302000000"},
            {"area": "双柏县", "code": "532322000000"},
            {"area": "牟定县", "code": "532323000000"},
            {"area": "南华县", "code": "532324000000"},
            {"area": "姚安县", "code": "532325000000"},
            {"area": "大姚县", "code": "532326000000"},
            {"area": "永仁县", "code": "532327000000"},
            {"area": "元谋县", "code": "532328000000"},
            {"area": "武定县", "code": "532329000000"}
          ]
        },
        {
          "city": "红河哈尼族彝族自治州",
          "code": "532500000000",
          "areas": [
            {"area": "个旧市", "code": "532501000000"},
            {"area": "开远市", "code": "532502000000"},
            {"area": "蒙自市", "code": "532503000000"},
            {"area": "弥勒市", "code": "532504000000"},
            {"area": "屏边苗族自治县", "code": "532523000000"},
            {"area": "建水县", "code": "532524000000"},
            {"area": "石屏县", "code": "532525000000"},
            {"area": "泸西县", "code": "532527000000"},
            {"area": "元阳县", "code": "532528000000"},
            {"area": "红河县", "code": "532529000000"},
            {"area": "金平苗族瑶族傣族自治县", "code": "532530000000"},
            {"area": "绿春县", "code": "532531000000"},
            {"area": "河口瑶族自治县", "code": "532532000000"}
          ]
        },
        {
          "city": "文山壮族苗族自治州",
          "code": "532600000000",
          "areas": [
            {"area": "文山市", "code": "532601000000"},
            {"area": "砚山县", "code": "532622000000"},
            {"area": "西畴县", "code": "532623000000"},
            {"area": "麻栗坡县", "code": "532624000000"},
            {"area": "马关县", "code": "532625000000"},
            {"area": "丘北县", "code": "532626000000"},
            {"area": "广南县", "code": "532627000000"},
            {"area": "富宁县", "code": "532628000000"}
          ]
        },
        {
          "city": "西双版纳傣族自治州",
          "code": "532800000000",
          "areas": [
            {"area": "景洪市", "code": "532801000000"},
            {"area": "勐海县", "code": "532822000000"},
            {"area": "勐腊县", "code": "532823000000"}
          ]
        },
        {
          "city": "大理白族自治州",
          "code": "532900000000",
          "areas": [
            {"area": "大理市", "code": "532901000000"},
            {"area": "漾濞彝族自治县", "code": "532922000000"},
            {"area": "祥云县", "code": "532923000000"},
            {"area": "宾川县", "code": "532924000000"},
            {"area": "弥渡县", "code": "532925000000"},
            {"area": "南涧彝族自治县", "code": "532926000000"},
            {"area": "巍山彝族回族自治县", "code": "532927000000"},
            {"area": "永平县", "code": "532928000000"},
            {"area": "云龙县", "code": "532929000000"},
            {"area": "洱源县", "code": "532930000000"},
            {"area": "剑川县", "code": "532931000000"},
            {"area": "鹤庆县", "code": "532932000000"}
          ]
        },
        {
          "city": "德宏傣族景颇族自治州",
          "code": "533100000000",
          "areas": [
            {"area": "瑞丽市", "code": "533102000000"},
            {"area": "芒市", "code": "533103000000"},
            {"area": "梁河县", "code": "533122000000"},
            {"area": "盈江县", "code": "533123000000"},
            {"area": "陇川县", "code": "533124000000"}
          ]
        },
        {
          "city": "怒江傈僳族自治州",
          "code": "533300000000",
          "areas": [
            {"area": "泸水市", "code": "533301000000"},
            {"area": "福贡县", "code": "533323000000"},
            {"area": "贡山独龙族怒族自治县", "code": "533324000000"},
            {"area": "兰坪白族普米族自治县", "code": "533325000000"}
          ]
        },
        {
          "city": "迪庆藏族自治州",
          "code": "533400000000",
          "areas": [
            {"area": "香格里拉市", "code": "533401000000"},
            {"area": "德钦县", "code": "533422000000"},
            {"area": "维西傈僳族自治县", "code": "533423000000"}
          ]
        }
      ]
    },
    {
      "province": "西藏自治区",
      "code": "540000",
      "citys": [
        {
          "city": "拉萨市",
          "code": "540100000000",
          "areas": [
            {"area": "城关区", "code": "540102000000"},
            {"area": "堆龙德庆区", "code": "540103000000"},
            {"area": "达孜区", "code": "540104000000"},
            {"area": "林周县", "code": "540121000000"},
            {"area": "当雄县", "code": "540122000000"},
            {"area": "尼木县", "code": "540123000000"},
            {"area": "曲水县", "code": "540124000000"},
            {"area": "墨竹工卡县", "code": "540127000000"},
            {"area": "格尔木藏青工业园区", "code": "540171000000"},
            {"area": "拉萨经济技术开发区", "code": "540172000000"},
            {"area": "西藏文化旅游创意园区", "code": "540173000000"},
            {"area": "达孜工业园区", "code": "540174000000"}
          ]
        },
        {
          "city": "日喀则市",
          "code": "540200000000",
          "areas": [
            {"area": "桑珠孜区", "code": "540202000000"},
            {"area": "南木林县", "code": "540221000000"},
            {"area": "江孜县", "code": "540222000000"},
            {"area": "定日县", "code": "540223000000"},
            {"area": "萨迦县", "code": "540224000000"},
            {"area": "拉孜县", "code": "540225000000"},
            {"area": "昂仁县", "code": "540226000000"},
            {"area": "谢通门县", "code": "540227000000"},
            {"area": "白朗县", "code": "540228000000"},
            {"area": "仁布县", "code": "540229000000"},
            {"area": "康马县", "code": "540230000000"},
            {"area": "定结县", "code": "540231000000"},
            {"area": "仲巴县", "code": "540232000000"},
            {"area": "亚东县", "code": "540233000000"},
            {"area": "吉隆县", "code": "540234000000"},
            {"area": "聂拉木县", "code": "540235000000"},
            {"area": "萨嘎县", "code": "540236000000"},
            {"area": "岗巴县", "code": "540237000000"}
          ]
        },
        {
          "city": "昌都市",
          "code": "540300000000",
          "areas": [
            {"area": "卡若区", "code": "540302000000"},
            {"area": "江达县", "code": "540321000000"},
            {"area": "贡觉县", "code": "540322000000"},
            {"area": "类乌齐县", "code": "540323000000"},
            {"area": "丁青县", "code": "540324000000"},
            {"area": "察雅县", "code": "540325000000"},
            {"area": "八宿县", "code": "540326000000"},
            {"area": "左贡县", "code": "540327000000"},
            {"area": "芒康县", "code": "540328000000"},
            {"area": "洛隆县", "code": "540329000000"},
            {"area": "边坝县", "code": "540330000000"}
          ]
        },
        {
          "city": "林芝市",
          "code": "540400000000",
          "areas": [
            {"area": "巴宜区", "code": "540402000000"},
            {"area": "工布江达县", "code": "540421000000"},
            {"area": "墨脱县", "code": "540423000000"},
            {"area": "波密县", "code": "540424000000"},
            {"area": "察隅县", "code": "540425000000"},
            {"area": "朗县", "code": "540426000000"},
            {"area": "米林市", "code": "540481000000"}
          ]
        },
        {
          "city": "山南市",
          "code": "540500000000",
          "areas": [
            {"area": "乃东区", "code": "540502000000"},
            {"area": "扎囊县", "code": "540521000000"},
            {"area": "贡嘎县", "code": "540522000000"},
            {"area": "桑日县", "code": "540523000000"},
            {"area": "琼结县", "code": "540524000000"},
            {"area": "曲松县", "code": "540525000000"},
            {"area": "措美县", "code": "540526000000"},
            {"area": "洛扎县", "code": "540527000000"},
            {"area": "加查县", "code": "540528000000"},
            {"area": "隆子县", "code": "540529000000"},
            {"area": "浪卡子县", "code": "540531000000"},
            {"area": "错那市", "code": "540581000000"}
          ]
        },
        {
          "city": "那曲市",
          "code": "540600000000",
          "areas": [
            {"area": "色尼区", "code": "540602000000"},
            {"area": "嘉黎县", "code": "540621000000"},
            {"area": "比如县", "code": "540622000000"},
            {"area": "聂荣县", "code": "540623000000"},
            {"area": "安多县", "code": "540624000000"},
            {"area": "申扎县", "code": "540625000000"},
            {"area": "索县", "code": "540626000000"},
            {"area": "班戈县", "code": "540627000000"},
            {"area": "巴青县", "code": "540628000000"},
            {"area": "尼玛县", "code": "540629000000"},
            {"area": "双湖县", "code": "540630000000"}
          ]
        },
        {
          "city": "阿里地区",
          "code": "542500000000",
          "areas": [
            {"area": "普兰县", "code": "542521000000"},
            {"area": "札达县", "code": "542522000000"},
            {"area": "噶尔县", "code": "542523000000"},
            {"area": "日土县", "code": "542524000000"},
            {"area": "革吉县", "code": "542525000000"},
            {"area": "改则县", "code": "542526000000"},
            {"area": "措勤县", "code": "542527000000"}
          ]
        }
      ]
    },
    {
      "province": "陕西省",
      "code": "610000",
      "citys": [
        {
          "city": "西安市",
          "code": "610100000000",
          "areas": [
            {"area": "新城区", "code": "610102000000"},
            {"area": "碑林区", "code": "610103000000"},
            {"area": "莲湖区", "code": "610104000000"},
            {"area": "灞桥区", "code": "610111000000"},
            {"area": "未央区", "code": "610112000000"},
            {"area": "雁塔区", "code": "610113000000"},
            {"area": "阎良区", "code": "610114000000"},
            {"area": "临潼区", "code": "610115000000"},
            {"area": "长安区", "code": "610116000000"},
            {"area": "高陵区", "code": "610117000000"},
            {"area": "鄠邑区", "code": "610118000000"},
            {"area": "蓝田县", "code": "610122000000"},
            {"area": "周至县", "code": "610124000000"}
          ]
        },
        {
          "city": "铜川市",
          "code": "610200000000",
          "areas": [
            {"area": "王益区", "code": "610202000000"},
            {"area": "印台区", "code": "610203000000"},
            {"area": "耀州区", "code": "610204000000"},
            {"area": "宜君县", "code": "610222000000"}
          ]
        },
        {
          "city": "宝鸡市",
          "code": "610300000000",
          "areas": [
            {"area": "渭滨区", "code": "610302000000"},
            {"area": "金台区", "code": "610303000000"},
            {"area": "陈仓区", "code": "610304000000"},
            {"area": "凤翔区", "code": "610305000000"},
            {"area": "岐山县", "code": "610323000000"},
            {"area": "扶风县", "code": "610324000000"},
            {"area": "眉县", "code": "610326000000"},
            {"area": "陇县", "code": "610327000000"},
            {"area": "千阳县", "code": "610328000000"},
            {"area": "麟游县", "code": "610329000000"},
            {"area": "凤县", "code": "610330000000"},
            {"area": "太白县", "code": "610331000000"}
          ]
        },
        {
          "city": "咸阳市",
          "code": "610400000000",
          "areas": [
            {"area": "秦都区", "code": "610402000000"},
            {"area": "杨陵区", "code": "610403000000"},
            {"area": "渭城区", "code": "610404000000"},
            {"area": "三原县", "code": "610422000000"},
            {"area": "泾阳县", "code": "610423000000"},
            {"area": "乾县", "code": "610424000000"},
            {"area": "礼泉县", "code": "610425000000"},
            {"area": "永寿县", "code": "610426000000"},
            {"area": "长武县", "code": "610428000000"},
            {"area": "旬邑县", "code": "610429000000"},
            {"area": "淳化县", "code": "610430000000"},
            {"area": "武功县", "code": "610431000000"},
            {"area": "兴平市", "code": "610481000000"},
            {"area": "彬州市", "code": "610482000000"}
          ]
        },
        {
          "city": "渭南市",
          "code": "610500000000",
          "areas": [
            {"area": "临渭区", "code": "610502000000"},
            {"area": "华州区", "code": "610503000000"},
            {"area": "潼关县", "code": "610522000000"},
            {"area": "大荔县", "code": "610523000000"},
            {"area": "合阳县", "code": "610524000000"},
            {"area": "澄城县", "code": "610525000000"},
            {"area": "蒲城县", "code": "610526000000"},
            {"area": "白水县", "code": "610527000000"},
            {"area": "富平县", "code": "610528000000"},
            {"area": "韩城市", "code": "610581000000"},
            {"area": "华阴市", "code": "610582000000"}
          ]
        },
        {
          "city": "延安市",
          "code": "610600000000",
          "areas": [
            {"area": "宝塔区", "code": "610602000000"},
            {"area": "安塞区", "code": "610603000000"},
            {"area": "延长县", "code": "610621000000"},
            {"area": "延川县", "code": "610622000000"},
            {"area": "志丹县", "code": "610625000000"},
            {"area": "吴起县", "code": "610626000000"},
            {"area": "甘泉县", "code": "610627000000"},
            {"area": "富县", "code": "610628000000"},
            {"area": "洛川县", "code": "610629000000"},
            {"area": "宜川县", "code": "610630000000"},
            {"area": "黄龙县", "code": "610631000000"},
            {"area": "黄陵县", "code": "610632000000"},
            {"area": "子长市", "code": "610681000000"}
          ]
        },
        {
          "city": "汉中市",
          "code": "610700000000",
          "areas": [
            {"area": "汉台区", "code": "610702000000"},
            {"area": "南郑区", "code": "610703000000"},
            {"area": "城固县", "code": "610722000000"},
            {"area": "洋县", "code": "610723000000"},
            {"area": "西乡县", "code": "610724000000"},
            {"area": "勉县", "code": "610725000000"},
            {"area": "宁强县", "code": "610726000000"},
            {"area": "略阳县", "code": "610727000000"},
            {"area": "镇巴县", "code": "610728000000"},
            {"area": "留坝县", "code": "610729000000"},
            {"area": "佛坪县", "code": "610730000000"}
          ]
        },
        {
          "city": "榆林市",
          "code": "610800000000",
          "areas": [
            {"area": "榆阳区", "code": "610802000000"},
            {"area": "横山区", "code": "610803000000"},
            {"area": "府谷县", "code": "610822000000"},
            {"area": "靖边县", "code": "610824000000"},
            {"area": "定边县", "code": "610825000000"},
            {"area": "绥德县", "code": "610826000000"},
            {"area": "米脂县", "code": "610827000000"},
            {"area": "佳县", "code": "610828000000"},
            {"area": "吴堡县", "code": "610829000000"},
            {"area": "清涧县", "code": "610830000000"},
            {"area": "子洲县", "code": "610831000000"},
            {"area": "神木市", "code": "610881000000"}
          ]
        },
        {
          "city": "安康市",
          "code": "610900000000",
          "areas": [
            {"area": "汉滨区", "code": "610902000000"},
            {"area": "汉阴县", "code": "610921000000"},
            {"area": "石泉县", "code": "610922000000"},
            {"area": "宁陕县", "code": "610923000000"},
            {"area": "紫阳县", "code": "610924000000"},
            {"area": "岚皋县", "code": "610925000000"},
            {"area": "平利县", "code": "610926000000"},
            {"area": "镇坪县", "code": "610927000000"},
            {"area": "白河县", "code": "610929000000"},
            {"area": "旬阳市", "code": "610981000000"}
          ]
        },
        {
          "city": "商洛市",
          "code": "611000000000",
          "areas": [
            {"area": "商州区", "code": "611002000000"},
            {"area": "洛南县", "code": "611021000000"},
            {"area": "丹凤县", "code": "611022000000"},
            {"area": "商南县", "code": "611023000000"},
            {"area": "山阳县", "code": "611024000000"},
            {"area": "镇安县", "code": "611025000000"},
            {"area": "柞水县", "code": "611026000000"}
          ]
        }
      ]
    },
    {
      "province": "甘肃省",
      "code": "620000",
      "citys": [
        {
          "city": "兰州市",
          "code": "620100000000",
          "areas": [
            {"area": "城关区", "code": "620102000000"},
            {"area": "七里河区", "code": "620103000000"},
            {"area": "西固区", "code": "620104000000"},
            {"area": "安宁区", "code": "620105000000"},
            {"area": "红古区", "code": "620111000000"},
            {"area": "永登县", "code": "620121000000"},
            {"area": "皋兰县", "code": "620122000000"},
            {"area": "榆中县", "code": "620123000000"},
            {"area": "兰州新区", "code": "620171000000"}
          ]
        },
        {"city": "嘉峪关市", "code": "620200000000", "areas": []},
        {
          "city": "金昌市",
          "code": "620300000000",
          "areas": [
            {"area": "金川区", "code": "620302000000"},
            {"area": "永昌县", "code": "620321000000"}
          ]
        },
        {
          "city": "白银市",
          "code": "620400000000",
          "areas": [
            {"area": "白银区", "code": "620402000000"},
            {"area": "平川区", "code": "620403000000"},
            {"area": "靖远县", "code": "620421000000"},
            {"area": "会宁县", "code": "620422000000"},
            {"area": "景泰县", "code": "620423000000"}
          ]
        },
        {
          "city": "天水市",
          "code": "620500000000",
          "areas": [
            {"area": "秦州区", "code": "620502000000"},
            {"area": "麦积区", "code": "620503000000"},
            {"area": "清水县", "code": "620521000000"},
            {"area": "秦安县", "code": "620522000000"},
            {"area": "甘谷县", "code": "620523000000"},
            {"area": "武山县", "code": "620524000000"},
            {"area": "张家川回族自治县", "code": "620525000000"}
          ]
        },
        {
          "city": "武威市",
          "code": "620600000000",
          "areas": [
            {"area": "凉州区", "code": "620602000000"},
            {"area": "民勤县", "code": "620621000000"},
            {"area": "古浪县", "code": "620622000000"},
            {"area": "天祝藏族自治县", "code": "620623000000"}
          ]
        },
        {
          "city": "张掖市",
          "code": "620700000000",
          "areas": [
            {"area": "甘州区", "code": "620702000000"},
            {"area": "肃南裕固族自治县", "code": "620721000000"},
            {"area": "民乐县", "code": "620722000000"},
            {"area": "临泽县", "code": "620723000000"},
            {"area": "高台县", "code": "620724000000"},
            {"area": "山丹县", "code": "620725000000"}
          ]
        },
        {
          "city": "平凉市",
          "code": "620800000000",
          "areas": [
            {"area": "崆峒区", "code": "620802000000"},
            {"area": "泾川县", "code": "620821000000"},
            {"area": "灵台县", "code": "620822000000"},
            {"area": "崇信县", "code": "620823000000"},
            {"area": "庄浪县", "code": "620825000000"},
            {"area": "静宁县", "code": "620826000000"},
            {"area": "华亭市", "code": "620881000000"}
          ]
        },
        {
          "city": "酒泉市",
          "code": "620900000000",
          "areas": [
            {"area": "肃州区", "code": "620902000000"},
            {"area": "金塔县", "code": "620921000000"},
            {"area": "瓜州县", "code": "620922000000"},
            {"area": "肃北蒙古族自治县", "code": "620923000000"},
            {"area": "阿克塞哈萨克族自治县", "code": "620924000000"},
            {"area": "玉门市", "code": "620981000000"},
            {"area": "敦煌市", "code": "620982000000"}
          ]
        },
        {
          "city": "庆阳市",
          "code": "621000000000",
          "areas": [
            {"area": "西峰区", "code": "621002000000"},
            {"area": "庆城县", "code": "621021000000"},
            {"area": "环县", "code": "621022000000"},
            {"area": "华池县", "code": "621023000000"},
            {"area": "合水县", "code": "621024000000"},
            {"area": "正宁县", "code": "621025000000"},
            {"area": "宁县", "code": "621026000000"},
            {"area": "镇原县", "code": "621027000000"}
          ]
        },
        {
          "city": "定西市",
          "code": "621100000000",
          "areas": [
            {"area": "安定区", "code": "621102000000"},
            {"area": "通渭县", "code": "621121000000"},
            {"area": "陇西县", "code": "621122000000"},
            {"area": "渭源县", "code": "621123000000"},
            {"area": "临洮县", "code": "621124000000"},
            {"area": "漳县", "code": "621125000000"},
            {"area": "岷县", "code": "621126000000"}
          ]
        },
        {
          "city": "陇南市",
          "code": "621200000000",
          "areas": [
            {"area": "武都区", "code": "621202000000"},
            {"area": "成县", "code": "621221000000"},
            {"area": "文县", "code": "621222000000"},
            {"area": "宕昌县", "code": "621223000000"},
            {"area": "康县", "code": "621224000000"},
            {"area": "西和县", "code": "621225000000"},
            {"area": "礼县", "code": "621226000000"},
            {"area": "徽县", "code": "621227000000"},
            {"area": "两当县", "code": "621228000000"}
          ]
        },
        {
          "city": "临夏回族自治州",
          "code": "622900000000",
          "areas": [
            {"area": "临夏市", "code": "622901000000"},
            {"area": "临夏县", "code": "622921000000"},
            {"area": "康乐县", "code": "622922000000"},
            {"area": "永靖县", "code": "622923000000"},
            {"area": "广河县", "code": "622924000000"},
            {"area": "和政县", "code": "622925000000"},
            {"area": "东乡族自治县", "code": "622926000000"},
            {"area": "积石山保安族东乡族撒拉族自治县", "code": "622927000000"}
          ]
        },
        {
          "city": "甘南藏族自治州",
          "code": "623000000000",
          "areas": [
            {"area": "合作市", "code": "623001000000"},
            {"area": "临潭县", "code": "623021000000"},
            {"area": "卓尼县", "code": "623022000000"},
            {"area": "舟曲县", "code": "623023000000"},
            {"area": "迭部县", "code": "623024000000"},
            {"area": "玛曲县", "code": "623025000000"},
            {"area": "碌曲县", "code": "623026000000"},
            {"area": "夏河县", "code": "623027000000"}
          ]
        }
      ]
    },
    {
      "province": "青海省",
      "code": "630000",
      "citys": [
        {
          "city": "西宁市",
          "code": "630100000000",
          "areas": [
            {"area": "城东区", "code": "630102000000"},
            {"area": "城中区", "code": "630103000000"},
            {"area": "城西区", "code": "630104000000"},
            {"area": "城北区", "code": "630105000000"},
            {"area": "湟中区", "code": "630106000000"},
            {"area": "大通回族土族自治县", "code": "630121000000"},
            {"area": "湟源县", "code": "630123000000"}
          ]
        },
        {
          "city": "海东市",
          "code": "630200000000",
          "areas": [
            {"area": "乐都区", "code": "630202000000"},
            {"area": "平安区", "code": "630203000000"},
            {"area": "民和回族土族自治县", "code": "630222000000"},
            {"area": "互助土族自治县", "code": "630223000000"},
            {"area": "化隆回族自治县", "code": "630224000000"},
            {"area": "循化撒拉族自治县", "code": "630225000000"}
          ]
        },
        {
          "city": "海北藏族自治州",
          "code": "632200000000",
          "areas": [
            {"area": "门源回族自治县", "code": "632221000000"},
            {"area": "祁连县", "code": "632222000000"},
            {"area": "海晏县", "code": "632223000000"},
            {"area": "刚察县", "code": "632224000000"}
          ]
        },
        {
          "city": "黄南藏族自治州",
          "code": "632300000000",
          "areas": [
            {"area": "同仁市", "code": "632301000000"},
            {"area": "尖扎县", "code": "632322000000"},
            {"area": "泽库县", "code": "632323000000"},
            {"area": "河南蒙古族自治县", "code": "632324000000"}
          ]
        },
        {
          "city": "海南藏族自治州",
          "code": "632500000000",
          "areas": [
            {"area": "共和县", "code": "632521000000"},
            {"area": "同德县", "code": "632522000000"},
            {"area": "贵德县", "code": "632523000000"},
            {"area": "兴海县", "code": "632524000000"},
            {"area": "贵南县", "code": "632525000000"}
          ]
        },
        {
          "city": "果洛藏族自治州",
          "code": "632600000000",
          "areas": [
            {"area": "玛沁县", "code": "632621000000"},
            {"area": "班玛县", "code": "632622000000"},
            {"area": "甘德县", "code": "632623000000"},
            {"area": "达日县", "code": "632624000000"},
            {"area": "久治县", "code": "632625000000"},
            {"area": "玛多县", "code": "632626000000"}
          ]
        },
        {
          "city": "玉树藏族自治州",
          "code": "632700000000",
          "areas": [
            {"area": "玉树市", "code": "632701000000"},
            {"area": "杂多县", "code": "632722000000"},
            {"area": "称多县", "code": "632723000000"},
            {"area": "治多县", "code": "632724000000"},
            {"area": "囊谦县", "code": "632725000000"},
            {"area": "曲麻莱县", "code": "632726000000"}
          ]
        },
        {
          "city": "海西蒙古族藏族自治州",
          "code": "632800000000",
          "areas": [
            {"area": "格尔木市", "code": "632801000000"},
            {"area": "德令哈市", "code": "632802000000"},
            {"area": "茫崖市", "code": "632803000000"},
            {"area": "乌兰县", "code": "632821000000"},
            {"area": "都兰县", "code": "632822000000"},
            {"area": "天峻县", "code": "632823000000"},
            {"area": "大柴旦行政委员会", "code": "632857000000"}
          ]
        }
      ]
    },
    {
      "province": "宁夏回族自治区",
      "code": "640000",
      "citys": [
        {
          "city": "银川市",
          "code": "640100000000",
          "areas": [
            {"area": "兴庆区", "code": "640104000000"},
            {"area": "西夏区", "code": "640105000000"},
            {"area": "金凤区", "code": "640106000000"},
            {"area": "永宁县", "code": "640121000000"},
            {"area": "贺兰县", "code": "640122000000"},
            {"area": "灵武市", "code": "640181000000"}
          ]
        },
        {
          "city": "石嘴山市",
          "code": "640200000000",
          "areas": [
            {"area": "大武口区", "code": "640202000000"},
            {"area": "惠农区", "code": "640205000000"},
            {"area": "平罗县", "code": "640221000000"}
          ]
        },
        {
          "city": "吴忠市",
          "code": "640300000000",
          "areas": [
            {"area": "利通区", "code": "640302000000"},
            {"area": "红寺堡区", "code": "640303000000"},
            {"area": "盐池县", "code": "640323000000"},
            {"area": "同心县", "code": "640324000000"},
            {"area": "青铜峡市", "code": "640381000000"}
          ]
        },
        {
          "city": "固原市",
          "code": "640400000000",
          "areas": [
            {"area": "原州区", "code": "640402000000"},
            {"area": "西吉县", "code": "640422000000"},
            {"area": "隆德县", "code": "640423000000"},
            {"area": "泾源县", "code": "640424000000"},
            {"area": "彭阳县", "code": "640425000000"}
          ]
        },
        {
          "city": "中卫市",
          "code": "640500000000",
          "areas": [
            {"area": "沙坡头区", "code": "640502000000"},
            {"area": "中宁县", "code": "640521000000"},
            {"area": "海原县", "code": "640522000000"}
          ]
        }
      ]
    },
    {
      "province": "新疆维吾尔自治区",
      "code": "650000",
      "citys": [
        {
          "city": "乌鲁木齐市",
          "code": "650100000000",
          "areas": [
            {"area": "天山区", "code": "650102000000"},
            {"area": "沙依巴克区", "code": "650103000000"},
            {"area": "新市区", "code": "650104000000"},
            {"area": "水磨沟区", "code": "650105000000"},
            {"area": "头屯河区", "code": "650106000000"},
            {"area": "达坂城区", "code": "650107000000"},
            {"area": "米东区", "code": "650109000000"},
            {"area": "乌鲁木齐县", "code": "650121000000"}
          ]
        },
        {
          "city": "克拉玛依市",
          "code": "650200000000",
          "areas": [
            {"area": "独山子区", "code": "650202000000"},
            {"area": "克拉玛依区", "code": "650203000000"},
            {"area": "白碱滩区", "code": "650204000000"},
            {"area": "乌尔禾区", "code": "650205000000"}
          ]
        },
        {
          "city": "吐鲁番市",
          "code": "650400000000",
          "areas": [
            {"area": "高昌区", "code": "650402000000"},
            {"area": "鄯善县", "code": "650421000000"},
            {"area": "托克逊县", "code": "650422000000"}
          ]
        },
        {
          "city": "哈密市",
          "code": "650500000000",
          "areas": [
            {"area": "伊州区", "code": "650502000000"},
            {"area": "巴里坤哈萨克自治县", "code": "650521000000"},
            {"area": "伊吾县", "code": "650522000000"}
          ]
        },
        {
          "city": "昌吉回族自治州",
          "code": "652300000000",
          "areas": [
            {"area": "昌吉市", "code": "652301000000"},
            {"area": "阜康市", "code": "652302000000"},
            {"area": "呼图壁县", "code": "652323000000"},
            {"area": "玛纳斯县", "code": "652324000000"},
            {"area": "奇台县", "code": "652325000000"},
            {"area": "吉木萨尔县", "code": "652327000000"},
            {"area": "木垒哈萨克自治县", "code": "652328000000"}
          ]
        },
        {
          "city": "博尔塔拉蒙古自治州",
          "code": "652700000000",
          "areas": [
            {"area": "博乐市", "code": "652701000000"},
            {"area": "阿拉山口市", "code": "652702000000"},
            {"area": "精河县", "code": "652722000000"},
            {"area": "温泉县", "code": "652723000000"}
          ]
        },
        {
          "city": "巴音郭楞蒙古自治州",
          "code": "652800000000",
          "areas": [
            {"area": "库尔勒市", "code": "652801000000"},
            {"area": "轮台县", "code": "652822000000"},
            {"area": "尉犁县", "code": "652823000000"},
            {"area": "若羌县", "code": "652824000000"},
            {"area": "且末县", "code": "652825000000"},
            {"area": "焉耆回族自治县", "code": "652826000000"},
            {"area": "和静县", "code": "652827000000"},
            {"area": "和硕县", "code": "652828000000"},
            {"area": "博湖县", "code": "652829000000"}
          ]
        },
        {
          "city": "阿克苏地区",
          "code": "652900000000",
          "areas": [
            {"area": "阿克苏市", "code": "652901000000"},
            {"area": "库车市", "code": "652902000000"},
            {"area": "温宿县", "code": "652922000000"},
            {"area": "沙雅县", "code": "652924000000"},
            {"area": "新和县", "code": "652925000000"},
            {"area": "拜城县", "code": "652926000000"},
            {"area": "乌什县", "code": "652927000000"},
            {"area": "阿瓦提县", "code": "652928000000"},
            {"area": "柯坪县", "code": "652929000000"}
          ]
        },
        {
          "city": "克孜勒苏柯尔克孜自治州",
          "code": "653000000000",
          "areas": [
            {"area": "阿图什市", "code": "653001000000"},
            {"area": "阿克陶县", "code": "653022000000"},
            {"area": "阿合奇县", "code": "653023000000"},
            {"area": "乌恰县", "code": "653024000000"}
          ]
        },
        {
          "city": "喀什地区",
          "code": "653100000000",
          "areas": [
            {"area": "喀什市", "code": "653101000000"},
            {"area": "疏附县", "code": "653121000000"},
            {"area": "疏勒县", "code": "653122000000"},
            {"area": "英吉沙县", "code": "653123000000"},
            {"area": "泽普县", "code": "653124000000"},
            {"area": "莎车县", "code": "653125000000"},
            {"area": "叶城县", "code": "653126000000"},
            {"area": "麦盖提县", "code": "653127000000"},
            {"area": "岳普湖县", "code": "653128000000"},
            {"area": "伽师县", "code": "653129000000"},
            {"area": "巴楚县", "code": "653130000000"},
            {"area": "塔什库尔干塔吉克自治县", "code": "653131000000"}
          ]
        },
        {
          "city": "和田地区",
          "code": "653200000000",
          "areas": [
            {"area": "和田市", "code": "653201000000"},
            {"area": "和田县", "code": "653221000000"},
            {"area": "墨玉县", "code": "653222000000"},
            {"area": "皮山县", "code": "653223000000"},
            {"area": "洛浦县", "code": "653224000000"},
            {"area": "策勒县", "code": "653225000000"},
            {"area": "于田县", "code": "653226000000"},
            {"area": "民丰县", "code": "653227000000"}
          ]
        },
        {
          "city": "伊犁哈萨克自治州",
          "code": "654000000000",
          "areas": [
            {"area": "伊宁市", "code": "654002000000"},
            {"area": "奎屯市", "code": "654003000000"},
            {"area": "霍尔果斯市", "code": "654004000000"},
            {"area": "伊宁县", "code": "654021000000"},
            {"area": "察布查尔锡伯自治县", "code": "654022000000"},
            {"area": "霍城县", "code": "654023000000"},
            {"area": "巩留县", "code": "654024000000"},
            {"area": "新源县", "code": "654025000000"},
            {"area": "昭苏县", "code": "654026000000"},
            {"area": "特克斯县", "code": "654027000000"},
            {"area": "尼勒克县", "code": "654028000000"}
          ]
        },
        {
          "city": "塔城地区",
          "code": "654200000000",
          "areas": [
            {"area": "塔城市", "code": "654201000000"},
            {"area": "乌苏市", "code": "654202000000"},
            {"area": "沙湾市", "code": "654203000000"},
            {"area": "额敏县", "code": "654221000000"},
            {"area": "托里县", "code": "654224000000"},
            {"area": "裕民县", "code": "654225000000"},
            {"area": "和布克赛尔蒙古自治县", "code": "654226000000"}
          ]
        },
        {
          "city": "阿勒泰地区",
          "code": "654300000000",
          "areas": [
            {"area": "阿勒泰市", "code": "654301000000"},
            {"area": "布尔津县", "code": "654321000000"},
            {"area": "富蕴县", "code": "654322000000"},
            {"area": "福海县", "code": "654323000000"},
            {"area": "哈巴河县", "code": "654324000000"},
            {"area": "青河县", "code": "654325000000"},
            {"area": "吉木乃县", "code": "654326000000"}
          ]
        },
        {
          "city": "自治区直辖县级行政区划",
          "code": "659000000000",
          "areas": [
            {"area": "石河子市", "code": "659001000000"},
            {"area": "阿拉尔市", "code": "659002000000"},
            {"area": "图木舒克市", "code": "659003000000"},
            {"area": "五家渠市", "code": "659004000000"},
            {"area": "北屯市", "code": "659005000000"},
            {"area": "铁门关市", "code": "659006000000"},
            {"area": "双河市", "code": "659007000000"},
            {"area": "可克达拉市", "code": "659008000000"},
            {"area": "昆玉市", "code": "659009000000"},
            {"area": "胡杨河市", "code": "659010000000"},
            {"area": "新星市", "code": "659011000000"},
            {"area": "白杨市", "code": "659012000000"}
          ]
        }
      ]
    },
    {
      "province": "台湾省",
      "code": "710000",
      "citys": [
        {
          "city": "台北市",
          "code": "710000",
          "areas": [
            {"area": "台北市", "code": "710000"}
          ]
        },
        {
          "city": "新北市",
          "code": "710000",
          "areas": [
            {"area": "新北市", "code": "710000"}
          ]
        },
        {
          "city": "桃园市",
          "code": "710000",
          "areas": [
            {"area": "桃园市", "code": "710000"}
          ]
        },
        {
          "city": "台中市",
          "code": "710000",
          "areas": [
            {"area": "台中市", "code": "710000"}
          ]
        },
        {
          "city": "台南市",
          "code": "710000",
          "areas": [
            {"area": "台南市", "code": "710000"}
          ]
        },
        {
          "city": "高雄市",
          "code": "710000",
          "areas": [
            {"area": "高雄市", "code": "710000"}
          ]
        },
        {
          "city": "基隆市",
          "code": "710000",
          "areas": [
            {"area": "基隆市", "code": "710000"}
          ]
        },
        {
          "city": "新竹市",
          "code": "710000",
          "areas": [
            {"area": "新竹市", "code": "710000"}
          ]
        },
        {
          "city": "嘉义市",
          "code": "710000",
          "areas": [
            {"area": "嘉义市", "code": "710000"}
          ]
        },
        {
          "city": "新竹县",
          "code": "710000",
          "areas": [
            {"area": "新竹县", "code": "710000"}
          ]
        },
        {
          "city": "苗栗县",
          "code": "710000",
          "areas": [
            {"area": "苗栗县", "code": "710000"}
          ]
        },
        {
          "city": "彰化县",
          "code": "710000",
          "areas": [
            {"area": "彰化县", "code": "710000"}
          ]
        },
        {
          "city": "南投县",
          "code": "710000",
          "areas": [
            {"area": "南投县", "code": "710000"}
          ]
        },
        {
          "city": "云林县",
          "code": "710000",
          "areas": [
            {"area": "云林县", "code": "710000"}
          ]
        },
        {
          "city": "嘉义县",
          "code": "710000",
          "areas": [
            {"area": "嘉义县", "code": "710000"}
          ]
        },
        {
          "city": "屏东县",
          "code": "710000",
          "areas": [
            {"area": "屏东县", "code": "710000"}
          ]
        },
        {
          "city": "宜兰县",
          "code": "710000",
          "areas": [
            {"area": "宜兰县", "code": "710000"}
          ]
        },
        {
          "city": "花莲县",
          "code": "710000",
          "areas": [
            {"area": "花莲县", "code": "710000"}
          ]
        },
        {
          "city": "台东县",
          "code": "710000",
          "areas": [
            {"area": "台东县", "code": "710000"}
          ]
        },
        {
          "city": "澎湖县",
          "code": "710000",
          "areas": [
            {"area": "澎湖县", "code": "710000"}
          ]
        },
        {
          "city": "连江县",
          "code": "710000",
          "areas": [
            {"area": "连江县", "code": "710000"}
          ]
        }
      ]
    },
    {
      "province": "香港特别行政区",
      "code": "810000",
      "citys": [
        {
          "city": "香港特别行政区",
          "code": "810000",
          "areas": [
            {"area": "中西区", "code": "810001"},
            {"area": "湾仔区", "code": "810002"},
            {"area": "东区", "code": "810003"},
            {"area": "南区", "code": "810004"},
            {"area": "油尖旺区", "code": "810005"},
            {"area": "深水埗区", "code": "810006"},
            {"area": "九龙城区", "code": "810007"},
            {"area": "黄大仙区", "code": "810008"},
            {"area": "观塘区", "code": "810009"},
            {"area": "荃湾区", "code": "810010"},
            {"area": "屯门区", "code": "810011"},
            {"area": "元朗区", "code": "810012"},
            {"area": "北区", "code": "810013"},
            {"area": "大埔区", "code": "810014"},
            {"area": "西贡区", "code": "810015"},
            {"area": "沙田区", "code": "810016"},
            {"area": "葵青区", "code": "810017"},
            {"area": "离岛区", "code": "810018"}
          ]
        }
      ]
    },
    {
      "province": "澳门特别行政区",
      "code": "820000",
      "citys": [
        {
          "city": "澳门特别行政区",
          "code": "820000",
          "areas": [
            {"area": "花地玛堂区", "code": "820001"},
            {"area": "花王堂区", "code": "820002"},
            {"area": "望德堂区", "code": "820003"},
            {"area": "大堂区", "code": "820004"},
            {"area": "风顺堂区", "code": "820005"},
            {"area": "嘉模堂区", "code": "820006"},
            {"area": "路凼填海区", "code": "820007"},
            {"area": "圣方济各堂区", "code": "820008"}
          ]
        }
      ]
    }
  ];

  PickerChinaAddressEnum chinaAddressEnum;

  List<int> getSelectedsByCode(String code) {
    List<int> selecteds = [];
    for (var i = 0; i < data.length; i++) {
      PickerItem<PickerAddressItem> provinceItem = data[i];
      if (provinceItem.value != null) {
        if (chinaAddressEnum == PickerChinaAddressEnum.province) {
          if (provinceItem.value!.code == code) {
            selecteds.add(i);
            return selecteds;
          }
        } else if (provinceItem.children != null) {
          for (var j = 0; j < provinceItem.children!.length; j++) {
            PickerItem<PickerAddressItem> cityItem = provinceItem.children![j];
            if (cityItem.value != null) {
              if (chinaAddressEnum == PickerChinaAddressEnum.provinceAndCity) {
                if (cityItem.value!.code == code) {
                  selecteds.add(i);
                  selecteds.add(j);
                  return selecteds;
                }
              } else if (cityItem.children != null) {
                for (var k = 0; k < cityItem.children!.length; k++) {
                  PickerItem<PickerAddressItem> areaItem =
                      cityItem.children![k];
                  if (areaItem.value != null) {
                    if (chinaAddressEnum ==
                        PickerChinaAddressEnum.provinceAndCityAndArea) {
                      if (areaItem.value!.code == code) {
                        selecteds.add(i);
                        selecteds.add(j);
                        selecteds.add(k);
                        return selecteds;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    return selecteds;
  }

  List<int> getSelectedsByArea(String area) {
    List<int> selecteds = [];
    for (var i = 0; i < data.length; i++) {
      PickerItem<PickerAddressItem> provinceItem = data[i];
      if (provinceItem.value != null) {
        if (chinaAddressEnum == PickerChinaAddressEnum.province) {
          if (provinceItem.value!.area == area) {
            selecteds.add(i);
            return selecteds;
          }
        } else if (provinceItem.children != null) {
          for (var j = 0; j < provinceItem.children!.length; j++) {
            PickerItem<PickerAddressItem> cityItem = provinceItem.children![j];
            if (cityItem.value != null) {
              if (chinaAddressEnum == PickerChinaAddressEnum.provinceAndCity) {
                if (cityItem.value!.area == area) {
                  selecteds.add(i);
                  selecteds.add(j);
                  return selecteds;
                }
              } else if (cityItem.children != null) {
                for (var k = 0; k < cityItem.children!.length; k++) {
                  PickerItem<PickerAddressItem> areaItem =
                      cityItem.children![k];
                  if (areaItem.value != null) {
                    if (chinaAddressEnum ==
                        PickerChinaAddressEnum.provinceAndCityAndArea) {
                      if (areaItem.value!.area == area) {
                        selecteds.add(i);
                        selecteds.add(j);
                        selecteds.add(k);
                        return selecteds;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    return selecteds;
  }

  String getCodeByArea(String area) {
    for (var i = 0; i < data.length; i++) {
      PickerItem<PickerAddressItem> provinceItem = data[i];
      if (provinceItem.value != null) {
        if (chinaAddressEnum == PickerChinaAddressEnum.province) {
          if (provinceItem.value!.area == area) {
            return provinceItem.value!.code;
          }
        } else if (provinceItem.children != null) {
          for (var j = 0; j < provinceItem.children!.length; j++) {
            PickerItem<PickerAddressItem> cityItem = provinceItem.children![j];
            if (cityItem.value != null) {
              if (chinaAddressEnum == PickerChinaAddressEnum.provinceAndCity) {
                if (cityItem.value!.area == area) {
                  return cityItem.value!.code;
                }
              } else if (cityItem.children != null) {
                for (var k = 0; k < cityItem.children!.length; k++) {
                  PickerItem<PickerAddressItem> areaItem =
                      cityItem.children![k];
                  if (areaItem.value != null) {
                    if (chinaAddressEnum ==
                        PickerChinaAddressEnum.provinceAndCityAndArea) {
                      if (areaItem.value!.area == area) {
                        return areaItem.value!.code;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    return "";
  }

  String getAreaByCode(String code) {
    for (var i = 0; i < data.length; i++) {
      PickerItem<PickerAddressItem> provinceItem = data[i];
      if (provinceItem.value != null) {
        if (chinaAddressEnum == PickerChinaAddressEnum.province) {
          if (provinceItem.value!.code == code) {
            return provinceItem.value!.area;
          }
        } else if (provinceItem.children != null) {
          for (var j = 0; j < provinceItem.children!.length; j++) {
            PickerItem<PickerAddressItem> cityItem = provinceItem.children![j];
            if (cityItem.value != null) {
              if (chinaAddressEnum == PickerChinaAddressEnum.provinceAndCity) {
                if (cityItem.value!.code == code) {
                  return cityItem.value!.area;
                }
              } else if (cityItem.children != null) {
                for (var k = 0; k < cityItem.children!.length; k++) {
                  PickerItem<PickerAddressItem> areaItem =
                      cityItem.children![k];
                  if (areaItem.value != null) {
                    if (chinaAddressEnum ==
                        PickerChinaAddressEnum.provinceAndCityAndArea) {
                      if (areaItem.value!.code == code) {
                        return areaItem.value!.area;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    return "";
  }

  PickerChinaAddressAdapter(this.chinaAddressEnum) {
    List<PickerItem<PickerAddressItem>> provinceItems = [];
    for (var provinceMap in address) {
      String province = provinceMap['province'];
      String provinceCode = provinceMap['code'];
      List citys = provinceMap['citys'];

      List<PickerItem<PickerAddressItem>>? cityItems = [];
      if (chinaAddressEnum == PickerChinaAddressEnum.provinceAndCity ||
          chinaAddressEnum == PickerChinaAddressEnum.provinceAndCityAndArea) {
        for (var cityMap in citys) {
          String city = cityMap['city'];
          String cityCode = cityMap['code'];
          List areas = cityMap['areas'];

          List<PickerItem<PickerAddressItem>> areaItems = [];
          if (chinaAddressEnum ==
              PickerChinaAddressEnum.provinceAndCityAndArea) {
            for (var areaMap in areas) {
              String area = areaMap['area'];
              String areaCode = areaMap['code'];
              areaItems.add(PickerItem<PickerAddressItem>(
                  value: PickerAddressItem(area: area, code: areaCode)));
            }
          }

          cityItems.add(PickerItem<PickerAddressItem>(
              value: PickerAddressItem(area: city, code: cityCode),
              children: areaItems));
        }
      }

      provinceItems.add(PickerItem<PickerAddressItem>(
          value: PickerAddressItem(area: province, code: provinceCode),
          children: cityItems));
    }
    super.data = provinceItems;
  }
}

class NumberPickerColumn {
  final List<int>? items;
  final int begin;
  final int end;
  final int? initValue;
  final int columnFlex;
  final int jump;
  final Widget? postfix, suffix;
  final PickerValueFormat<int>? onFormatValue;

  const NumberPickerColumn({
    this.begin = 0,
    this.end = 9,
    this.items,
    this.initValue,
    this.jump = 1,
    this.columnFlex = 1,
    this.postfix,
    this.suffix,
    this.onFormatValue,
  });

  int indexOf(int? value) {
    if (value == null) return -1;
    if (items != null) return items!.indexOf(value);
    if (value < begin || value > end) return -1;
    return (value - begin) ~/ (jump == 0 ? 1 : jump);
  }

  int valueOf(int index) {
    if (items != null) {
      return items![index];
    }
    return begin + index * (jump == 0 ? 1 : jump);
  }

  String getValueText(int index) {
    return onFormatValue == null
        ? "${valueOf(index)}"
        : onFormatValue!(valueOf(index));
  }

  int count() {
    var v = (end - begin) ~/ (jump == 0 ? 1 : jump) + 1;
    if (v < 1) return 0;
    return v;
  }
}

class NumberPickerAdapter extends PickerAdapter<int> {
  NumberPickerAdapter({required this.data});

  final List<NumberPickerColumn> data;
  NumberPickerColumn? cur;
  int _col = 0;

  @override
  int getLength() {
    if (cur == null) return 0;
    if (cur!.items != null) return cur!.items!.length;
    return cur!.count();
  }

  @override
  int getMaxLevel() => data.length;

  @override
  bool getIsLinkage() {
    return false;
  }

  @override
  void setColumn(int index) {
    if (index != -1 && _col == index + 1) return;
    _col = index + 1;
    if (_col >= data.length) {
      cur = null;
    } else {
      cur = data[_col];
    }
  }

  @override
  void initSelects() {
    int maxLevel = getMaxLevel();
    // ignore: unnecessary_null_comparison
    if (picker!.selecteds == null) picker!.selecteds = <int>[];
    if (picker!.selecteds.isEmpty) {
      for (int i = 0; i < maxLevel; i++) {
        int v = data[i].indexOf(data[i].initValue);
        if (v < 0) v = 0;
        picker!.selecteds.add(v);
      }
    }
  }

  @override
  Widget buildItem(BuildContext context, int index) {
    final txt = cur!.getValueText(index);
    final isSel = index == picker!.selecteds[_col];
    if (picker!.onBuilderItem != null) {
      final v = picker!.onBuilderItem!(context, txt, null, isSel, _col, index);
      if (v != null) return makeText(v, null, isSel);
    }
    if (cur!.postfix == null && cur!.suffix == null) {
      return makeText(null, txt, isSel);
    } else {
      return makeTextEx(null, txt, cur!.postfix, cur!.suffix, isSel);
    }
  }

  @override
  int getColumnFlex(int column) {
    return data[column].columnFlex;
  }

  @override
  List<int> getSelectedValues() {
    List<int> items = [];
    for (int i = 0; i < picker!.selecteds.length; i++) {
      int j = picker!.selecteds[i];
      int v = data[i].valueOf(j);
      items.add(v);
    }
    return items;
  }
}

/// Picker DateTime Adapter Type
class PickerDateTimeType {
  static const int kMDY = 0; // m, d, y
  static const int kHM = 1; // hh, mm
  static const int kHMS = 2; // hh, mm, ss
  // ignore: constant_identifier_names
  static const int kHM_AP = 3; // hh, mm, ap(AM/PM)
  static const int kMDYHM = 4; // m, d, y, hh, mm
  // ignore: constant_identifier_names
  static const int kMDYHM_AP = 5; // m, d, y, hh, mm, AM/PM
  static const int kMDYHMS = 6; // m, d, y, hh, mm, ss

  static const int kYMD = 7; // y, m, d
  static const int kYMDHM = 8; // y, m, d, hh, mm
  static const int kYMDHMS = 9; // y, m, d, hh, mm, ss
  // ignore: constant_identifier_names
  static const int kYMD_AP_HM = 10; // y, m, d, ap, hh, mm

  static const int kYM = 11; // y, m
  static const int kDMY = 12; // d, m, y
  static const int kY = 13; // y
}

class DateTimePickerAdapter extends PickerAdapter<DateTime> {
  /// display type, ref: [columnType]
  final int type;

  /// Whether to display the month in numerical form.If true, months is not used.
  final bool isNumberMonth;

  /// custom months strings
  final List<String>? months;

  /// Custom AM, PM strings
  final List<String>? strAMPM;

  /// year begin...end.
  final int? yearBegin, yearEnd;

  /// hour min ... max, min >= 0, max <= 23, max > min
  final int? minHour, maxHour;

  /// minimum datetime
  final DateTime? minValue, maxValue;

  /// jump minutes, user could select time in intervals of 30min, 5mins, etc....
  final int? minuteInterval;

  /// Year, month, day suffix
  final String? yearSuffix,
      monthSuffix,
      daySuffix,
      hourSuffix,
      minuteSuffix,
      secondSuffix;

  /// use two-digit year, 2019, displayed as 19
  final bool twoDigitYear;

  /// year 0, month 1, day 2, hour 3, minute 4, sec 5, am/pm 6, hour-ap: 7
  final List<int>? customColumnType;

  static const List<String> monthsListEN = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];

  static const List<String> monthsListENL = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  DateTimePickerAdapter({
    Picker? picker,
    this.type = 0,
    this.isNumberMonth = false,
    this.months = monthsListEN,
    this.strAMPM,
    this.yearBegin = 1900,
    this.yearEnd = 2100,
    this.value,
    this.minValue,
    this.maxValue,
    this.minHour,
    this.maxHour,
    this.secondSuffix,
    this.minuteSuffix,
    this.hourSuffix,
    this.yearSuffix,
    this.monthSuffix,
    this.daySuffix,
    this.minuteInterval,
    this.customColumnType,
    this.twoDigitYear = false,
  }) : assert(minuteInterval == null ||
            (minuteInterval >= 1 &&
                minuteInterval <= 30 &&
                (60 % minuteInterval == 0))) {
    super.picker = picker;
    _yearBegin = yearBegin ?? 0;
    if (minValue != null && minValue!.year > _yearBegin) {
      _yearBegin = minValue!.year;
    }
    // Judge whether the day is in front of the month
    // If in the front, set "needUpdatePrev" = true
    List<int> colType;
    if (customColumnType != null) {
      colType = customColumnType!;
    } else {
      colType = columnType[type];
    }
    var month = colType.indexWhere((element) => element == 1);
    var day = colType.indexWhere((element) => element == 2);
    _needUpdatePrev =
        day < month || day < colType.indexWhere((element) => element == 0);
    if (!_needUpdatePrev) {
      // check am/pm before hour-ap
      var ap = colType.indexWhere((element) => element == 6);
      if (ap > colType.indexWhere((element) => element == 7)) {
        _apBeforeHourAp = true;
        _needUpdatePrev = true;
      }
    }
    value ??= DateTime.now();
    _existSec = existSec();
    _verificationMinMaxValue();
  }

  bool _existSec = false;
  int _col = 0;
  int _colAP = -1;
  int _colHour = -1;
  int _colDay = -1;
  int _yearBegin = 0;
  bool _needUpdatePrev = false;
  bool _apBeforeHourAp = false;

  /// Currently selected value
  DateTime? value;

  // but it can improve the performance, so keep it.
  static const List<List<int>> lengths = [
    [12, 31, 0],
    [24, 60],
    [24, 60, 60],
    [12, 60, 2],
    [12, 31, 0, 24, 60],
    [12, 31, 0, 12, 60, 2],
    [12, 31, 0, 24, 60, 60],
    [0, 12, 31],
    [0, 12, 31, 24, 60],
    [0, 12, 31, 24, 60, 60],
    [0, 12, 31, 2, 12, 60],
    [0, 12],
    [31, 12, 0],
    [0],
  ];

  static const Map<int, int> columnTypeLength = {
    0: 0,
    1: 12,
    2: 31,
    3: 24,
    4: 60,
    5: 60,
    6: 2,
    7: 12
  };

  /// year 0, month 1, day 2, hour 3, minute 4, sec 5, am/pm 6, hour-ap: 7
  static const List<List<int>> columnType = [
    [1, 2, 0],
    [3, 4],
    [3, 4, 5],
    [7, 4, 6],
    [1, 2, 0, 3, 4],
    [1, 2, 0, 7, 4, 6],
    [1, 2, 0, 3, 4, 5],
    [0, 1, 2],
    [0, 1, 2, 3, 4],
    [0, 1, 2, 3, 4, 5],
    [0, 1, 2, 6, 7, 4],
    [0, 1],
    [2, 1, 0],
    [0],
  ];

  // static const List<int> leapYearMonths = const <int>[1, 3, 5, 7, 8, 10, 12];

  // 获取当前列的类型
  int getColumnType(int index) {
    if (customColumnType != null) return customColumnType![index];
    List<int> items = columnType[type];
    if (index >= items.length) return -1;
    return items[index];
  }

  // 判断是否存在秒
  bool existSec() {
    final columns =
        customColumnType == null ? columnType[type] : customColumnType!;
    return columns.contains(5);
  }

  @override
  int getLength() {
    int v = (customColumnType == null
        ? lengths[type][_col]
        : columnTypeLength[customColumnType![_col]])!;
    if (v == 0) {
      int ye = yearEnd!;
      if (maxValue != null) ye = maxValue!.year;
      return ye - _yearBegin + 1;
    }
    if (v == 31) return _calcDateCount(value!.year, value!.month);
    int columnType = getColumnType(_col);
    switch (columnType) {
      case 3: // hour
        if ((minHour != null && minHour! >= 0) ||
            (maxHour != null && maxHour! <= 23)) {
          return (maxHour ?? 23) - (minHour ?? 0) + 1;
        }
        break;
      case 4: // minute
        if (minuteInterval != null && minuteInterval! > 1) {
          return v ~/ minuteInterval!;
        }
        break;
      case 7: // hour am/pm
        if ((minHour != null && minHour! >= 0) ||
            (maxHour != null && maxHour! <= 23)) {
          if (_colAP < 0) {
            // I don't know AM or PM
            return 12;
          } else {
            var min = 0;
            var max = 0;
            if (picker!.selecteds[_colAP] == 0) {
              // am
              min = minHour == null
                  ? 1
                  : minHour! >= 12
                      ? 12
                      : minHour! + 1;
              max = maxHour == null
                  ? 12
                  : maxHour! >= 12
                      ? 12
                      : maxHour! + 1;
            } else {
              // pm
              min = minHour == null
                  ? 1
                  : minHour! >= 12
                      ? 24 - minHour! - 12
                      : 1;
              max = maxHour == null
                  ? 12
                  : maxHour! >= 12
                      ? maxHour! - 12
                      : 1;
            }
            return max > min ? max - min + 1 : min - max + 1;
          }
        }
    }
    return v;
  }

  @override
  int getMaxLevel() {
    return customColumnType == null
        ? lengths[type].length
        : customColumnType!.length;
  }

  @override
  bool needUpdatePrev(int curIndex) {
    if (_needUpdatePrev) {
      if (value?.month == 2) {
        // Only February needs to be dealt with
        var curentColumnType = getColumnType(curIndex);
        return curentColumnType == 1 || curentColumnType == 0;
      } else if (_apBeforeHourAp) {
        return getColumnType(curIndex) == 6;
      }
    }
    return false;
  }

  @override
  void setColumn(int index) {
    //print("setColumn index: $index");
    _col = index + 1;
    if (_col < 0) _col = 0;
  }

  @override
  void initSelects() {
    _colAP = _getAPColIndex();
    int maxLevel = getMaxLevel();
    // ignore: unnecessary_null_comparison
    if (picker!.selecteds == null) picker!.selecteds = <int>[];
    if (picker!.selecteds.isEmpty) {
      for (int i = 0; i < maxLevel; i++) {
        picker!.selecteds.add(0);
      }
    }
  }

  @override
  Widget buildItem(BuildContext context, int index) {
    String text = "";
    int colType = getColumnType(_col);
    switch (colType) {
      case 0:
        if (twoDigitYear) {
          text = "${_yearBegin + index}";
          var txtLength = text.length;
          text =
              "${text.substring(txtLength - (txtLength - 2), txtLength)}${_checkStr(yearSuffix)}";
        } else {
          text = "${_yearBegin + index}${_checkStr(yearSuffix)}";
        }
        break;
      case 1:
        if (isNumberMonth) {
          text = "${index + 1}${_checkStr(monthSuffix)}";
        } else {
          if (months != null) {
            text = months![index];
          } else {
            List months =
                PickerLocalizations.of(context).months ?? monthsListEN;
            text = "${months[index]}";
          }
        }
        break;
      case 2:
        text = "${index + 1}${_checkStr(daySuffix)}";
        break;
      case 3:
        text = "${intToStr(index + (minHour ?? 0))}${_checkStr(hourSuffix)}";
        break;
      case 5:
        text = "${intToStr(index)}${_checkStr(secondSuffix)}";
        break;
      case 4:
        if (minuteInterval == null || minuteInterval! < 2) {
          text = "${intToStr(index)}${_checkStr(minuteSuffix)}";
        } else {
          text =
              "${intToStr(index * minuteInterval!)}${_checkStr(minuteSuffix)}";
        }
        break;
      case 6:
        final apStr = strAMPM ??
            PickerLocalizations.of(context).ampm ??
            const ['AM', 'PM'];
        text = "${apStr[index]}";
        break;
      case 7:
        text = intToStr(index +
            (minHour == null
                ? 0
                : (picker!.selecteds[_colAP] == 0 ? minHour! : 0)) +
            1);
        break;
    }

    final isSel = picker!.selecteds[_col] == index;
    if (picker!.onBuilderItem != null) {
      var v = picker!.onBuilderItem!(context, text, null, isSel, _col, index);
      if (v != null) return makeText(v, null, isSel);
    }
    return makeText(null, text, isSel);
  }

  @override
  String getText() {
    return value.toString();
  }

  @override
  int getColumnFlex(int column) {
    if (picker!.columnFlex != null && column < picker!.columnFlex!.length) {
      return picker!.columnFlex![column];
    }
    if (getColumnType(column) == 0) return 3;
    return 2;
  }

  @override
  void doShow() {
    if (_yearBegin == 0) getLength();
    var maxLevel = getMaxLevel();
    final sh = value!.hour;
    for (int i = 0; i < maxLevel && i < picker!.selecteds.length; i++) {
      int colType = getColumnType(i);
      switch (colType) {
        case 0:
          picker!.selecteds[i] = yearEnd != null && value!.year > yearEnd!
              ? yearEnd! - _yearBegin
              : value!.year - _yearBegin;
          break;
        case 1:
          picker!.selecteds[i] = value!.month - 1;
          break;
        case 2:
          picker!.selecteds[i] = value!.day - 1;
          break;
        case 3:
          var h = sh;
          if ((minHour != null && minHour! >= 0) ||
              (maxHour != null && maxHour! <= 23)) {
            if (minHour != null) {
              h = h > minHour! ? h - minHour! : 0;
            } else {
              h = (maxHour ?? 23) - (minHour ?? 0) + 1;
            }
          }
          picker!.selecteds[i] = h;
          break;
        case 4:
          // minute
          if (minuteInterval == null || minuteInterval! < 2) {
            picker!.selecteds[i] = value!.minute;
          } else {
            picker!.selecteds[i] = value!.minute ~/ minuteInterval!;
            final m = picker!.selecteds[i] * minuteInterval!;
            if (m != value!.minute) {
              // 需要更新 value
              var s = value!.second;
              if (type != 2 && type != 6) s = 0;
              final h = _colAP >= 0 ? _calcHourOfAMPM(sh, m) : sh;
              value = DateTime(value!.year, value!.month, value!.day, h, m, s);
            }
          }
          break;
        case 5:
          picker!.selecteds[i] = value!.second;
          break;
        case 6:
          // am/pm
          picker!.selecteds[i] = (sh > 12 ||
                  (sh == 12 && (value!.minute > 0 || value!.second > 0)))
              ? 1
              : 0;
          break;
        case 7:
          picker!.selecteds[i] = sh == 0
              ? 11
              : (sh > 12)
                  ? sh - 12 - 1
                  : sh - 1;
          break;
      }
    }
  }

  @override
  void doSelect(int column, int index) {
    int year, month, day, h, m, s;
    year = value!.year;
    month = value!.month;
    day = value!.day;
    h = value!.hour;
    m = value!.minute;
    s = _existSec ? value!.second : 0;

    int colType = getColumnType(column);
    switch (colType) {
      case 0:
        year = _yearBegin + index;
        break;
      case 1:
        month = index + 1;
        break;
      case 2:
        day = index + 1;
        break;
      case 3:
        h = index + (minHour ?? 0);
        break;
      case 4:
        m = (minuteInterval == null || minuteInterval! < 2)
            ? index
            : index * minuteInterval!;
        if (_colAP >= 0) {
          h = _calcHourOfAMPM(h, m);
        }
        break;
      case 5:
        s = index;
        break;
      case 6:
        h = _calcHourOfAMPM(h, m);
        if (minHour != null || maxHour != null) {
          if (minHour != null && _colHour >= 0) {
            if (h < minHour!) {
              picker!.selecteds[_colHour] = 0;
              picker!.updateColumn(_colHour);
              return;
            }
          }
          if (maxHour != null && h > maxHour!) h = maxHour!;
        }
        break;
      case 7:
        h = index +
            (minHour == null
                ? 0
                : (picker!.selecteds[_colAP] == 0 ? minHour! : 0)) +
            1;
        if (_colAP >= 0) {
          h = _calcHourOfAMPM(h, m);
        }
        if (h > 23) h = 0;
        break;
    }
    int dayCount = _calcDateCount(year, month);

    bool isChangeDay = false;
    if (day > dayCount) {
      day = dayCount;
      isChangeDay = true;
    }
    value = DateTime(year, month, day, h, m, s);

    if (_verificationMinMaxValue()) {
      notifyDataChanged();
    } else if (isChangeDay && _colDay >= 0) {
      doShow();
      picker!.updateColumn(_colDay);
    }
  }

  bool _verificationMinMaxValue() {
    DateTime? minV = minValue;
    DateTime? maxV = maxValue;
    if (minV == null && yearBegin != null) {
      minV = DateTime(yearBegin!, 1, 1, minHour ?? 0);
    }
    if (maxV == null && yearEnd != null) {
      maxV = DateTime(yearEnd!, 12, 31, maxHour ?? 23, 59, 59);
    }
    if (minV != null &&
        (value!.millisecondsSinceEpoch < minV.millisecondsSinceEpoch)) {
      value = minV;
      return true;
    } else if (maxV != null &&
        value!.millisecondsSinceEpoch > maxV.millisecondsSinceEpoch) {
      value = maxV;
      return true;
    }
    return false;
  }

  // Calculate am/pm time transfer
  int _calcHourOfAMPM(int h, int m) {
    // 12:00 AM , 00:00:000
    // 12:30 AM , 12:30:000
    // 12:00 PM , 12:00:000
    // 12:30 PM , 00:30:000
    if (picker!.selecteds[_colAP] == 0) {
      // am
      if (h == 12 && m == 0) {
        h = 0;
      } else if (h == 0 && m > 0) {
        h = 12;
      }
      if (h > 12) h = h - 12;
    } else {
      // pm
      if (h > 0 && h < 12) h = h + 12;
      if (h == 12 && m > 0) {
        h = 0;
      } else if (h == 0 && m == 0) {
        h = 12;
      }
    }
    return h;
  }

  int _getAPColIndex() {
    List<int> items = customColumnType ?? columnType[type];
    _colHour = items.indexWhere((e) => e == 7);
    _colDay = items.indexWhere((e) => e == 2);
    for (int i = 0; i < items.length; i++) {
      if (items[i] == 6) return i;
    }
    return -1;
  }

  int _calcDateCount(int year, int month) {
    switch (month) {
      case 1:
      case 3:
      case 5:
      case 7:
      case 8:
      case 10:
      case 12:
        return 31;
      case 2:
        {
          if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) {
            return 29;
          }
          return 28;
        }
    }
    return 30;
  }

  String intToStr(int v) {
    return (v < 10) ? "0$v" : "$v";
  }

  String _checkStr(String? v) {
    return v ?? "";
  }
}
