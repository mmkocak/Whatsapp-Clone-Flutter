class ChatModel {
  String name;
  String? icon;
  bool isGroup;
  String time;
  String currentMessage;
  String status;
  bool select = false;
  int id;
  ChatModel({
    this.name = "No Name",
     this.icon,
     this.isGroup = false,
     this.time = "No Time",
     this.currentMessage = "No Messages",
     this.status = "No Status",
    this.select = false,
     this.id = 1,
  });
}
