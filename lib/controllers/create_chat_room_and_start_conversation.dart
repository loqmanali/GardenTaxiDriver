import 'package:flutter/material.dart';
import 'package:mycabdriver/controllers/firebase_helper/chat_methods.dart';
import 'package:mycabdriver/controllers/navigators.dart';
import 'package:mycabdriver/views/conversation_screen.dart';
import 'package:mycabdriver/widgets/exception_dialog.dart';
import 'package:mycabdriver/widgets/loading_dialog.dart';

void createChatRoomAndStartConversation({
  @required BuildContext context,
  @required String userName,
  @required String driverName,
  @required String driverId,
  @required String userId,
}) async {
  loadingDialog(context);
  try {
    String roomId =
        FireStoreHelper().getRoomId(userId: userId, driverId: driverId);
    List<String> usersList = ["$driverName", "$userName"];
    Map<String, dynamic> dataMap = {
      "room_id": "$roomId",
      "users": usersList,
      "data": {
        "user_name": userName,
        "user_id": userId,
        "driver_name": driverName,
        "driver_id": driverId,
      },
    };
    bool creationResult =
        await FireStoreHelper().addChatRoom(roomId: roomId, data: dataMap);
    print("Create  : $creationResult");
    if (creationResult) {
      pushNavigatorReplacement(
          context, ConversationScreen("$roomId", "$driverName"));
    } else
      print("Error");
  } catch (e) {
    Navigator.pop(context);
    exceptionDialog(context);
  }
}
