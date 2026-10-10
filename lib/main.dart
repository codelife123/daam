/// Daam — Sri Lankan checkers. Entry point, home, how-to-play, settings.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const DaamApp());
}

class DaamApp extends StatefulWidget {
  const DaamApp({super.key});

  @override
  State<DaamApp> createState() => _DaamAppState();
}

class _DaamAppState extends State<DaamApp> {
  AppLocale locale = AppLocale.sinhala;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'si';
    if (!mounted) return;
    setState(() => locale = lang == 'en' ? AppLocale.english : AppLocale.sinhala);
  }

  Future<void> _setLocale(AppLocale l) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', l == AppLocale.english ? 'en' : 'si');
    setState(() => locale = l);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S(locale);
    return MaterialApp(
      title: 'Daam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B4226)),
        useMaterial3: true,
      ),
      home: HomeScreen(
        strings: strings,
        locale: locale,
        onLocale: _setLocale,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final S strings;
  final AppLocale locale;
  final Future<void> Function(AppLocale) onLocale;

  const HomeScreen({
    super.key,
    required this.strings,
    required this.locale,
    required this.onLocale,
  });

  Future<int> _difficulty(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('difficulty') ?? 1;
  }

  void _playVsComputer(BuildContext context) async {
    final d = await _difficulty(context);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(
        mode: GameMode.vsComputer,
        difficulty: d,
        strings: strings,
        locale: locale,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Text('♛', style: TextStyle(fontSize: 64)),
                Text(s.appTitle,
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(s.appSubtitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 40),
                _MenuButton(
                  label: s.vsComputer,
                  icon: Icons.smart_toy,
                  onTap: () => _playVsComputer(context),
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: s.twoPlayers,
                  icon: Icons.people,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GameScreen(
                      mode: GameMode.twoPlayer,
                      difficulty: 1,
                      strings: strings,
                      locale: locale,
                    ),
                  )),
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: s.howToPlay,
                  icon: Icons.help_outline,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HowToScreen(strings: s),
                  )),
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: s.settings,
                  icon: Icons.settings,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      strings: s,
                      locale: locale,
                      onLocale: onLocale,
                    ),
                  )),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label, style: const TextStyle(fontSize: 17)),
        ),
      ),
    );
  }
}

class HowToScreen extends StatelessWidget {
  final S strings;
  const HowToScreen({super.key, required this.strings});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('howTo1Title', 'howTo1'),
      ('howTo2Title', 'howTo2'),
      ('howTo3Title', 'howTo3'),
      ('howTo4Title', 'howTo4'),
      ('howTo5Title', 'howTo5'),
      ('howTo6Title', 'howTo6'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(strings.howToPlay)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final (t, b) in items) ...[
            Text(strings.get(t),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(strings.get(b), style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final S strings;
  final AppLocale locale;
  final Future<void> Function(AppLocale) onLocale;

  const SettingsScreen({
    super.key,
    required this.strings,
    required this.locale,
    required this.onLocale,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int difficulty = 1;
  int wins = 0, losses = 0, draws = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      difficulty = prefs.getInt('difficulty') ?? 1;
      wins = (prefs.getInt('ai_wins') ?? 0) + (prefs.getInt('p2_wins') ?? 0);
      losses =
          (prefs.getInt('ai_losses') ?? 0) + (prefs.getInt('p2_losses') ?? 0);
      draws =
          (prefs.getInt('ai_draws') ?? 0) + (prefs.getInt('p2_draws') ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final diffNames = [s.get('easy'), s.get('medium'), s.get('hard')];
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(s.get('language'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<AppLocale>(
            segments: const [
              ButtonSegment(value: AppLocale.sinhala, label: Text('සිංහල')),
              ButtonSegment(value: AppLocale.english, label: Text('English')),
            ],
            selected: {widget.locale},
            onSelectionChanged: (sel) => widget.onLocale(sel.first),
          ),
          const SizedBox(height: 24),
          Text(s.get('difficulty'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              for (int i = 0; i < 3; i++)
                ButtonSegment(value: i, label: Text(diffNames[i])),
            ],
            selected: {difficulty},
            onSelectionChanged: (sel) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('difficulty', sel.first);
              setState(() => difficulty = sel.first);
            },
          ),
          const SizedBox(height: 24),
          Text(s.get('stats'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('${s.get('wins')}: $wins   ${s.get('losses')}: $losses   ${s.get('draws')}: $draws'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              for (final k in [
                'ai_wins', 'ai_losses', 'ai_draws',
                'p2_wins', 'p2_losses', 'p2_draws',
              ]) {
                await prefs.remove(k);
              }
              _load();
            },
            child: Text(s.get('resetStats')),
          ),
        ],
      ),
    );
  }
}
