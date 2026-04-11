import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _sosVibration = true;
  bool _locationSharing = true;
  bool _nightAlerts = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Settings',
            style: TextStyle(
                fontSize: h * 0.024,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E))),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              padding: EdgeInsets.all(h * 0.02),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE91E8C), Color(0xFFFF6B9D)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFE91E8C).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: h * 0.035,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Icon(Icons.person_rounded,
                        color: Colors.white, size: h * 0.04),
                  ),
                  SizedBox(width: w * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Anjali Singh',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: h * 0.022,
                                fontWeight: FontWeight.bold)),
                        Text('+91 98765 43210',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: h * 0.015)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.all(h * 0.01),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.edit_rounded,
                          color: Colors.white, size: h * 0.022),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.025),

            _SectionLabel(label: 'Safety Settings', h: h),
            SizedBox(height: h * 0.01),
            _ToggleTile(
              icon: Icons.vibration_rounded,
              title: 'SOS Vibration',
              subtitle: 'Vibrate on SOS trigger',
              color: const Color(0xFFE91E8C),
              value: _sosVibration,
              onChanged: (v) => setState(() => _sosVibration = v),
            ),
            SizedBox(height: h * 0.01),
            _ToggleTile(
              icon: Icons.location_on_rounded,
              title: 'Live Location Sharing',
              subtitle: 'Share location with contacts',
              color: const Color(0xFF3F51B5),
              value: _locationSharing,
              onChanged: (v) => setState(() => _locationSharing = v),
            ),
            SizedBox(height: h * 0.01),
            _ToggleTile(
              icon: Icons.nightlight_round,
              title: 'Night Mode Alerts',
              subtitle: 'Extra alerts between 10PM–6AM',
              color: const Color(0xFF673AB7),
              value: _nightAlerts,
              onChanged: (v) => setState(() => _nightAlerts = v),
            ),
            SizedBox(height: h * 0.01),
            _ToggleTile(
              icon: Icons.notifications_rounded,
              title: 'Push Notifications',
              subtitle: 'Receive safety alerts',
              color: const Color(0xFFFF9800),
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),

            SizedBox(height: h * 0.025),

            _SectionLabel(label: 'Account', h: h),
            SizedBox(height: h * 0.01),
            _ActionTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                color: const Color(0xFF4CAF50),
                onTap: () {}),
            SizedBox(height: h * 0.01),
            _ActionTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                color: const Color(0xFF2196F3),
                onTap: () {}),
            SizedBox(height: h * 0.01),
            _ActionTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                color: const Color(0xFF9C27B0),
                onTap: () {}),
            SizedBox(height: h * 0.01),
            _ActionTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                color: Colors.red,
                onTap: () {}),

            SizedBox(height: h * 0.03),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final double h;
  const _SectionLabel({required this.label, required this.h});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            fontSize: h * 0.018,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600));
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: h * 0.016, vertical: h * 0.012),
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
            child: Icon(icon, color: color, size: h * 0.024),
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
                    style: TextStyle(
                        fontSize: h * 0.013, color: Colors.grey)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFE91E8C),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.icon,
      required this.title,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: h * 0.016, vertical: h * 0.016),
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
              child: Icon(icon, color: color, size: h * 0.024),
            ),
            SizedBox(width: h * 0.015),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: h * 0.016,
                      fontWeight: FontWeight.w600,
                      color: title == 'Logout'
                          ? Colors.red
                          : const Color(0xFF1A1A2E))),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: h * 0.025),
          ],
        ),
      ),
    );
  }
}
