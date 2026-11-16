import 'package:flutter/material.dart';
import 'vocab.dart';

class QuizStats {
  static const _sql =
      'CREATE TABLE IF NOT EXISTS quiz_scores(id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER NOT NULL, score INTEGER NOT NULL, total INTEGER NOT NULL, kor INTEGER NOT NULL)';

  static Future<void> save(int score, int total, bool kor) async {
    try {
      final db = await Db.get();
      await db.execute(_sql);
      await db.insert('quiz_scores', {
        'ts': DateTime.now().millisecondsSinceEpoch,
        'score': score,
        'total': total,
        'kor': kor ? 1 : 0,
      });
    } catch (_) {}
  }

  // [কতবার, গড় %, সেরা %]
  static Future<List<int>> summary() async {
    try {
      final db = await Db.get();
      await db.execute(_sql);
      final rows = await db.query('quiz_scores');
      var n = 0, best = 0;
      double sum = 0;
      for (final r in rows) {
        final t = r['total'] as int;
        if (t <= 0) continue;
        final p = ((r['score'] as int) * 100 / t).round();
        sum += p;
        n++;
        if (p > best) best = p;
      }
      return [n, n == 0 ? 0 : (sum / n).round(), best];
    } catch (_) {
      return [0, 0, 0];
    }
  }
}

class QuizAvgCard extends StatelessWidget {
  const QuizAvgCard({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: QuizStats.summary(),
      builder: (c, s) {
        final d = s.data ?? [0, 0, 0];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.quiz, color: Colors.orange, size: 32),
            title: const Text('কুইজের গড়', style: TextStyle(fontSize: 16)),
            subtitle: Text('${d[0]} বার দিয়েছেন • সেরা ${d[2]}%'),
            trailing: Text('${d[1]}%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
