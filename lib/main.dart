import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lahar/route_generator.dart';
import 'package:connectivity/connectivity.dart';

void printHello() {
  final DateTime now = DateTime.now();
  print("[$now] Hello, world!");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Lahar',
      theme: ThemeData.dark(),
      initialRoute: '/',
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  StreamSubscription iosSubscription;
  StreamSubscription<Position> positionStream;
  String typeChosen ;
  WebViewController webViewController;
  String uid;
  String docIDofWorkFromNotification;
  String initialUrl = "https://baii-c8a24.web.app";
  var connectivitySubscription;

  @override
  void initState() {
    super.initState();
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if(result == ConnectivityResult.none) {
        Navigator.of(context).popAndPushNamed('/no_internet');
      }
      else {
        Navigator.of(context).popAndPushNamed('/');   //Opens Home View
      }
    });
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("fcm message received");
        print("fcm onMessage: $message");
        if (message['notification']['title'] == "Workers Position") {
          webViewController.evaluateJavascript("AddWorkersPosition('" +
              message['notification']['content'] +
              "')");
          print('okso');
        } else if (message['data']['work_taken'] == "true"){
          print('loading url work_set.html on webView');
          // work taken from notification
          webViewController.loadUrl("https://baii-c8a24.web.app/work_set.html");
        }
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("fcm onLaunch: $message");
        docIDofWorkFromNotification = message['data']['docID'];     //doc id to be sent to server when it asks on confirm_work.html page
        webViewController.loadUrl("https://baii-c8a24.web.app/confirm_work.html");
        // it does not work on launch
        initialUrl = "https://baii-c8a24.web.app/confirm_work.html";
      },
      onResume: (Map<String, dynamic> message) async {
        print("fcm onResume: $message");
        docIDofWorkFromNotification = message['data']['docID'];         //doc id to be sent to server when it asks on confirm_work.html page
        print("docIDofWorkFromNotification : " + message['data']['docID']);
        webViewController.loadUrl("https://baii-c8a24.web.app/confirm_work.html");
      }

    );

    if (Platform.isIOS) {
      iosSubscription =
          _firebaseMessaging.onIosSettingsRegistered.listen((data) {
        _showFCMtoken();
      });
      _firebaseMessaging
          .requestNotificationPermissions(IosNotificationSettings());
    } else {
      _showFCMtoken();
    }
    _firebaseMessaging.subscribeToTopic("lahar");
  }

  _showFCMtoken() async {
    String fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print('fcm token :' + fcmToken);
    }
  }



  void sendLocationForPost() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location Services are disabled ');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      print(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        print('Location permissions are denied (actual value: $permission).');
        return;
      }
    }

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    print('test3');
    webViewController.evaluateJavascript("OpenMap(" +
        pos.latitude.toString() +
        ", " +
        pos.longitude.toString() +
        " );");
    print('test4');
  }

  void shout() async {
    //TODO : uncomment this for continuous location updated but change it so it only happens to employees

    //await AndroidAlarmManager.periodic(const Duration(seconds: 7), 0, SendPeriodicLocation);
  }
  void sendPositionStream() async {
   // Position pos = await Geolocator.getCurrentPosition(
       // desiredAccuracy: LocationAccuracy.best);
  //  print('test1');
  // Position pos2 = await Geolocator.getLastKnownPosition();
  //  print('test2');
 //   var dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, pos2.latitude, pos2.longitude);
 //   if (dist > 10) {
      //Update location
 //   }
  //  webViewController.evaluateJavascript("PostPeriodicLocation(" +
   //     pos.latitude.toString() +
   //     ", " +
   //     pos.longitude.toString() +
    //    " );");

    positionStream = Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.best,distanceFilter:5).listen(
            (Position position) {
          print(position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString());
          webViewController.evaluateJavascript("UpdateMyLocation(" + position.latitude.toString() + "," + position.longitude.toString() + ")");
        });

  }
  void sendLocation(String m) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location Services are disabled ');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      print(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        print('Location permissions are denied (actual value: $permission).');
        return;
      }
    }

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    print('test3');
    webViewController.evaluateJavascript("$m(" +
        pos.latitude.toString() +
        ", " +
        pos.longitude.toString() +
        " );");
    print('test4');
  }

  void cancelPositionStream() {
    positionStream.cancel();
  }
  void handleJSMessage(String msg) {
    String code = msg.split(':')[0].trim();
    String m = msg.split(':')[1].trim();
    print(code );
    print(m);
    if (code == 'uid') {
      uid = m;
    }
    else if (code == 'type_chosen' ) {
      typeChosen = m;
    }
    else if (code == 'open_map') {
      //open map for searching employees
      print('sendLocForPostCalled');
      sendLocationForPost();
    }
    else if (code == 'start_position_stream') {
      sendPositionStream();
    }
    else if (code == 'cancel_position_stream') {
      cancelPositionStream();
    }
    else if(code == 'send_location') {
      sendLocation(m);
    }
    else if(code == 'send_notification_docID'){
      webViewController.evaluateJavascript("$m('$docIDofWorkFromNotification')");
    }
    else if(code == "send_fcm_token") {
      _firebaseMessaging.getToken().then((value) => webViewController.evaluateJavascript("$m('$value')"));
    }
    else if(code == "send_uid") {
      webViewController.evaluateJavascript("$m('uid')");
    }
    else if (code == "open_camera") {
      Navigator.of(context).popAndPushNamed('/camera_open');
    }
    else {
      print('Unhandled Code : $code and message : $m');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: "https://www.baii-c8a24.web.app",
        javascriptMode: JavascriptMode.unrestricted,
        javascriptChannels: Set.from([
          JavascriptChannel(name: 'flutter_bridge', onMessageReceived: (JavascriptMessage message) {
            handleJSMessage(message.message);
            print(message.message);
          })
        ]),
        onWebViewCreated: (WebViewController w) {
          webViewController = w;
        },
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}

class NoInternetPage extends StatelessWidget {
  NoInternetPage({
    Key key,
  }) : super(key : key);
  Widget build(BuildContext context) {
    return Scaffold(
      appBar : AppBar(
        title: Text('Lahar'),
      ),
      body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'No Internet',
              style: TextStyle(fontSize: 50),
            ),
            Text(
              ' Try checking your connection',
              style: TextStyle(fontSize: 20),
            )
          ]
      )
    );
  }
}

