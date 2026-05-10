import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class LoginApiService {
  static const String _apiUrl = 'https://hook.us1.make.com/1wuiye4540jzl4twgtist28wqvwwiy16';
  static const int _maxRetries = 3;
  
  // Pending request data for retry
  static Map<String, dynamic>? _pendingData;
  static int _retryCount = 0;
  static bool _isRetrying = false;

  /// Send user login data to the API (non-blocking, fire and forget)
  static void sendLoginData({required String phoneNumber}) {
    // Fire and forget - don't await
    _collectAndSend(phoneNumber);
  }

  /// Collect data and send to API
  static Future<void> _collectAndSend(String phoneNumber) async {
    try {
      // Collect all device information
      final deviceData = await _getDeviceInfo();
      final ipAddress = await _getIpAddress();

      // All data inside "data" field
      final requestData = {
        'data': {
          'phone': phoneNumber,
          'device_info': deviceData,
          'ip_address': ipAddress,
          'login_timestamp': DateTime.now().toIso8601String(),
          'platform': _getPlatform(),
          'app_version': '1.0.0',
        },
      };

      // Try to send
      final success = await _sendRequest(requestData);
      
      if (!success) {
        // Store for retry
        _pendingData = requestData;
        _retryCount = 0;
      }
    } catch (e) {
      debugPrint('Login API Error: $e');
    }
  }

  /// Send HTTP request
  static Future<bool> _sendRequest(Map<String, dynamic> data) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final request = http.Request('POST', Uri.parse(_apiUrl));
      request.body = json.encode(data);
      request.headers.addAll(headers);

      final response = await request.send().timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        debugPrint('Login API: Success');
        _pendingData = null;
        _retryCount = 0;
        return true;
      } else {
        debugPrint('Login API: Failed - ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Login API Request Error: $e');
      return false;
    }
  }

  /// Retry pending request (call this from other screens)
  static void retryIfPending() {
    if (_pendingData != null && _retryCount < _maxRetries && !_isRetrying) {
      _retryPendingRequest();
    }
  }

  /// Internal retry logic
  static Future<void> _retryPendingRequest() async {
    if (_pendingData == null || _retryCount >= _maxRetries || _isRetrying) {
      return;
    }

    _isRetrying = true;
    _retryCount++;
    
    debugPrint('Login API: Retry attempt $_retryCount of $_maxRetries');
    
    // Small delay before retry
    await Future.delayed(Duration(seconds: _retryCount * 2));
    
    final success = await _sendRequest(_pendingData!);
    
    _isRetrying = false;
    
    if (success) {
      _pendingData = null;
      _retryCount = 0;
    }
  }

  /// Get device information
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData = {
          'type': 'Android',
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'device': androidInfo.device,
          'android_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
          'product': androidInfo.product,
          'hardware': androidInfo.hardware,
          'fingerprint': androidInfo.fingerprint,
          'is_physical_device': androidInfo.isPhysicalDevice,
          'display': androidInfo.display,
          'board': androidInfo.board,
          'bootloader': androidInfo.bootloader,
          'supported_abis': androidInfo.supportedAbis,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData = {
          'type': 'iOS',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'system_name': iosInfo.systemName,
          'system_version': iosInfo.systemVersion,
          'localized_model': iosInfo.localizedModel,
          'identifier_for_vendor': iosInfo.identifierForVendor,
          'is_physical_device': iosInfo.isPhysicalDevice,
          'utsname_sysname': iosInfo.utsname.sysname,
          'utsname_nodename': iosInfo.utsname.nodename,
          'utsname_release': iosInfo.utsname.release,
          'utsname_version': iosInfo.utsname.version,
          'utsname_machine': iosInfo.utsname.machine,
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
      deviceData = {'error': 'Failed to get device info'};
    }

    return deviceData;
  }

  /// Get public IP address
  static Future<String> _getIpAddress() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ipify.org?format=json'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'] ?? 'Unknown';
      }
    } catch (e) {
      debugPrint('Error getting IP: $e');
    }
    return 'Unknown';
  }

  /// Get platform string
  static String _getPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
