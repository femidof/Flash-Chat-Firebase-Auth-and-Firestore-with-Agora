import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/components/call.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:wakelock/wakelock.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = "chat_screen";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _callChannel = "wellwell";
  String messageText;
  bool checker;

  @override
  Future<void> initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
    readData();
    checker = false;
  }

  void getCurrentUser() async {
    final user = await _auth.currentUser();
    if (user != null) {
      loggedInUser = user;
    }
  }

  Future<void> readData() async {
    DocumentSnapshot calls = await _firestore
        .collection('calls')
        .document('fajCYg8cRzIfc95psNOX')
        .get();
    String call = calls.data['call'];
    print("Firebase Call state: $call");

    setState(() async {
      if (call == 'true') {
        checker = true;
        Wakelock.toggle(on: checker);
      } else {
        checker = false;
        Wakelock.toggle(on: checker);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return (!checker)
        ? Scaffold(
            appBar: AppBar(
              leading: null,
              actions: <Widget>[
                IconButton(
                    icon: Icon(Icons.video_call),
                    onPressed: () async {
                      await _firestore
                          .collection('calls')
                          .document('fajCYg8cRzIfc95psNOX')
                          .updateData({'call': 'true'});

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CallPage(
                            channelName: _callChannel,
                          ),
                        ),
                      );
                    }),
                IconButton(icon: Icon(Icons.call), onPressed: null),
                IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      //Implement logout functionality
                      _auth.signOut();
                      Navigator.pop(context);
                    }),
              ],
              title: Text('⚡️Chat'),
              backgroundColor: Colors.lightBlueAccent,
            ),
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  MessagesStream(),
                  Container(
                    decoration: kMessageContainerDecoration,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: messageTextController,
                            onChanged: (value) {
                              //Do something with the user input.
                              messageText = value;
                            },
                            decoration: kMessageTextFieldDecoration,
                          ),
                        ),
                        FlatButton(
                          onPressed: () {
                            messageTextController.clear();
                            //Implement send functionality.
                            _firestore.collection('messages').add({
                              'text': messageText,
                              'sender': loggedInUser.email,
                              'timestamp':
                                  DateTime.now().toUtc().millisecondsSinceEpoch,
                            });
                          },
                          child: Text(
                            'Send',
                            style: kSendButtonTextStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        :
        //better if it is a request picking
        Scaffold(
            body: CallPage(
              channelName: _callChannel,
            ),
          );
  }
}

//class CallStream extends StatefulWidget {
//  @override
//  _CallStreamState createState() => _CallStreamState();
//}
//
//class _CallStreamState extends State<CallStream> {
//  @override
//  Widget build(BuildContext context) {
//    return StreamBuilder<QuerySnapshot>(
//      stream: _firestore.collection('calls').snapshots(),
//      builder: (context, snapshot) {
//        if (!snapshot.hasData) {
//          return Center(
//            child: CircularProgressIndicator(
//              backgroundColor: Colors.lightBlueAccent,
//            ),
//          );
//        }
//        DocumentSnapshot calls;
//        String call;
//        void readData() async {
//          calls = await _firestore
//              .collection('calls')
//              .document('fajCYg8cRzIfc95psNOX')
//              .get();
//          call = calls.data['call'];
//          print("Firebase Call state: $call");
//
//          // if (call == 'true') {}
//        }
//
//        void updateData() async {
//          await _firestore
//              .collection('calls')
//              .document()
//              .updateData({'calls': 'false'});
//        }
//
//        readData();
//        setState(() {
//          if (call == 'true') {}
//          // final call = calls[calls.length - 1];
//          // if (call.data['call'] != 'true') {}
//
//          return (call == 'true')
//              ? Center(
//                  child: Stack(
//                    children: <Widget>[
//                      Container(),
//                      Column(
//                        children: <Widget>[
//                          IconButton(
//                              icon: Icon(
//                                Icons.phone_in_talk,
//                                color: Colors.green,
//                              ),
//                              onPressed: () {
//                                _firestore.collection('messages').add({
//                                  'call': 'false',
//                                });
//                              }),
//                          IconButton(
//                              icon: Icon(
//                                Icons.phone,
//                                color: Colors.red,
//                              ),
//                              onPressed: () {
//                                Navigator.push(
//                                    context,
//                                    MaterialPageRoute(
//                                        builder: (context) => CallPage(
//                                              channelName: "wellwell",
//                                            )));
//                              }),
//                        ],
//                      ),
//                    ],
//                  ),
//                )
//              : ChatScreen();
//        });
//      },
//    );
//  }
//}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.documents.reversed;
        // final calls = snapshot.data.documents;
        List<MessageBubble> messageBubbles = [];

        for (var message in messages) {
          final messageText = message.data['text'];
          final messageSender = message.data['sender'];
          final currentUser = loggedInUser.email;

          // if (call == 'true') {
          //   return Center();
          // }

          if (currentUser == messageSender) {
            //message from logged in User
          }
          final messageBubble = MessageBubble(
            sender: messageSender,
            text: messageText,
            isMe: currentUser == messageSender,
          );
          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 20.0,
            ),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe});
  final String sender;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  )
                : BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                '$text',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
