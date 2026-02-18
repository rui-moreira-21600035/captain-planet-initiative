import 'package:eco_sort_game/src/data/catalog/catalog_parser.dart';
import 'package:eco_sort_game/src/domain/bin_type.dart';
import 'package:eco_sort_game/src/domain/bin_type_mapper.dart';
import 'package:eco_sort_game/src/domain/waste_item.dart';
import 'package:eco_sort_game/src/game/controllers/round_controller.dart';
import 'package:eco_sort_game/src/game/controllers/scoring_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Testa Dominio
  // BinTypeMapper
  test('binFromId maps ids', () {
    expect(BinTypeMapper.fromId('blue'), BinType.blue);
    expect(() => BinTypeMapper.fromId('nope'), throwsStateError);
  });

  test('toId maps correctly', () {
    expect(BinTypeMapper.toId(BinType.blue), 'blue');
    expect(BinTypeMapper.toId(BinType.green), 'green');
    expect(BinTypeMapper.toId(BinType.yellow), 'yellow');
    expect(BinTypeMapper.toId(BinType.brown), 'brown');
  });

  // Testa Controllers
  // ScoringController
  test('correct updates score and streak', () {
    final s = ScoringController();
    s.registerCorrect();
    expect(s.correct, 1);
    expect(s.wrong, 0);
    expect(s.streak, 1);
    expect(s.streakMax, 1);
    expect(s.score, greaterThan(0));
  });

  test('ScoringController.reset limpa todo o estado', () {
    final s = ScoringController();

    s.registerCorrect();
    s.registerCorrect();
    s.registerWrong();

    expect(s.score, greaterThan(0));
    expect(s.correct, greaterThan(0));
    expect(s.wrong, greaterThan(0));

    s.reset();

    expect(s.score, 0);
    expect(s.correct, 0);
    expect(s.wrong, 0);
    expect(s.streak, 0);
    expect(s.streakMax, 0);
  });

  // RoundController
  test('wrong resets streak and increments wrong', () {
    final s = ScoringController()..registerCorrect()..registerCorrect();
    s.registerWrong();
    expect(s.wrong, 1);
    expect(s.streak, 0);
    expect(s.streakMax, 2);
  });

  test('RoundController.reset reinicia contador e estado', () {
  final items = [
    WasteItem(id: 'a', label: 'A', bin: BinType.blue, asset: 'x'),
    WasteItem(id: 'b', label: 'B', bin: BinType.green, asset: 'y'),
  ];

  final r = RoundController(items);

  r.nextOrLoop();
  r.nextOrLoop();

  expect(r.totalRoundsPlayed, 2);

  r.reset();

  expect(r.totalRoundsPlayed, 0);
});

  test('round controller loops and counts', () {
    final items = [
      WasteItem(id: 'a', label: 'A', bin: BinType.blue, asset: 'x'),
    ];
    final r = RoundController(items);
    final first = r.nextOrLoop();
    final second = r.nextOrLoop();
    expect(first.id, 'a');
    expect(second.id, 'a');
    expect(r.totalRoundsPlayed, 2);
  });

  // Testa Data
  // CatalogParser
  group('CatalogParser', () {
    test('parse: catálogo válido', () {
      const jsonStr = r'''
      {
        "version": 1,
        "bins": [
          {"id":"blue","label":"Azul","asset":"assets/images/containers/blue.png"},
          {"id":"green","label":"Verde","asset":"assets/images/containers/green.png"},
          {"id":"yellow","label":"Amarelo","asset":"assets/images/containers/yellow.png"},
          {"id":"brown","label":"Castanho","asset":"assets/images/containers/brown.png"}
        ],
        "items": [
          {"id":"apple_core","label":"Miolo","bin":"brown","asset":"assets/images/waste_items/brown/apple_core.png"},
          {"id":"bottle","label":"Garrafa","bin":"green","asset":"assets/images/waste_items/green/bottle.png","scaleBias":0.9}
        ]
      }
      ''';

      final catalog = CatalogParser.parse(jsonStr);
      expect(catalog.version, 1);
      expect(catalog.bins.length, 4);
      expect(catalog.items.length, 2);
    });

    test('parse: falha com bin id inválido', () {
      const jsonStr = r'''
      {
        "version": 1,
        "bins": [
          {"id":"blu","label":"Azul","asset":"assets/images/containers/blue.png"}
        ],
        "items": [
          {"id":"x","label":"X","bin":"blu","asset":"assets/images/waste_items/x.png"}
        ]
      }
      ''';

      expect(
        () => CatalogParser.parse(jsonStr),
        throwsA(isA<CatalogFormatException>()),
      );
    });

    test('parse: falha com item id duplicado', () {
      const jsonStr = r'''
      {
        "version": 1,
        "bins": [
          {"id":"blue","label":"Azul","asset":"assets/images/containers/blue.png"},
          {"id":"green","label":"Verde","asset":"assets/images/containers/green.png"},
          {"id":"yellow","label":"Amarelo","asset":"assets/images/containers/yellow.png"},
          {"id":"brown","label":"Castanho","asset":"assets/images/containers/brown.png"}
        ],
        "items": [
          {"id":"dup","label":"A","bin":"blue","asset":"assets/images/waste_items/a.png"},
          {"id":"dup","label":"B","bin":"green","asset":"assets/images/waste_items/b.png"}
        ]
      }
      ''';

      expect(
        () => CatalogParser.parse(jsonStr),
        throwsA(isA<CatalogFormatException>()),
      );
    });

    test('parse: falha quando item refere bin inexistente', () {
      const jsonStr = r'''
      {
        "version": 1,
        "bins": [
          {"id":"blue","label":"Azul","asset":"assets/images/containers/blue.png"},
          {"id":"green","label":"Verde","asset":"assets/images/containers/green.png"},
          {"id":"yellow","label":"Amarelo","asset":"assets/images/containers/yellow.png"},
          {"id":"brown","label":"Castanho","asset":"assets/images/containers/brown.png"}
        ],
        "items": [
          {"id":"x","label":"X","bin":"purple","asset":"assets/images/waste_items/x.png"}
        ]
      }
      ''';

      expect(
        () => CatalogParser.parse(jsonStr),
        throwsA(isA<CatalogFormatException>()),
      );
    });

    test('parse: falha com items vazios', () {
      const jsonStr = r'''
      {
        "version": 1,
        "bins": [
          {"id":"blue","label":"Azul","asset":"assets/images/containers/blue.png"},
          {"id":"green","label":"Verde","asset":"assets/images/containers/green.png"},
          {"id":"yellow","label":"Amarelo","asset":"assets/images/containers/yellow.png"},
          {"id":"brown","label":"Castanho","asset":"assets/images/containers/brown.png"}
        ],
        "items": []
      }
      ''';

      expect(
        () => CatalogParser.parse(jsonStr),
        throwsA(isA<CatalogFormatException>()),
      );
    });

    test('parse: falha com asset vazio', () {
      const jsonStr = r'''
      {
        "version": 1,
        "bins": [
          {"id":"blue","label":"Azul","asset":" "}
        ],
        "items": [
          {"id":"x","label":"X","bin":"blue","asset":"assets/images/waste_items/x.png"}
        ]
      }
      ''';

      expect(
        () => CatalogParser.parse(jsonStr),
        throwsA(isA<CatalogFormatException>()),
      );
    });
  });

  test('CatalogFormatException.toString inclui mensagem', () {
  const e = CatalogFormatException('X');
  expect(e.toString(), 'CatalogFormatException: X');
});

