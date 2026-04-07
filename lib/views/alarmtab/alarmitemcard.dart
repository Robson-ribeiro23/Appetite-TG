// lib/views/alarmtab/alarmitemcard.dart
import 'package:flutter/material.dart';
import 'package:appetite/models/alarmmodel.dart';

class AlarmItemCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const AlarmItemCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  String _formatDays(List<int> days) {
    if (days.isEmpty) return 'Não repete';
    final dayMap = {1: 'SEG', 2: 'TER', 3: 'QUA', 4: 'QUI', 5: 'SEX', 6: 'SAB', 7: 'DOM'};
    return days.map((day) => dayMap[day]).whereType<String>().join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      // Se ativo: cor do card padrão do tema. Se inativo: cor desabilitada suave.
      color: alarm.isActive 
          ? theme.cardColor 
          : theme.disabledColor.withValues(alpha: 0.1),
      
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: alarm.isActive ? 4 : 1, // Menos sombra se inativo
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hora do Alarme
            Text(
              alarm.time.format(context),
              style: theme.textTheme.headlineLarge?.copyWith(
                // Cor primária se ativo, cor de desabilitado se inativo
                color: alarm.isActive ? theme.primaryColor : theme.disabledColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(width: 20),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantidade em Gramas
                  Text(
                    '${alarm.grams.toStringAsFixed(1)} gramas',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      // Texto com cor padrão do tema ou mais apagado se inativo
                      color: alarm.isActive ? null : theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Dias da Semana
                  Text(
                    _formatDays(alarm.repeatDays),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: alarm.isActive ? null : theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Switch para Ativar/Desativar
            Switch(
              value: alarm.isActive,
              onChanged: (val) => onToggle(),
              activeTrackColor: theme.colorScheme.secondary,
            ),
            
            // Botão de Opções (Editar e Excluir)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Editar'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Excluir'),
                ),
              ],
              // Ícone se adapta à cor de ícone padrão do tema
              icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
            ),
          ],
        ),
      ),
    );
  }
}