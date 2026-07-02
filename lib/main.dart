import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const QuestApp());

/* ============================================================
   ЦВЕТА И ТЕКСТ
   ============================================================ */

class AppColors {
  static const ink = Color(0xFF15132A);
  static const inkDeep = Color(0xFF0F0E20);
  static const surface = Color(0xFF1E1B38);
  static const surfaceRaised = Color(0xFF272350);
  static const border = Color(0x14F5F3FF);
  static const borderStrong = Color(0x29F5F3FF);

  static const text = Color(0xFFF5F3FF);
  static const textMuted = Color(0xFF9C97C4);
  static const textFaint = Color(0xFF6B678F);

  static const gold = Color(0xFFF2B705);
  static const goldSoft = Color(0x29F2B705);
  static const ember = Color(0xFFFF6B4A);
  static const emberSoft = Color(0x29FF6B4A);

  static const statStr = Color(0xFFFF6B4A);
  static const statInt = Color(0xFF4FD1C5);
  static const statCrt = Color(0xFFC084FC);
  static const statSoc = Color(0xFFFFC857);
  static const statMnd = Color(0xFF7FE8A0);

  static const Map<String, Color> statColors = {
    'exp_str': statStr, 'exp_int': statInt, 'exp_crt': statCrt,
    'exp_soc': statSoc, 'exp_mnd': statMnd,
  };
}

