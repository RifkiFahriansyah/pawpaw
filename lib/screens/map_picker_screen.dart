import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation ?? const LatLng(-6.200000, 106.816666);
    _getPlaceName(_pickedLocation!);
  }

  void _onTapMap(LatLng position) {
    setState(() {
      _pickedLocation = position;
      _locationName = 'Memuat nama lokasi...';
    });
    _getPlaceName(position);
  }

  Future<void> _getPlaceName(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _locationName = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationName = 'Gagal memuat nama lokasi';
      });
    }
  }

  void _confirmLocation() {
    if (_pickedLocation != null) {
      Navigator.pop(context, _pickedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih lokasi di peta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Lokasi di Peta"),
        actions: [
          IconButton(
            onPressed: _confirmLocation,
            icon: const Icon(Icons.check),
            tooltip: 'Konfirmasi Lokasi',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation!,
              zoom: 16,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onTapMap,
            markers: _pickedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('pickedLocation'),
                      position: _pickedLocation!,
                    ),
                  }
                : {},
          ),
          if (_locationName != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Text(
                  _locationName!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}