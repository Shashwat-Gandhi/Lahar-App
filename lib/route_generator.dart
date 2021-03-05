import 'package:flutter/material.dart';
import 'package:lahar/main.dart';
import 'package:lahar/pages/camera_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
       final args = settings.arguments;
       switch (settings.name) {
         case '/':
           return MaterialPageRoute(builder: (_) => HomeView());
         case '/no_internet':
           return MaterialPageRoute(builder: (_) => NoInternetPage());
         case '/camera_open' :
           return MaterialPageRoute(builder: (_) => CameraScreen());
         default:
            return _errorRoute();
       }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder : (_) {
      return Scaffold(
        appBar : AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text("ERROR"),
        )
      );
    });
  }
}