class AppText {
  static TextStyle display({double size = 20, FontWeight weight = FontWeight.w700, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color ?? AppColors.text, letterSpacing: -0.2);

  static TextStyle body({double size = 14.5, FontWeight weight = FontWeight.w500, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color ?? AppColors.text);

  static TextStyle mono({double size = 13, FontWeight weight = FontWeight.w700, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color ?? AppColors.text, fontFamily: 'monospace');
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.inkDeep,
    colorScheme: const ColorScheme.dark(primary: AppColors.gold, secondary: AppColors.ember, surface: AppColors.surface),
    splashFactory: NoSplash.splashFactory,
  );
}

/* ============================================================
   ДАННЫЕ: расписание квестов, характеристики, достижения
   ============================================================ */

const statOrder = ['exp_str', 'exp_int', 'exp_crt', 'exp_soc', 'exp_mnd'];
const statLabels = {
  'exp_str': 'Сила', 'exp_int': 'Интеллект', 'exp_crt': 'Креатив',
  'exp_soc': 'Социум', 'exp_mnd': 'Менталка',
};
const statEmoji = {
  'exp_str': '💪', 'exp_int': '🧠', 'exp_crt': '🎬', 'exp_soc': '🗣', 'exp_mnd': '🧘',
};
const int xpPenaltyOnMiss = 5;

class ScheduledQuest {
  final String title;
  final int xp;
  final String skill;
  const ScheduledQuest({required this.title, required this.xp, required this.skill});
}

class DaySchedule {
  final String focus;
  final List<ScheduledQuest> quests;
  const DaySchedule({required this.focus, required this.quests});
}

/// 0 = понедельник ... 6 = воскресенье
final Map<int, DaySchedule> weekSchedule = {
  0: const DaySchedule(focus: 'Креативный штурм и Психология', quests: [
    ScheduledQuest(title: 'Математика и Русский', xp: 50, skill: 'exp_int'),
    ScheduledQuest(title: 'Сценарное мастерство (в стиле Науки)', xp: 30, skill: 'exp_crt'),
    ScheduledQuest(title: 'Психология + импровизация', xp: 15, skill: 'exp_soc'),
    ScheduledQuest(title: 'Стадион', xp: 25, skill: 'exp_str'),
    ScheduledQuest(title: 'Поток сознания', xp: 5, skill: 'exp_mnd'),
  ]),
  1: const DaySchedule(focus: 'Съемка Экшена и Кодинг', quests: [
    ScheduledQuest(title: 'Информатика и Русский', xp: 50, skill: 'exp_int'),
    ScheduledQuest(title: 'Съемка и Действие', xp: 30, skill: 'exp_crt'),
    ScheduledQuest(title: 'Игра на гитаре', xp: 25, skill: 'exp_soc'),
    ScheduledQuest(title: 'Силовая калистеника', xp: 25, skill: 'exp_str'),
    ScheduledQuest(title: 'Поток сознания', xp: 5, skill: 'exp_mnd'),
  ]),
  2: const DaySchedule(focus: 'Монтаж Креатива и Эстетика', quests: [
    ScheduledQuest(title: 'ПОЛНЫЙ ВЫХОДНОЙ ОТ ЕГЭ', xp: 50, skill: 'exp_int'),
    ScheduledQuest(title: 'Эстетика и Цветокоррекция', xp: 30, skill: 'exp_crt'),
    ScheduledQuest(title: 'Развитие кругозора', xp: 15, skill: 'exp_soc'),
    ScheduledQuest(title: 'Стадион', xp: 25, skill: 'exp_str'),
    ScheduledQuest(title: 'Поток сознания', xp: 5, skill: 'exp_mnd'),
  ]),
  3: const DaySchedule(focus: 'Жесткий Монтаж и Дисциплина', quests: [
    ScheduledQuest(title: 'Информатика и Русский', xp: 50, skill: 'exp_int'),
    ScheduledQuest(title: 'Технический монтаж', xp: 30, skill: 'exp_crt'),
    ScheduledQuest(title: 'Тайм-менеджмент', xp: 15, skill: 'exp_soc'),
    ScheduledQuest(title: 'Силовая калистеника', xp: 25, skill: 'exp_str'),
    ScheduledQuest(title: 'Поток сознания', xp: 5, skill: 'exp_mnd'),
  ]),
  4: const DaySchedule(focus: 'Плотный Звук и Реальное Общение', quests: [
    ScheduledQuest(title: 'Математика и Русский', xp: 50, skill: 'exp_int'),
    ScheduledQuest(title: 'Работа со звуком', xp: 30, skill: 'exp_crt'),
    ScheduledQuest(title: 'Игра на гитаре', xp: 25, skill: 'exp_soc'),
    ScheduledQuest(title: 'Стадион', xp: 25, skill: 'exp_str'),
    ScheduledQuest(title: 'Поток сознания', xp: 5, skill: 'exp_mnd'),
  ]),
  5: const DaySchedule(focus: 'Динамическая Графика и Английский', quests: [
    ScheduledQuest(title: 'Информатика и Русский', xp: 50, skill: 'exp_int'),
    ScheduledQuest(title: 'Моушен-дизайн в After Effects', xp: 30, skill: 'exp_crt'),
    ScheduledQuest(title: 'Английский язык + импровизация', xp: 20, skill: 'exp_soc'),
    ScheduledQuest(title: 'Силовая калистеника', xp: 25, skill: 'exp_str'),
    ScheduledQuest(title: 'Поток сознания', xp: 5, skill: 'exp_mnd'),
  ]),
  6: const DaySchedule(focus: 'День полного ТО', quests: []),
};

class Achievement {
  final String code;
  final String name;
  final String desc;
  final bool Function(Profile) check;
  const Achievement({required this.code, required this.name, required this.desc, required this.check});
}

final List<Achievement> achievementDefs = [
  Achievement(code: 'streak_7', name: '🔥 Неделя дисциплины', desc: '7 дней подряд с квестами', check: (p) => p.currentStreak >= 7),
  Achievement(code: 'streak_30', name: '💎 Железная воля', desc: '30 дней подряд с квестами', check: (p) => p.currentStreak >= 30),
  Achievement(code: 'level_5', name: '⭐ Пятый уровень', desc: 'Достигнут 5 уровень', check: (p) => p.level >= 5),
  Achievement(code: 'level_10', name: '🌟 Десятый уровень', desc: 'Достигнут 10 уровень', check: (p) => p.level >= 10),
  Achievement(code: 'str_100', name: '💪 Силач', desc: '100 XP в характеристике Сила', check: (p) => p.expStr >= 100),
  Achievement(code: 'int_100', name: '🧠 Мыслитель', desc: '100 XP в характеристике Интеллект', check: (p) => p.expInt >= 100),
  Achievement(code: 'crt_100', name: '🎬 Творец', desc: '100 XP в характеристике Креатив', check: (p) => p.expCrt >= 100),
  Achievement(code: 'soc_100', name: '🗣 Душа компании', desc: '100 XP в характеристике Социум', check: (p) => p.expSoc >= 100),
  Achievement(code: 'mnd_100', name: '🧘 Дзен-мастер', desc: '100 XP в характеристике Менталка', check: (p) => p.expMnd >= 100),
];

/* ============================================================
   МОДЕЛИ
   ============================================================ */

class CustomQuest {
  final int id;
  final String title;
  final int xp;
  final String skill;
  final String date;
  CustomQuest({required this.id, required this.title, required this.xp, required this.skill, required this.date});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'xp': xp, 'skill': skill, 'date': date};
  factory CustomQuest.fromJson(Map<String, dynamic> json) => CustomQuest(
        id: json['id'] as int, title: json['title'] as String, xp: json['xp'] as int,
        skill: json['skill'] as String, date: json['date'] as String,
      );
}

class CompletedQuest {
  final String title;
  final String date;
  final int xp;
  final String skill;
  CompletedQuest({required this.title, required this.date, required this.xp, required this.skill});

