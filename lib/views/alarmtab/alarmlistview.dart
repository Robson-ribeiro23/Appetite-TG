// lib/views/alarms_tab/alarm_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/alarmcontroller.dart';
import 'package:appetite/models/alarmmodel.dart';
import 'package:appetite/views/alarmtab/alarmitemcard.dart';
import 'package:appetite/views/alarmtab/addalarmdialog.dart';

class AlarmListView extends StatelessWidget {
  const AlarmListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AlarmController>(
      builder: (context, controller, child) {
        return Stack(
          children: [
            if (controller.alarms.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ícone Grande e Bonito
                    Icon(Icons.alarm_off_rounded, size: 80, color: theme.disabledColor.withValues(alpha: 0.2)),
                    const SizedBox(height: 20),
                    Text(
                      'Nenhum alarme configurado',
                      style: theme.textTheme.titleLarge?.copyWith(color: theme.disabledColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toque no botão "+" para\nagendar uma refeição.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                    ),
                    const SizedBox(height: 80), // Espaço para não ficar colado no botão
                  ],
                ),
              )
            else
              ListView.builder(
                // Adiciona um padding no final para o último item não ficar atrás do botão
                padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
                itemCount: controller.alarms.length,
                itemBuilder: (context, index) {
                  final alarm = controller.alarms[index];
                  return AlarmItemCard(
                    alarm: alarm,
                    onToggle: () => controller.toggleAlarmActive(alarm.id),
                    onDelete: () => controller.deleteAlarm(alarm.id),
                    onEdit: () => _showAddEditAlarm(context, controller, alarm),
                  );
                },
              ),

            // CAMADA 2: O BOTÃO FLUTUANTE (Sempre visível)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0), 
                child: FloatingActionButton(
                  onPressed: () => _showAddEditAlarm(context, controller), 
                  backgroundColor: theme.primaryColor,
                  shape: const CircleBorder(),
                  // Ícone preto ou branco dependendo do contraste, mas preto costuma ser seguro na cor primária
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