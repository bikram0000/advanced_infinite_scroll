library advanced_infinite_scroll;

import 'package:advanced_infinite_scroll/utility.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quiver/iterables.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
export 'package:responsive_grid_list/responsive_grid_list.dart';

class AdvancedInfiniteScrollController<T> {
  /// when rendering it will return numbers of item in a row.
  final Function(int)? onItemCount;

  /// when rendering it will return item's width
  final Function(double)? onItemWidth;

  /// it is for getting numbers of items per page from network by default
  /// it will 10.
  final int perPage;

  /// to get the state of [AdvancedInfiniteScroll]
  AdvancedInfiniteScrollState<T>? widgetState;

  /// Callback function on pull up to load more data and refresh
  final Future<List<T>?> Function(int page, int perPage, Map? params) onFuture;

  void _bind(AdvancedInfiniteScrollState<T> state) {
    widgetState = state;
  }

  AdvancedInfiniteScrollController(
      {this.onItemCount,
      this.onItemWidth,
      required this.onFuture,
      this.perPage = 10});

  /// TO refresh the network call.
  Future<List<T>?> refresh({
    Map? params,
  }) async {
    return await widgetState?.loadFutureList(params: params);
  }

}

class AdvancedInfiniteScroll<T> extends StatefulWidget {
  /// Whether need pull refresh or not.
  final bool pullRefresh;

  /// Builder for getting list of widget. [listData] it will return the same getting from network.
  final List<Widget> Function(BuildContext context, List<T> listData) builder;

  final Widget? loadingMoreWidget;
  final Widget? loadingWidget;

  final Widget Function(AdvancedInfiniteScrollController<T> controller)?
      noDataFoundWidget;
  final Widget Function(AdvancedInfiniteScrollController<T> controller)?
      errorWidget;

  ///
  /// Object that can be set if any of the [ListView.builder] options
  /// need to be overridden. The [ResponsiveGridList] defines the builder
  /// and item count. All other options are optional and can be set through
  /// this object.
  ///
  final ListViewBuilderOptions? listViewBuilderOptions;

  ///
  /// The minimum item width of each individual item in the list. Can be smaller
  /// if the viewport constraints are smaller.
  ///
  final double minItemWidth;

  ///
  /// Minimum items to show per row. If this is set to a value higher than 1,
  /// this takes precedence over [minItemWidth] and allows items to be smaller
  /// than [minItemWidth] to fit at least [minItemsPerRow] items.
  ///
  final int minItemsPerRow;

  ///
  /// Maximum items to show per row. By default the package shows all items that
  /// fit into the available space according to [minItemWidth].
  ///
  /// Note that this should only be used when limiting items on large screens
  /// since it will stretch [maxItemsPerRow] items across the whole width
  /// when maximum is reached. This can result in a large difference to
  /// [minItemWidth].
  ///
  final int? maxItemsPerRow;

  ///
  /// The horizontal spacing between the items in the grid.
  ///
  final double horizontalGridSpacing;

  ///
  /// The vertical spacing between the items in the grid.
  ///
  final double verticalGridSpacing;

  ///
  /// The horizontal spacing around the grid.
  ///
  final double? horizontalGridMargin;

  ///
  /// The vertical spacing around the grid.
  ///
  final double? verticalGridMargin;

  ///
  /// [MainAxisAlignment] of each row in the grid list.
  ///
  final MainAxisAlignment rowMainAxisAlignment; // coverage:ignore-end

  ///
  ///[AdvancedInfiniteScrollController] it can help to refresh the list manually,
  ///
  final AdvancedInfiniteScrollController<T> controller;

