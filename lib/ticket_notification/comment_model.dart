class Comments {
  Id? id;
  int? createdTime;
  AlarmId? alarmId;
  AlarmId? userId;
  String? type;
  Comment? comment;
  String? firstName;
  String? lastName;
  String? email;
  String? name;

  Comments(
      {this.id,
      this.createdTime,
      this.alarmId,
      this.userId,
      this.type,
      this.comment,
      this.firstName,
      this.lastName,
      this.email,
      this.name});

  Comments.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? Id.fromJson(json['id']) : null;
    createdTime = json['createdTime'];
    alarmId =
        json['alarmId'] != null ? AlarmId.fromJson(json['alarmId']) : null;
    userId = json['userId'] != null ? AlarmId.fromJson(json['userId']) : null;
    type = json['type'];
    comment =
        json['comment'] != null ? Comment.fromJson(json['comment']) : null;
    firstName = json['firstName'];
    lastName = json['lastName'];
    email = json['email'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) {
      data['id'] = id!.toJson();
    }
    data['createdTime'] = createdTime;
    if (alarmId != null) {
      data['alarmId'] = alarmId!.toJson();
    }
    if (userId != null) {
      data['userId'] = userId!.toJson();
    }
    data['type'] = type;
    if (comment != null) {
      data['comment'] = comment!.toJson();
    }
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['email'] = email;
    data['name'] = name;
    return data;
  }
}

class Id {
  String? id;

  Id({this.id});

  Id.fromJson(Map<String, dynamic> json) {
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    return data;
  }
}

class AlarmId {
  String? entityType;
  String? id;

  AlarmId({this.entityType, this.id});

  AlarmId.fromJson(Map<String, dynamic> json) {
    entityType = json['entityType'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['entityType'] = entityType;
    data['id'] = id;
    return data;
  }
}

class Comment {
  String? text;
  String? subtype;
  String? userId;
  String? assigneeId;

  Comment({this.text, this.subtype, this.userId, this.assigneeId});

  Comment.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    subtype = json['subtype'];
    userId = json['userId'];
    assigneeId = json['assigneeId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    data['subtype'] = subtype;
    data['userId'] = userId;
    data['assigneeId'] = assigneeId;
    return data;
  }
}
