# Nyxx Paginate

![](https://i.imgur.com/I9UYpp5.gif)

NOTE: *This project is usable but is still work in progress.*

Currently, paginated multi select's is probably the most elegant
solution we have in Discord bot Development and that's precisely what this package does.

## Features
- Paginate any list that contains over 25 items.
- Also processes list's containing less than 25 items as a single page.
- Next and Back options on the top and bottom of list respectively.
- Page counter to show the current page and total pages.
- Ability to prepend message content.
- Automatically creates and registers `MultiSelectInteractionHandlers`.
- Optional Next and Back buttons (planned future).

## Usage
```dart
final testList = List.generate(96, (index) => 0 + index);

final multiSelect = PaginateMultiSelect(
    id: 'myPaginatedList1',
    list: testList,
    bot: bot,
    contentPrefix: 'Choose an option from the list below.',
    customHandler: printMe);
```

Work in progress...
