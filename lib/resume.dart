import 'settings.dart';
import 'vocab.dart';

// "যেখানে ছিলাম সেখান থেকে": শেষ অবস্থান ফোনের ডাটাবেসে রাখে
class Resume {
  static Future<String?> getStr(String k) async {
    try {
      final db = await Db.get();
      final r = await db.query('settings',
          where: 'k = ?', whereArgs: ['r_$k'], limit: 1);
      if (r.isEmpty) return null;
      return r.first['v'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<int?> getInt(String k) async {
    final s = await getStr(k);
    return s == null ? null : int.tryParse(s);
  }

  static Future<void> setStr(String k, String v) async {
    try {
      await AppSettings.save('r_$k', v);
    } catch (_) {}
  }

  static Future<void> setInt(String k, int v) => setStr(k, '$v');
}
