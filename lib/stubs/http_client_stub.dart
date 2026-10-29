import 'package:http/http.dart' as http;
import 'package:vibenance/offline_cache.dart';

http.Client getPlatformHttpClient() => OfflineCachingClient(http.Client());
