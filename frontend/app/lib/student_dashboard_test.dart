import 'package:flutter/material.dart';

void main() {
  runApp(const StudentDashboardTestApp());
}

class StudentDashboardTestApp extends StatelessWidget {
  const StudentDashboardTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AlgoVerse Student Dashboard',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const StudentDashboardPage(),
    );
  }
}

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              DashboardHeader(),
              SizedBox(height: 28),

              LevelXpCard(),
              SizedBox(height: 28),

              SectionTitle(title: 'CONTINUE YOUR JOURNEY'),
              SizedBox(height: 12),

              ContinueLearningCard(),
              SizedBox(height: 28),

              SectionTitle(title: 'DAILY MISSIONS', action: 'VIEW ALL'),
              SizedBox(height: 12),

              DailyMissionsSection(),
              SizedBox(height: 28),

              SectionTitle(title: 'YOUR PERFORMANCE'),
              SizedBox(height: 12),

              PerformanceStatsSection(),
              SizedBox(height: 28),

              SectionTitle(title: 'NEXT ACHIEVEMENT'),
              SizedBox(height: 12),

              NextAchievementCard(),
              SizedBox(height: 28),

              SectionTitle(title: 'WEEKLY CHALLENGE'),
              SizedBox(height: 12),

              WeeklyChallengeCard(),
              SizedBox(height: 28),

              SectionTitle(title: 'RECENT ACTIVITY'),
              SizedBox(height: 12),

              RecentActivitySection(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

//
// HEADER
//

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Student',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Continue building your problem-solving skills.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_outlined),
        ),
      ],
    );
  }
}

//
// SECTION TITLE
//

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;

  const SectionTitle({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (action != null) TextButton(onPressed: () {}, child: Text(action!)),
      ],
    );
  }
}

//
// LEVEL + XP CARD
//

class LevelXpCard extends StatelessWidget {
  const LevelXpCard({super.key});

  @override
  Widget build(BuildContext context) {
    const double progress = 0.78;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'CURRENT LEVEL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            '12',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const Text(
            'LEVEL',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 24),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 12),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '780 / 1000 XP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '220 XP TO NEXT LEVEL',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//
// CONTINUE LEARNING
//

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.menu_book_outlined, size: 28),

            const SizedBox(height: 16),

            const Text(
              'DATA STRUCTURES & ALGORITHMS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Binary Trees',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            const Text(
              '72% COMPLETE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const LinearProgressIndicator(value: 0.72, minHeight: 8),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('CONTINUE LEARNING'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// DAILY MISSIONS
//

class DailyMissionsSection extends StatelessWidget {
  const DailyMissionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        MissionCard(
          number: '01',
          title: 'Solve 3 Problems',
          progressText: '2 / 3',
          progress: 0.66,
          reward: '50 XP',
          icon: Icons.code_outlined,
        ),

        SizedBox(height: 12),

        MissionCard(
          number: '02',
          title: 'Complete a Lesson',
          progressText: '0 / 1',
          progress: 0.0,
          reward: '30 XP',
          icon: Icons.menu_book_outlined,
        ),

        SizedBox(height: 12),

        MissionCard(
          number: '03',
          title: 'Daily Challenge',
          progressText: 'AVAILABLE',
          progress: 0.0,
          reward: '75 XP',
          icon: Icons.track_changes_outlined,
        ),
      ],
    );
  }
}

class MissionCard extends StatelessWidget {
  final String number;
  final String title;
  final String progressText;
  final double progress;
  final String reward;
  final IconData icon;

  const MissionCard({
    super.key,
    required this.number,
    required this.title,
    required this.progressText,
    required this.progress,
    required this.reward,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.indigo),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number  $title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'REWARD  $reward',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Text(
              progressText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

//
// PERFORMANCE STATS
//

class PerformanceStatsSection extends StatelessWidget {
  const PerformanceStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department_outlined,
            value: '12',
            label: 'DAY STREAK',
          ),
        ),

        SizedBox(width: 12),

        Expanded(
          child: StatCard(
            icon: Icons.bolt_outlined,
            value: '1,240',
            label: 'TOTAL XP',
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),

            const SizedBox(height: 18),

            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// NEXT ACHIEVEMENT
//

class NextAchievementCard extends StatelessWidget {
  const NextAchievementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.indigo.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.military_tech_outlined, size: 30),

          const SizedBox(height: 18),

          const Text(
            'PROBLEM SOLVER',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 6),

          const Text('Solve 100 problems to unlock this achievement.'),

          const SizedBox(height: 20),

          const Text(
            '87 / 100 PROBLEMS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(value: 0.87, minHeight: 8),
          ),

          const SizedBox(height: 12),

          const Text(
            '13 PROBLEMS TO UNLOCK',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

//
// WEEKLY CHALLENGE
//

class WeeklyChallengeCard extends StatelessWidget {
  const WeeklyChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.leaderboard_outlined, size: 30),

            const SizedBox(height: 18),

            const Text(
              'ALGORITHM SPRINT',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            const Text('Solve 10 problems this week.'),

            const SizedBox(height: 20),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '7 / 10 COMPLETE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('200 XP', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(value: 0.7, minHeight: 8),
            ),
          ],
        ),
      ),
    );
  }
}

//
// RECENT ACTIVITY
//

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: const Column(
        children: [
          ActivityTile(
            title: 'Solved Two Sum',
            xp: '+20 XP',
            icon: Icons.code_outlined,
          ),

          Divider(height: 1),

          ActivityTile(
            title: 'Completed Arrays Basics',
            xp: '+30 XP',
            icon: Icons.menu_book_outlined,
          ),

          Divider(height: 1),

          ActivityTile(
            title: 'Reached Level 12',
            xp: '+100 XP',
            icon: Icons.workspace_premium_outlined,
          ),
        ],
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  final String title;
  final String xp;
  final IconData icon;

  const ActivityTile({
    super.key,
    required this.title,
    required this.xp,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Text(xp, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
