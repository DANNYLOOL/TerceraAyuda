import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MyMap extends StatefulWidget {
  const MyMap({super.key, required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(widget.latitude, widget.longitude),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.emotionpulse.app',
          maxNativeZoom: 19,
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => Uri.parse('https://openstreetmap.org/copyright'),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(widget.latitude, widget.longitude),
              width: 40,
              height: 40,
              child: Image.asset('assets/images/map_marker.png'),
            ),
          ],
        ),
      ],
    );
  }
}
