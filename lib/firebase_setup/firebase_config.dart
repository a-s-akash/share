import 'package:firebase_core/firebase_core.dart';

import '../env.dart';

FirebaseOptions get ticketsFirebaseOptions {
  switch (currentEnvironment) {
    case Environment.development:
      return const FirebaseOptions(
        apiKey: "AIzaSyBe0c4P4IpmxgcJwR2Vj08ghQ2ySiXCAH4",
        appId: "1:935112910629:android:e09797e1dd12f25cf01ccc",
        messagingSenderId: "935112910629",
        projectId: "iotpro-smartlights",
      );

    case Environment.staging:
    case Environment.production:
      return const FirebaseOptions(
        apiKey: "AIzaSyD6IsPzaN5wUsEvX5rXf5xYpig4Wv3KtFA",
        appId: '1:250108274624:android:4116b8f72196a4f56b8a25',
        messagingSenderId: '250108274624',
        projectId: 'schnelliot-380113',
      );
  }
}

String get ticketCollectionName {
  switch (currentEnvironment) {
    case Environment.development:
    case Environment.production:
    case Environment.staging:
      return 'tickets';
  }
}

String get dbName {
  switch (currentEnvironment) {
    case Environment.development:
      return "iotpro";
    case Environment.production:
    case Environment.staging:
      return "smartlights";
  }
}

String get ticketCountUrl {
  switch (currentEnvironment) {
    case Environment.development:
      return 'https://ticketscount-nz6bd4kzlq-uc.a.run.app';
    case Environment.production:
    case Environment.staging:
      return 'https://ticketscount-hf5ylctu7a-uc.a.run.app';
  }
}

String get createTicketUrl {
  switch (currentEnvironment) {
    case Environment.development:
      return "https://y4dygdpbbj8qhhy9o7cq-nz6bd4kzlq-uc.a.run.app";
    case Environment.production:
    case Environment.staging:
      return 'https://y4dygdpbbj8qhhy9o7cq-hf5ylctu7a-uc.a.run.app';
  }
}

String get updateTicketUrl {
  switch (currentEnvironment) {
    case Environment.development:
      return "https://vnxxklgv3kv2pdw6wkuq-nz6bd4kzlq-uc.a.run.app";
    case Environment.production:
    case Environment.staging:
      return 'https://vnxxklgv3kv2pdw6wkuq-hf5ylctu7a-uc.a.run.app';
  }
}

String get createTicketSecKey {
  switch (currentEnvironment) {
    case Environment.development:
    case Environment.production:
    case Environment.staging:
      return "NQYKHqmKz9DN3TFKpOKVvKlC5LCnC2av7h2fJKJndEiaZn4vl7Q7niyc5o5C";
  }
}

String get updateTicketSecKey {
  switch (currentEnvironment) {
    case Environment.development:
    case Environment.production:
    case Environment.staging:
      return "uF3oRv0QmLEIOhDgDp9caDCzEW2m7bMRS2IcX3pgvxirbbniPE882k6NdFvT";
  }
}
