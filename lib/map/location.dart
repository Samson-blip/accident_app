import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool showRealTimeLocationMarker;
  final String messageBody;

  MapScreen({
    required this.latitude,
    required this.longitude,
    required this.showRealTimeLocationMarker,
    required this.messageBody,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Position? currentPosition;
  late PermissionStatus permissionStatus;
  bool isLoading = true;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  void _checkLocationPermission() async {
    permissionStatus = await Permission.location.status;
    if (permissionStatus.isGranted) {
      _getCurrentLocation();
    } else {
      await Permission.location.request();
    }
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(position.latitude, position.longitude),
      northeast: LatLng(position.latitude, position.longitude),
    );

    mapController.moveCamera(CameraUpdate.newLatLngBounds(bounds, 15.0));

    setState(() {
      currentPosition = position;
      isLoading = false;
    });

    if (widget.showRealTimeLocationMarker) {
      _addRealTimeLocationMarker();
    }
  }

  void _addRealTimeLocationMarker() {
    if (currentPosition != null) {
      final realTimeMarker = Marker(
        markerId: const MarkerId("realTimeLocation"),
        position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarker,
        anchor: const Offset(0.5, 0.5),
      );

      setState(() {
        markers.add(realTimeMarker);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Map',
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              _getCurrentLocation();
            },
            initialCameraPosition: currentPosition != null
                ? CameraPosition(
                    target: LatLng(
                      currentPosition!.latitude,
                      currentPosition!.longitude,
                    ),
                    zoom: 15.0,
                  )
                : CameraPosition(
                    target: LatLng(widget.latitude, widget.longitude),
                    zoom: 15.0,
                  ),
            markers: markers,
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (widget.showRealTimeLocationMarker)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accident occured:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'follow red marker',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
