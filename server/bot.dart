import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ---------------- Settings ----------------
// If you used the PROXY method, keep useProxy = true and set your port.
// If you enabled "Tun Mode" in V2Ray, set useProxy = false.
const useProxy = false;
const proxyHost = '127.0.0.1';
const proxyPort = 10809; // your V2Ray HTTP proxy port
const httpPort = 8787; // local API port the app will sync to
const dataFileName = 'data.json';
// ------------------------------------------

late String botBase;
late HttpClient tg;

// In-memory store (also saved to data.json)
Map<String, dynamic> store = {
  'ownerChatId': null,
  'tasks': <dynamic>[], // {id,title,dueAt(ISO),done,reminded}
  'ideas': <dynamic>[], // {id,title,createdAt(ISO),reminded}
};

File get dataFile => File(dataFileName);

Future<void> loadStore() async {
  if (await dataFile.exists()) {
    try {
      final m = jsonDecode(await dataFile.readAsString());
      if (m is Map<String, dynamic>) {
        store = {
          'ownerChatId': m['ownerChatId'],
          'tasks': (m['tasks'] as List?) ?? <dynamic>[],
          'ideas': (m['ideas'] as List?) ?? <dynamic>[],
        };
      }
    } catch (_) {}
  }
}

Future<void> saveStore() async => dataFile.writeAsString(jsonEncode(store));

// ---------------- Telegram ----------------
Future<Map<String, dynamic>> tgGet(String method, [String query = '']) async {
  final req = await tg.getUrl(Uri.parse('$botBase/$method$query'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<void> tgSend(Object chatId, String text) async {
  final req = await tg.postUrl(Uri.parse('$botBase/sendMessage'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({'chat_id': chatId, 'text': text}));
  await req.close();
}

// ---------------- Bot polling ----------------
Future<void> startPolling() async {
  var offset = 0;
  while (true) {
    try {
      final data = await tgGet('getUpdates', '?timeout=25&offset=$offset');
      if (data['ok'] != true) {
        await Future.delayed(const Duration(seconds: 3));
        continue;
      }
      for (final u in (data['result'] as List)) {
        offset = (u['update_id'] as int) + 1;
        final msg = u['message'];
        if (msg == null) continue;
        final chatId = msg['chat']['id'];
        final name = (msg['chat']['first_name'] ?? '').toString();
        final text = (msg['text'] ?? '').toString();
        if (text.trim() == '/start') {
          store['ownerChatId'] = chatId;
          await saveStore();
          await tgSend(chatId,
              'سلام $name! ✅ اتصال برقرار شد.\nاز این به بعد یادآوری‌هات همین‌جا میاد.\nکدِ چتِ تو: $chatId');
          stdout.writeln('Paired owner chat: $chatId');
        } else {
          await tgSend(chatId, 'دریافت شد 👍 (فعلاً فقط یادآوری می‌فرستم)');
        }
      }
    } catch (e) {
      stderr.writeln('polling error: $e');
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}

// ---------------- HTTP API (the app syncs here) ----------------
Future<void> startHttp() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, httpPort);
  stdout.writeln('HTTP API روی http://127.0.0.1:$httpPort آماده‌ست');
  await for (final req in server) {
    try {
      final path = req.uri.path;
      if (path == '/health') {
        req.response.write('ok');
      } else if (path == '/addtest' && req.method == 'GET') {
        final minutes =
            int.tryParse(req.uri.queryParameters['minutes'] ?? '1') ?? 1;
        final title = req.uri.queryParameters['title'] ?? 'تسکِ آزمایشی';
        final due = DateTime.now().add(Duration(minutes: minutes));
        (store['tasks'] as List).add({
          'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
          'title': title,
          'dueAt': due.toIso8601String(),
          'done': false,
          'reminded': false,
        });
        await saveStore();
        req.response.write('OK: added "$title" due in $minutes min');
      } else if (path == '/sync' && req.method == 'POST') {
        final body = await utf8.decoder.bind(req).join();
        mergeSync(jsonDecode(body) as Map<String, dynamic>);
        await saveStore();
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'ok': true}));
      } else {
        req.response.statusCode = 404;
        req.response.write('not found');
      }
    } catch (e) {
      req.response.statusCode = 500;
      req.response.write('error: $e');
    }
    await req.response.close();
  }
}

// Merge incoming data, preserving "reminded" flags by id.
void mergeSync(Map<String, dynamic> payload) {
  if (payload['chatId'] != null) store['ownerChatId'] = payload['chatId'];

  final oldTasks = {for (final t in (store['tasks'] as List)) t['id']: t};
  store['tasks'] = [
    for (final t in (payload['tasks'] as List? ?? []))
      {
        'id': t['id'],
        'title': t['title'],
        'dueAt': t['dueAt'],
        'done': t['done'] ?? false,
        'reminded': (oldTasks[t['id']] != null &&
                oldTasks[t['id']]['dueAt'] == t['dueAt'])
            ? (oldTasks[t['id']]['reminded'] ?? false)
            : false,
      }
  ];

  final oldIdeas = {for (final i in (store['ideas'] as List)) i['id']: i};
  store['ideas'] = [
    for (final i in (payload['ideas'] as List? ?? []))
      {
        'id': i['id'],
        'title': i['title'],
        'createdAt': i['createdAt'],
        'reminded': oldIdeas[i['id']] != null
            ? (oldIdeas[i['id']]['reminded'] ?? false)
            : false,
      }
  ];
}

// ---------------- Scheduler ----------------
void startScheduler() {
  Timer.periodic(const Duration(seconds: 20), (_) async {
    final chatId = store['ownerChatId'];
    if (chatId == null) return;
    final now = DateTime.now();
    var changed = false;

    for (final t in (store['tasks'] as List)) {
      if ((t['done'] ?? false) == true || (t['reminded'] ?? false) == true) {
        continue;
      }
      final dueAt = DateTime.tryParse(t['dueAt'] ?? '');
      if (dueAt != null && !dueAt.isAfter(now)) {
        await tgSend(chatId, '⏰ یادت نره: ${t['title']}\nهنوز انجامش ندادی؟');
        t['reminded'] = true;
        changed = true;
      }
    }

    for (final i in (store['ideas'] as List)) {
      if ((i['reminded'] ?? false) == true) continue;
      final created = DateTime.tryParse(i['createdAt'] ?? '');
      if (created != null && now.difference(created).inHours >= 72) {
        await tgSend(chatId,
            '💡 ایده‌ی «${i['title']}» رو ۳ روز پیش نوشتی.\nچیزِ جدیدی نمی‌خوای بهش اضافه کنی؟');
        i['reminded'] = true;
        changed = true;
      }
    }

    if (changed) await saveStore();
  });
}

Future<void> main() async {
  final tokenFile = File('token.txt');
  if (!tokenFile.existsSync()) {
    stderr.writeln('token.txt پیدا نشد.');
    exit(1);
  }
  botBase = 'https://api.telegram.org/bot${(await tokenFile.readAsString()).trim()}';

  tg = HttpClient();
  if (useProxy) tg.findProxy = (uri) => 'PROXY $proxyHost:$proxyPort';

  await loadStore();

  try {
    final me = await tgGet('getMe');
    if (me['ok'] != true) {
      stderr.writeln('توکن درست نیست: $me');
      exit(1);
    }
    stdout.writeln('ربات وصل شد ✅ @${me['result']['username']}');
  } catch (e) {
    stderr.writeln('اتصال به تلگرام نشد. VPN/پورتِ پروکسی؟ خطا: $e');
    exit(1);
  }

  startScheduler();
  unawaited(startHttp());
  await startPolling();
}