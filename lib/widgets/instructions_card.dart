import 'package:flutter/material.dart';

class InstructionsCard extends StatelessWidget {
  const InstructionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textMuted = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(.65),
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(.6),
          width: 1,
        ),
      ),
      color: Theme.of(context).colorScheme.surface.withOpacity(.6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          children: [
            Text('Instrucciones:', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Ingresa el PIN y contraseña proporcionados por tu supervisor',
              textAlign: TextAlign.center,
              style: textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              'Los administradores deben usar el panel de acceso administrativo',
              textAlign: TextAlign.center,
              style: textMuted,
            ),
          ],
        ),
      ),
    );
  }
}