  Map<String, dynamic> toJson() => {'title': title, 'date': date, 'xp': xp, 'skill': skill};
  factory CompletedQuest.fromJson(Map<String, dynamic> json) => CompletedQuest(
        title: json['title'] as String, date: json['date'] as String,
        xp: json['xp'] as int, skill: json['skill'] as String,
      );
}

class Profile {
  int level;
  int expStr, expInt, expCrt, expSoc, expMnd;
  int currentStreak;
  int bestStreak;
  String? lastActiveDate;

  Profile({
    this.level = 1, this.expStr = 0, this.expInt = 0, this.expCrt = 0, this.expSoc = 0, this.expMnd = 0,
    this.currentStreak = 0, this.bestStreak = 0, this.lastActiveDate,
  });

  int get totalXp => expStr + expInt + expCrt + expSoc + expMnd;

  int statByKey(String skill) {
    switch (skill) {
      case 'exp_str': return expStr;
      case 'exp_int': return expInt;
      case 'exp_crt': return expCrt;
      case 'exp_soc': return expSoc;
      case 'exp_mnd': return expMnd;
      default: throw ArgumentError('Неизвестная характеристика: $skill');
    }
  }

  void addXp(String skill, int amount) {
    switch (skill) {
      case 'exp_str': expStr += amount; break;
      case 'exp_int': expInt += amount; break;
      case 'exp_crt': expCrt += amount; break;
      case 'exp_soc': expSoc += amount; break;
      case 'exp_mnd': expMnd += amount; break;
      default: throw ArgumentError('Неизвестная характеристика: $skill');
    }
  }

  Map<String, dynamic> toJson() => {
        'level': level, 'exp_str': expStr, 'exp_int': expInt, 'exp_crt': expCrt,
        'exp_soc': expSoc, 'exp_mnd': expMnd, 'currentStreak': currentStreak,
        'bestStreak': bestStreak, 'lastActiveDate': lastActiveDate,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        level: json['level'] as int? ?? 1,
        expStr: json['exp_str'] as int? ?? 0,
        expInt: json['exp_int'] as int? ?? 0,
        expCrt: json['exp_crt'] as int? ?? 0,
        expSoc: json['exp_soc'] as int? ?? 0,
        expMnd: json['exp_mnd'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        lastActiveDate: json['lastActiveDate'] as String?,
      );
}

class GameState {
  Profile profile;
  List<CompletedQuest> completedQuests;
  List<CustomQuest> customQuests;
  List<String> achievements;

  GameState({required this.profile, required this.completedQuests, required this.customQuests, required this.achievements});

  factory GameState.initial() => GameState(profile: Profile(), completedQuests: [], customQuests: [], achievements: []);

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'completedQuests': completedQuests.map((q) => q.toJson()).toList(),
        'customQuests': customQuests.map((q) => q.toJson()).toList(),
        'achievements': achievements,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        profile: Profile.fromJson(json['profile'] as Map<String, dynamic>? ?? {}),
        completedQuests: (json['completedQuests'] as List<dynamic>? ?? [])
            .map((e) => CompletedQuest.fromJson(e as Map<String, dynamic>)).toList(),
        customQuests: (json['customQuests'] as List<dynamic>? ?? [])
            .map((e) => CustomQuest.fromJson(e as Map<String, dynamic>)).toList(),
        achievements: (json['achievements'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      );
}

/* ============================================================
   КОНТРОЛЛЕР (ChangeNotifier из flutter/foundation — не сторонний пакет)
   ============================================================ */

class GameEvent {
  final String emoji;
  final String text;
  final bool isAchievement;
  GameEvent({required this.emoji, required this.text, this.isAchievement = false});
}

class GameController extends ChangeNotifier {
  static const _storageKey = 'questAppState_v1';

