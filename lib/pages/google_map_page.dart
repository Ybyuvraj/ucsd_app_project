import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  final String googleMapsApiKey = dotenv.env['GOOGLE_MAPS_KEY']!;

  LatLng? _currentPosition;
  LatLng? _destination;
  BitmapDescriptor? _currentLocationIcon;
  BitmapDescriptor? _destinationIcon;

  bool _followCurrentLocation = true;

  @override
  void initState() {
    super.initState();
    _setCustomMarkerIcon();
    _setDestinationMarkerIcon();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkAndRequestLocationPermission();
      });
    });
  }

  Future<void> _setCustomMarkerIcon() async {
    final Uint8List markerIcon = await getBytesFromAsset('lib/images/currDragon.png', 200);
    setState(() {
      _currentLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
    });
  }

  Future<void> _setDestinationMarkerIcon() async {
    final Uint8List markerIcon = await getBytesFromAsset('lib/images/destDragon.png', 150);
    setState(() {
      _destinationIcon = BitmapDescriptor.fromBytes(markerIcon);
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 45,
        title: const Text(
          "Maps",
          style: TextStyle(decoration: TextDecoration.none),
        ),
      ),
      body: Stack(
        children: [
          _currentPosition == null
              ? const Center(child: Text("Loading..."))
              : GoogleMap(
                  onMapCreated: (GoogleMapController controller) =>
                      _mapController.complete(controller),
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId("_currentLocation"),
                      icon: _currentLocationIcon ?? BitmapDescriptor.defaultMarker,
                      position: _currentPosition!,
                    ),
                    if (_destination != null)
                      Marker(
                        markerId: const MarkerId("_destinationLocation"),
                        icon: _destinationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                        position: _destination!,
                      ),
                  },
                ),
          Positioned(
            top: kToolbarHeight / 2.2,
            left: 12,
            right: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: _searchController,
                  googleAPIKey: googleMapsApiKey,
                  inputDecoration: InputDecoration(
                    hintText: "Search places...",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    prefixIcon: Icon(Icons.search, color: Colors.blue[400]),
                    filled: true,
                    fillColor: Colors.grey[900],
                  ),
                  textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                  debounceTime: 400,
                  isLatLngRequired: true,
                  containerHorizontalPadding: 5,
                  containerVerticalPadding: 5,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    setState(() {
                      _destination = LatLng(
                        double.parse(prediction.lat ?? "0"),
                        double.parse(prediction.lng ?? "0"),
                      );
                      _searchController.text = prediction.description ?? "";
                      _followCurrentLocation = false; // disable camera jump-back
                      _cameraToPosition(_destination!);
                    });
                  },
                  itemClick: (Prediction prediction) {
                    _searchController.text = prediction.description ?? "";
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: prediction.description?.length ?? 0),
                    );
                  },
                  itemBuilder: (context, index, Prediction prediction) {
                    return ListTile(
                      leading: Icon(Icons.place_outlined, color: Colors.blue[400]),
                      title: Text(prediction.description ?? "",
                          style: const TextStyle(fontSize: 16)),
                      subtitle: Text(prediction.description ?? "",
                          style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentPosition != null && _destination != null
          ? FloatingActionButton.extended(
              onPressed: _openInGoogleMaps,
              label: const Text("Open in Maps"),
              icon: const Icon(Icons.navigation),
              backgroundColor: Colors.blue[600],
              elevation: 2,
            )
          : null,
    );
  }

  Future<void> _cameraToPosition(LatLng pos, {bool animate = true}) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(target: pos, zoom: 15);
    if (animate) {
      await controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    } else {
      await controller.moveCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location service not enabled. Requesting...");
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
    if (permissionGranted == PermissionStatus.deniedForever) return;

    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentPosition = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
        });
        if (_followCurrentLocation) {
          _cameraToPosition(_currentPosition!);
        }
      }
    });
  }

  void _openInGoogleMaps() async {
    if (_currentPosition == null || _destination == null) return;

    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${_destination!.latitude},${_destination!.longitude}&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps.")),
      );
    }
  }
}
