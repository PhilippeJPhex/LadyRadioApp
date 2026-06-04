import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/schedule_service.dart';
import '../widgets/global_mini_player.dart';
import 'program_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final List<String> _allDays = [
    'LUN',
    'MAR',
    'MER',
    'GIO',
    'VEN',
    'SAB',
    'DOM',
  ];
  final List<String> _activeDays = [];
  final List<int> _activeDayIndexes = []; // 1-7
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, List<Map<String, dynamic>>> _scheduleByDay = {
    for (var i = 1; i <= 7; i++) i: [],
  };

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final scheduleService = ScheduleService();
      final programs = await scheduleService.fetchSchedule();

      for (var program in programs) {
        final dayStr = program['day'].toString();
        if (dayStr.isNotEmpty) {
          final dayInt = int.tryParse(dayStr);
          if (dayInt != null && _scheduleByDay.containsKey(dayInt)) {
            _scheduleByDay[dayInt]!.add(program);
          }
        }
      }

      // Sort chronological
      _scheduleByDay.forEach((key, list) {
        list.sort(
          (a, b) =>
              (a['startTime'] as String).compareTo(b['startTime'] as String),
        );
      });

      _activeDays.clear();
      _activeDayIndexes.clear();
      for (var i = 1; i <= 7; i++) {
        if (_scheduleByDay[i]!.isNotEmpty) {
          _activeDays.add(_allDays[i - 1]);
          _activeDayIndexes.add(i);
        }
      }

      int initialIndex = 0;
      if (_activeDayIndexes.isNotEmpty) {
        int weekday = DateTime.now().weekday;
        initialIndex = _activeDayIndexes.indexOf(weekday);
        if (initialIndex == -1) initialIndex = 0;
        _tabController = TabController(
          length: _activeDays.length,
          vsync: this,
          initialIndex: initialIndex,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Errore durante il caricamento del palinsesto. Riprova più tardi.';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalMiniPlayerBackgroundScope(
      color: const Color(0xFF6A1E68),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.45],
              colors: [Color(0xFFB15BB0), Colors.white], // Match mockup fade
            ),
          ),
          child: GlobalMiniPlayerVisibilityBuilder(
            builder: (context, isMiniPlayerVisible) {
              return SafeArea(
                top: !isMiniPlayerVisible,
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(top: isMiniPlayerVisible ? 10 : 0),
                  child: Column(
                    children: [
                      SizedBox(height: isMiniPlayerVisible ? 0 : 10),
                      // Logo Card
                      Container(
                        width: 70, // Dimezzato da 140
                        height: 70, // Dimezzato da 140
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // Ridotto raggio curvatura
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: Image.asset(
                            'assets/lady512.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Center(
                              child: Text(
                                'Lady\nRadio',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12), // Ridotto da 24
                      // Titles
                      Text(
                        'Il palinsesto di Lady Radio',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF14003E), // Dark navy
                          fontWeight: FontWeight.w800,
                          fontSize: 18, // Ridotto da 20
                        ),
                      ),
                      const SizedBox(height: 4), // Ridotto da 6
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          'Scopri e ascolta tutte le trasmissioni di Lady Radio, dalla cronaca allo sport.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12.5,
                          ), // Ridotto da 13.5
                        ),
                      ),
                      const SizedBox(height: 16), // Ridotto da 32

                      if (_isLoading)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      else if (_errorMessage != null)
                        Expanded(
                          child: Center(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      else if (_activeDays.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Nessun programma per il palinsesto',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        )
                      else ...[
                        // TabBar (styled like the mockup: transparent background, underline only)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            indicator: const UnderlineTabIndicator(
                              borderSide: BorderSide(
                                color: Color(0xFF801A7B),
                                width: 2,
                              ), // Mockup has a slightly darker purple underline
                            ),
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: const Color(0xFF14003E), // dark text
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            unselectedLabelColor: const Color(
                              0xFF14003E,
                            ).withValues(alpha: 0.8),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            tabs: _activeDays
                                .map((day) => Tab(text: day))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // List
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: TabBarView(
                              controller: _tabController,
                              children: _activeDayIndexes.map((dayIndex) {
                                final programs = _scheduleByDay[dayIndex]!;
                                return ListView.builder(
                                  padding: EdgeInsets.only(
                                    top: 10,
                                    bottom:
                                        112 +
                                        MediaQuery.paddingOf(context).bottom,
                                  ),
                                  itemCount: programs.length,
                                  itemBuilder: (context, index) {
                                    final item = programs[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProgramScreen(
                                              programData: item,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0,
                                          vertical: 14.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Time column
                                            SizedBox(
                                              width: 45,
                                              child: Text(
                                                item['startTime'],
                                                style: const TextStyle(
                                                  color: Color(0xFF231E3D),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 60,
                                              height: 60,
                                              margin: const EdgeInsets.only(
                                                right: 16,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                image: DecorationImage(
                                                  image:
                                                      item['image']
                                                          .toString()
                                                          .startsWith('http')
                                                      ? NetworkImage(
                                                              item['image'],
                                                            )
                                                            as ImageProvider
                                                      : AssetImage(
                                                          item['image'],
                                                        ),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['title'],
                                                    style: const TextStyle(
                                                      color: Color(0xFF14003E),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item['description'],
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12.5,
                                                      height: 1.25,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
