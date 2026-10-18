import 'dart:convert';

import 'package:flutter/material.dart';

import '../logging/log_storage.dart';

class LogsButton extends StatelessWidget {
  const LogsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Logs',
    icon: const Icon(Icons.description_outlined),
    onPressed: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const _LogsScreen())),
  );
}

class _LogsScreen extends StatefulWidget {
  const _LogsScreen();
  @override
  State<_LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<_LogsScreen> {
  late Future<List<String>> _files = listLogFiles();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Logs'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() => _files = listLogFiles()),
        ),
      ],
    ),
    body: FutureBuilder<List<String>>(
      future: _files,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(
            child: Text('Could not load log files. Tap Refresh to retry.'),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final files = snapshot.data!;
        if (files.isEmpty)
          return const Center(child: Text('No log files found'));
        return ListView.separated(
          itemCount: files.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(files[index]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _LogContentScreen(name: files[index]),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _LogContentScreen extends StatefulWidget {
  const _LogContentScreen({required this.name});
  final String name;
  @override
  State<_LogContentScreen> createState() => _LogContentScreenState();
}

class _LogContentScreenState extends State<_LogContentScreen> {
  late Future<List<String>> _entries = _read();
  Future<List<String>> _read() async {
    final content = await readLogFile(widget.name);
    return const LineSplitter()
        .convert(content)
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          try {
            return const JsonEncoder.withIndent('  ').convert(jsonDecode(line));
          } catch (_) {
            return line;
          }
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.name, style: const TextStyle(fontSize: 16)),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() => _entries = _read()),
        ),
      ],
    ),
    body: FutureBuilder<List<String>>(
      future: _entries,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(
            child: Text('Could not read log file. Tap Refresh to retry.'),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final entries = snapshot.data!;
        if (entries.isEmpty)
          return const Center(child: Text('Log file is empty'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 24),
          itemBuilder: (_, index) => SelectableText(
            entries[index],
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        );
      },
    ),
  );
}
