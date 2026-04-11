import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// ── Risk level enum ──────────────────────────────────────────────────────────
enum RiskLevel { high, medium, safe }

extension RiskLevelExt on RiskLevel {
  Color get color {
    switch (this) {
      case RiskLevel.high:   return const Color(0xFFE53935);
      case RiskLevel.medium: return const Color(0xFFFF9800);
      case RiskLevel.safe:   return const Color(0xFF43A047);
    }
  }

  Color get light {
    switch (this) {
      case RiskLevel.high:   return const Color(0xFFE53935).withOpacity(0.18);
      case RiskLevel.medium: return const Color(0xFFFF9800).withOpacity(0.18);
      case RiskLevel.safe:   return const Color(0xFF43A047).withOpacity(0.18);
    }
  }

  String get label {
    switch (this) {
      case RiskLevel.high:   return 'High Risk';
      case RiskLevel.medium: return 'Medium Risk';
      case RiskLevel.safe:   return 'Safe Zone';
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.high:   return Icons.warning_rounded;
      case RiskLevel.medium: return Icons.info_rounded;
      case RiskLevel.safe:   return Icons.shield_rounded;
    }
  }
}

// ── Data model ───────────────────────────────────────────────────────────────
class _Zone {
  final String name;
  final String description;
  final LatLng point;
  final RiskLevel risk;
  final double radius; // metres

  const _Zone({
    required this.name,
    required this.description,
    required this.point,
    required this.risk,
    this.radius = 600,
  });
}

// ── Dummy Delhi zones ────────────────────────────────────────────────────────
const List<_Zone> _zones = [
  // HIGH RISK
  _Zone(name: 'Paharganj', description: 'High crime rate reported at night. Avoid isolated lanes after 10 PM.', point: LatLng(28.6448, 77.2167), risk: RiskLevel.high, radius: 700),
  _Zone(name: 'Sangam Vihar', description: 'Multiple incidents of chain snatching and assault reported.', point: LatLng(28.5100, 77.2700), risk: RiskLevel.high, radius: 800),
  _Zone(name: 'Uttam Nagar', description: 'Frequent eve-teasing cases near bus stops.', point: LatLng(28.6200, 77.0500), risk: RiskLevel.high, radius: 750),
  _Zone(name: 'Shahdara', description: 'High risk zone — avoid travelling alone at night.', point: LatLng(28.6700, 77.2900), risk: RiskLevel.high, radius: 700),
  _Zone(name: 'Mustafabad', description: 'Reported incidents of harassment and theft.', point: LatLng(28.7200, 77.2700), risk: RiskLevel.high, radius: 650),

  // MEDIUM RISK
  _Zone(name: 'Lajpat Nagar', description: 'Moderate risk — stay alert in crowded market areas.', point: LatLng(28.5677, 77.2433), risk: RiskLevel.medium, radius: 600),
  _Zone(name: 'Karol Bagh', description: 'Pickpocketing reported in busy market hours.', point: LatLng(28.6520, 77.1900), risk: RiskLevel.medium, radius: 600),
  _Zone(name: 'Dwarka Sector 7', description: 'Some incidents near metro station late night.', point: LatLng(28.5921, 77.0460), risk: RiskLevel.medium, radius: 550),
  _Zone(name: 'Rohini Sector 3', description: 'Moderate risk — stay on main roads after dark.', point: LatLng(28.7200, 77.1300), risk: RiskLevel.medium, radius: 600),
  _Zone(name: 'Saket', description: 'Occasional incidents near isolated parking areas.', point: LatLng(28.5244, 77.2066), risk: RiskLevel.medium, radius: 500),

  // SAFE
  _Zone(name: 'Connaught Place', description: 'Well-lit, high police patrolling. Generally safe.', point: LatLng(28.6315, 77.2167), risk: RiskLevel.safe, radius: 700),
  _Zone(name: 'Vasant Kunj', description: 'Residential area with good security coverage.', point: LatLng(28.5200, 77.1600), risk: RiskLevel.safe, radius: 650),
  _Zone(name: 'Greater Kailash', description: 'Safe neighbourhood with active community watch.', point: LatLng(28.5494, 77.2400), risk: RiskLevel.safe, radius: 600),
  _Zone(name: 'Dwarka Sector 21', description: 'Near metro — well-patrolled and safe.', point: LatLng(28.5530, 77.0588), risk: RiskLevel.safe, radius: 600),
  _Zone(name: 'Hauz Khas', description: 'Popular area with good lighting and security.', point: LatLng(28.5494, 77.2001), risk: RiskLevel.safe, radius: 550),
];

