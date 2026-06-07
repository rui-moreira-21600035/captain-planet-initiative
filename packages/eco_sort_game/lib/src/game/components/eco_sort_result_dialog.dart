import 'package:eco_sort_game/src/domain/wrong_answer_record.dart';
import 'package:flutter/material.dart';

import 'package:eco_sort_game/src/domain/bin_type.dart';
import 'package:eco_sort_game/src/domain/ecosort_game_result.dart';

class EcoSortResultDialog extends StatefulWidget {
  final EcoSortGameResult result;

  const EcoSortResultDialog({super.key, required this.result});

  @override
  State<EcoSortResultDialog> createState() => _EcoSortResultDialogState();
}

class _EcoSortResultDialogState extends State<EcoSortResultDialog> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentErrorIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final total = result.correct + result.wrong;
    final accuracy = total == 0 ? 0 : ((result.correct / total) * 100).round();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFFF7FAF2),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⭐ FIM DO JOGO ⭐',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                'Pontuação: ${result.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat(label: 'Certos', value: '${result.correct}', icon: '✅'),
                  _Stat(label: 'Errados', value: '${result.wrong}', icon: '❌'),
                  _Stat(label: 'Precisão', value: '$accuracy%', icon: '🎯'),
                ],
              ),

              const SizedBox(height: 8),

              _WrongAnswersCarousel(
                wrongAnswers: result.wrongAnswers,
                controller: _pageController,
                currentIndex: _currentErrorIndex,
                onChanged: (i) => setState(() => _currentErrorIndex = i),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _WrongAnswersCarousel extends StatelessWidget {
  final List<WrongAnswerRecord> wrongAnswers;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _WrongAnswersCarousel({
    required this.wrongAnswers,
    required this.controller,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (wrongAnswers.isEmpty) {
      return Container(
        width: double.infinity,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1EA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Pontuação perfeita. Excelente! 🌟',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              const Text(
                'Onde falhaste:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),

              const Spacer(),

              Text(
                '${currentIndex + 1}/${wrongAnswers.length}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        SizedBox(
          height: 68,
          child: PageView.builder(
            controller: controller,
            itemCount: wrongAnswers.length,
            onPageChanged: onChanged,
            itemBuilder: (context, index) {
              final w = wrongAnswers[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1EA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('❌', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.item.labelPt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Correto: ${_binName(w.expected)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        if (wrongAnswers.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              wrongAnswers.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: i == currentIndex ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == currentIndex
                      ? const Color(0xFF202820)
                      : const Color(0x33202820),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

String _binName(BinType t) {
  switch (t) {
    case BinType.blue:
      return 'Azul';
    case BinType.green:
      return 'Verde';
    case BinType.yellow:
      return 'Amarelo';
    case BinType.brown:
      return 'Castanho';
  }
}
