import 'package:dio/dio.dart';

void main() {
  api();
}

Future<void> api() async {
  Dio dio = Dio();
  var token =
      "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJha3NoaXRoYS5zQHNsMi5xYS5pb3Rwcm8iLCJ1c2VySWQiOiI1OTJlZjdkMC03NTVlLTExZWUtOGMxYS1jZDc1Nzc3Y2JjMGEiLCJzY29wZXMiOlsiVEVOQU5UX0FETUlOIl0sInNlc3Npb25JZCI6IjQ2NzJiMTJhLWMyZjUtNDc1MC1hM2M3LTUyODQ3ZDg1ZjUwOCIsImlzcyI6InRoaW5nc2JvYXJkLmlvIiwiaWF0IjoxNzA2ODUwNzkyLCJleHAiOjE3MDY4NTk3OTIsImZpcnN0TmFtZSI6IkFrc2hpdGhhIiwibGFzdE5hbWUiOiJTIiwiZW5hYmxlZCI6dHJ1ZSwiaXNQdWJsaWMiOmZhbHNlLCJ0ZW5hbnRJZCI6IjkxMTk0N2IwLTc1MmItMTFlZC1hMWQ1LWM3Mjg2OWRjZDY5MyIsImN1c3RvbWVySWQiOiIxMzgxNDAwMC0xZGQyLTExYjItODA4MC04MDgwODA4MDgwODAifQ.nAarau305K_PWGZBzBGh-Ul913T2mFXzTMaPjILfCDPfMFRHRSPKZqRr2aTggPMvEZf0Mnk4msP9M3hlocL41w";
  var data = {
    {
      "ilm": {"name": "ILMA93"},
      "latitude": 11.0810354,
      "longitude": 76.9891761,
      "accuracy": 12.7,
      "landmark": "Saravanampatti, Coimbatore, Tamil Nadu, India, 641006,",
      "wardName": "ooty1-1",
      "zoneName": "ooty1",
      "region": "OOTY",
      "installedOn": 1706852332,
      "installedBy": "akshitha.s@sl2.qa.iotpro",
      "customerId": "af085e20-7a10-11ed-a1d5-c72869dcd693",
      "wardId": "95fdb720-80fc-11ed-82ca-f9d13b8ff550",
      "lightPointId": "",
      "poleId": "",
      "lamp": {
        "name": "ILM548999",
        "type": "lamp",
        "lampWatts": 0120,
        "manufacturer": "BI",
        "lampType": "02",
        "dimmable": "01",
        "year": "2022"
      }
    }
  };
  dio.options.headers["token"] = token;
  await dio.post('http://iotpro.io:8079/api/luminaire/maintain/',
      options: Options(contentType: 'application/json'), data: data);
}