  const AdvancedInfiniteScroll({
    super.key,
    this.listViewBuilderOptions,
    required this.minItemWidth,
    required this.minItemsPerRow,
    this.horizontalGridSpacing = 1,
    this.verticalGridSpacing = 1,
    this.rowMainAxisAlignment = MainAxisAlignment.center,
    this.maxItemsPerRow,
    this.horizontalGridMargin,
    this.verticalGridMargin,

    ///related to load more..
    this.pullRefresh = true,
    required this.builder,

    ///loader..
    this.loadingMoreWidget = const Center(child: CircularProgressIndicator()),
    this.loadingWidget,
    this.noDataFoundWidget,
    this.errorWidget,
    required this.controller,
  })  : assert(
          // coverage:ignore-start
          minItemWidth > 0,
          'minItemWidth has to be > 0. It instead was set to $minItemWidth',
        ),
        assert(
          minItemsPerRow > 0,
          'minItemsPerRow has to be > 0. It instead was set to $minItemsPerRow',
        ),
        assert(
          maxItemsPerRow == null || maxItemsPerRow >= minItemsPerRow,
          'maxItemsPerRow can only be null or >= minItemsPerRow '
          '($minItemsPerRow). It instead was set to $maxItemsPerRow',
        );

  ///
  /// Method to generate a list of [ResponsiveGridRow]'s with spacing in between
  /// them.
  ///
  /// [maxWidth] is the maximum width of the current layout.
  ///
  List<Widget> getResponsiveGridListItems(
      double maxWidth, List<Widget> children) {
    // Start with the minimum allowed number of items per row.
    var itemsPerRow = minItemsPerRow;

    // Calculate the current width according to the items per row
    var currentWidth =
        itemsPerRow * minItemWidth + (itemsPerRow - 1) * horizontalGridSpacing;

    // Add outer margin (vertical) if set
    if (horizontalGridMargin != null) {
      currentWidth += 2 * horizontalGridMargin!;
    }

    // While another pair of spacing + minItemWidth fits the row, add it to
    // the variables. Only add items while maxItemsPerRow is not reached.
    while (currentWidth < maxWidth &&
        (maxItemsPerRow == null || itemsPerRow < maxItemsPerRow!)) {
      if (currentWidth + (minItemWidth + horizontalGridSpacing) <= maxWidth) {
        // If another spacing + item fits in the row, add one item to the row
        // and update the currentWidth
        currentWidth += minItemWidth + horizontalGridSpacing;
        itemsPerRow++;
      } else {
        // If no other item + spacer fits into the row, break
        break;
      }
    }

    // Calculate the spacers per row (they are only in between the items, not
    // at the edges)
    final spacePerRow = itemsPerRow - 1;

    // Calculate the itemWidth that results from the maxWidth and number of
    // spacers and outer margin (horizontal)
    final itemWidth = (maxWidth -
            (spacePerRow * horizontalGridSpacing) -
            (2 * (horizontalGridMargin ?? 0))) /
        itemsPerRow;

    // Partition the items into groups of itemsPerRow length and map them
    // to ResponsiveGridRow's
    final items = partition(children, itemsPerRow)
        .map<Widget>(
          (e) => ResponsiveGridRow(
            rowItems: e,
            spacing: horizontalGridSpacing,
            horizontalGridMargin: horizontalGridMargin,
            itemWidth: itemWidth,
            rowMainAxisAlignment: rowMainAxisAlignment,
          ),
        )
        .toList();

    // Join the rows width spacing in between them (vertical)
    final responsiveGridListItems =
        items.genericJoin(SizedBox(height: verticalGridSpacing));

    // Add outer margin (vertical) if set
    if (verticalGridMargin != null) {
      return [
        SizedBox(height: verticalGridMargin),
        ...responsiveGridListItems,
        SizedBox(height: verticalGridMargin)
      ];
    }

    return responsiveGridListItems;
  }

  @override
  AdvancedInfiniteScrollState<T> createState() =>
      AdvancedInfiniteScrollState<T>();
}

class AdvancedInfiniteScrollState<T> extends State<AdvancedInfiniteScroll<T>> {
  List<T>? futureList;
  int page = 1;
  bool? isLastPage;
  bool loadingFuture = false;

  @override
  void initState() {
    super.initState();
    loadFutureList();
  }

