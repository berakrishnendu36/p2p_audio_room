class SocketId {
  late String originId;
  late String destinationId;

  SocketId({required this.originId, required this.destinationId});

  //toJson
  Map<String, dynamic> toJson() => {
        'originId': originId,
        'destinationId': destinationId,
      };

  //fromJson
  factory SocketId.fromJson(Map<String, dynamic> json) => SocketId(
        originId: json['originId'],
        destinationId: json['destinationId'],
      );
}
