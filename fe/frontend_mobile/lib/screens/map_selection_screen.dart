import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  String _selectedAddress = "Đang tải vị trí...";
  bool _isLoading = true;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Dịch vụ vị trí bị tắt. Vui lòng bật GPS.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Quyền truy cập vị trí bị từ chối.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Quyền truy cập vị trí bị từ chối vĩnh viễn.');
      return;
    }

    try {
      Position? position = await Geolocator.getLastKnownPosition();
      
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }
      
      setState(() {
        _currentLocation = LatLng(position!.latitude, position.longitude);
        _selectedLocation = _currentLocation;
        _isLoading = false;
      });
      _getAddressFromLatLng(_currentLocation!);
    } catch (e) {
      // Fallback to a default location (e.g. Hanoi) if GPS times out
      setState(() {
        _currentLocation = const LatLng(21.028511, 105.804817);
        _selectedLocation = _currentLocation;
        _isLoading = false;
      });
      _getAddressFromLatLng(_currentLocation!);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _selectedAddress = "Đang tìm địa chỉ...";
    });
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'AuraApp/1.0 (dev@auraapp.local)',
        'Accept-Language': 'vi-VN,vi;q=0.9',
      });

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _selectedAddress = data['display_name'] ?? 'Không rõ địa chỉ';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _selectedAddress = 'Lỗi tìm địa chỉ (${response.statusCode})';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = 'Lỗi kết nối';
        });
      }
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    
    // Hide keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'AuraApp/1.0 (dev@auraapp.local)',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final result = data[0];
          final lat = double.parse(result['lat'].toString());
          final lon = double.parse(result['lon'].toString());
          final newLocation = LatLng(lat, lon);
          
          _mapController.move(newLocation, 15.0);
          
          if (mounted) {
            setState(() {
              _currentLocation = newLocation;
              _selectedLocation = newLocation;
            });
          }
          await _getAddressFromLatLng(newLocation);
        } else {
          _showError('Không tìm thấy địa điểm nào');
        }
      } else {
        _showError('Lỗi tìm kiếm (${response.statusCode})');
      }
    } catch (e) {
      _showError('Lỗi kết nối khi tìm kiếm');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedAddress = "Không xác định";
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn địa chỉ giao hàng', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFC8102E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          if (_currentLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 15.0,
                onMapEvent: (MapEvent event) {
                  if (event is MapEventMoveStart) {
                    setState(() {
                      _isMoving = true;
                    });
                  } else if (event is MapEventMoveEnd) {
                    setState(() {
                      _isMoving = false;
                      _selectedLocation = _mapController.camera.center;
                    });
                    if (_selectedLocation != null) {
                      _getAddressFromLatLng(_selectedLocation!);
                    }
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.frontend_mobile',
                ),
              ],
            ),
            
          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập địa điểm, đường, phường, quận...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: _searchAddress,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFFC8102E)),
                    onPressed: () => _searchAddress(_searchController.text),
                  ),
                ],
              ),
            ),
          ),
            
          // Fixed center pin overlay
          if (_currentLocation != null)
            Center(
              child: Transform.translate(
                offset: const Offset(0, -20), // Push up by half of icon size so the tip is exactly at the center
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0, _isMoving ? -10 : 0, 0),
                  child: Icon(
                    Icons.location_on,
                    color: _isMoving ? Colors.redAccent : Colors.red,
                    size: 40,
                    shadows: const [
                      Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4))
                    ],
                  ),
                ),
              ),
            ),
            
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
            
          if (!_isLoading)
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
                    const Text('Vị trí đã ghim:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_selectedAddress, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMoving ? Colors.grey : const Color(0xFFC8102E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isMoving ? null : () {
                          if (_selectedLocation != null) {
                            Navigator.pop(context, {
                              'address': _selectedAddress,
                              'lat': _selectedLocation!.latitude,
                              'lng': _selectedLocation!.longitude,
                            });
                          }
                        },
                        child: Text(_isMoving ? 'Đang chọn vị trí...' : 'Xác nhận địa chỉ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
