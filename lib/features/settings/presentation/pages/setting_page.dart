import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection/injection_container.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

@RoutePage()
class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsBloc>()..add(const SettingsEvent.started()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Enable notifications'),
                  value: state.notificationsEnabled,
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(
                      SettingsEvent.notificationsToggled(value),
                    );
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: state.languageCode,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'vi', child: Text('Vietnamese')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    context.read<SettingsBloc>().add(
                      SettingsEvent.languageChanged(value),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
