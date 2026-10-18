import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_config.dart';
import '../api/api_client.dart';

class DeviceGate extends StatefulWidget {
  const DeviceGate({super.key, required this.child});
  final Widget child;

  @override
  State<DeviceGate> createState() => _DeviceGateState();
}

class _DeviceGateState extends State<DeviceGate> with WidgetsBindingObserver {
  Map<String, String>? _info;
  bool _loading = true;
  bool _verified = false;
  String? _error;
  bool _registrationOpen = false;
  bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_android) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_android && state == AppLifecycleState.resumed && !_loading && !_registrationOpen) _check();
  }

  Future<void> _check() async {
    setState(() { _loading = true; _error = null; _verified = false; });
    final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 12)));
    try {
      final info = await const MethodChannel('kamilresto/device').invokeMapMethod<String, String>('info');
      if (info == null) throw StateError('Device information unavailable');
      if (mounted) setState(() => _info = info);
      final response = await dio.post<dynamic>('/check_device', data: info,
        options: Options(headers: {'Accept': 'application/json'}, validateStatus: (status) => status == 200 || status == 421));
      if (mounted) setState(() => _verified = response.statusCode == 200 && response.data == 'verified');
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not verify this device. Check the connection and retry.');
    } finally {
      dio.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_android || _verified) return widget.child;
    // The gate replaces the router child, so blocked-device dialogs need
    // their own navigator below MaterialApp.builder.
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) => _registrationScreen(context),
      ),
    );
  }

  Widget _registrationScreen(BuildContext context) {
    final info = _info;
    return Scaffold(
      appBar: AppBar(title: const Text('Device Registration')),
      body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Icon(Icons.tablet_android, size: 64),
            const SizedBox(height: 20),
            Text(_loading ? 'Checking device...' : _error == null ? 'Device not registered or blocked' : 'Device check failed',
              style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(_error ?? 'Contact your administrator to register or enable this device using the information below.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (info != null) ...[
              for (final field in {'device': 'Device Name', 'pid': 'Machine ID', 'mac': 'MAC Registration Value', 'ip': 'IP Address'}.entries)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(field.value, style: const TextStyle(fontWeight: FontWeight.w700)),
                  SelectableText(info[field.key] ?? ''),
                ])),
              TextButton.icon(onPressed: () async {
                await Clipboard.setData(ClipboardData(text: info.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n')));
              }, icon: const Icon(Icons.copy), label: const Text('Copy Device Info')),
            ],
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator())
            else FilledButton.icon(onPressed: _check, icon: const Icon(Icons.refresh), label: const Text('Check Again')),
            if (!_loading && info != null) Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Register With Admin'),
                onPressed: _registrationOpen ? null : () async {
                  setState(() => _registrationOpen = true);
                  try {
                  final registered = await showDialog<bool>(context: context,
                    useRootNavigator: false,
                    barrierDismissible: false,
                    builder: (_) => _AdminRegistrationDialog(info: info));
                  if (!mounted) return;
                  if (registered == true) await _check();
                  } finally {
                    if (mounted) setState(() => _registrationOpen = false);
                  }
                },
              ),
            ),
          ]),
        ),
      )),
    );
  }
}

class _AdminRegistrationDialog extends StatefulWidget {
  const _AdminRegistrationDialog({required this.info});
  final Map<String, String> info;

  @override
  State<_AdminRegistrationDialog> createState() => _AdminRegistrationDialogState();
}

class _AdminRegistrationDialogState extends State<_AdminRegistrationDialog> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose(); _password.dispose(); _confirmation.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 12),
      headers: {'Accept': 'application/json'}));
    try {
      await dio.post<dynamic>('/register_device', data: {
        ...widget.info, 'name': _username.text.trim(),
        'password': _password.text, 'password_confirmation': _confirmation.text,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = readableApiError(error));
    } finally {
      dio.close();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Administrator Verification'),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: _username, enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Admin Username'),
            validator: (value) => value == null || value.trim().isEmpty ? 'Enter admin username' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _password, enabled: !_saving, obscureText: true,
            enableSuggestions: false, autocorrect: false,
            decoration: const InputDecoration(labelText: 'Admin Password'),
            validator: (value) => value == null || value.isEmpty ? 'Enter admin password' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _confirmation, enabled: !_saving, obscureText: true,
            enableSuggestions: false, autocorrect: false,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
            validator: (value) => value != _password.text ? 'Passwords do not match' : null),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ]),
      ))),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton.icon(onPressed: _saving ? null : _register,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.verified_user_outlined),
          label: Text(_saving ? 'Verifying...' : 'Verify & Register')),
      ],
    ),
  );
}
