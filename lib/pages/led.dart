import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MaterialColorPickerExample extends StatefulWidget {
  const MaterialColorPickerExample({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    required this.client,
    required this.topic,
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final MqttServerClient client;
  final String topic;

  @override
  State<MaterialColorPickerExample> createState() =>
      _MaterialColorPickerExampleState();
}

class _MaterialColorPickerExampleState
    extends State<MaterialColorPickerExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  titlePadding: const EdgeInsets.all(0),
                  contentPadding: const EdgeInsets.all(0),
                  content: SingleChildScrollView(
                    child: MaterialPicker(
                      pickerColor: widget.pickerColor,
                      onColorChanged: widget.onColorChanged,
                    ),
                  ),
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.pickerColor,
            shadowColor: widget.pickerColor.withOpacity(1),
            elevation: 10,
          ),
          child: Text(
            'Cambiar Color Led',
            style: TextStyle(
                color: useWhiteForeground(widget.pickerColor)
                    ? Colors.white
                    : Colors.black),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class CustomColorPicker extends StatefulWidget {
  const CustomColorPicker(
      {super.key, required this.topic, required this.client});

  final String topic;
  final MqttServerClient client;

  @override
  State<StatefulWidget> createState() => _CustomColorPicker();
}

class _CustomColorPicker extends State<CustomColorPicker> {
  Color currentColor = Colors.amber;

  @override
  void initState() {
    super.initState();
  }

  void changeColor(Color color) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(color.toHexString().substring(2));

    setState(() => currentColor = color);

    if (widget.client.connectionStatus?.state ==
        MqttConnectionState.connected) {
      widget.client
          .publishMessage(widget.topic, MqttQos.atMostOnce, builder.payload!);
    } else {
      print('No hay conexión con el broker');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialColorPickerExample(
      pickerColor: currentColor,
      onColorChanged: changeColor,
      client: widget.client,
      topic: widget.topic,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