  GameState state = GameState.initial();
  bool isLoaded = false;

  final List<GameEvent> _pendingEvents = [];
  List<GameEvent> takePendingEvents() {
    final events = List<GameEvent>.from(_pendingEvents);
    _pendingEvents.clear();
    return events;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        state = GameState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        state = GameState.initial();
      }
    }
    _applyMissedDayPenaltyIfNeeded();
    isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String todayKey() => _dateKey(DateTime.now());
  static String yesterdayKey() => _dateKey(DateTime.now().subtract(const Duration(days: 1)));
  static int currentWeekday() => DateTime.now().weekday - 1;

  DaySchedule get todaySchedule => weekSchedule[currentWeekday()]!;
  List<CustomQuest> get customQuestsToday => state.customQuests.where((q) => q.date == todayKey()).toList();
  bool isQuestDoneToday(String title) => state.completedQuests.any((q) => q.title == title && q.date == todayKey());

  static int levelFromXp(int xp) => (xp ~/ 100) + 1;

  void completeScheduledQuest(int index) {
    final quest = todaySchedule.quests[index];
    if (isQuestDoneToday(quest.title)) return;
    _completeQuest(quest.title, quest.xp, quest.skill);
  }

  void completeCustomQuest(int id) {
    final quest = state.customQuests.firstWhere((q) => q.id == id);
    if (isQuestDoneToday(quest.title)) return;
    _completeQuest(quest.title, quest.xp, quest.skill);
  }

  void _completeQuest(String title, int xp, String skill) {
    state.profile.addXp(skill, xp);
    state.profile.level = levelFromXp(state.profile.totalXp);
    state.completedQuests.add(CompletedQuest(title: title, date: todayKey(), xp: xp, skill: skill));
    final streak = _updateStreak();

    _pendingEvents.add(GameEvent(emoji: '✅', text: '+$xp XP — $title · стрик $streak 🔥'));
    for (final ach in _checkAchievements()) {
      _pendingEvents.add(GameEvent(emoji: '🎉', text: '${ach.name}\n${ach.desc}', isAchievement: true));
    }

    _save();
    notifyListeners();
  }

  int _updateStreak() {
    final p = state.profile;
    final today = todayKey();
    final yesterday = yesterdayKey();
    if (p.lastActiveDate == today) return p.currentStreak;
    if (p.lastActiveDate == yesterday) {
      p.currentStreak += 1;
    } else {
      p.currentStreak = 1;
    }
    p.bestStreak = p.bestStreak > p.currentStreak ? p.bestStreak : p.currentStreak;
    p.lastActiveDate = today;
    return p.currentStreak;
  }

  void _applyMissedDayPenaltyIfNeeded() {
    final p = state.profile;
    final today = todayKey();
    final yesterday = yesterdayKey();
    if (p.lastActiveDate == today || p.lastActiveDate == yesterday) return;
    if (p.currentStreak == 0) return;

    p.currentStreak = 0;
    p.expMnd = (p.expMnd - xpPenaltyOnMiss).clamp(0, 1 << 30);
    p.level = levelFromXp(p.totalXp);
    _pendingEvents.add(GameEvent(emoji: '💔', text: 'Вчера не было квестов — стрик сброшен. Начни заново сегодня!'));
    _save();
  }

  List<Achievement> _checkAchievements() {
    final unlocked = state.achievements.toSet();
    final fresh = <Achievement>[];
    for (final ach in achievementDefs) {
      if (!unlocked.contains(ach.code) && ach.check(state.profile)) {
        unlocked.add(ach.code);
        fresh.add(ach);
      }
    }
    if (fresh.isNotEmpty) state.achievements = unlocked.toList();
    return fresh;
  }

  void addCustomQuest(String title, int xp, String skill) {
    final id = DateTime.now().millisecondsSinceEpoch;
    state.customQuests.add(CustomQuest(id: id, title: title, xp: xp, skill: skill, date: todayKey()));
    _save();
    notifyListeners();
  }

