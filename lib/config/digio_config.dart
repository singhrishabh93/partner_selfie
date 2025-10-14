import 'package:flutter_dotenv/flutter_dotenv.dart';

class DigioConfig {
  // DIGIO API Configuration from environment variables
  static String get baseUrl {
    final url = dotenv.env['DIGIO_BASE_URL'];
    if (url == null) {
      throw Exception('DIGIO_BASE_URL not found in environment variables');
    }
    return url;
  }

  static String get authToken {
    final token = dotenv.env['DIGIO_AUTH_TOKEN'];
    if (token == null) {
      throw Exception('DIGIO_AUTH_TOKEN not found in environment variables');
    }
    return token; 
  }

  static String get templateKey {
    final key = dotenv.env['DIGIO_TEMPLATE_KEY'];
    if (key == null) {
      throw Exception('DIGIO_TEMPLATE_KEY not found in environment variables');
    }
    return key;
  }

  static String get gatewayBaseUrl {
    final url = dotenv.env['DIGIO_GATEWAY_URL'];
    if (url == null) {
      throw Exception('DIGIO_GATEWAY_URL not found in environment variables');
    }
    return url;
  }

  static String get redirectUrl {
    final url = dotenv.env['DIGIO_REDIRECT_URL'];
    if (url == null) {
      throw Exception('DIGIO_REDIRECT_URL not found in environment variables');
    }
    return url;
  }

  // API Endpoints
  static const String createSignRequestEndpoint =
      '/template/multi_templates/create_sign_request';

  // Default values from environment variables
  static int get expireInDays {
    final days = dotenv.env['DIGIO_EXPIRE_IN_DAYS'];
    return int.tryParse(days ?? '10') ?? 10;
  }

  static bool get generateAccessToken {
    final value = dotenv.env['DIGIO_GENERATE_ACCESS_TOKEN'];
    return value?.toLowerCase() == 'true';
  }

  static bool get sendSignLink {
    final value = dotenv.env['DIGIO_SEND_SIGN_LINK'];
    return value?.toLowerCase() == 'true';
  }

  static bool get notifySigners {
    final value = dotenv.env['DIGIO_NOTIFY_SIGNERS'];
    return value?.toLowerCase() == 'false';
  }

  static String get displayOnPage {
    return dotenv.env['DIGIO_DISPLAY_ON_PAGE'] ?? 'custom';
  }
}