test('parse: JSON inválido (catch) -> CatalogFormatException', () {
  expect(
    () => CatalogParser.parse('{"version":1,'), // JSON truncado
    throwsA(isA<CatalogFormatException>()),
  );
});

test('parse: versão não suportada -> CatalogFormatException', () {
  const jsonStr = r'''
  {
    "version": 999,
    "bins": [
      {"id":"blue","label":"Azul","asset":"assets/images/containers/blue.png"},
      {"id":"green","label":"Verde","asset":"assets/images/containers/green.png"},
      {"id":"yellow","label":"Amarelo","asset":"assets/images/containers/yellow.png"},
      {"id":"brown","label":"Castanho","asset":"assets/images/containers/brown.png"}
    ],
    "items": [
      {"id":"x","label":"X","bin":"blue","asset":"assets/images/waste_items/x.png"}
    ]
  }
  ''';

  expect(
    () => CatalogParser.parse(jsonStr),
    throwsA(
      isA<CatalogFormatException>().having(
        (e) => e.message,
        'message',
        contains('Versão do catálogo não suportada'),
      ),
    ),
  );
});

test('parse: scaleBias não numérico -> CatalogFormatException', () {
  const jsonStr = r'''
  {
    "version": 1,
    "bins": [
      {"id":"blue","label":"Azul","asset":"assets/images/containers/blue.png"},
      {"id":"green","label":"Verde","asset":"assets/images/containers/green.png"},
      {"id":"yellow","label":"Amarelo","asset":"assets/images/containers/yellow.png"},
      {"id":"brown","label":"Castanho","asset":"assets/images/containers/brown.png"}
    ],
    "items": [
      {
        "id":"x",
        "label":"X",
        "bin":"blue",
        "asset":"assets/images/waste_items/x.png",
        "scaleBias":"nope"
      }
    ]
  }
  ''';

  expect(
    () => CatalogParser.parse(jsonStr),
    throwsA(
      isA<CatalogFormatException>().having(
        (e) => e.message,
        'message',
        contains('scaleBias tem de ser numérico'),
      ),
    ),
  );
});

