part of 'variant.dart';

class BuiltVariant {
  final Variant data;

  final List<PieceDefinition> pieces;
  final Map<String, PieceDefinition> pieceLookup;
  final Map<String, int> pieceIndexLookup;
  final List<int> promotionPieces;
  final int epPiece;
  final int castlingPiece;
  final int royalPiece;
  final MaterialConditions<int> materialConditions;

  const BuiltVariant({
    required this.data,
    required this.pieces,
    required this.pieceLookup,
    required this.pieceIndexLookup,
    required this.promotionPieces,
    required this.epPiece,
    required this.castlingPiece,
    required this.royalPiece,
    required this.materialConditions,
  });

  factory BuiltVariant.fromData(Variant data) {
    // TODO: make these immutable somehow
    data.pieceTypes.forEach((_, p) => p.init(data.boardSize));

    List<PieceDefinition> pieces = [PieceDefinition.empty()];
    Map<String, PieceDefinition> pieceLookup = {};
    Map<String, int> pieceIndexLookup = {};
    data.pieceTypes.forEach((s, p) {
      int value = p.royal ? Bishop.mateUpper : p.value;
      if (data.pieceValues?.containsKey(s) ?? false) {
        value = data.pieceValues![s]!;
      }
      PieceDefinition piece = PieceDefinition(type: p, symbol: s, value: value);
      pieces.add(piece);
      pieceLookup[s] = piece;
      pieceIndexLookup[s] = pieces.length - 1;
    });
    List<int> promotionPieces = [];
    for (int i = 0; i < pieces.length; i++) {
      // && !pieces[i].type.royal) ?
      if (pieces[i].type.canPromoteTo) promotionPieces.add(i);
    }

    return BuiltVariant(
      data: data,
      pieces: pieces,
      pieceLookup: pieceLookup,
      pieceIndexLookup: pieceIndexLookup,
      promotionPieces: promotionPieces,
      epPiece: data.enPassant
          ? pieces.indexWhere((p) => p.type.enPassantable)
          : Bishop.invalid,
      castlingPiece: data.castling
          ? pieces.indexWhere((p) => p.symbol == data.castlingOptions.rookPiece)
          : Bishop.invalid,
      royalPiece: pieces.indexWhere((p) => p.type.royal),
      materialConditions: data.materialConditions.convert(pieces),
    );
  }

  int pieceIndex(String symbol) => pieces.indexWhere((p) => p.symbol == symbol);
  List<int> pieceIndices(List<String> symbols) =>
      symbols.map((p) => pieceIndex(p)).where((p) => p >= 0).toList();

  /// A human-friendly name.
  String get name => data.name;

  /// The size of the board.
  BoardSize get boardSize => data.boardSize;

  /// The pieces to be used in this variant, in the form symbol: pieceType.
  /// Symbols are single uppercase letters, such as 'P' (pawn) or 'N' (knight).
  Map<String, PieceType> get pieceTypes => data.pieceTypes;

  /// The castling rules for this VariantData.
  CastlingOptions get castlingOptions => data.castlingOptions;

  GameEndConditions get gameEndConditions => data.gameEndConditions;
  OutputOptions get outputOptions => data.outputOptions;

  /// A full starting position, specified as a
  /// [FEN string](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation).
  String? get startPosition => data.startPosition;

  /// A builder function for variants with variable start positions, such as Chess 960.
  FenBuilder? get startPosBuilder => data.startPosBuilder;

  /// Is promotion enabled?
  bool get promotion => data.promotion;

  /// The first ranks for [WHITE, BLACK] that pieces can be promoted on.
  /// If the rank specified is not the final rank the piece can reach, then promotion
  /// will be optional on every rank up until the final rank, when it becomes mandatory.
  List<int> get promotionRanks => data.promotionRanks;

  /// Is en passant allowed in this variant?
  bool get enPassant => data.enPassant;

  /// The ranks for [WHITE, BLACK] that a piece with a 'first-only' move can make that
  /// move from. For example, a pawn's double move.
  List<List<int>> get firstMoveRanks => data.firstMoveRanks;

  /// Set this to 100 for the 50-move rule in standard chess.
  int? get halfMoveDraw => data.halfMoveDraw;

  /// Set this to 3 for the threefold repeition rule in standard chess.
  int? get repetitionDraw => data.repetitionDraw;

  /// Are hands enabled in this variant? For example, Crazyhouse.
  bool get hands => data.hands;

  /// What type of gating, if any, is used in this variant?
  GatingMode get gatingMode => data.gatingMode;

  /// The relative values of pieces. These are usually already set in the [PieceType]
  /// definitions, so only use this if you want to override those.
  /// For example, you have a variant where a pawn is worth 200 instead of 100,
  /// but you still want to use the normal pawn definition.
  Map<String, int>? get pieceValues => data.pieceValues;

  bool get castling => data.castling;
  bool get gating => data.gating;

  @override
  String toString() => name;
}
