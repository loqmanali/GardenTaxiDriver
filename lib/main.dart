//finish in 29-11-2020
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mycabdriver/constance/constance.dart';
import 'package:mycabdriver/auth/loginScreen.dart';
import 'package:mycabdriver/controllers/current_trip_provider.dart';
import 'package:mycabdriver/controllers/firebase_helper.dart';
import 'package:mycabdriver/controllers/user_data_provider.dart';
import 'package:mycabdriver/home/inside_outside.dart';
import 'package:mycabdriver/models/notification_model.dart';
import 'package:mycabdriver/providers/driverLocation.dart';
import 'package:mycabdriver/providers/driver_info_provider.dart';
import 'package:mycabdriver/providers/driver_trip.dart';
import 'package:mycabdriver/providers/drvier_to_client_trip.dart';
import 'package:mycabdriver/setting/settingScreen.dart';
import 'package:mycabdriver/splashScreen.dart';
import 'package:mycabdriver/introduction/addVehicalScreen.dart';
import 'package:mycabdriver/views/lifeCycleEvent.dart';
import 'package:mycabdriver/widgets/dialog.dart';
import 'package:provider/provider.dart';
import 'appTheme.dart';
import 'auth/signUpScreen.dart';
import 'controllers/chat_provider.dart';
import 'history/historyScreen.dart';
import 'home/homeScreen.dart';
import 'introduction/LocationScreen.dart';
import 'introduction/introductionScreen.dart';
import 'introduction/language_screen.dart';
import 'inviteFriend/inviteFriendScreen.dart';
import 'package:mycabdriver/wallet/myWallet.dart';
import 'constance/constance.dart' as constance;
import 'package:mycabdriver/controllers/FCM_service.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]).then((_) => runApp(new MyApp()));
// }

//void main() => runApp(DevicePreview(builder: (context) => MyApp()));
void main() => runApp(InitProviders());

//
// class _MyApp extends StatefulWidget {
//   @override
//   __MyAppState createState() => __MyAppState();
// }
//
// class __MyAppState extends State<_MyApp> {
//   bool _launchApp = false;
//
//   @override
//   void initState() {
//     Firebase.initializeApp()
//         .then((value) => setState(() => this._launchApp = true));
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return (this._launchApp) ? MyApp() : Container();
//   }
// }
class InitProviders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => DriverInfoProvider(),
        ),
        ChangeNotifierProvider(
            create: (context) => DriverToClient(),
        ),
        ChangeNotifierProvider(
          create: (context) => DriverTrip(),
        ),
        ChangeNotifierProvider(
          create: (context) => DriverLocation(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserDataProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => CurrentTripProvider(),
        )
      ],
      child: MyApp(),
    );
    //  MyApp()
  }
}

class MyApp extends StatefulWidget {
  static setCustomeTheme(BuildContext context, int index) {
    final _MyAppState state = context.findAncestorStateOfType<_MyAppState>();
    state.setCustomTheme(index);
  }