  ({Map<String, int> totals, int count}) weeklySummary() {
    final cutoff = _dateKey(DateTime.now().subtract(const Duration(days: 7)));
    final totals = {for (final k in statOrder) k: 0};
    var count = 0;
    for (final q in state.completedQuests) {
      if (q.date.compareTo(cutoff) >= 0) {
        totals[q.skill] = (totals[q.skill] ?? 0) + q.xp;
        count += 1;
      }
    }
    return (totals: totals, count: count);
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(state.toJson());

  bool importJson(String raw) {
    try {
      state = GameState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _save();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/* ============================================================
   ROOT APP (без provider — контроллер создаётся и пробрасывается
   вручную через конструкторы, обновления — через AnimatedBuilder)
   ============================================================ */

class QuestApp extends StatefulWidget {
  const QuestApp({super.key});
  @override
  State<QuestApp> createState() => _QuestAppState();
}

class _QuestAppState extends State<QuestApp> {
  final controller = GameController();

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Квест',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (!controller.isLoaded) {
            return const Scaffold(
              backgroundColor: AppColors.inkDeep,
              body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
            );
          }
          return _AppRoot(controller: controller);
        },
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  final GameController controller;
  const _AppRoot({required this.controller});
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final events = widget.controller.takePendingEvents();
      for (final event in events) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${event.emoji} ${event.text}'), duration: const Duration(seconds: 4)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => HomeShell(controller: widget.controller);
}

/* ============================================================
   ГЛАВНЫЙ ЭКРАН (нижняя навигация)
   ============================================================ */

class HomeShell extends StatefulWidget {
  final GameController controller;
  const HomeShell({super.key, required this.controller});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  static const _navItems = [
    (icon: '🗺️', label: 'Сегодня'),
    (icon: '🧙', label: 'Профиль'),
    (icon: '🏆', label: 'Ачивки'),
    (icon: '📈', label: 'Неделя'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final screens = [
      TodayScreen(controller: c),
      ProfileScreen(controller: c),
      AchievementsScreen(controller: c),
      WeekScreen(controller: c),
    ];
    final streak = c.state.profile.currentStreak;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(text: TextSpan(children: [
                    TextSpan(text: 'Квест', style: AppText.display(size: 20)),
                    TextSpan(text: '.', style: AppText.display(size: 20, color: AppColors.gold)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: streak > 0 ? AppColors.emberSoft : Colors.transparent,
                      border: Border.all(color: streak > 0 ? AppColors.ember.withOpacity(0.3) : AppColors.border),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('🔥 $streak', style: AppText.mono(size: 13, color: streak > 0 ? AppColors.ember : AppColors.textFaint)),
                  ),
                ],
              ),
            ),
            Expanded(child: IndexedStack(index: _tabIndex, children: screens)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: const BoxDecoration(color: AppColors.ink, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final active = i == _tabIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _tabIndex = i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: active ? AppColors.goldSoft : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      Text(item.icon, style: const TextStyle(fontSize: 19)),
                      const SizedBox(height: 3),
                      Text(item.label, style: AppText.body(size: 10.5, weight: FontWeight.w600, color: active ? AppColors.gold : AppColors.textFaint)),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   ЭКРАН: СЕГОДНЯ
   ============================================================ */

class TodayScreen extends StatefulWidget {
  final GameController controller;
  const TodayScreen({super.key, required this.controller});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final day = controller.todaySchedule;
    final customQuests = controller.customQuestsToday;
    final allEmpty = day.quests.isEmpty && customQuests.isEmpty;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          LevelCard(profile: controller.state.profile),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(day.focus.toUpperCase(),
                      style: AppText.display(size: 13, weight: FontWeight.w600, color: AppColors.textFaint).copyWith(letterSpacing: 1.2)),
                ),
                if (allEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderStrong)),
                    alignment: Alignment.center,
                    child: Text('Сегодня квестов нет — заслуженный отдых 🌴', textAlign: TextAlign.center, style: AppText.body(size: 14, color: AppColors.textFaint)),
                  ),
                ...List.generate(day.quests.length, (index) {
                  final q = day.quests[index];
                  final done = controller.isQuestDoneToday(q.title);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: QuestCard(
                      title: q.title, xp: q.xp, skill: q.skill, done: done,
                      onTap: () {
                        controller.completeScheduledQuest(index);
                        showGameEvents(context, controller.takePendingEvents());
                      },
                    ),
                  );
                }),
                ...customQuests.map((q) {
                  final done = controller.isQuestDoneToday(q.title);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: QuestCard(
                      title: '✨ ${q.title}', xp: q.xp, skill: q.skill, done: done,
                      onTap: () {
                        controller.completeCustomQuest(q.id);
                        showGameEvents(context, controller.takePendingEvents());
                      },
                    ),
                  );
                }),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () => showAddQuestSheet(context, controller),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.borderStrong),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('+ Добавить свой квест', style: AppText.body(size: 13.5, weight: FontWeight.w600, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   ЭКРАН: ПРОФИЛЬ
   ============================================================ */

class ProfileScreen extends StatelessWidget {
  final GameController controller;
  const ProfileScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final profile = controller.state.profile;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text('ХАРАКТЕРИСТИКИ', style: AppText.display(size: 13, weight: FontWeight.w600, color: AppColors.textFaint).copyWith(letterSpacing: 1.2)),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  RadarChart(profile: profile),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10, crossAxisSpacing: 14, childAspectRatio: 4.4,
                    children: statOrder.map((key) {
                      final color = AppColors.statColors[key]!;
                      return Row(children: [
                        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(statLabels[key]!, style: AppText.body(size: 12.5, color: AppColors.textMuted))),
                        Text('${profile.statByKey(key)}', style: AppText.mono(size: 12, color: color)),
                      ]);
                    }).toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(children: [
                Expanded(child: _GhostButton(icon: '⬇', label: 'Экспорт', onTap: () => _exportData(context))),
                const SizedBox(width: 10),
                Expanded(child: _GhostButton(icon: '⬆', label: 'Импорт', onTap: () => _importData(context))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                'Данные хранятся только на этом устройстве. Экспортируй файл, если хочешь перенести прогресс на другой телефон.',
                textAlign: TextAlign.center, style: AppText.body(size: 11.5, color: AppColors.textFaint),
              ),
            ),
          ],
        );
      },
    );
  }

