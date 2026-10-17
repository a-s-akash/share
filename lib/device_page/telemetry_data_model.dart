class TelemetryData {
  // final String timestamp;
  final int systime;
  final int relayStatus;
  final int rv; //voltage
  final int yv; //voltage
  final int bv; //voltage
  final int rkw; //power
  final int ykw; //power
  final int bkw; //power
  final int ri; //current
  final int yi; //current
  final int bi; //current
  final int fault;
  final int tbtOpen;
  final int tbtClose;
  final int pkt;

  TelemetryData({
    // required this.timestamp,
    required this.systime,
    required this.relayStatus,
    required this.rv,
    required this.yv,
    required this.bv,
    required this.rkw,
    required this.ykw,
    required this.bkw,
    required this.ri,
    required this.yi,
    required this.bi,
    required this.fault,
    required this.tbtOpen,
    required this.tbtClose,
    required this.pkt,
  });

  factory TelemetryData.fromJson(Map<dynamic, dynamic> json) {
    return TelemetryData(
      systime: int.parse(json['systime']?[0]['value']),
      relayStatus: int.parse(json['rly']?[0]['value']),
      rv: int.parse(json['rv']?[0]['value']),
      yv: int.parse(json['yv']?[0]['value']),
      bv: int.parse(json['bv']?[0]['value']),
      rkw: int.parse(json['rw']?[0]['value']),
      ykw: int.parse(json['yw']?[0]['value']),
      bkw: int.parse(json['bw']?[0]['value']),
      ri: int.parse(json['ri']?[0]['value']),
      yi: int.parse(json['yi']?[0]['value']),
      bi: int.parse(json['bi']?[0]['value']),
      fault: int.parse(json['fault']?[0]['value']),
      tbtOpen: int.parse(json['tbtOpen']?[0]['value']),
      tbtClose: int.parse(json['tbtClose']?[0]['value']),
      pkt: int.parse(json['pkt']?[0]['value']),
    );
  }
}
