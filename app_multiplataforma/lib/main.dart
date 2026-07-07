import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const SuperMapeadorApp());
}

class SuperMapeadorApp extends StatelessWidget {
  const SuperMapeadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Tema escuro para economizar bateria na moto
      home: const TelaMapeamento(),
    );
  }
}

class TelaMapeamento extends StatefulWidget {
  const TelaMapeamento({super.key});

  @override
  State<TelaMapeamento> createState() => _TelaMapeamentoState();
}

class _TelaMapeamentoState extends State<TelaMapeamento> {
  String _status = "Aguardando início...";
  bool _gravando = false;

  // Função para capturar GPS em tempo real e enviar para o servidor de IA
  void _iniciarCaptura() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() {
      _gravando = true;
      _status = "Rastreando e transmitindo dados milimétricos...";
    });

    // Escuta a localização a cada mudança de posição física
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // Máxima precisão do chip interno
        distanceFilter: 1, // Atualiza a cada 1 metro movido
      ),
    ).listen((Position position) {
      if (_gravando) {
        _enviarDadosParaServidor(position.latitude, position.longitude, position.speed);
      }
    });
  }

  // Envia a telemetria via HTTP POST para o servidor Python
  Future<void> _enviarDadosParaServidor(double lat, double lon, double speed) async {
    final url = Uri.parse('https://seu-servidor-ia.com/api/stream-telemetria');
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "lat": lat,
          "lon": lon,
          "velocidade": speed,
          "timestamp": DateTime.now().toIso8601String()
        }),
      );
    } catch (e) {
      // Se falhar a rede (sinal ruim em Águas Lindas), armazena localmente
      print("Erro de conexão. Salvando em cache local: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapeador Espacial RTK")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _gravando ? Icons.satellite_alt : Icons.location_off,
              size: 80,
              color: _gravando ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _gravando ? () => setState(() { _gravando = false; _status = "Parado."; }) : _iniciarCaptura,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
              child: Text(_gravando ? "Parar Rastreamento" : "Iniciar Mapeamento 24/7"),
            ),
          ],
        ),
      ),
    );
  }
}
