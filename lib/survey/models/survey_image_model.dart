class MultiCapturedImageModel {
  String filePath1;
  String fileName1;
  bool isUploaded1;
  //backward compatibility
  String? base64Image1;

  String filePath2;
  String fileName2;
  bool isUploaded2;
  String? base64Image2;

  String filePath3;
  String fileName3;
  bool isUploaded3;
  String? base64Image3;

  bool get isAllUploaded => isUploaded1 && isUploaded2 && isUploaded3;

  MultiCapturedImageModel({
    required this.filePath1,
    required this.fileName1,
    this.isUploaded1 = false,
    this.base64Image1,
    required this.filePath2,
    required this.fileName2,
    this.isUploaded2 = false,
    this.base64Image2,
    required this.filePath3,
    required this.fileName3,
    this.isUploaded3 = false,
    this.base64Image3,
  });

  Map<String, dynamic> toMap() {
    return {
      'filePath1': filePath1,
      'fileName1': fileName1,
      'isUploaded1': isUploaded1,
      'base64Image1': base64Image1,
      'filePath2': filePath2,
      'fileName2': fileName2,
      'isUploaded2': isUploaded2,
      'base64Image2': base64Image2,
      'filePath3': filePath3,
      'fileName3': fileName3,
      'isUploaded3': isUploaded3,
      'base64Image3': base64Image3,
    };
  }

  factory MultiCapturedImageModel.fromMap(Map<dynamic, dynamic> map) {
    return MultiCapturedImageModel(
      filePath1: map['filePath1'] ?? '',
      fileName1: map['fileName1'] ?? '',
      isUploaded1: map['isUploaded1'] ?? false,
      base64Image1: map['base64Image1'],
      filePath2: map['filePath2'] ?? '',
      fileName2: map['fileName2'] ?? '',
      isUploaded2: map['isUploaded2'] ?? false,
      base64Image2: map['base64Image2'],
      filePath3: map['filePath3'] ?? '',
      fileName3: map['fileName3'] ?? '',
      isUploaded3: map['isUploaded3'] ?? false,
      base64Image3: map['base64Image3'],
    );
  }
}
