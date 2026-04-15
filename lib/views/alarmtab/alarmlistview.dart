// lib/views/alarms_tab/alarm_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/alarmcontroller.dart';
import 'package:appetite/controllers/feedercontroller.dart';
import 'package:appetite/models/alarmmodel.dart';
import 'package:appetite/views/alarmtab/alarmitemcard.dart';
import 'package:appetite/views/alarmtab/addalarmdialog.dart';

class AlarmListView extends StatefulWidget {
  const AlarmListView({super.key});

  @override
  State<AlarmListView> createState() => _AlarmListViewState();
}

class _AlarmListViewState extends State<AlarmListView> {
  @override
  void initState() {
    super.initState();
    // Atualiza o feeder no AlarmController quando a tela monta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fc = Provider.of<FeederController>(context, listen: false);
      final ac = Provider.of<AlarmController>(context, listen: false);
      if (fc.selectedFeeder != null) {
        ac.setCurrentFeeder(fc.selectedFeeder!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<AlarmController, FeederController>(
      builder: (context, alarmCtrl, feederCtrl, child) {
        // Sincroniza feeder ativo
        if (feederCtrl.selectedFeeder != null) {
          alarmCtrl.setCurrentFeeder(feederCtrl.selectedFeeder!.id);
        }

        final alarms = alarmCtrl.alarmsForCurrentFeeder;
        final feederName = feederCtrl.selectedFeeder?.name ?? '';

        return Stack(
          children: [
            // Feeder selector
            if (feederCtrl.feeders.length > 1 && feederName.isNotEmpty)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: DropdownButton<String>(
                      value: feederCtrl.selectedFeeder?.id,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: feederCtrl.feeders.map((f) {
                        return DropdownMenuItem(
                          value: f.id,
                          child: Text(
                            f.name,
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          final feeder = feederCtrl.feeders.firstWhere((f) => f.id == id);
                          feederCtrl.selectFeeder(feeder);
                          alarmCtrl.setCurrentFeeder(id);
                        }
                      },
                    ),
                  ),
                ),
              ),

            if (alarms.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alarm_off_rounded, size: 80, color: theme.disabledColor.withValues(alpha: 0.2)),
                    const SizedBox(height: 20),
                    Text(
                      feederName.isNotEmpty
                          ? 'Nenhum alarme para $feederName'
                          : 'Nenhum alarme configurado',
                      style: theme.textTheme.titleLarge?.copyWith(color: theme.disabledColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toque no botão "+" para\nagendar uma refeição.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.only(top: 60.0, bottom: 80.0),
                itemCount: alarms.length,
                itemBuilder: (context, index) {
                  final alarm = alarms[index];
                  return AlarmItemCard(
                    alarm: alarm,
                    onToggle: () => alarmCtrl.toggleAlarmActive(alarm.id),
                    onDelete: () => alarmCtrl.deleteAlarm(alarm.id),
                    onEdit: () => _showAddEditAlarm(context, alarmCtrl, alarm),
                  );
                },
              ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: FloatingActionButton(
                  onPressed: feederCtrl.selectedFeeder != null
                      ? () => _showAddEditAlarm(context, alarmCtrl)
                      : null,
                  backgroundColor: theme.primaryColor,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 30.0, color: Colors.black),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditAlarm(BuildContext context, AlarmController controller, [Alarm? alarmToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddAlarmDialog(alarmToEdit: alarmToEdit);
      },
    );
  }
}
