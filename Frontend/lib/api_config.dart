class ApiConfig {
  static const String baseUrl = 'http://192.168.1.40:4000';

  static const String login          = '$baseUrl/api/auth/login';
  static const String register       = '$baseUrl/api/auth/register';
  static const String addContact     = '$baseUrl/api/contacts/add';
  static const String getContacts    = '$baseUrl/api/contacts/getContacts';
  static String deleteContact(String id) => '$baseUrl/api/contacts/$id';
  static String updateContact(String id) => '$baseUrl/api/contacts/$id';
  static const String sendSos = '$baseUrl/api/sos/send';
  
  // Threat detection endpoints
  static const String sendThreatAlert = '$baseUrl/api/threat/alert';
  static const String reportThreat = '$baseUrl/api/threat/report';
}
