import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class GoogleMapsFlutterPlatform extends PlatformInterface {
  /// Construtor
  GoogleMapsFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  // Instância singleton
  static GoogleMapsFlutterPlatform _instance = MethodChannelGoogleMapsFlutter();

  /// Padrão singleton
  static GoogleMapsFlutterPlatform get instance => _instance;

  /// Permite definir uma instância de plataforma personalizada
  static set instance(GoogleMapsFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Inicializa o serviço de mapas na plataforma nativa
  Future<void> initialize({
    required String apiKey,
    String? androidApiKey,
    String? iosApiKey,
  }) async {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Verifica se os serviços do Google Play estão disponíveis (Android)
  Future<bool> areGooglePlayServicesAvailable() async {
    throw UnimplementedError(
        'areGooglePlayServicesAvailable() has not been implemented.');
  }

  /// Solicita ao usuário para atualizar/instalar os serviços do Google Play (Android)
  Future<bool> makeGooglePlayServicesAvailable() async {
    throw UnimplementedError(
        'makeGooglePlayServicesAvailable() has not been implemented.');
  }

  /// Verifica a versão dos serviços do Google Play (Android)
  Future<int> getGooglePlayServicesVersion() async {
    throw UnimplementedError(
        'getGooglePlayServicesVersion() has not been implemented.');
  }

  /// Abre o Google Maps nativo com uma rota
  Future<bool> launchGoogleMapsNavigation({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    String? directionsMode, // "driving", "walking", "bicycling" or "transit"
  }) async {
    throw UnimplementedError(
        'launchGoogleMapsNavigation() has not been implemented.');
  }
}

/// Implementação concreta usando MethodChannel
class MethodChannelGoogleMapsFlutter extends GoogleMapsFlutterPlatform {
  static const MethodChannel _channel =
      MethodChannel('plugins.flutter.io/google_maps_flutter');

  @override
  Future<void> initialize({
    required String apiKey,
    String? androidApiKey,
    String? iosApiKey,
  }) async {
    try {
      await _channel.invokeMethod('map#initialize', {
        'apiKey': apiKey,
        'androidApiKey': androidApiKey ?? apiKey,
        'iosApiKey': iosApiKey ?? apiKey,
      });
    } on PlatformException catch (e) {
      throw Exception(
          'Failed to initialize Google Maps Flutter: ${e.message}');
    }
  }

  @override
  Future<bool> areGooglePlayServicesAvailable() async {
    try {
      return await _channel.invokeMethod(
          'play#services#available') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> makeGooglePlayServicesAvailable() async {
    try {
      return await _channel.invokeMethod(
          'play#services#makeAvailable') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<int> getGooglePlayServicesVersion() async {
    try {
      return await _channel.invokeMethod('play#services#version') ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  @override
  Future<bool> launchGoogleMapsNavigation({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    String? directionsMode,
  }) async {
    try {
      return await _channel.invokeMethod('maps#launchNavigation', {
        'startLatitude': startLatitude,
        'startLongitude': startLongitude,
        'endLatitude': endLatitude,
        'endLongitude': endLongitude,
        'directionsMode': directionsMode ?? 'driving',
      }) ?? false;
    } on PlatformException {
      return false;
    }
  }
}