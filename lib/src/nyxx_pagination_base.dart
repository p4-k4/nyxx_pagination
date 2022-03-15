import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';

class PaginatedMultiSelectHandler {
  PaginatedMultiSelectHandler(this.id, this.callback);
  Future<void> Function(IMultiselectInteractionEvent) callback;
  String id;
}

class PaginateMultiSelect {
/// NOTE: Work in progress!
/// Creates a paginated multi select's for lists that exceed 25 items.
/// For any lists containing less than 25 items, will produce 1  multi select on a single page.
  PaginateMultiSelect({
    required this.id,
    required this.list,
    required this.bot,
    this.contentPrefix,
    this.customHandler,
  });
  /// ID to be used as a string prefix with the multi select handler and labels.
  /// On interaction events, customID's will appear as ID_item, "ID" being the [id]
  /// and "item" being the [list] item converted to `String`.
  final String id;
  /// `List` of items that will be converted to `String` values for display in the list.
  final List list;
  /// The bot client.
  final INyxxWebsocket bot;

  /// Additional content that preceeds the page counter.
  final String? contentPrefix;
  /// Any additional event handling.
  ///
  /// Option labels are set in the format of id_item.
  final Future<void> Function(IMultiselectInteractionEvent)? customHandler;
 
  /// Returns a `ComponentMessageBuilder` containing page counter and the multi select component.
  ComponentMessageBuilder build() {
    final multiPages = _paginateMultiselect();
    final comp = ComponentMessageBuilder()
      ..content = '$contentPrefix\nPage: 1/${multiPages.length}';
    comp.addComponentRow(ComponentRowBuilder()..addComponent(multiPages.first));
    return comp;
  }

  List<MultiselectBuilder> _paginateMultiselect() {
    final chunks = <MultiselectBuilder>[];

    if (list.length <= 25) {
      final multiSelectBuilder = MultiselectBuilder(id);
      for (var i in list) {
        multiSelectBuilder.addOption(
            MultiselectOptionBuilder(i.toString(), id + '_' + i.toString()));
      }
      chunks.add(multiSelectBuilder);
    } else {
      final options = [];
      // Convert the list elements into `MultiselectOptionBuilder` then
      // also convert the list elements into `String` for use with [label] and [value].
      // [value] gets [id] prepended to it's `String` value.
      for (var i in list) {
        options.add(
            MultiselectOptionBuilder(i.toString(), id + '_' + i.toString()));
      }

      // Group `options` elements into a size of [listSizePerPage] then add them to a `MultiselectBuilder`.
      // Add each `MultiselectBuilder` to the resulting `List`.
      final optionsPerPage = 23;
      for (var i = 0; i < options.length; i += optionsPerPage) {
        final multiSelectBuilder = MultiselectBuilder(id);
        int size = i + optionsPerPage;
        for (var i in options.sublist(
            i, size > options.length ? options.length : size)) {
          multiSelectBuilder.addOption(i);
        }
        chunks.add(multiSelectBuilder);
      }
      var counterBack = 0;
      var counterNext = 0;
      // Add the next option for every multi select except last
      for (var i in chunks.sublist(0, chunks.length - 1)) {
        counterNext++;
        i.options.insert(
            i.options.length,
            MultiselectOptionBuilder('Next ➡️ ',
                id + '_' + 'next' + '_' + (counterNext - 1).toString()));
      }
      // Add the back option for every multi select except first
      for (var i in chunks.sublist(1)) {
        counterBack++;
        i.options.insert(
            0,
            MultiselectOptionBuilder('Back ⬅️',
                id + '_' + 'back' + '_' + (counterBack - 1).toString()));
      }
      counterBack = 0;
      counterNext = 0;
    }
    return chunks;
  }

  List<PaginatedMultiSelectHandler> paginateNavigationHandler() {
    List<PaginatedMultiSelectHandler> multiSelectInteractionHandlers = [];
    final pages = _paginateMultiselect();

    Future<void> handler(IMultiselectInteractionEvent event) async {
      // If next button is pressed
      if (event.interaction.values.any((element) => element.contains(id)) &&
          event.interaction.values.any((element) => element.contains('next'))) {
        final pageValue = event.interaction.values.firstWhere(
            (element) => element.contains(id) && element.contains('next'));

        final pageCount = int.parse(pageValue.substring(pageValue.length - 1));

        await event.acknowledge();
        await event.editOriginalResponse(ComponentMessageBuilder()
          ..addComponentRow(
              ComponentRowBuilder()..addComponent(pages[pageCount + 1]))
          ..content = '$contentPrefix\nPage: ${pageCount + 2}/${pages.length}');
      }
      // If back button is pressed
      if (event.interaction.values.any((element) => element.contains(id)) &&
          event.interaction.values.any((element) => element.contains('back'))) {
        final pageValue = event.interaction.values.firstWhere(
            (element) => element.contains(id) && element.contains('back'));

        final pageCount = int.parse(pageValue.substring(pageValue.length - 1));

        await event.acknowledge();
        await event.editOriginalResponse(ComponentMessageBuilder()
          ..addComponentRow(
              ComponentRowBuilder()..addComponent(pages[pageCount]))
          ..content = '$contentPrefix\nPage: ${pageCount + 1}/${pages.length}');
      }
      if (customHandler != null) {
        await customHandler!(event);
      }
    }

    multiSelectInteractionHandlers
        .add(PaginatedMultiSelectHandler(id, handler));

    return multiSelectInteractionHandlers;
  }

  register() {
    final chunks = paginateNavigationHandler();
    final paginatedNavigationHandlers = [
      for (var i in chunks) paginateNavigationHandler()
    ];
    for (var i in paginatedNavigationHandlers) {
      for (var b in i) {
        IInteractions.create(WebsocketInteractionBackend(bot))
            .registerMultiselectHandler(b.id, b.callback);
      }
    }
  }
}
