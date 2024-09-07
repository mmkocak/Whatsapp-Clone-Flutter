import 'package:chatapp/CustomUI/OwnMessgaeCrad.dart';
import 'package:chatapp/CustomUI/ReplyCard.dart';
import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Model/MessageModel.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class IndividualPage extends StatefulWidget {
  const IndividualPage({Key? key, required this.chatModel, required this.sourchat}) : super(key: key);
  final ChatModel chatModel;
  final ChatModel sourchat;

  @override
  _IndividualPageState createState() => _IndividualPageState();
}

class _IndividualPageState extends State<IndividualPage> {
  bool show = false;
  FocusNode focusNode = FocusNode();
  bool sendButton = false;
  List<MessageModel> messages = [];
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChange);
    connect();
  }

  void _onFocusChange() {
    if (focusNode.hasFocus) {
      setState(() {
        show = false;
      });
    }
  }

  void connect() {
    socket = IO.io("http://192.168.0.106:5000", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });
    socket.connect();
    socket.emit("signin", widget.sourchat.id);
    socket.onConnect((data) {
      print("Connected");
      socket.on("message", (msg) {
        print(msg);
        setMessage("destination", msg["message"]);
        _scrollToBottom();
      });
    });
    print(socket.connected);
  }

  void sendMessage(String message, int sourceId, int targetId) {
    setMessage("source", message);
    socket.emit("message", {"message": message, "sourceId": sourceId, "targetId": targetId});
  }

  void setMessage(String type, String message) {
    MessageModel messageModel = MessageModel(
      type: type,
      message: message,
      time: DateTime.now().toString().substring(10, 16),
    );

    setState(() {
      messages.add(messageModel);
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    focusNode.dispose();
    _controller.dispose();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          "assets/whatsapp_Back.png",
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(),
          body: _buildBody(),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leadingWidth: 70,
      titleSpacing: 0,
      leading: InkWell(
        onTap: () {
          Navigator.pop(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back, size: 24),
            CircleAvatar(
              child: SvgPicture.asset(
                widget.chatModel.isGroup ? "assets/groups.svg" : "assets/person.svg",
                color: Colors.white,
                height: 36,
                width: 36,
              ),
              radius: 20,
              backgroundColor: Colors.blueGrey,
            ),
          ],
        ),
      ),
      title: InkWell(
        onTap: () {},
        child: Container(
          margin: EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chatModel.name,
                style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold),
              ),
              Text("last seen today at 12:05", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(icon: Icon(Icons.videocam), onPressed: () {}),
        IconButton(icon: Icon(Icons.call), onPressed: () {}),
        _buildPopupMenuButton(),
      ],
    );
  }

  Widget _buildPopupMenuButton() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.all(0),
      onSelected: (value) {
        print(value);
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(child: Text("View Contact"), value: "View Contact"),
          PopupMenuItem(child: Text("Media, links, and docs"), value: "Media, links, and docs"),
          PopupMenuItem(child: Text("Whatsapp Web"), value: "Whatsapp Web"),
          PopupMenuItem(child: Text("Search"), value: "Search"),
          PopupMenuItem(child: Text("Mute Notification"), value: "Mute Notification"),
          PopupMenuItem(child: Text("Wallpaper"), value: "Wallpaper"),
        ];
      },
    );
  }

  Widget _buildBody() {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Container(height: 70);
        }
        if (messages[index].type == "source") {
          return OwnMessageCard(message: messages[index].message, time: messages[index].time);
        } else {
          return ReplyCard(message: messages[index].message, time: messages[index].time);
        }
      },
    );
  }

  Widget _buildMessageInput() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildInputRow(),
            if (show) emojiSelect(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        _buildTextField(),
        _buildSendButton(),
      ],
    );
  }

  Widget _buildTextField() {
    return Expanded(
      child: Card(
        margin: EdgeInsets.only(left: 2, right: 2, bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: TextFormField(
          controller: _controller,
          focusNode: focusNode,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          minLines: 1,
          onChanged: _onMessageChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Type a message",
            hintStyle: TextStyle(color: Colors.grey),
            prefixIcon: _buildEmojiButton(),
            suffixIcon: _buildAttachmentIcons(),
            contentPadding: EdgeInsets.all(5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiButton() {
    return IconButton(
      icon: Icon(show ? Icons.keyboard : Icons.emoji_emotions_outlined),
      onPressed: () {
        if (!show) {
          focusNode.unfocus();
          focusNode.canRequestFocus = false;
        }
        setState(() {
          show = !show;
        });
      },
    );
  }

  Widget _buildAttachmentIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.attach_file),
          onPressed: _showAttachmentOptions,
        ),
        IconButton(
          icon: Icon(Icons.camera_alt),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 2, left: 2),
      child: CircleAvatar(
        radius: 25,
        backgroundColor: Color(0xFF128C7E),
        child: IconButton(
          icon: Icon(sendButton ? Icons.send : Icons.mic, color: Colors.white),
          onPressed: _onSendButtonPressed,
        ),
      ),
    );
  }

  void _onMessageChanged(String value) {
    setState(() {
      sendButton = value.isNotEmpty;
    });
  }

  void _onSendButtonPressed() {
    if (sendButton) {
      _scrollToBottom();
      sendMessage(_controller.text, widget.sourchat.id, widget.chatModel.id);
      _controller.clear();
      setState(() {
        sendButton = false;
      });
    }
  }

  Future<bool> _handleWillPop() {
    if (show) {
      setState(() {
        show = false;
      });
    } else {
      Navigator.pop(context);
    }
    return Future.value(false);
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (builder) => bottomSheet(),
    );
  }

  Widget bottomSheet() {
    return Container(
      height: 278,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: const EdgeInsets.all(18.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreation(Icons.insert_drive_file, Colors.indigo, "Document"),
                  SizedBox(width: 40),
                  iconCreation(Icons.camera_alt, Colors.pink, "Camera"),
                  SizedBox(width: 40),
                  iconCreation(Icons.insert_photo, Colors.purple, "Gallery"),
                ],
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreation(Icons.headset, Colors.orange, "Audio"),
                  SizedBox(width: 40),
                  iconCreation(Icons.location_pin, Colors.teal, "Location"),
                  SizedBox(width: 40),
                  iconCreation(Icons.person, Colors.blue, "Contact"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget iconCreation(IconData icons, Color color, String text) {
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icons, size: 29, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(text, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget emojiSelect() {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        setState(() {
          _controller.text += emoji.emoji;
        });

      },
      config: Config(
      height: 256,
    checkPlatformCompatibility: true,
      ),
    );
  }
}
