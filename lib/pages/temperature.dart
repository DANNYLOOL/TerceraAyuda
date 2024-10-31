import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class TemperatureChart extends StatefulWidget {
  const TemperatureChart(
      {super.key, required this.topic, required this.client});

  final String topic;
  final MqttServerClient client;

  @override
  State<TemperatureChart> createState() => _TemperatureChartState();
}

class _TemperatureChartState extends State<TemperatureChart> {
  String temperature = '35.0';
  final supabase = Supabase.instance.client;
  late StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> _subscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    suscribeToTopic(widget.topic);
  }

  void suscribeToTopic(String topic) {
    widget.client.subscribe(topic, MqttQos.atMostOnce);

    _subscription = widget.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttReceivedMessage<MqttMessage> receivedMessage = c[0];
      if (receivedMessage.topic == topic) {
        final MqttPublishMessage message =
            receivedMessage.payload as MqttPublishMessage;
        final String payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);
        _onMessageReceived(payload);
      }
    });
  }

  Future<void> _onMessageReceived(String message) async {
    final double newValue = double.parse(message);

    // Verificar si el widget aún está montado antes de llamar a setState
    if (mounted && !_isDisposed) {
      setState(() {
        temperature = newValue.toString();
      });
    }

    await supabase
        .from('datossensores')
        .insert({'sensor_id': 2, 'valor': temperature}).onError(
      (error, stackTrace) {
        print('Error inserting data: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
        enableLoadingAnimation: true,
        animationDuration: 4500,
        title: const GaugeTitle(
            text: 'Temperatura',
            textStyle: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
        axes: <RadialAxis>[
          RadialAxis(minimum: 34, maximum: 41, ranges: <GaugeRange>[
            GaugeRange(startValue: 34, endValue: 35, color: Colors.blue),
            GaugeRange(startValue: 35, endValue: 37.5, color: Colors.green),
            GaugeRange(startValue: 37.5, endValue: 39.5, color: Colors.yellow),
            GaugeRange(startValue: 39.5, endValue: 41, color: Colors.red),
          ], pointers: <GaugePointer>[
            NeedlePointer(
              value: double.parse(temperature),
              enableAnimation: true,
            )
          ], annotations: <GaugeAnnotation>[
            GaugeAnnotation(
                widget: Text('$temperature °',
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold)),
                angle: 90,
                positionFactor: 0.5)
          ])
        ]);
  }

  @override
  void dispose() {
    _isDisposed = true; // Indicar que el widget se ha desmontado
    _subscription
        .cancel(); // Cancelar la suscripción para evitar fugas de memoria
    super.dispose();
  }
}
