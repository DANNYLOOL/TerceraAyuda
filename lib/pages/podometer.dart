import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TiltStatusListener extends StatefulWidget {
  const TiltStatusListener({super.key, required this.topic, required this.client});

  final String topic;
  final MqttServerClient client;

  @override
  State<TiltStatusListener> createState() => _TiltStatusListenerState();
}

class _TiltStatusListenerState extends State<TiltStatusListener> {
  late StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> _subscription;
  String isActive = '';

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

  Future<void> _onMessageReceived(String tiltStatus) async {
    if (mounted) {
      setState(() {
        isActive = tiltStatus;
      });
    }

    try {
      final response = await Supabase.instance.client
          .from('datossensores')
          .insert({
            'sensor_id': 2,
            'valor': tiltStatus,
          });
          

      if (response.error != null) {
        print("Error saving tilt status: ${response.error!.message}");
      } else {
        print("Tilt status saved: $tiltStatus");
      }
    } catch (e) {
      print("Exception while saving tilt status: $e");
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("El sensor de inclinación esta $isActive"),
      ),
    );
  }
}
