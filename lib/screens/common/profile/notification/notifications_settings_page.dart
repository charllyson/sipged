// lib/screens/common/profile/settings/notifications_settings_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_source.dart';
import 'package:sipged/_blocs/system/notification/preferences/notification_preference_data.dart';
import 'package:sipged/_blocs/system/notification/preferences/notification_preferences_cubit.dart';
import 'package:sipged/_blocs/system/notification/preferences/notification_preferences_state.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/input/switch_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/screens/common/profile/widgets/modern_card.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  static const String _prefsPrefix = 'notification_settings_expansion_';

  final Map<String, bool> _expandedGroups = <String, bool>{};

  bool _loadedExpansionPrefs = false;

  String get _userId {
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadExpansionPreferences();

      if (!mounted) return;

      final uid = _userId;

      if (uid.isEmpty) return;

      context.read<NotificationPreferencesCubit>().watch(uid);
    });
  }

  Future<void> _loadExpansionPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final values = <String, bool>{};

    for (final group in NotificationSourceRegistry.groups) {
      final sourceKey = group.source.key;

      values[sourceKey] = prefs.getBool(_expansionPrefsKey(sourceKey)) ?? false;
    }

    if (!mounted) return;

    setState(() {
      _expandedGroups
        ..clear()
        ..addAll(values);

      _loadedExpansionPrefs = true;
    });
  }

  Future<void> _saveExpansionPreference({
    required String sourceKey,
    required bool expanded,
  }) async {
    setState(() {
      _expandedGroups[sourceKey] = expanded;
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _expansionPrefsKey(sourceKey),
      expanded,
    );
  }

  String _expansionPrefsKey(String sourceKey) {
    return '$_prefsPrefix$sourceKey';
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      appBar: UpBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
      ),
      body: Stack(
        children: [
          const BackgroundChange(),
          BlocBuilder<NotificationPreferencesCubit,
              NotificationPreferencesState>(
            builder: (context, state) {
              if (userId.isEmpty) {
                return const Center(
                  child: Text('Usuário não autenticado.'),
                );
              }

              if (!_loadedExpansionPrefs ||
                  (state.loading && state.items.isEmpty)) {
                return const Center(
                  child: LoadingTreeDots(size: 120),
                );
              }

              final preferencesByKey = _preferencesByKey(state.items);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: ModernCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SettingsHeader(
                            icon: Icons.notifications_active_rounded,
                            title: 'Notificações',
                            subtitle:
                            'Defina quais áreas do SIPGED podem enviar avisos e por quais canais.',
                          ),
                          const SizedBox(height: 18),
                          if (state.error != null) ...[
                            _ErrorBox(message: state.error!),
                            const SizedBox(height: 14),
                          ],
                          ...NotificationSourceRegistry.groups.map(
                                (group) {
                              final sourceKey = group.source.key;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _NotificationSourceGroupCard(
                                  userId: userId,
                                  group: group,
                                  preferencesByKey: preferencesByKey,
                                  saving: state.saving,
                                  initiallyExpanded:
                                  _expandedGroups[sourceKey] ?? false,
                                  onExpansionChanged: (expanded) {
                                    _saveExpansionPreference(
                                      sourceKey: sourceKey,
                                      expanded: expanded,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, NotificationPreferenceData> _preferencesByKey(
      List<NotificationPreferenceData> items,
      ) {
    return <String, NotificationPreferenceData>{
      for (final item in items) item.sourceKey: item,
    };
  }
}

class _NotificationSourceGroupCard extends StatelessWidget {
  const _NotificationSourceGroupCard({
    required this.userId,
    required this.group,
    required this.preferencesByKey,
    required this.saving,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
  });

  final String userId;
  final NotificationSourceGroup group;
  final Map<String, NotificationPreferenceData> preferencesByKey;
  final bool saving;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final enabledCount = group.subSources.where((subSource) {
      final preference = preferencesByKey[subSource.key] ??
          NotificationPreferenceData.defaultForSubSource(subSource);

      return _hasAnyChannelEnabled(preference);
    }).length;

    return ExpansionTile(
      key: PageStorageKey<String>('notification_group_${group.source.key}'),
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 14, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.black.withValues(alpha: .055),
        ),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.black.withValues(alpha: .055),
        ),
      ),
      backgroundColor: const Color(0xFFF7FAFF),
      collapsedBackgroundColor: const Color(0xFFF7FAFF),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          group.icon,
          color: Colors.orange.shade700,
          size: 22,
        ),
      ),
      title: Text(
        group.title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF263238),
        ),
      ),
      subtitle: Text(
        '${group.subtitle}\n$enabledCount de ${group.subSources.length} categoria(s) com canal ativo.',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.blueGrey.shade600,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
      children: [
        const SizedBox(height: 6),
        ...group.subSources.map(
              (subSource) {
            final preference = preferencesByKey[subSource.key] ??
                NotificationPreferenceData.defaultForSubSource(subSource);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotificationSubSourceCard(
                userId: userId,
                preference: preference,
                saving: saving,
              ),
            );
          },
        ),
      ],
    );
  }

  bool _hasAnyChannelEnabled(NotificationPreferenceData preference) {
    return _visibleChannels.any((channel) {
      return preference.channels[channel] ?? channel.enabledByDefault;
    });
  }
}

class _NotificationSubSourceCard extends StatelessWidget {
  const _NotificationSubSourceCard({
    required this.userId,
    required this.preference,
    required this.saving,
  });

  final String userId;
  final NotificationPreferenceData preference;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final subSource = NotificationSourceRegistry.resolveSubSource(
      preference.sourceKey,
    );

    final theme = Theme.of(context);

    final enabled = preference.enabled;

    final icon = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: enabled
            ? Colors.orange.withValues(alpha: .12)
            : Colors.blueGrey.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? Colors.orange.withValues(alpha: .18)
              : Colors.blueGrey.withValues(alpha: .12),
        ),
      ),
      child: Icon(
        subSource.icon,
        color: enabled ? Colors.orange.shade700 : Colors.blueGrey.shade400,
        size: 23,
      ),
    );

    final textBlock = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subSource.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: enabled
                  ? const Color(0xFF263238)
                  : Colors.blueGrey.shade400,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subSource.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
              enabled ? Colors.blueGrey.shade600 : Colors.blueGrey.shade300,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    final switches = _ChannelsSwitchGroup(
      userId: userId,
      preference: preference,
      saving: saving,
    );

    return Material(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: saving
            ? null
            : () {
          context.read<NotificationPreferencesCubit>().setSourceEnabled(
            userId: userId,
            preference: preference,
            enabled: !preference.enabled,
          );
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: saving ? .68 : 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled
                    ? Colors.orange.withValues(alpha: .16)
                    : Colors.black.withValues(alpha: .045),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .025),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          textBlock,
                          if (saving) ...[
                            const SizedBox(width: 10),
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      switches,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    textBlock,
                    const SizedBox(width: 12),
                    if (saving)
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                        ),
                      )
                    else
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: switches,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelsSwitchGroup extends StatelessWidget {
  const _ChannelsSwitchGroup({
    required this.userId,
    required this.preference,
    required this.saving,
  });

  final String userId;
  final NotificationPreferenceData preference;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: _visibleChannels.map(
            (channel) {
          return _CompactChannelSwitch(
            userId: userId,
            preference: preference,
            channel: channel,
            saving: saving,
          );
        },
      ).toList(),
    );
  }
}