  @override
  Widget build(BuildContext context) {
    widget.controller._bind(this);
    if ((futureList == null || (futureList as List).isEmpty)) {
      if (loadingFuture) {
        return (widget.loadingWidget ??
            widget.loadingMoreWidget ??
            const Center(child: CircularProgressIndicator()));
      } else if (!loadingFuture && futureList != null) {
        ///its means it is empty
        return (widget.noDataFoundWidget != null
            ? widget.noDataFoundWidget!(widget.controller)
            : const Center(child: Text("NO DATA FOUND")));
      } else {
        return (widget.errorWidget != null
            ? widget.errorWidget!(widget.controller)
            : const Center(child: Text("SOMETHING WENT WRONG !!")));
      }
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Get the grid list items
        final items = widget.getResponsiveGridListItems(
          constraints.maxWidth -
              (widget.listViewBuilderOptions?.padding?.horizontal ?? 0),
          widget.builder(
            context,
            futureList!,
          ),
        );

        if (widget.controller.onItemCount != null) {
          if (items.first is ResponsiveGridRow) {
            if (widget.controller.onItemCount != null) {
              widget.controller.onItemCount!(
                  (items.first as ResponsiveGridRow).rowItems.length);
            }
            if (widget.controller.onItemWidth != null) {
              widget.controller
                  .onItemWidth!((items.first as ResponsiveGridRow).itemWidth);
            }
          }
        }
        Widget child = ListView.builder(
          itemCount: items.length + (widget.loadingMoreWidget != null ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if (index >= items.length) {
              if (isLastPage ?? true) {
                return const SizedBox();
              } else {
                loadFutureList(loadMore: true);
                return widget.loadingMoreWidget;
              }
            } else {
              return items[index];
            }
          },
          scrollDirection:
              widget.listViewBuilderOptions?.scrollDirection ?? Axis.vertical,
          reverse: widget.listViewBuilderOptions?.reverse ?? false,
          controller: widget.listViewBuilderOptions?.controller,
          primary: widget.listViewBuilderOptions?.primary,
          physics: widget.listViewBuilderOptions?.physics,
          shrinkWrap: widget.listViewBuilderOptions?.shrinkWrap ?? false,
          padding: widget.listViewBuilderOptions?.padding,
          itemExtent: widget.listViewBuilderOptions?.itemExtent,
          prototypeItem: widget.listViewBuilderOptions?.prototypeItem,
          findChildIndexCallback:
              widget.listViewBuilderOptions?.findChildIndexCallback,
          addAutomaticKeepAlives:
              widget.listViewBuilderOptions?.addAutomaticKeepAlives ?? true,
          addRepaintBoundaries:
              widget.listViewBuilderOptions?.addRepaintBoundaries ?? true,
          addSemanticIndexes:
              widget.listViewBuilderOptions?.addSemanticIndexes ?? true,
          cacheExtent: widget.listViewBuilderOptions?.cacheExtent,
          semanticChildCount: widget.listViewBuilderOptions?.semanticChildCount,
          dragStartBehavior: widget.listViewBuilderOptions?.dragStartBehavior ??
              DragStartBehavior.start,
          keyboardDismissBehavior:
              widget.listViewBuilderOptions?.keyboardDismissBehavior ??
                  ScrollViewKeyboardDismissBehavior.manual,
          restorationId: widget.listViewBuilderOptions?.restorationId,
          clipBehavior:
              widget.listViewBuilderOptions?.clipBehavior ?? Clip.hardEdge,
        );
        return !widget.pullRefresh
            ? child
            : ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.invertedStylus,
                  },
                ),
                child: RefreshIndicator(
                  color: Theme.of(context).primaryColor,
                  onRefresh: () async {
                    page = 1;
                    await loadFutureList();
                  },
                  child: child,
                ),
              );
      },
    );
  }

  Future<List<T>?> loadFutureList({bool loadMore = false, Map? params}) async {
    if (loadingFuture) {
      return null;
    }
    if (loadMore) {
      page++;
    } else {
      page = 1;
    }
    if (page == 1) {
      futureList = null;
    }
    loadingFuture = true;
    update();
    try {
      List<T>? futureList2 = await widget.controller
          .onFuture(page, widget.controller.perPage, params);
      if (futureList2 != null) {
        if (page == 1) {
          futureList = futureList2;
        } else {
          futureList?.addAll(futureList2);
        }

        if ((futureList2).length == widget.controller.perPage) {
          isLastPage = false;
        } else {
          isLastPage = true;
        }
      }
    } catch (e) {
      debugPrint("ERROR AIS ::  $e");
    }
    loadingFuture = false;
    update();
    return futureList;
  }

  void update() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
}
