import 'package:accident_app/main.dart';
import 'package:accident_app/map/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({Key? key}) : super(key: key);

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final List<Map<String, String>> notificationMessages = [];
  int selectedMessageIndex = -1;
  bool showRealTimeLocationMarker = false;
  @override
  void initState() {
    super.initState();

    _databaseReference.child('sensor_value').onValue.listen((event) {
      final sensorValue = event.snapshot.value;
      if (sensorValue != null && sensorValue == '1') {
        _databaseReference.child('notifications').onValue.listen((event) {
          final data = event.snapshot.value;
          if (data != null && data is Map) {
            final title = data['title'];
            final body = data['body'];

            Noti.showBigTextNotification(
              title: title,
              body: body,
              fln: flutterLocalNotificationsPlugin,
            );

            setState(() {
              notificationMessages.add({'title': title, 'body': body});
            });
          }
        });
      } else {
        setState(() {
          notificationMessages.clear();
        });
      }
    });

    _firebaseMessaging.subscribeToTopic('your_topic_name');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3ac3cb), Color(0xFFf85187)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor:
              const Color.fromARGB(255, 40, 247, 47).withOpacity(0.5),
        ),
        body: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView.builder(
              itemCount: notificationMessages.length,
              itemBuilder: (context, index) {
                final title = notificationMessages[index]['title'] ?? '';
                final body = notificationMessages[index]['body'] ?? '';

                final isSelected = index == selectedMessageIndex;

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      selectedMessageIndex = index;
                      showRealTimeLocationMarker = true;
                    });

                    Position position = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          latitude: position.latitude,
                          longitude: position.longitude,
                          showRealTimeLocationMarker:
                              showRealTimeLocationMarker,
                          messageBody: body,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: isSelected ? Colors.grey : null,
                    child: ListTile(
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 20,
                        ),
                      ),
                      subtitle: Text(body),
                      trailing: Icon(Icons.notifications),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class Noti {
  static Future showBigTextNotification({
    required String title,
    required String body,
    required FlutterLocalNotificationsPlugin fln,
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'you_can_name_it_whatever1',
      'channel_name',
      playSound: true,
      importance: Importance.max,
      priority: Priority.high,
    );

    var not = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, not);
  }
}
