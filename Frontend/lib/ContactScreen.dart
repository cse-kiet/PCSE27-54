import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_manager.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<String?> _getToken() => SessionManager.getToken();

  Future<void> _fetchContacts() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse(ApiConfig.getContacts),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() => _contacts = List<Map<String, dynamic>>.from(data['contacts']));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _addContact(String name, String phone) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse(ApiConfig.addContact),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'phone': phone}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      setState(() => _contacts.add(data['contact']));
    } else {
      throw Exception(data['message'] ?? 'Failed to add contact');
    }
  }

  Future<void> _deleteContact(String id, int index) async {
    final token = await _getToken();
    final res = await http.delete(
      Uri.parse(ApiConfig.deleteContact(id)),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      setState(() => _contacts.removeAt(index));
    }
  }

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
                      style: TextStyle(color: Colors.white, fontSize: h * 0.014),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.02),

            // Contact list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C)))
                  : _contacts.isEmpty
                      ? Center(
                          child: Text('No contacts added yet',
                              style: TextStyle(color: Colors.grey, fontSize: h * 0.016)))
                      : ListView.separated(
                          itemCount: _contacts.length,
                          separatorBuilder: (_, __) => SizedBox(height: h * 0.012),
                          itemBuilder: (_, i) => _ContactCard(
                            contact: _contacts[i],
                            onDelete: () => _deleteContact(_contacts[i]['_id'], i),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactSheet(BuildContext context, double h) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Trusted Contact',
                    style: TextStyle(
                        fontSize: h * 0.022, fontWeight: FontWeight.bold)),
                SizedBox(height: h * 0.02),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter name' : null,
                ),
                SizedBox(height: h * 0.015),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter phone' : null,
                ),
                SizedBox(height: h * 0.02),
                SizedBox(
                  width: double.infinity,
                  height: h * 0.06,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModal(() => saving = true);
                            try {
                              await _addContact(
                                  nameCtrl.text.trim(), phoneCtrl.text.trim());
                              if (mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                                );
                              }
                            } finally {
                              setModal(() => saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E8C),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text('Save Contact',
                            style: TextStyle(
                                color: Colors.white, fontSize: h * 0.018)),
                  ),
                ),
                SizedBox(height: h * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onDelete;

  const _ContactCard({required this.contact, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final name = contact['name'] ?? '';
    final phone = contact['phone'] ?? '';

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
            backgroundColor: const Color(0xFFE91E8C).withOpacity(0.15),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: const Color(0xFFE91E8C),
                    fontWeight: FontWeight.bold,
                    fontSize: h * 0.022)),
          ),
          SizedBox(width: h * 0.015),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: h * 0.017,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E))),
                Text(phone,
                    style: TextStyle(fontSize: h * 0.013, color: Colors.grey)),
              ],
            ),
          ),
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
