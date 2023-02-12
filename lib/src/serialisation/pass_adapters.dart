part of 'serialisation.dart';

class NoPassAdapter extends BasicAdapter<NoPass> {
  const NoPassAdapter() : super('bishop.pass.none', NoPass.new);
}

class StandardPassAdapter extends BasicAdapter<StandardPass> {
  const StandardPassAdapter() : super('bishop.pass.standard', StandardPass.new);
}
