# AdvanceInfiniteScroll

A versatile Flutter package for implementing advanced scrolling. Whether you're looking for infinite scrolling, responsive grid views, or customizable loaders, `AdvanceInfiniteScroll` has got you covered.

## Features:

- Infinite Scrolling
- Responsive Grid/List Views
- Pull-to-Refresh Capability
- Customizable Loaders For Loading More or Initial Loader
- "No Data Found" Widget Handling
- "ON ERROR" Widget Handling,
- Optimized Rendering for Visible Items

## Usage:

To use this package, add `advance_infinite_scroll` as a dependency in your `pubspec.yaml` file.

### Data Fetching:

You can fetch data from your network or any source. For demonstration purposes, here's a dummy data-fetching function:

```dart
Future<List<String>> onListFutureDummy(int page, int perPage, Map? params) async {
  debugPrint("ON LOAD DATA AIS :: $page");
  await Future.delayed(const Duration(seconds: 1));
  return List.generate(perPage, (index) => "PAGE :: $page ::");
  // return [];
}
```

This function simulates a network call with a delay and generates dummy data.

### Basic Setup:

Here's a simple example demonstrating the usage:

```dart
AdvanceInfiniteScroll<String>(
    minItemWidth: MediaQuery.of(context).size.width,
    minItemsPerRow: 1,
    controller: AdvanceInfiniteScrollController<String>(
      onFuture: onListFutureDummy,
      perPage: 14,
    ),
    noDataFoundWidget: (c) {
      return TextButton(
        onPressed: () {
          c.refresh();
        },
        child: const Text("Refresh"),
      );
    },
    loadingMoreWidget: const Center(
      child: CircularProgressIndicator(),
    ),
    builder: (BuildContext context, listData) {
      return [
        Container(
          color: Colors.green,
          child: SizedBox(
            height: 100,
            width: MediaQuery.of(context).size.width,
          ),
        ),
        ...List.generate(listData.length, (index) {
          return ListTile(
            title: Text(
              "${listData[index]}:: INDEX :: $index ::",
            ),
          );
        }),
      ];
    },
)
```

### Parameters:

Here's a brief overview of the key parameters:

- `minItemWidth`: The minimum width for an item.
- `minItemsPerRow`: The minimum number of items per row.
- `controller`: The controller associated with `AdvanceInfiniteScroll`.
- `loadingMoreWidget`: A widget to display while more items are being loaded.
- `builder`: A function that returns a list of widgets based on the provided data.


For more information and please checkout example folder.


## Contributing:

Feel free to submit issues or pull requests to enhance the package. Contributions are always welcome!