part of 'serialisation.dart';

/// This one is usually not exported.
class StandardFirstMoveAdapter extends BasicAdapter<StandardFirstMoveOptions> {
  const StandardFirstMoveAdapter()
      : super('bishop.first.standard', StandardFirstMoveOptions.new);
}

class FirstMovePairAdapter extends DeepAdapter<FirstMoveOptionsPair> {
  @override
  String get id => 'bishop.first.pair';

  @override
  FirstMoveOptionsPair build(
    Map<String, dynamic>? params, {
    List<BishopTypeAdapter> adapters = const [],
  }) =>
      FirstMoveOptionsPair(
        deserialise<FirstMoveOptions>(params?['white'], adapters: adapters),
        deserialise<FirstMoveOptions>(params?['black'], adapters: adapters),
      );

  @override
  Map<String, dynamic>? export(
    FirstMoveOptionsPair e, {
    List<BishopTypeAdapter> adapters = const [],
  }) =>
      {
        'white': e.white != null
            ? serialise<FirstMoveOptions>(e.white!, adapters: adapters)
            : null,
        'black': e.black != null
            ? serialise<FirstMoveOptions>(e.black!, adapters: adapters)
            : null,
      };
}

class FirstMoveSetAdapter extends DeepAdapter<FirstMoveOptionsSet> {
  @override
  String get id => 'bishop.first.set';

  @override
  FirstMoveOptionsSet build(
    Map<String, dynamic>? params, {
    List<BishopTypeAdapter> adapters = const [],
  }) =>
      FirstMoveOptionsSet(
        BishopSerialisation.buildMap<FirstMoveOptions>(
          params!,
          adapters: adapters,
        ),
      );

  @override
  Map<String, dynamic>? export(
    FirstMoveOptionsSet e, {
    List<BishopTypeAdapter> adapters = const [],
  }) =>
      BishopSerialisation.exportMap(e.set, adapters: adapters);
}

class RanksFirstMoveAdapter extends BishopTypeAdapter<RanksFirstMoveOptions> {
  @override
  String get id => 'bishop.first.ranks';

  @override
  RanksFirstMoveOptions build(Map<String, dynamic>? params) =>
      RanksFirstMoveOptions((params!['ranks'] as List).cast<int>());

  @override
  Map<String, dynamic> export(RanksFirstMoveOptions e) => {'ranks': e.ranks};
}

class InitialFirstMoveAdapter
    extends BasicAdapter<InitialStateFirstMoveOptions> {
  const InitialFirstMoveAdapter()
      : super('bishop.first.initial', InitialStateFirstMoveOptions.new);
}
