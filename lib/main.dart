// ignore_for_file: avoid_print

import 'dart:async';
import 'package:emotion_pulse/pages/heartbeatsensor.dart';
import 'package:emotion_pulse/pages/linechart.dart';
import 'package:emotion_pulse/pages/map.dart';
import 'package:emotion_pulse/pages/podometer.dart';
import 'package:emotion_pulse/pages/actionButtons.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://itqandwmuhlscdtqhhcb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0cWFuZHdtdWhsc2NkdHFoaGNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAyNjM0ODMsImV4cCI6MjA0NTgzOTQ4M30.afza6o-HVlnsKYd3rbdUOv4ttX5d19_lma6_NQvQxrM',
  );
  
  runApp(AppInitializer());
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  MqttServerClient? _mqttClient;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async { 
    // Configuración del cliente MQTT
    final client = MqttServerClient('broker.hivemq.com', 'terceraAyuda1524');
    client.keepAlivePeriod = 20;
    client.secure = false;
    client.port = 1883;

    // Configurar el mensaje de conexión y deshabilitar la reconexión automática
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('terceraAyuda1524')
        .startClean();
    client.autoReconnect = false;
    client.connectionMessage = connMessage;

    try {
      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('MQTT Client Connected');
        setState(() {
          _mqttClient = client;
          _isLoading = false;
        });
      } else {
        print('Connection failed, retrying in 5 seconds...');
        client.disconnect(); // Desconectar antes de reintentar
        Future.delayed(const Duration(seconds: 5), _initializeApp);
      }
    } catch (e) {
      print('Connection failed: $e, retrying in 5 seconds...');
      client.disconnect(); // Desconectar antes de reintentar en caso de error
      Future.delayed(const Duration(seconds: 5), _initializeApp);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    } else {
      return MainApp(client: _mqttClient!);
    }
  }
}

class MainApp extends StatelessWidget {
  final MqttServerClient client;

  const MainApp({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Tercera Ayuda'),
          backgroundColor: Colors.deepPurple[300],
        ),
        body: GridView.count(
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 20.0,
          crossAxisCount: 2,
          children: <Widget>[
            // Latidos del corazón
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: HeartbeatSensor(
                      client: client,
                      topic: 'terceraAyuda/bpm',
                    ),
                  ),
                ),
              ),
            ),
            // Historico de latidos
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Card(
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CustomLineChart(
                      sensorId: 3,
                      intervalo: 10,
                      gradiente: LinearGradient(
                        colors: [
                          Color(0xfffc466b),
                          Color(0xffffa8a8),
                          Color(0xffff9e9e)
                        ],
                        stops: [0.25, 0.75, 0.87],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Podometro
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TiltStatusListener(
                      topic: 'terceraAyuda/tiltStatus',
                      client: client,
                    ),
                  ),
                ),
              ),
            ),
            // Mapa
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Card(
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: MyMap(
                      latitude: 21.1675710,
                      longitude: -100.9294100,
                    ),
                  ),
                ),
              ),
            ),
            // Botones
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ActionButtons(
                      topic: [
                        'terceraAyuda/record',
                        'terceraAyuda/play',
                        'terceraAyuda/resetPedometer',
                        'terceraAyuda/led',
                        'terceraAyuda/motor',
                      ],
                      client: client,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
