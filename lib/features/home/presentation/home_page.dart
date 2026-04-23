import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi App'),
        actions: [
          TextButton(
            onPressed: () => context.go('/material-categories'),
            child: const Text('Categorías'),
          ),
          TextButton(
            onPressed: () => context.go('/materials'),
            child: const Text('Materias'),
          ),
          TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Salir'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sesión iniciada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'Usuario autenticado',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const Text(
                'La base Firebase ya está lista. Ahora puedes construir los módulos de materias primas, subproductos, productos y simulador por archivos separados.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () => context.go('/material-categories'),
                    child: const Text('Abrir categorías de materias primas'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => context.go('/materials'),
                    child: const Text('Abrir materias primas'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
