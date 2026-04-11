import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _loading = false;
  double _zoom = 3.0;

  Future<void> _requestAndFetchLocation() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      // 1. Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enable location services on your device.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }

      // 2. Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission denied. Enable from app settings.'),
              backgroundColor: Colors.redAccent,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }
      if (permission == LocationPermission.denied) {
        setState(() => _loading = false);
        return;
      }

      // 3. Try last known position first (instant)
      Position? position = await Geolocator.getLastKnownPosition();

      // 4. If no cached position, get current with timeout
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final loc = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = loc;
          _zoom = 15.0;
          _loading = false;
        });
        _mapController.move(loc, _zoom);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('TimeoutException')
                  ? 'Location timed out. Try again in open area.'
                  : 'Could not get location. Try again.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _zoomIn() {
    _zoom = (_zoom + 1).clamp(1.0, 18.0);
    _mapController.move(_mapController.camera.center, _zoom);
    setState(() {});
  }

  void _zoomOut() {
    _zoom = (_zoom - 1).clamp(1.0, 18.0);
    _mapController.move(_mapController.camera.center, _zoom);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(20.5937, 78.9629), // India center
              initialZoom: _zoom,
              onTap: (_, __) => _requestAndFetchLocation(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.streehelp.frontend',
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: h * 0.04,
                      height: h * 0.04,
                      child: _BlueDot(h: h),
                    ),
                  ],
                ),
            ],
          ),

          // Top title bar
          Positioned(
            top: MediaQuery.of(context).padding.top + h * 0.01,
            left: h * 0.02,
            right: h * 0.02,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: h * 0.02, vertical: h * 0.014),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.map_rounded,
                      color: const Color(0xFFE91E8C), size: h * 0.028),
                  SizedBox(width: h * 0.012),
                  Text('Safety Heatmap',
                      style: TextStyle(
                          fontSize: h * 0.022,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E))),
                  const Spacer(),
                  if (_currentLocation == null)
                    Text('Tap map for location',
                        style: TextStyle(
                            fontSize: h * 0.013, color: Colors.grey)),
                  if (_currentLocation != null)
                    Row(
                      children: [
                        Container(
                          width: h * 0.01,
                          height: h * 0.01,
                          decoration: const BoxDecoration(
                              color: Color(0xFF2196F3),
                              shape: BoxShape.circle),
                        ),
                        SizedBox(width: h * 0.006),
                        Text('Located',
                            style: TextStyle(
                                fontSize: h * 0.013,
                                color: const Color(0xFF2196F3),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Zoom controls
          Positioned(
            right: h * 0.02,
            bottom: h * 0.12,
            child: Column(
              children: [
                _ZoomButton(
                    icon: Icons.add, onTap: _zoomIn, h: h),
                SizedBox(height: h * 0.01),
                _ZoomButton(
                    icon: Icons.remove, onTap: _zoomOut, h: h),
              ],
            ),
          ),

          // My location FAB
          Positioned(
            right: h * 0.02,
            bottom: h * 0.04,
            child: GestureDetector(
              onTap: _requestAndFetchLocation,
              child: Container(
                width: h * 0.065,
                height: h * 0.065,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E8C),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFE91E8C).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: _loading
                    ? Padding(
                        padding: EdgeInsets.all(h * 0.016),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(Icons.my_location_rounded,
                        color: Colors.white, size: h * 0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Animated blue dot for current location
class _BlueDot extends StatefulWidget {
  final double h;
  const _BlueDot({required this.h});

  @override
  State<_BlueDot> createState() => _BlueDotState();
}

class _BlueDotState extends State<_BlueDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _anim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          Container(
            width: widget.h * 0.04 * _anim.value,
            height: widget.h * 0.04 * _anim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2196F3)
                  .withOpacity((1 - _anim.value) * 0.5),
            ),
          ),
          // Blue dot
          Container(
            width: widget.h * 0.018,
            height: widget.h * 0.018,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.5),
                    blurRadius: 6)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double h;

  const _ZoomButton(
      {required this.icon, required this.onTap, required this.h});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: h * 0.055,
        height: h * 0.055,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1A1A2E), size: h * 0.025),
      ),
    );
  }
}
