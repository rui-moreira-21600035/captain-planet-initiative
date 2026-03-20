import 'package:eco_guess_game/src/application/controllers/eco_guess_controller.dart';
import 'package:eco_guess_game/src/application/state/eco_guess_session_state.dart';
import 'package:eco_guess_game/src/data/repositories/challenge_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository();
});

final ecoGuessControllerProvider =
    NotifierProvider<EcoGuessController, EcoGuessSessionState>(() {
  return EcoGuessController();
});