// Spike T-01 — phát hiện rời app / khóa màn hình (DropIt!).
// Quyền riêng tư (BR-34, NFR-P01): chỉ ghi sự kiện vòng đời của CHÍNH app này
// + thời điểm. Không đọc app khác, không UsageStatsManager, không cảm biến.
import 'package:flutter/material.dart';

import 'session_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpikeApp());
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T-01 Lifecycle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Color(0xFF6C8CFF)),
      ),
      home: const SessionScreen(),
    );
  }
}

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final _ctrl = SessionController();
  final _url = TextEditingController(text: 'http://192.168.1.10:3000');
  final _name = TextEditingController(text: 'may-1');

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rec = _ctrl.recording;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!rec) ...[
                TextField(
                    controller: _url,
                    decoration: const InputDecoration(labelText: 'Server URL')),
                TextField(
                    controller: _name,
                    decoration:
                        const InputDecoration(labelText: 'Tên máy (nhãn)')),
              ],
              const SizedBox(height: 8),
              Text(
                'Trạng thái client: ${_ctrl.localState}  |  server: ${_ctrl.serverState}\n'
                'Socket: ${_ctrl.connected ? "nối" : "ngắt"}  |  RTT: ${_ctrl.lastRttMs ?? "-"} ms  |  lệch giờ: ${_ctrl.clockOffsetMs ?? "-"} ms',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => rec
                    ? _ctrl.stop()
                    : _ctrl.start(_url.text.trim(), _name.text.trim()),
                child: Text(rec ? 'Kết thúc' : 'Bắt đầu'),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: _ctrl.events.isEmpty ? null : _ctrl.exportLog,
                      child: const Text('Xuất log (JSON)')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                      onPressed: () => _ctrl.mark(),
                      child: Text('Đánh dấu ca #${_ctrl.markCount + 1}')),
                ),
              ]),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: _ctrl.events.length,
                  itemBuilder: (_, i) {
                    final e = _ctrl.events[_ctrl.events.length - 1 - i];
                    return Text(e.line,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.white60));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
