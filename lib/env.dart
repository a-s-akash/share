enum Environment {
  development,
  staging,
  production,
}

Environment get currentEnvironment {
  const flavor = String.fromEnvironment('flavor');
  switch (flavor) {
    case 'development':
      return Environment.development;
    case 'staging':
      return Environment.staging;
    case 'production':
    default:
      return Environment.production;
  }
}

String get baseURL {
  switch (currentEnvironment) {
    case Environment.development:
      return 'https://qa-api.iotpro.io';
    case Environment.staging:
      return 'https://beta.api.schnelliot.in';
    case Environment.production:
      return 'https://p2-api.schnelliot.in';
  }
}

String get thingsboardURL {
  switch (currentEnvironment) {
    case Environment.development:
      return 'https://iotpro.io';
    case Environment.production:
    case Environment.staging:
      return 'https://schnelliot.in';
  }
}

String get webviewDashboardId {
  switch (currentEnvironment) {
    case Environment.development:
      return '26abf9f0-a246-11ef-8001-693c9082cff6';
    case Environment.production:
    case Environment.staging:
      return '3b987300-ad6a-11ef-98d3-e3bb640e3ce9';
  }
}

String get websocketApi {
  switch (currentEnvironment) {
    case Environment.development:
      return "ws://iotpro.io/api/ws";
    case Environment.production:
    case Environment.staging:
      return 'wss://schnelliot.in/api/ws';
  }
}