  static setCustomeLanguage(BuildContext context, String languageCode) {
    final _MyAppState state = context.findAncestorStateOfType<_MyAppState>();
    state.setLanguage(languageCode);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PushNotificationsServices _fcm;

  @override
  void initState() {
    this._fcm = new PushNotificationsServices();
    this._fcm.registerOnFirebaseAndGetToken();
    super.initState();
  }

  bool _fcmInit = false;

  final navigatorKey = GlobalKey<NavigatorState>();

  void show(NotificationModel model) {
    final context = navigatorKey.currentState.overlay.context;

    showNotificationAlert(context, model);
  }

  FirebaseHelper _firebaseHelper = new FirebaseHelper();
  UserDataProvider _userDataProvider;

  @override
  didChangeDependencies() {
    this._userDataProvider = Provider.of<UserDataProvider>(context);
    if (!this._fcmInit) {
      this._fcmInit = true;
      this._fcm.initAndGetMessage(show);

      WidgetsBinding.instance.addObserver(
        LifecycleEventHandler(resumeCallBack: () async {
          print("Was Active : ${this._userDataProvider.wasActive}");
          this._userDataProvider.activeStatusPicked = false;

          if (this._userDataProvider.wasActive) {
            this._userDataProvider.activeNow = true;
            this._firebaseHelper.updateLocation(
                id: this._userDataProvider.id,
                position: await Geolocator.getCurrentPosition(),
                gender: this._userDataProvider.gender,
                inSide: this._userDataProvider.inSide);
          }
        }, suspendingCallBack: () async {
          print("Delete");
          if (!this._userDataProvider.activeStatusPicked) {
            this._userDataProvider.activeStatusPicked = true;
            this._userDataProvider.wasActive = this._userDataProvider.activeNow;
            print("Was Active : ${this._userDataProvider.wasActive}");
          }
          this._userDataProvider.activeNow = false;
          this
              ._firebaseHelper
              .deleteFromOnlineDrivers(this._userDataProvider.id);
        }),
      );
    }

    super.didChangeDependencies();
  }

  setCustomTheme(int index) {
    if (index == 6) {
      setState(() {
        AppTheme.isLightTheme = true;
      });
    } else if (index == 7) {
      setState(() {
        AppTheme.isLightTheme = false;
      });
    } else {
      setState(() {
        constance.colorsIndex = index;
        constance.primaryColorString =
        ConstanceData().colors[constance.colorsIndex];
        constance.secondaryColorString = constance.primaryColorString;
      });
    }
  }

  String locale = "en";

  setLanguage(String languageCode) {
    setState(() {
      locale = languageCode;
      constance.locale = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    constance.locale = locale;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarColor: Colors.black12,
        systemNavigationBarColor: Colors.black,
      ),
    );
    return MaterialApp(
      navigatorKey: navigatorKey,
      // builder: DevicePreview.appBuilder,
      title: 'MyCab Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      routes: routes,
      //home: HomeScreen(),
    );
  }

  var routes = <String, WidgetBuilder>{
    Routes.SPLASH: (BuildContext context) => SplashScreen(),
    Routes.INTRODUCTION: (BuildContext context) => new IntroductionScreen(),
    Routes.ENABLELOCATION: (BuildContext context) => new EnableLocation(),
    Routes.AUTH: (BuildContext context) => new SignUpScreen(),
    Routes.HOME: (BuildContext context) => new HomeScreen(),
    Routes.HISTORY: (BuildContext context) => new HistoryScreen(),
    //Routes.NOTIFICATION: (BuildContext context) => new NotificationScreen(),
    Routes.INVITE: (BuildContext context) => new InviteFriendScreen(),
    Routes.SETTING: (BuildContext context) => new SettingScreen(),
    Routes.WALLET: (BuildContext context) => new MyWallet(),
    Routes.LOGIN: (BuildContext context) => new LoginScreen(),
    Routes.Languages: (context) => LanguageScreen(),
    Routes.AddVehicle: (context) => AddNewVehical(),
    Routes.SelectDstrict: (context) => InsideAndOutSide(),
    //Routes.Licenses: (context) => LicenceImage(),
  };
}

class Routes {
  static const String SPLASH = "/";
  static const String INTRODUCTION = "/introduction/introductionScreen";
  static const String ENABLELOCATION = "/introduction/LocationScreen";
  static const String AUTH = "/auth/signUpScreen";
  static const String LOGIN = "/auth/loginScreen";
  static const String HOME = "/home/homeScreen";
  static const String HISTORY = "/history/historyScreen";
  static const String NOTIFICATION = "/notification/notificationScree";
  static const String INVITE = "/inviteFriend/inviteFriendScreen";
  static const String SETTING = "/setting/settingScreen";
  static const String WALLET = "/wallet/myWallet";
  static const String Languages = "languages";
  static const String AddVehicle = "addVehicle";
  static const String SelectDstrict = "selectDistrict";
//static const String Licenses = "licenses";
}
//keytool -list -v -keystore "C:\Users\SHEHAP\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
// SHA1: 15:AB:27:BF:83:AF:65:25:21:43:5B:F2:A6:E3:77:C4:0D:10:5B:31
// SHA256: 93:72:A7:B6:37:E6:14:8C:5C:6E:EE:3D:36:16:0F:E4:02:0C:88:DF:F5:B7:6C:AA:07:F0:0C:4A:01:BF:A9:2F



//https://stackoverflow.com/questions/53294551/showdialog-from-root-widget

//https://gardentaxi.net/Back_End/public/api/driver/verify_paper_check
//{"img_url_id":"test","img_url_car":"test","api_token":"lXsyTjfqB1OiTFBQq6sb1bOZeWZylUPdocqlgVslBvFWxlKGFqO6vKLq1BOp"}