test('parse: bin id duplicado -> CatalogFormatException', () {
  const jsonStr = r'''
  {
    "version": 1,
    "bins": [
      {"id":"blue","label":"Azul","asset":"assets/images/containers/blue.png"},
      {"id":"blue","label":"Azul 2","asset":"assets/images/containers/blue.png"},
      {"id":"yellow","label":"Amarelo","asset":"assets/images/containers/yellow.png"},
      {"id":"brown","label":"Castanho","asset":"assets/images/containers/brown.png"}
    ],
    "items": [
      {"id":"x","label":"X","bin":"blue","asset":"assets/images/waste_items/x.png"}
    ]
  }
  ''';

  expect(
    () => CatalogParser.parse(jsonStr),
    throwsA(
      isA<CatalogFormatException>().having(
        (e) => e.message,
        'message',
        contains('Bin id duplicado'),
      ),
    ),
  );
});

test('parse: bin asset vazio -> CatalogFormatException', () {
  const jsonStr = r'''
  {
    "version": 1,
    "bins": [
      {"id":"blue","label":"Azul","asset":"   "},
      {"id":"green","label":"Verde","asset":"assets/images/containers/green.png"},
      {"id":"yellow","label":"Amarelo","asset":"assets/images/containers/yellow.png"},
      {"id":"brown","label":"Castanho","asset":"assets/images/containers/brown.png"}
    ],
    "items": [
      {"id":"x","label":"X","bin":"blue","asset":"assets/images/waste_items/x.png"}
    ]
  }
  ''';

  expect(
    () => CatalogParser.parse(jsonStr),
    throwsA(
      isA<CatalogFormatException>().having(
        (e) => e.message,
        'message',
        contains('Campo "asset" vazio'),
      ),
    ),
  );
});

  test('parse: item asset vazio -> CatalogFormatException', () {
    const jsonStr = r'''
    {
      "version": 1,
      "bins": [
        {"id":"blue","label":"Azul","asset":"assets/images/containers/blue.png"},
        {"id":"green","label":"Verde","asset":"assets/images/containers/green.png"},
        {"id":"yellow","label":"Amarelo","asset":"assets/images/containers/yellow.png"},
        {"id":"brown","label":"Castanho","asset":"assets/images/containers/brown.png"}
      ],
      "items": [
        {"id":"x","label":"X","bin":"blue","asset":"   "}
      ]
    }
    ''';

    expect(
      () => CatalogParser.parse(jsonStr),
      throwsA(
        isA<CatalogFormatException>().having(
          (e) => e.message,
          'message',
          contains('Campo "asset" vazio'),
        ),
      ),
    );
  });

  test('parse: scaleBias fora do intervalo -> CatalogFormatException', () {
    const jsonStr = r'''
    {
      "version": 1,
      "bins": [
        {"id":"blue","label":"Azul","asset":"assets/images/containers/blue.png"},
        {"id":"green","label":"Verde","asset":"assets/images/containers/green.png"},
        {"id":"yellow","label":"Amarelo","asset":"assets/images/containers/yellow.png"},
        {"id":"brown","label":"Castanho","asset":"assets/images/containers/brown.png"}
      ],
      "items": [
        {"id":"x","label":"X","bin":"blue","asset":"assets/images/waste_items/x.png","scaleBias": 0}
      ]
    }
    ''';

    expect(
      () => CatalogParser.parse(jsonStr),
      throwsA(
        isA<CatalogFormatException>().having(
          (e) => e.message,
          'message',
          contains('tem scaleBias fora do intervalo (0, 1.2]'),
        ),
      ),
    );
  });
}