  void _exportData(BuildContext context) {
    Clipboard.setData(ClipboardData(text: controller.exportJson()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Данные скопированы в буфер обмена')));
  }

  void _importData(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;
    final ok = controller.importJson(data!.text!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Данные загружены' : 'Не удалось прочитать данные из буфера')));
  }
}

class _GhostButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text('$icon $label', style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.textMuted)),
    );
  }
}

/* ============================================================
   ЭКРАН: ДОСТИЖЕНИЯ
   ============================================================ */

class AchievementsScreen extends StatelessWidget {
  final GameController controller;
  const AchievementsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final unlocked = controller.state.achievements.toSet();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text('ДОСТИЖЕНИЯ', style: AppText.display(size: 13, weight: FontWeight.w600, color: AppColors.textFaint).copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ...achievementDefs.map((ach) {
              final isUnlocked = unlocked.contains(ach.code);
              final parts = ach.name.split(' ');
              final emoji = parts.first;
              final name = parts.skip(1).join(' ');
              return Opacity(
                opacity: isUnlocked ? 1 : 0.4,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    SizedBox(width: 32, child: Text(isUnlocked ? emoji : '🔒', style: const TextStyle(fontSize: 22), textAlign: TextAlign.center)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(isUnlocked ? name : 'Заблокировано', style: AppText.body(size: 14, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(ach.desc, style: AppText.body(size: 12, color: AppColors.textFaint)),
                      ]),
                    ),
                  ]),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

/* ============================================================
   ЭКРАН: НЕДЕЛЯ
   ============================================================ */

class WeekScreen extends StatelessWidget {
  final GameController controller;
  const WeekScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final summary = controller.weeklySummary();
        final maxVal = summary.totals.values.fold<int>(1, (a, b) => a > b ? a : b);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text('ИТОГИ 7 ДНЕЙ', style: AppText.display(size: 13, weight: FontWeight.w600, color: AppColors.textFaint).copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  ...statOrder.map((key) {
                    final value = summary.totals[key] ?? 0;
                    final color = AppColors.statColors[key]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        SizedBox(width: 90, child: Text(statLabels[key]!, style: AppText.body(size: 12.5, color: AppColors.textMuted))),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(height: 10, child: Stack(children: [
                              Container(color: Colors.white.withOpacity(0.06)),
                              FractionallySizedBox(widthFactor: value / maxVal, child: Container(color: color)),
                            ])),
                          ),
                        ),
                        SizedBox(width: 42, child: Text('+$value', textAlign: TextAlign.right, style: AppText.mono(size: 12, weight: FontWeight.w500, color: AppColors.textFaint))),
                      ]),
                    );
                  }),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.only(top: 14),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                    width: double.infinity,
                    child: Text('Квестов выполнено: ${summary.count}', textAlign: TextAlign.center, style: AppText.mono(size: 12.5, color: AppColors.textFaint)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/* ============================================================
   ВИДЖЕТ: КАРТОЧКА КВЕСТА
   ============================================================ */

class QuestCard extends StatelessWidget {
  final String title;
  final int xp;
  final String skill;
  final bool done;
  final VoidCallback? onTap;
  const QuestCard({super.key, required this.title, required this.xp, required this.skill, required this.done, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statColor = AppColors.statColors[skill]!;
    return Opacity(
      opacity: done ? 0.45 : 1,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: done ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(
                top: const BorderSide(color: AppColors.border),
                right: const BorderSide(color: AppColors.border),
                bottom: const BorderSide(color: AppColors.border),
                left: BorderSide(color: done ? AppColors.borderStrong : statColor, width: 3),
              ),
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: statColor.withOpacity(done ? 0.06 : 0.2), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(statEmoji[skill]!, style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AppText.body(size: 14.5, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(statLabels[skill]!, style: AppText.mono(size: 12, weight: FontWeight.w500, color: AppColors.textFaint)),
                ]),
              ),
              Text(done ? '✓' : '+$xp', style: AppText.mono(size: 13, color: done ? AppColors.textFaint : statColor)),
            ]),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   ВИДЖЕТ: КАРТОЧКА УРОВНЯ
   ============================================================ */

class LevelCard extends StatelessWidget {
  final Profile profile;
  const LevelCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final xpIntoLevel = profile.totalXp % 100;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.surfaceRaised, AppColors.surface]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Уровень', style: AppText.display(size: 15, weight: FontWeight.w500, color: AppColors.textMuted)),
          Text('${profile.level}', style: AppText.display(size: 28, color: AppColors.gold)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(height: 8, child: Stack(children: [
            Container(color: Colors.white.withOpacity(0.06)),
            FractionallySizedBox(
              widthFactor: xpIntoLevel / 100,
              child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.ember, AppColors.gold]))),
            ),
          ])),
        ),
        const SizedBox(height: 8),
        Text('$xpIntoLevel / 100 XP до ${profile.level + 1} уровня', style: AppText.mono(size: 12, weight: FontWeight.w500, color: AppColors.textFaint)),
      ]),
    );
  }
}

