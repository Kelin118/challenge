import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/device_session.dart';
import '../controllers/session_controller.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({
    super.key,
    required this.controller,
  });

  final SessionController controller;

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  late Future<List<DeviceSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = widget.controller.fetchActiveSessions();
  }

  Future<void> _reload() async {
    setState(() {
      _sessionsFuture = widget.controller.fetchActiveSessions();
    });
    await _sessionsFuture;
  }

  Future<void> _logoutSession(DeviceSession session) async {
    await widget.controller.logoutSession(session.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Устройство отключено')),
    );
    await _reload();
  }

  Future<void> _logoutAllSessions() async {
    await widget.controller.logoutAllSessions();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Все устройства отключены')),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Активные устройства'),
            actions: [
              TextButton(
                onPressed: widget.controller.isLoggingOutAll ? null : _logoutAllSessions,
                child: Text(
                  widget.controller.isLoggingOutAll ? 'Выходим...' : 'Выйти везде',
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ),
            ],
          ),
          body: FutureBuilder<List<DeviceSession>>(
            future: _sessionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Не удалось загрузить устройства',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final sessions = snapshot.data ?? const [];
              if (sessions.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Активных устройств нет.',
                      style: TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.panel,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  session.deviceName ?? 'Неизвестное устройство',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                (session.platform ?? 'unknown').toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _MetaRow(label: 'IP', value: session.ipAddress ?? 'Неизвестно'),
                          _MetaRow(label: 'Создана', value: formatDateTime(session.createdAt)),
                          _MetaRow(label: 'Последняя активность', value: formatDateTime(session.lastUsedAt)),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _logoutSession(session),
                              child: const Text(
                                'Выйти с этого устройства',
                                style: TextStyle(color: AppTheme.danger),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: sessions.length,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

