
abstract class IntegratedValue {
  final bool save;
  IntegratedValue({required this.save});
  /// Modifies the current value with another value of higher precedence, any new entry's or mismatches will be overwritten by the new values data
  void merge(IntegratedValue integratedValue);

  dynamic toJson() => null;
}

class Integrations {
  static Integrations? _instance;
  static Integrations get instance => _instance ??= Integrations();
  final Map<String, Set<Integration>> integrations = {};
  final Map<String, bool> initializedIntegrations = {};
  final Map<String, IntegratedValue> cachedValues = {};

  Integrations();

  void registerIntegration(Integration integration) {
    for (final providedValue in integration.values.keys) {
      final valueIntegrations = integrations.putIfAbsent(providedValue, () => <Integration>{});
      valueIntegrations.add(integration);
    }
    initializedIntegrations.putIfAbsent(integration.name, () => false);
  }

  void unregisterIntegration(String integrationName) {
    integrations.forEach((key, value) => value.removeWhere((integration) => integration.name == integrationName));
  }

  Future<void> update({List<String> values = const []}) async {
    // Update values in integrations
    final futures = <Future>[];
    final consideredIntegrations = integrations.entries.where((entry) => values.isEmpty || values.contains(entry.key));
    for (final valueIntegrations in consideredIntegrations) {
      for (final integration in valueIntegrations.value) {
        // Initialize integration on first update
        if (!initializedIntegrations[integration.name]!) {
          await integration.init();
          initializedIntegrations[integration.name] = true;
        }
        futures.add(integration.update());
      }
    }
    await Future.wait(futures);
    _cacheIntegrations(consideredIntegrations);
  }

  IntegratedValue? getValue(String valueName) {
    return cachedValues[valueName];
  }

  Map<String, Map<String, dynamic>> saveIntegrationValuesToJson() {
    final integrationJsonValues = <String,  Map<String, dynamic>>{};
    for (final valueIntegrations in integrations.values) {
      for (final integration in valueIntegrations) {
        if (!integration.save) continue;
        integrationJsonValues[integration.name] = integration.saveValuesToJson();
      }
    }
    return integrationJsonValues;
  }

  void loadIntegrationValuesFromJson(Map<String, dynamic> integrationJsonValues) {
    for (final valuesIntegrationEntry in integrationJsonValues.entries) {
      final integrationName = valuesIntegrationEntry.key;
      final integration = integrations.values.firstWhere((valueIntegrations) => valueIntegrations.any((integration) => integration.name == integrationName))
          .firstWhere((integration) => integration.name == integrationName);
      integration.loadValuesFromJson(valuesIntegrationEntry.value as Map<String, dynamic>);
    }
    _cacheIntegrations(integrations.entries);
  }

  /// Integrate values and cache result
  void _cacheIntegrations(Iterable<MapEntry<String, Set<Integration>>> valueIntegrations) {
    for (final e in valueIntegrations) {
      final value = _integrateValue(e.key);
      if (value != null) {
        cachedValues[e.key] = value;
      }
    }
  }

  IntegratedValue? _integrateValue(String valueName) {
    final valueIntegrations = integrations[valueName]!;
    IntegratedValue? currentValue;
    int? currentPrecedence;
    for (final integration in valueIntegrations) {
      final integrationValue = integration.values[valueName];
      if (integrationValue == null) continue;
      currentValue ??= integrationValue;
      currentPrecedence ??= integration.precedence;
      if (integration.precedence == currentPrecedence && currentValue != integrationValue) {
        throw Exception("Encountered value mismatch, with equal precedence $currentPrecedence for value $valueName");
      }
      if (integration.precedence > currentPrecedence) {
        currentValue.merge(integrationValue);
        currentPrecedence = integration.precedence;
      }
    }
    return currentValue;
  }

}

abstract class Integration {
  final String name;
  final bool save;
  final int precedence;
  final Map<String, IntegratedValue?> values = {};

  /// Create a new Integration and automatically register it
  Integration({required this.name, required this.save, required this.precedence, required List<String> providedValues}) {
    for (final providedValue in providedValues) {
      values[providedValue] = null;
    }
    Integrations.instance.registerIntegration(this);
  }

  /// Gets called before the first update
  Future<void> init();

  /// Fetch new data and update values accordingly
  Future<void> update();

  /// Override this, if save is true
  void loadValuesFromJson(Map<String, dynamic> jsonValues) => {};

  Map<String, dynamic> saveValuesToJson() {
    final jsonValues = <String, dynamic>{};
    for (final entry in values.entries) {
      if (entry.value == null) continue;
      if (!entry.value!.save) continue;
      jsonValues[entry.key] = entry.value!.toJson();
    }
    return jsonValues;
  }
}
