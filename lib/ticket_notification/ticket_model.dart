class Ticket {
  String? alarmId;
  String? originatorId;
  String? originatorType;
  String? ticketStatus;
  String? priority;
  String? assignee;
  String? assigneeId;
  String? lastModifiedDate;
  String? ticketId;
  String? complaineeType;
  String? complainee;
  String? location;
  String? entityType; //DEVICE/ASSET for api posting purpose
  String? deviceId;
  String? problemType;
  String? comment;
  String? deviceType; //lamp, ilm, ge, ccms, pole..etc,
  String? latitude;
  String? longitude;
  String? createdTime;
  Map? ticketDetails;
  bool? componentsChanged;
  String? issuesIdentified;
  String? replacedEntityName;
  List<dynamic>? auditTrail;

  /// Location-hierarchy names (not ids) — same field names/values Firestore
  /// tickets are filtered on server-side (see ticket_service.dart's
  /// getDefaultTicketServiceFB `query.where(latestContext, ...)`), carried
  /// into the local model so MyTicketsView can apply the same ward/zone/
  /// region/customer filter against the offline-first ticketListBox.
  String? ward;
  String? zone;
  String? region;
  String? customer;

  /// Set only for tickets created on this device while offline (or while an
  /// online create was still in flight): the same uuid TicketRepository
  /// queues under in ticketQueueBox, and the ticketListBox key until the
  /// sync engine swaps it for the server-issued ticketId. Null for every
  /// ticket that came from a normal server fetch.
  String? localId;

  /// True once the ticket exists on the server (server-fetched tickets, and
  /// locally-created ones after a successful sync). False only for a
  /// still-queued offline ticket — drives the "Not Synced" badge. Missing in
  /// JSON (older stored records, or any server-fetched ticket) defaults to
  /// true, since absence only ever happens for already-synced data.
  bool synced;

  /// True while an edit to this ticket (status/comment/etc.) is queued
  /// offline and hasn't reached the server yet — independent of [synced],
  /// which only tracks whether the ticket itself has been *created* on the
  /// server. A ticket can be synced (exists on the server) while also
  /// having a pending update. Drives a separate "Update Pending" badge.
  bool hasPendingUpdate;

  Ticket({
    this.alarmId,
    this.originatorId,
    this.originatorType,
    this.ticketStatus,
    this.priority,
    this.assignee,
    this.assigneeId,
    this.lastModifiedDate,
    this.ticketId,
    this.complaineeType,
    this.complainee,
    this.location,
    this.entityType,
    this.deviceId,
    this.problemType,
    this.comment,
    this.deviceType,
    this.latitude,
    this.longitude,
    this.createdTime,
    this.ticketDetails,
    this.componentsChanged,
    this.issuesIdentified,
    this.replacedEntityName,
    this.auditTrail,
    this.ward,
    this.zone,
    this.region,
    this.customer,
    this.localId,
    this.synced = true,
    this.hasPendingUpdate = false,
  });

  Ticket.fromJson(Map<String, dynamic> json)
      : synced = json['synced'] ?? true,
        hasPendingUpdate = json['hasPendingUpdate'] ?? false {
    alarmId = json['alarmId'];
    originatorId = json['originatorId'];
    originatorType = json['originatorType'];
    ticketStatus = json['ticketStatus'];
    priority = json['priority'];
    assignee = json['assignee'];
    assigneeId = json['assigneeId'];
    lastModifiedDate = json['lastModifiedDate'];
    ticketId = json['ticketId'];
    complaineeType = json['complaineeType'];
    complainee = json['complainee'];
    location = json['location'];
    entityType = json['deviceType'];
    deviceId = json['deviceId'];
    problemType = json['problemType'];
    comment = json['comments'];
    deviceType = json['type'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    createdTime = json['createdTime'];
    ticketDetails = json['details'];
    componentsChanged = json['components_changed'];
    issuesIdentified = json['issues_identified'];
    replacedEntityName = json['replaced_entity_name'];
    auditTrail = json['audit_trail'];
    ward = json['ward'];
    zone = json['zone'];
    region = json['region'];
    customer = json['customer'];
    localId = json['localId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['alarmId'] = alarmId;
    data['originatorId'] = originatorId;
    data['originatorType'] = originatorType;
    data['ticketStatus'] = ticketStatus;
    data['priority'] = priority;
    data['assignee'] = assignee;
    data['assigneeId'] = assigneeId;
    data['lastModifiedDate'] = lastModifiedDate;
    data['ticketId'] = ticketId;
    data['complaineeType'] = complaineeType;
    data['complainee'] = complainee;
    data['location'] = location;
    data['deviceType'] = entityType;
    data['deviceId'] = deviceId;
    data['problemType'] = problemType;
    data['comments'] = comment;
    data['createdTime'] = createdTime;
    data['type'] = deviceType;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['details'] = ticketDetails;
    data['components_changed'] = componentsChanged;
    data['issues_identified'] = issuesIdentified;
    data['replaced_entity_name'] = replacedEntityName;
    data['audit_trail'] = auditTrail;
    data['ward'] = ward;
    data['zone'] = zone;
    data['region'] = region;
    data['customer'] = customer;
    data['localId'] = localId;
    data['synced'] = synced;
    data['hasPendingUpdate'] = hasPendingUpdate;
    return data;
  }
}