/* ============================================================
   ВИДЖЕТ: РАДАР-ДИАГРАММА
   ============================================================ */

class RadarChart extends StatelessWidget {
  final Profile profile;
  const RadarChart({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 240, height: 240, child: CustomPaint(painter: _RadarPainter(profile)));
  }
}

class _RadarPainter extends CustomPainter {
  final Profile profile;
  _RadarPainter(this.profile);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.34;
    final n = statOrder.length;

    final values = {for (final k in statOrder) k: profile.statByKey(k)};
    final rawMax = values.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxVal = math.max(100, ((rawMax / 50).ceil()) * 50);

    Offset pt(int i, double r) {
      final angle = -math.pi / 2 + i * (2 * math.pi / n);
      return Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
    }

    final ringPaint = Paint()..color = Colors.white.withOpacity(0.10)..style = PaintingStyle.stroke..strokeWidth = 1;
    for (final frac in [0.33, 0.66, 1.0]) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = pt(i, maxR * frac);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, ringPaint);
    }

    for (var i = 0; i < n; i++) {
      final key = statOrder[i];
      final axisPaint = Paint()..color = AppColors.statColors[key]!.withOpacity(0.25)..strokeWidth = 1.5;
      canvas.drawLine(center, pt(i, maxR), axisPaint);
    }

    final dataPts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final key = statOrder[i];
      final r = (values[key]!.clamp(0, maxVal) / maxVal) * maxR;
      dataPts.add(pt(i, r));
    }
    final dataPath = Path()..moveTo(dataPts[0].dx, dataPts[0].dy);
    for (final p in dataPts.skip(1)) {
      dataPath.lineTo(p.dx, p.dy);
    }
    dataPath.close();

    final fillPaint = Paint()..shader = LinearGradient(colors: [AppColors.ember.withOpacity(0.35), AppColors.gold.withOpacity(0.35)]).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawPath(dataPath, fillPaint);

    final strokePaint = Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, strokePaint);

    for (var i = 0; i < n; i++) {
      final key = statOrder[i];
      canvas.drawCircle(dataPts[i], 5, Paint()..color = AppColors.statColors[key]!);
      canvas.drawCircle(dataPts[i], 5, Paint()..color = AppColors.ink..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    for (var i = 0; i < n; i++) {
      final key = statOrder[i];
      final labelPos = pt(i, maxR + 22);
      final tp = TextPainter(text: TextSpan(text: statLabels[key], style: const TextStyle(color: AppColors.textMuted, fontSize: 11)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}

/* ============================================================
   ВИДЖЕТ: МОДАЛКА ДОБАВЛЕНИЯ КВЕСТА
   ============================================================ */

Future<void> showAddQuestSheet(BuildContext context, GameController controller) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddQuestSheet(controller: controller),
  );
}

class _AddQuestSheet extends StatefulWidget {
  final GameController controller;
  const _AddQuestSheet({required this.controller});
  @override
  State<_AddQuestSheet> createState() => _AddQuestSheetState();
}

class _AddQuestSheetState extends State<_AddQuestSheet> {
  final _titleController = TextEditingController();
  final _xpController = TextEditingController();
  String _selectedStat = 'exp_int';
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final xp = int.tryParse(_xpController.text.trim());
    if (title.isEmpty) { setState(() => _error = 'Введи название квеста'); return; }
    if (xp == null || xp < 1 || xp > 200) { setState(() => _error = 'XP должно быть числом от 1 до 200'); return; }

    widget.controller.addCustomQuest(title, xp, _selectedStat);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✨ Квест «$title» добавлен на сегодня')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        decoration: const BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Новый квест', style: AppText.display(size: 17)),
            const SizedBox(height: 16),
            Text('Название', style: AppText.body(size: 12, color: AppColors.textFaint)),
            const SizedBox(height: 6),
            _buildTextField(_titleController, 'Например: Прочитать главу книги'),
            const SizedBox(height: 14),
            Text('Награда, XP', style: AppText.body(size: 12, color: AppColors.textFaint)),
            const SizedBox(height: 6),
            _buildTextField(_xpController, '20', isNumber: true),
            if (_error != null) ...[const SizedBox(height: 6), Text(_error!, style: AppText.body(size: 12.5, color: AppColors.ember))],
            const SizedBox(height: 14),
            Text('Характеристика', style: AppText.body(size: 12, color: AppColors.textFaint)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: statOrder.map((key) {
                final selected = key == _selectedStat;
                final color = AppColors.statColors[key]!;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStat = key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.transparent,
                      border: Border.all(color: selected ? Colors.transparent : AppColors.borderStrong),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${statEmoji[key]} ${statLabels[key]}', style: AppText.mono(size: 11.5, color: selected ? AppColors.inkDeep : AppColors.textMuted)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderStrong), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text('Отмена', style: AppText.body(weight: FontWeight.w700, color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text('Добавить', style: AppText.body(weight: FontWeight.w700, color: AppColors.inkDeep)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: AppText.body(),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(color: AppColors.textFaint),
        filled: true, fillColor: AppColors.ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderStrong)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderStrong)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gold)),
      ),
    );
  }
}

/* ============================================================
   ВИДЖЕТ: ТОСТЫ (XP / достижения)
   ============================================================ */

void showGameEvents(BuildContext context, List<GameEvent> events) {
  var delay = Duration.zero;
  for (final event in events) {
    Future.delayed(delay, () {
      if (context.mounted) _showToast(context, event);
    });
    delay += const Duration(milliseconds: 350);
  }
}

void _showToast(BuildContext context, GameEvent event) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (ctx) => _ToastCard(event: event, top: MediaQuery.of(ctx).padding.top + 14));
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 3000), () => entry.remove());
}

class _ToastCard extends StatelessWidget {
  final GameEvent event;
  final double top;
  const _ToastCard({required this.event, required this.top});

  @override
  Widget build(BuildContext context) {
    final borderColor = event.isAchievement ? AppColors.statCrt : AppColors.gold;
    return Positioned(
      top: top, left: 16, right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * -10), child: child)),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor.withOpacity(0.45)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 12))],
            ),
            child: Row(children: [
              Text(event.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(event.text, style: AppText.body(size: 13.5))),
            ]),
          ),
        ),
      ),
    );
  }
}
