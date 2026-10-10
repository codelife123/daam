/// Sinhala + English strings. Sinhala is the default.
library;

enum AppLocale { sinhala, english }

class S {
  final AppLocale locale;
  const S(this.locale);

  static const _en = <String, String>{
    'appTitle': 'Daam',
    'appSubtitle': 'Sri Lankan Checkers',
    'vsComputer': 'Play vs Computer',
    'twoPlayers': 'Two Players',
    'howToPlay': 'How to Play',
    'settings': 'Settings',
    'easy': 'Easy',
    'medium': 'Medium',
    'hard': 'Hard',
    'chooseDifficulty': 'Choose difficulty',
    'thinking': 'Thinking...',
    'whiteTurn': "White's turn",
    'blackTurn': "Black's turn",
    'youWin': 'You win!',
    'youLose': 'You lose',
    'draw': 'Draw',
    'whiteWins': 'White wins',
    'blackWins': 'Black wins',
    'rematch': 'Rematch',
    'menu': 'Menu',
    'resign': 'Resign',
    'language': 'Language',
    'difficulty': 'Difficulty',
    'sound': 'Sound',
    'stats': 'Stats',
    'wins': 'Wins',
    'losses': 'Losses',
    'draws': 'Draws',
    'resetStats': 'Reset stats',
    'mustCapture': 'You must capture!',
    'yourMove': 'Your move',
    'howTo1Title': 'The board',
    'howTo1': 'Daam is played on a 12x12 board with 30 pieces per side, on the dark squares of the first five rows.',
    'howTo2Title': 'Moving',
    'howTo2': 'Men move one square diagonally forward. When a man reaches the far row it becomes a dama (king).',
    'howTo3Title': 'Capturing',
    'howTo3': 'Jump over an enemy piece to capture it. Men capture forward and backward. Capturing is compulsory — if you can capture, you must.',
    'howTo4Title': 'Maximum capture',
    'howTo4': 'When several captures are possible, you must take the sequence that captures the most pieces.',
    'howTo5Title': 'The dama (king)',
    'howTo5': 'A dama is a flying king: it moves any number of squares diagonally and captures from a distance.',
    'howTo6Title': 'Winning',
    'howTo6': 'Win by capturing all enemy pieces or blocking them so they cannot move.',
  };

  static const _si = <String, String>{
    'appTitle': 'දාම්',
    'appSubtitle': 'ශ්‍රී ලාංකික දාම් ක්‍රීඩාව',
    'vsComputer': 'පරිගණකය සමඟ සෙල්ලම් කරන්න',
    'twoPlayers': 'දෙදෙනෙක් සෙල්ලම් කරන්න',
    'howToPlay': 'සෙල්ලම් කරන හැටි',
    'settings': 'සැකසුම්',
    'easy': 'පහසු',
    'medium': 'මධ්‍යම',
    'hard': 'අමාරු',
    'chooseDifficulty': 'මට්ටම තෝරන්න',
    'thinking': 'හිතනවා...',
    'whiteTurn': 'සුදුගේ වාරය',
    'blackTurn': 'කළුගේ වාරය',
    'youWin': 'ඔබ ජයග්‍රහණය කළා!',
    'youLose': 'ඔබ පරාජය වුණා',
    'draw': 'සමයි',
    'whiteWins': 'සුදු ජයග්‍රහණය කරයි',
    'blackWins': 'කළු ජයග්‍රහණය කරයි',
    'rematch': 'නැවත සෙල්ලම් කරන්න',
    'menu': 'මුල් පිටුව',
    'resign': 'ඉවත්වන්න',
    'language': 'භාෂාව',
    'difficulty': 'අමාරු මට්ටම',
    'sound': 'ශබ්දය',
    'stats': 'වාර්තා',
    'wins': 'ජයග්‍රහණ',
    'losses': 'පරාජයන්',
    'draws': 'සම',
    'resetStats': 'වාර්තා මකන්න',
    'mustCapture': 'අනිවාර්යයෙන් කපන්න!',
    'yourMove': 'ඔබේ වාරය',
    'howTo1Title': 'පුවරුව',
    'howTo1': 'දාම් ක්‍රීඩා කරන්නේ 12x12 පුවරුවක, කළු කොටුවල පේළි පහක පිහිටි ඉත්තන් 30 බැගින්.',
    'howTo2Title': 'සෙල්ලම් කිරීම',
    'howTo2': 'ඉත්තන් විකර්ණ ලෙස එක කොටුවක් ඉදිරියට යනවා. අනිත් පැත්තට ගිය ඉත්තා දාම් (රජ) වෙනවා.',
    'howTo3Title': 'කැපීම',
    'howTo3': 'විරුද්ධ ඉත්තෙකු පනින්න කපන්න. ඉත්තන් ඉදිරියට සහ පසුපසට කපනවා. කැපිය හැකි නම් කැපීම අනිවාර්යයි.',
    'howTo4Title': 'වැඩිපුරම කැපීම',
    'howTo4': 'කැපීම් කිහිපයක් කළ හැකි නම්, වැඩිපුරම ඉත්තන් කැපෙන පිළිවෙළ තෝරන්න ඕන.',
    'howTo5Title': 'දාම් (රජ)',
    'howTo5': 'දාම් ඉත්තා ඕනෑම දුරක් විකර්ණ ලෙස යනවා, දුර සිට කපනවා.',
    'howTo6Title': 'ජයග්‍රහණය',
    'howTo6': 'විරුද්ධ පාර්ශවයේ ඉත්තන් සියල්ල කපා හෝ හිර කර ජයගන්න.',
  };

  String get(String key) =>
      (locale == AppLocale.sinhala ? _si : _en)[key] ?? key;

  String get appTitle => get('appTitle');
  String get appSubtitle => get('appSubtitle');
  String get vsComputer => get('vsComputer');
  String get twoPlayers => get('twoPlayers');
  String get howToPlay => get('howToPlay');
  String get settings => get('settings');
  String get thinking => get('thinking');
  String get rematch => get('rematch');
  String get menu => get('menu');
  String get resign => get('resign');
  String get youWin => get('youWin');
  String get youLose => get('youLose');
}
