import 'dart:io';

class ConnectivityService {
  const ConnectivityService();

  Future<bool> hasInternetConnection() async {
    try {
      final lookup = await InternetAddress.lookup('generativelanguage.googleapis.com');
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

