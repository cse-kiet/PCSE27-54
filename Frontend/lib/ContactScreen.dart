import 'dart:async';
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
      final res = await http
          .get(
            Uri.parse(ApiConfig.getContacts),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _contacts = List<Map<String, dynamic>>.from(data['contacts']);
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addContact(String name, String email) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not logged in');
    final res = await http.post(
      Uri.parse(ApiConfig.addContact),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      setState(() => _contacts.add(data['contact']));
    } else {
      throw Exception(data['message'] ?? 'Failed to add contact');
    }
  }

  Future<void> _updateContact(String id, int index, String name, String email) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not logged in');
    final res = await http.put(
      Uri.parse(ApiConfig.updateContact(id)),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      setState(() => _contacts[index] = data['contact']);
    } else {
      throw Exception(data['message'] ?? 'Failed to update contact');
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
        onPressed: () => _showContactSheet(context, h),
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
                      'These contacts will be alerted via email during SOS',
                      style: TextStyle(color: Colors.white, fontSize: h * 0.014),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: h * 0.02),
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
                            onEdit: () => _showContactSheet(context, h,
                                contact: _contacts[i], index: i),
                            onDelete: () => _deleteContact(_contacts[i]['_id'], i),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSheet(BuildContext context, double h,
      {Map<String, dynamic>? contact, int? index}) {
    final isEdit = contact != null;
    final nameCtrl = TextEditingController(text: contact?['name'] ?? '');
    final emailCtrl = TextEditingController(text: contact?['email'] ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        bool saving = false;
        String? errorMsg;

        return StatefulBuilder(
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
                  Text(isEdit ? 'Edit Contact' : 'Add Trusted Contact',
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
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter email';
                      if (!v.contains('@')) return 'Enter valid email';
                      return null;
                    },
                  ),
                  if (errorMsg != null) ...[
                    SizedBox(height: h * 0.01),
                    Text(errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  SizedBox(height: h * 0.02),
                  SizedBox(
                    width: double.infinity,
                    height: h * 0.06,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModal(() { saving = true; errorMsg = null; });
                              try {
                                if (isEdit) {
                                  await _updateContact(
                                    contact!['_id'],
                                    index!,
                                    nameCtrl.text.trim(),
                                    emailCtrl.text.trim(),
                                  );
                                } else {
                                  await _addContact(
                                    nameCtrl.text.trim(),
                                    emailCtrl.text.trim(),
                                  );
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                setModal(() {
                                  errorMsg = e.toString().replaceFirst('Exception: ', '');
                                  saving = false;
                                });
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
                          : Text(isEdit ? 'Update Contact' : 'Save Contact',
                              style: TextStyle(
                                  color: Colors.white, fontSize: h * 0.018)),
                    ),
                  ),
                  SizedBox(height: h * 0.02),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactCard(
      {required this.contact, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final name = contact['name'] ?? '';
    final email = contact['email'] ?? '';

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
                if (email.isNotEmpty)
                  Text(email,
                      style: TextStyle(fontSize: h * 0.013, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: const Color(0xFFE91E8C), size: h * 0.025),
            onPressed: onEdit,
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
