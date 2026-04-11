import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Wave controllers
  late final List<AnimationController> _waveControllers;
  late final List<Animation<double>> _waveAnimations;

  // SOS active state
  bool _sosActive = false;

  // Safety timer
  int _timerSeconds = 300; // default 5 min
  int _remaining = 0;
  bool _timerRunning = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _waveControllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      ),
    );
    _waveAnimations = _waveControllers
        .asMap()
        .entries
        .map((e) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: e.value, curve: Curves.easeOut),
            ))
        .toList();

    _waveControllers[0].repeat();
    Future.delayed(const Duration(milliseconds: 600),
        () { if (mounted) _waveControllers[1].repeat(); });
    Future.delayed(const Duration(milliseconds: 1200),
        () { if (mounted) _waveControllers[2].repeat(); });
  }

  @override
  void dispose() {
    for (final c in _waveControllers) c.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _toggleSOS() {
    setState(() => _sosActive = !_sosActive);
    HapticFeedback.heavyImpact();
  }

  void _startTimer() {
    setState(() {
      _remaining = _timerSeconds;
      _timerRunning = true;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _timerRunning = false);
        _onTimerExpired();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    setState(() { _timerRunning = false; _remaining = 0; });
  }

  void _onTimerExpired() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('⚠️ Safety Timer Expired'),
        content: const Text('Are you safe? If no response, SOS will be triggered.'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _startTimer(); },
            child: const Text("I'm Safe", style: TextStyle(color: Color(0xFF4CAF50))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E8C)),
            onPressed: () { Navigator.pop(context); setState(() => _sosActive = true); },
            child: const Text('SOS!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTimerPicker() {
    int picked = _timerSeconds ~/ 60;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        final h = MediaQuery.of(context).size.height;
        return StatefulBuilder(builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.all(h * 0.025),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Set Safety Timer',
                    style: TextStyle(
                        fontSize: h * 0.022, fontWeight: FontWeight.bold)),
                SizedBox(height: h * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () { if (picked > 1) setModal(() => picked--); },
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: Color(0xFFE91E8C)),
                      iconSize: h * 0.035,
                    ),
                    SizedBox(width: h * 0.02),
                    Text('$picked min',
                        style: TextStyle(
                            fontSize: h * 0.032, fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A2E))),
                    SizedBox(width: h * 0.02),
                    IconButton(
                      onPressed: () { if (picked < 60) setModal(() => picked++); },
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          color: Color(0xFFE91E8C)),
                      iconSize: h * 0.035,
                    ),
                  ],
                ),
                SizedBox(height: h * 0.02),
                SizedBox(
                  width: double.infinity,
                  height: h * 0.06,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E8C),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() => _timerSeconds = picked * 60);
                      Navigator.pop(context);
                      _startTimer();
                    },
                    child: Text('Start Timer',
                        style: TextStyle(
                            color: Colors.white, fontSize: h * 0.018)),
                  ),
                ),
                SizedBox(height: h * 0.015),
              ],
            ),
          );
        });
      },
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.02),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Back 👋',
                          style: TextStyle(
                              fontSize: h * 0.018, color: Colors.grey)),
                      Text('Arpit Tripathi',
                          style: TextStyle(
                              fontSize: h * 0.028,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E))),
                    ],
                  ),
                  CircleAvatar(
                    radius: h * 0.028,
                    backgroundImage:
                        const AssetImage('assets/images/Splash.jpeg'),
                  ),
                ],
              ),

              SizedBox(height: h * 0.025),

              // SOS active status indicator
              Center(
                child: GestureDetector(
                  onTap: _toggleSOS,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                        horizontal: h * 0.02, vertical: h * 0.008),
                    decoration: BoxDecoration(
                      color: _sosActive
                          ? const Color(0xFF4CAF50).withOpacity(0.12)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _sosActive
                            ? const Color(0xFF4CAF50)
                            : Colors.red.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BlinkingDot(active: _sosActive),
                        SizedBox(width: h * 0.008),
                        Text(
                          _sosActive ? 'SOS Active' : 'SOS Inactive',
                          style: TextStyle(
                            fontSize: h * 0.015,
                            fontWeight: FontWeight.w600,
                            color: _sosActive
                                ? const Color(0xFF4CAF50)
                                : Colors.red.shade400,
                          ),
                        ),
                        SizedBox(width: h * 0.008),
                        Text('• tap to toggle',
                            style: TextStyle(
                                fontSize: h * 0.012, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.02),

              // SOS Button with waves
              Center(
                child: SizedBox(
                  width: h * 0.22,
                  height: h * 0.22,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(3, (i) {
                        return AnimatedBuilder(
                          animation: _waveAnimations[i],
                          builder: (_, __) {
                            final value = _waveAnimations[i].value;
                            return Container(
                              width: h * 0.22 * (0.5 + value * 0.5),
                              height: h * 0.22 * (0.5 + value * 0.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_sosActive
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFE91E8C))
                                    .withOpacity((1 - value) * 0.35),
                              ),
                            );
                          },
                        );
                      }),
                      GestureDetector(
                        onTap: _toggleSOS,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: h * 0.13,
                          height: h * 0.13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _sosActive
                                  ? [
                                      const Color(0xFF66BB6A),
                                      const Color(0xFF4CAF50)
                                    ]
                                  : [
                                      const Color(0xFFFF6B9D),
                                      const Color(0xFFE91E8C)
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_sosActive
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFE91E8C))
                                    .withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('SOS',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: h * 0.028,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2)),
                              Text('EMERGENCY',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: h * 0.011,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: h * 0.025),

              // Safety Timer
              Container(
                padding: EdgeInsets.all(h * 0.018),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(h * 0.012),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F51B5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.timer_rounded,
                          color: const Color(0xFF3F51B5), size: h * 0.028),
                    ),
                    SizedBox(width: h * 0.015),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Safety Timer',
                              style: TextStyle(
                                  fontSize: h * 0.017,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A2E))),
                          Text(
                            _timerRunning
                                ? 'Remaining: ${_formatTime(_remaining)}'
                                : 'Set a check-in timer',
                            style: TextStyle(
                                fontSize: h * 0.013,
                                color: _timerRunning
                                    ? const Color(0xFF3F51B5)
                                    : Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (_timerRunning)
                      GestureDetector(
                        onTap: _stopTimer,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: h * 0.014, vertical: h * 0.007),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Stop',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: h * 0.014,
                                  fontWeight: FontWeight.w600)),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _showTimerPicker,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: h * 0.014, vertical: h * 0.007),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F51B5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Set & Start',
                              style: TextStyle(
                                  color: const Color(0xFF3F51B5),
                                  fontSize: h * 0.014,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: h * 0.025),

              // Quick Call Emergency
              Text('Quick Call',
                  style: TextStyle(
                      fontSize: h * 0.02,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A2E))),
              SizedBox(height: h * 0.015),
              Row(
                children: [
                  _EmergencyCallCard(
                      label: 'Police', number: '100',
                      icon: Icons.local_police_rounded,
                      color: const Color(0xFF3F51B5)),
                  SizedBox(width: w * 0.03),
                  _EmergencyCallCard(
                      label: 'Ambulance', number: '108',
                      icon: Icons.medical_services_rounded,
                      color: Colors.red),
                  SizedBox(width: w * 0.03),
                  _EmergencyCallCard(
                      label: 'Women', number: '1091',
                      icon: Icons.woman_rounded,
                      color: const Color(0xFFE91E8C)),
                  SizedBox(width: w * 0.03),
                  _EmergencyCallCard(
                      label: 'Fire', number: '101',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFFF9800)),
                ],
              ),

              SizedBox(height: h * 0.025),

              // Recent Alerts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Alerts',
                      style: TextStyle(
                          fontSize: h * 0.02,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E))),
                  Text('See all',
                      style: TextStyle(
                          fontSize: h * 0.016,
                          color: const Color(0xFFE91E8C),
                          fontWeight: FontWeight.w500)),
                ],
              ),
              SizedBox(height: h * 0.015),
              _AlertTile(
                  icon: Icons.location_on_rounded,
                  title: 'High Risk Area Nearby',
                  subtitle: 'Connaught Place, Delhi',
                  time: '2 min ago',
                  color: Colors.red),
              SizedBox(height: h * 0.01),
              _AlertTile(
                  icon: Icons.notifications_rounded,
                  title: 'Friend Checked In',
                  subtitle: 'Priya reached home safely',
                  time: '1 hr ago',
                  color: const Color(0xFF4CAF50)),
              SizedBox(height: h * 0.01),
              _AlertTile(
                  icon: Icons.shield_rounded,
                  title: 'Safe Route Updated',
                  subtitle: 'New safe path to Metro Station',
                  time: '3 hr ago',
                  color: const Color(0xFFE91E8C)),

              SizedBox(height: h * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

// Blinking green/red dot
class _BlinkingDot extends StatefulWidget {
  final bool active;
  const _BlinkingDot({required this.active});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final color =
        widget.active ? const Color(0xFF4CAF50) : Colors.red.shade400;
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: h * 0.012,
        height: h * 0.012,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _EmergencyCallCard extends StatelessWidget {
  final String label, number;
  final IconData icon;
  final Color color;

  const _EmergencyCallCard(
      {required this.label,
      required this.number,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: EdgeInsets.symmetric(vertical: h * 0.015),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(h * 0.01),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: h * 0.025),
              ),
              SizedBox(height: h * 0.006),
              Text(number,
                  style: TextStyle(
                      fontSize: h * 0.018,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A2E))),
              Text(label,
                  style:
                      TextStyle(fontSize: h * 0.012, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, time;
  final Color color;

  const _AlertTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.time,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.all(h * 0.016),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(h * 0.01),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: h * 0.025),
          ),
          SizedBox(width: h * 0.015),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: h * 0.016,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E))),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: h * 0.013, color: Colors.grey)),
              ],
            ),
          ),
          Text(time,
              style: TextStyle(fontSize: h * 0.012, color: Colors.grey)),
        ],
      ),
    );
  }
}
