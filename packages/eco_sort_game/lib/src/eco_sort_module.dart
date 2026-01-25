import 'package:common_gamekit/common_gamekit.dart';
import 'package:flutter/widgets.dart';

class EcoSortPage extends StatelessWidget {
  const EcoSortPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: substituir pelo teu GameWidget( game: EcoSortFlameGame() )
    return const Center(child: Text('Eco Sort (placeholder)'));
  }
}

const ecoSortModule = GameModule(
  id: 'eco_sort',
  name: 'Eco Sort',
  description: 'Identifica o contentor certo para cada item.',
  pageBuilder: _ecoSortPageBuilder,
);

Widget _ecoSortPageBuilder() => const EcoSortPage();