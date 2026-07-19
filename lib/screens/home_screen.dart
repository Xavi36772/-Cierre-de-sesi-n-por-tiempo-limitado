import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => session.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSessionCard(session),
            const SizedBox(height: 16),
            _buildSensitiveDataCard(session, context),
            const SizedBox(height: 16),
            _buildFcmCard(session, context),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(SessionProvider session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sesión Activa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Token: ${session.token}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Timeout de inactividad: '),
                DropdownButton<int>(
                  value: session.inactivityTimeoutMinutes,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 min')),
                    DropdownMenuItem(value: 2, child: Text('2 min')),
                    DropdownMenuItem(value: 5, child: Text('5 min')),
                    DropdownMenuItem(value: 10, child: Text('10 min')),
                  ],
                  onChanged: (value) {
                    if (value != null) session.updateInactivityTimeout(value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitiveDataCard(SessionProvider session, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Datos Sensibles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (session.hasSensitiveData)
                  TextButton.icon(
                    onPressed: () => session.remoteWipeData(),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text('Borrar localmente',
                        style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!session.sensitiveDataLoaded)
              const Center(child: CircularProgressIndicator())
            else if (!session.hasSensitiveData)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No hay datos sensibles almacenados',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else ...[
              _sensitiveRow(
                  'Tarjeta de Crédito', session.creditCard ?? '---'),
              _sensitiveRow('NSS', session.ssn ?? '---'),
              _sensitiveRow(
                  'Cuenta Bancaria', session.bankAccount ?? '---'),
              _sensitiveRow('PIN', session.pinCode ?? '---'),
              _sensitiveRow('Dirección', session.address ?? '---'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sensitiveRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildFcmCard(SessionProvider session, BuildContext context) {
    final fcmToken = session.fcmService.currentFcmToken;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Firebase Cloud Messaging',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (fcmToken != null) ...[
              Text('Token FCM:',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(fcmToken, style: const TextStyle(fontSize: 10)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: fcmToken));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token copiado al portapapeles')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar token'),
              ),
            ] else
              const Text('Inicializando FCM...',
                  style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
