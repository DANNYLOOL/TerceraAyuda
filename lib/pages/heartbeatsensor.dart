import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:pulsator/pulsator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeartbeatSensor extends StatefulWidget {
  const HeartbeatSensor({super.key, required this.client, required this.topic});
  final MqttServerClient client;
  final String topic;

  @override
  State<HeartbeatSensor> createState() => _HeartbeatSensorState();
}

class _HeartbeatSensorState extends State<HeartbeatSensor> {
  String bpm = '';
  final supabase = Supabase.instance.client;
  late final StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>
      _subscription;

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
    final int newValue = int.parse(message);
    if (mounted) {
      setState(() {
        bpm = newValue.toString();
      });
    }

    await supabase
        .from('datossensores')
        .insert({'sensor_id': 3, 'valor': bpm}).onError(
      (error, stackTrace) {
        print('Error inserting data: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pulsator(
      style: const PulseStyle(color: Colors.red),
      count: 5,
      duration: const Duration(seconds: 4),
      repeat: 0,
      startFromScratch: false,
      autoStart: true,
      fit: PulseFit.contain,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40.0),
          Image.asset(
            'assets/images/gradient_heart.png',
            width: 120,
          ),
          Text(
            'BPM: $bpm',
            style: const TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}
