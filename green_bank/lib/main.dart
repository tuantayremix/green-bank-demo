import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Store {
  static late SharedPreferences p;
  static int balance = 10000000;
  static List<Map<String, dynamic>> txs = [];
  static const acc = '9704123456';
  static Future<void> load() async {
    p = await SharedPreferences.getInstance();
    balance = p.getInt('b') ?? 10000000;
    txs = (jsonDecode(p.getString('t') ?? '[]') as List).cast<Map<String, dynamic>>();
  }
  static Future<void> save() async {
    await p.setInt('b', balance);
    await p.setString('t', jsonEncode(txs));
  }
}

String vnd(int v) =>
    '${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} ₫';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.load();
  runApp(MaterialApp(
    title: 'Green Bank',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF00857C), useMaterial3: true),
    home: const Login(),
  ));
}

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _L();
}

class _L extends State<Login> {
  final c = TextEditingController();
  String? err;
  @override
  Widget build(BuildContext x) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.account_balance, size: 72, color: Color(0xFF00857C)),
            const SizedBox(height: 16),
            const Text('Green Bank', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: c,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                  labelText: 'Mã PIN (mặc định 123456)',
                  errorText: err,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (c.text == '123456') {
                  Navigator.pushReplacement(x, MaterialPageRoute(builder: (_) => const Home()));
                } else {
                  setState(() => err = 'Sai mã PIN');
                }
              },
              child: const Text('Đăng nhập'),
            ),
          ]),
        ),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _H();
}

class _H extends State<Home> {
  @override
  Widget build(BuildContext x) => Scaffold(
        appBar: AppBar(title: const Text('Green Bank')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            color: Theme.of(x).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Số dư', style: TextStyle(color: Colors.white70)),
                Text(vnd(Store.balance),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('STK: ${Store.acc}', style: const TextStyle(color: Colors.white70)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(x, MaterialPageRoute(builder: (_) => const Transfer()));
                  setState(() {});
                },
                icon: const Icon(Icons.send),
                label: const Text('Chuyển tiền'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showDialog(
                  context: x,
                  builder: (_) => AlertDialog(
                    title: const Text('QR nhận tiền'),
                    content: SizedBox(width: 220, height: 220, child: QrImageView(data: Store.acc)),
                  ),
                ),
                icon: const Icon(Icons.qr_code),
                label: const Text('QR'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const Text('Lịch sử giao dịch', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final t in Store.txs.reversed)
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: Text('${t['to']}'),
              subtitle: Text('${t['note']}\n${t['time']}'),
              trailing: Text('-${vnd(t['amt'] as int)}'),
              isThreeLine: true,
            ),
        ]),
      );
}

class Transfer extends StatefulWidget {
  const Transfer({super.key});
  @override
  State<Transfer> createState() => _T();
}

class _T extends State<Transfer> {
  final to = TextEditingController();
  final amt = TextEditingController();
  final note = TextEditingController();
  String? err;

  Future<void> send() async {
    final a = int.tryParse(amt.text) ?? 0;
    if (to.text.trim().isEmpty) {
      setState(() => err = 'Nhập số tài khoản nhận');
      return;
    }
    if (a <= 0 || a > Store.balance) {
      setState(() => err = 'Số tiền không hợp lệ hoặc không đủ số dư');
      return;
    }
    Store.balance -= a;
    Store.txs.add({
      'to': to.text.trim(),
      'amt': a,
      'note': note.text,
      'time': DateTime.now().toString().substring(0, 16),
    });
    await Store.save();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext x) => Scaffold(
        appBar: AppBar(title: const Text('Chuyển tiền')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
                controller: to,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tài khoản nhận', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: amt,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tiền (₫)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Nội dung', border: OutlineInputBorder())),
            if (err != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(err!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: send, child: const Text('Xác nhận'))),
          ]),
        ),
      );
}
