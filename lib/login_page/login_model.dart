class UserModel {
  String username = '';
  String password = '';
  String? userId;
  bool? active;
  String? token;
  String? refreshToken;
  String? createdBy;
  String? createdDate;
  String? updatedBy;
  String? updatedDate;

  UserModel(
      {required this.username,
      required this.password,
      this.userId,
      this.active,
      this.token,
      this.refreshToken,
      this.createdBy,
      this.createdDate,
      this.updatedBy,
      this.updatedDate});

  UserModel.fromJson(Map<String, dynamic> json) {
    username = json['username'].toString();
    password = json['password'].toString();
    userId = json['userId'];
    active = json['active'];
    token = json['token'];
    refreshToken = json['refreshToken'];
    createdBy = json['createdBy'];
    createdDate = json['createdDate'];
    updatedBy = json['updatedBy'];
    updatedDate = json['updatedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['username'] = username;
    data['password'] = password;
    data['userId'] = userId;
    data['active'] = active;
    data['token'] = token;
    data['refreshToken'] = refreshToken;
    data['createdBy'] = createdBy;
    data['createdDate'] = createdDate;
    data['updatedBy'] = updatedBy;
    data['updatedDate'] = updatedDate;
    return data;
  }
}