class _CompactChannelSwitch extends StatelessWidget {
  const _CompactChannelSwitch({
    required this.userId,
    required this.preference,
    required this.channel,
    required this.saving,
  });

  final String userId;
  final NotificationPreferenceData preference;
  final NotificationChannel channel;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final enabled = preference.channels[channel] ?? channel.enabledByDefault;

    return Tooltip(
      message: channel.subtitle,
      waitDuration: const Duration(milliseconds: 450),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.orange.withValues(alpha: .08)
              : Colors.blueGrey.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? Colors.orange.withValues(alpha: .20)
                : Colors.black.withValues(alpha: .045),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              channel.icon,
              size: 18,
              color: enabled ? Colors.orange.shade700 : Colors.blueGrey,
            ),
            const SizedBox(width: 6),
            Text(
              _shortChannelTitle(channel),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: enabled ? Colors.orange.shade800 : Colors.blueGrey,
              ),
            ),
            const SizedBox(width: 7),
            SwitchChange(
              value: enabled,
              textOn: 'SIM',
              textOff: 'NÃO',
              colorOn: Colors.orange,
              colorOff: Colors.blueGrey,
              iconOn: Icons.check_rounded,
              iconOff: Icons.close_rounded,
              textSize: 9,
              animationDuration: const Duration(milliseconds: 180),
              onChanged: saving
                  ? null
                  : (value) {
                context
                    .read<NotificationPreferencesCubit>()
                    .setChannelEnabled(
                  userId: userId,
                  preference: preference.copyWith(enabled: true),
                  channel: channel,
                  enabled: value,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _shortChannelTitle(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.local:
        return 'Tela';
      case NotificationChannel.push:
        return 'Push';
      case NotificationChannel.email:
        return 'E-mail';
      case NotificationChannel.sms:
        return 'SMS';
      case NotificationChannel.bell:
        return 'Sino';
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: Colors.orange.shade700,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.blueGrey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withValues(alpha: .18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const List<NotificationChannel> _visibleChannels = <NotificationChannel>[
  NotificationChannel.local,
  NotificationChannel.push,
  NotificationChannel.email,
  NotificationChannel.sms,
];