// ── Screen ───────────────────────────────────────────────────────────────────
class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _loading = false;
  double _zoom = 11.0;

  // Filter state
  final Set<RiskLevel> _activeFilters = {
    RiskLevel.high,
    RiskLevel.medium,
    RiskLevel.safe,
  };

  List<_Zone> get _filteredZones =>
      _zones.where((z) => _activeFilters.contains(z.risk)).toList();

  // ── Location ──────────────────────────────────────────────────────────────
  Future<void> _requestAndFetchLocation() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('Please enable location services.', Colors.orange);
        setState(() => _loading = false);
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        _snack('Location permission denied.', Colors.redAccent);
        setState(() => _loading = false);
        return;
      }
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = loc;
          _zoom = 14.0;
          _loading = false;
        });
        _mapController.move(loc, _zoom);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('Could not get location. Try again.', Colors.redAccent);
      }
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
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

  // ── Zone detail sheet ─────────────────────────────────────────────────────
  void _showZoneDetail(_Zone zone) {
    final h = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.all(h * 0.025),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: h * 0.02),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(h * 0.014),
                  decoration: BoxDecoration(
                    color: zone.risk.light,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(zone.risk.icon,
                      color: zone.risk.color, size: h * 0.032),
                ),
                SizedBox(width: h * 0.015),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zone.name,
                          style: TextStyle(
                              fontSize: h * 0.022,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E))),
                      SizedBox(height: h * 0.004),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: h * 0.01, vertical: h * 0.004),
                        decoration: BoxDecoration(
                          color: zone.risk.light,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(zone.risk.label,
                            style: TextStyle(
                                fontSize: h * 0.013,
                                color: zone.risk.color,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: h * 0.02),
            Container(
              padding: EdgeInsets.all(h * 0.016),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.grey, size: h * 0.022),
                  SizedBox(width: h * 0.01),
                  Expanded(
                    child: Text(zone.description,
                        style: TextStyle(
                            fontSize: h * 0.015, color: Colors.grey.shade700,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
            SizedBox(height: h * 0.015),
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: Colors.grey, size: h * 0.018),
                SizedBox(width: h * 0.006),
                Text(
                  '${zone.point.latitude.toStringAsFixed(4)}, ${zone.point.longitude.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: h * 0.013, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: h * 0.02),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final filtered = _filteredZones;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(28.6139, 77.2090), // Delhi
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.streehelp.frontend',
              ),

              // Circle overlays
              CircleLayer(
                circles: filtered
                    .map((z) => CircleMarker(
                          point: z.point,
                          radius: z.radius,
                          useRadiusInMeter: true,
                          color: z.risk.color.withOpacity(0.18),
                          borderColor: z.risk.color.withOpacity(0.6),
                          borderStrokeWidth: 1.5,
                        ))
                    .toList(),
              ),

              // Zone markers
              MarkerLayer(
                markers: filtered
                    .map((z) => Marker(
                          point: z.point,
                          width: h * 0.05,
                          height: h * 0.05,
                          child: GestureDetector(
                            onTap: () => _showZoneDetail(z),
                            child: _ZoneMarker(zone: z, h: h),
                          ),
                        ))
                    .toList(),
              ),

              // Current location
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

          // ── Top bar ────────────────────────────────────────────────────────
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safety Heatmap',
                          style: TextStyle(
                              fontSize: h * 0.02,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E))),
                      Text('Delhi Region',
                          style: TextStyle(
                              fontSize: h * 0.013, color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: h * 0.012, vertical: h * 0.005),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E8C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${filtered.length} zones',
                        style: TextStyle(
                            fontSize: h * 0.013,
                            color: const Color(0xFFE91E8C),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          // ── Filter chips ───────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + h * 0.1,
            left: h * 0.02,
            right: h * 0.02,
            child: Row(
              children: RiskLevel.values.map((level) {
                final active = _activeFilters.contains(level);
                return Padding(
                  padding: EdgeInsets.only(right: h * 0.01),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (active) {
                        if (_activeFilters.length > 1) {
                          _activeFilters.remove(level);
                        }
                      } else {
                        _activeFilters.add(level);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: h * 0.014, vertical: h * 0.007),
                      decoration: BoxDecoration(
                        color: active ? level.color : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(level.icon,
                              size: h * 0.016,
                              color: active ? Colors.white : level.color),
                          SizedBox(width: h * 0.005),
                          Text(level.label,
                              style: TextStyle(
                                  fontSize: h * 0.013,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      active ? Colors.white : Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Zoom controls ──────────────────────────────────────────────────
          Positioned(
            right: h * 0.02,
            bottom: h * 0.22,
            child: Column(
              children: [
                _ZoomButton(icon: Icons.add, onTap: _zoomIn, h: h),
                SizedBox(height: h * 0.01),
                _ZoomButton(icon: Icons.remove, onTap: _zoomOut, h: h),
              ],
            ),
          ),

          // ── My location FAB ────────────────────────────────────────────────
          Positioned(
            right: h * 0.02,
            bottom: h * 0.145,
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

          // ── Legend card ────────────────────────────────────────────────────
          Positioned(
            left: h * 0.02,
            right: h * 0.02,
            bottom: h * 0.02,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: h * 0.02, vertical: h * 0.016),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -2))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: RiskLevel.values.map((level) {
                  final count =
                      _zones.where((z) => z.risk == level).length;
                  return Row(
                    children: [
                      Container(
                        width: h * 0.016,
                        height: h * 0.016,
                        decoration: BoxDecoration(
                            color: level.color, shape: BoxShape.circle),
                      ),
                      SizedBox(width: h * 0.007),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(level.label,
                              style: TextStyle(
                                  fontSize: h * 0.013,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A2E))),
                          Text('$count zones',
                              style: TextStyle(
                                  fontSize: h * 0.011, color: Colors.grey)),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Zone marker widget ────────────────────────────────────────────────────────
class _ZoneMarker extends StatelessWidget {
  final _Zone zone;
  final double h;
  const _ZoneMarker({required this.zone, required this.h});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: zone.risk.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
              color: zone.risk.color.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 1)
        ],
      ),
      child: Icon(zone.risk.icon, color: Colors.white, size: h * 0.022),
    );
  }
}

// ── Animated blue dot ─────────────────────────────────────────────────────────
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
          Container(
            width: widget.h * 0.04 * _anim.value,
            height: widget.h * 0.04 * _anim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  const Color(0xFF2196F3).withOpacity((1 - _anim.value) * 0.5),
            ),
          ),
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

// ── Zoom button ───────────────────────────────────────────────────────────────
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double h;
  const _ZoomButton({required this.icon, required this.onTap, required this.h});

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
