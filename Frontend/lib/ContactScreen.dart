import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final List<_Contact> _contacts = [
    _Contact(name: 'Sunita Devi', phone: '+91 87654 32109', relation: 'Mother', color: Color(0xFFE91E8C)),
    _Contact(name: 'Rahul Verma', phone: '+91 91234 56789', relation: 'Brother', color: Color(0xFF3F51B5)),
    _Contact(name: 'Priya Sharma', phone: '+91 98765 43210', relation: 'Friend', color: Color(0xFF9C27B0)),
  ];

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Trusted Contacts',
            style: TextStyle(
                fontSize: h * 0.024,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E))),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactSheet(context, h),
        backgroundColor: const Color(0xFFE91E8C),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Add Contact',
            style: TextStyle(color: Colors.white, fontSize: h * 0.016)),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        child: Column(
          children: [
            SizedBox(height: h * 0.015),

            // Search bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: h * 0.016),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded,
                      color: Colors.grey, size: h * 0.025),
                ),
              ),
            ),

            SizedBox(height: h * 0.015),

            // Info banner
            Container(
              padding: EdgeInsets.all(h * 0.014),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE91E8C), Color(0xFFFF6B9D)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.white, size: h * 0.022),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Text(
                      'These contacts will be alerted during SOS',
                      style:
                          TextStyle(color: Colors.white, fontSize: h * 0.014),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.02),

            // Contact list
            Expanded(
              child: ListView.separated(
                itemCount: _contacts.length,
                separatorBuilder: (_, __) => SizedBox(height: h * 0.012),
                itemBuilder: (_, i) => _ContactCard(
                  contact: _contacts[i],
                  onDelete: () => setState(() => _contacts.removeAt(i)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactSheet(BuildContext context, double h) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Trusted Contact',
                style: TextStyle(
                    fontSize: h * 0.022, fontWeight: FontWeight.bold)),
            SizedBox(height: h * 0.02),
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: h * 0.015),
            TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: h * 0.02),
            SizedBox(
              width: double.infinity,
              height: h * 0.06,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save Contact',
                    style:
                        TextStyle(color: Colors.white, fontSize: h * 0.018)),
              ),
            ),
            SizedBox(height: h * 0.02),
          ],
        ),
      ),
    );
  }
}

class _Contact {
  final String name, phone, relation;
  final Color color;
  const _Contact(
      {required this.name,
      required this.phone,
      required this.relation,
      required this.color});
}

class _ContactCard extends StatelessWidget {
  final _Contact contact;
  final VoidCallback onDelete;

  const _ContactCard({required this.contact, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.all(h * 0.016),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: h * 0.026,
            backgroundColor: contact.color.withOpacity(0.15),
            child: Text(contact.name[0],
                style: TextStyle(
                    color: contact.color,
                    fontWeight: FontWeight.bold,
                    fontSize: h * 0.022)),
          ),
          SizedBox(width: h * 0.015),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                    style: TextStyle(
                        fontSize: h * 0.017,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E))),
                Text(contact.phone,
                    style: TextStyle(fontSize: h * 0.013, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: h * 0.01, vertical: h * 0.005),
            decoration: BoxDecoration(
              color: contact.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(contact.relation,
                style: TextStyle(
                    fontSize: h * 0.013,
                    color: contact.color,
                    fontWeight: FontWeight.w500)),
          ),
          SizedBox(width: h * 0.005),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: Colors.red.shade300, size: h * 0.025),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
