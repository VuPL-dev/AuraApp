import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffMapScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const StaffMapScreen({super.key, required this.order});

  @override
  State<StaffMapScreen> createState() => _StaffMapScreenState();
}

class _StaffMapScreenState extends State<StaffMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _staffLocation;
  LatLng? _customerLocation;
  double? _distanceInMeters;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    try {
      // 1. Get Customer Location from Order
      final lat = widget.order['shipping_lat'];
      final lng = widget.order['shipping_lng'];
      
      if (lat == null || lng == null) {
        setState(() {
          _errorMessage = 'Đơn hàng không có thông tin tọa độ giao hàng.';
          _isLoading = false;
        });
        return;
      }

      // Convert from String/Decimal to double if needed
      final double customerLat = lat is String ? double.parse(lat) : (lat as num).toDouble();
      final double customerLng = lng is String ? double.parse(lng) : (lng as num).toDouble();
      _customerLocation = LatLng(customerLat, customerLng);

      // 2. Get Staff Location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Dịch vụ vị trí bị tắt. Vui lòng bật GPS.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Quyền truy cập vị trí bị từ chối.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Quyền truy cập vị trí bị từ chối vĩnh viễn.';
      }

      Position position = await Geolocator.getCurrentPosition();
      _staffLocation = LatLng(position.latitude, position.longitude);

      // 3. Calculate distance
      _distanceInMeters = Geolocator.distanceBetween(
        _staffLocation!.latitude,
        _staffLocation!.longitude,
        _customerLocation!.latitude,
        _customerLocation!.longitude,
      );

      setState(() {
        _isLoading = false;
      });

      // Adjust map bounds to show both markers
      if (_staffLocation != null && _customerLocation != null) {
        final bounds = LatLngBounds.fromPoints([_staffLocation!, _customerLocation!]);
        Future.delayed(const Duration(milliseconds: 500), () {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50.0),
            )
          );
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openGoogleMaps() async {
    if (_staffLocation == null || _customerLocation == null) return;

    final url = 'https://www.google.com/maps/dir/?api=1&origin=${_staffLocation!.latitude},${_staffLocation!.longitude}&destination=${_customerLocation!.latitude},${_customerLocation!.longitude}&travelmode=driving';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps')),
        );
      }
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn #${widget.order['id']} - Giao hàng', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFC8102E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _staffLocation ?? const LatLng(21.028511, 105.804817),
                        initialZoom: 14.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.frontend_mobile',
                        ),
                        MarkerLayer(
                          markers: [
                            // Staff Marker
                            if (_staffLocation != null)
                              Marker(
                                point: _staffLocation!,
                                width: 60,
                                height: 60,
                                child: const Column(
                                  children: [
                                    Icon(Icons.directions_bike, color: Colors.blue, size: 36),
                                    Text('Staff', style: TextStyle(fontWeight: FontWeight.bold, backgroundColor: Colors.white)),
                                  ],
                                ),
                              ),
                            // Customer Marker
                            if (_customerLocation != null)
                              Marker(
                                point: _customerLocation!,
                                width: 80,
                                height: 80,
                                child: const Column(
                                  children: [
                                    Icon(Icons.location_on, color: Colors.red, size: 36),
                                    Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, backgroundColor: Colors.white)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (_staffLocation != null && _customerLocation != null)
                          PolylineLayer(
                            polylines: [
                              Polyline<Object>(
                                points: [_staffLocation!, _customerLocation!],
                                strokeWidth: 3.0,
                                color: Colors.blue.withOpacity(0.7),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    // Info Panel
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.route, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Khoảng cách: ${_distanceInMeters != null ? _formatDistance(_distanceInMeters!) : "N/A"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('Địa chỉ giao hàng:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(widget.order['shipping_address'] ?? 'Không rõ'),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC8102E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _openGoogleMaps,
                                icon: const Icon(Icons.map),
                                label: const Text('Chỉ đường bằng Google Maps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
