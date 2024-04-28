import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:progress_indicator/progress_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Models/CurrentCityDataModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:intl/intl.dart';
import 'Models/DaysForcast.dart';
import "package:flutter/services.dart";
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController textEditingController = TextEditingController();
  TextEditingController textEditingController2 = TextEditingController();
  Future<CurrentCityData>? currentWeatherFuture;
  StreamController<List<Forcast>>? forcastDaysStream;
  late SharedPreferences prefs;
  // final SharedPreferences prefs = awt SharedPreferences.getInstance();
  String currentCity = 'london';
  String? previousCity = 'london';
  bool isStarted = true;
  var lon;
  var lat;
  bool isValid = true;
  var citydata;
  var cityFound;

  
  @override
  void initState() {
    super.initState();
    currentWeatherFuture = sendRequestForCurrentWeather();
    forcastDaysStream = StreamController<List<Forcast>>();
  }

  void getForcast(lon, lat) async {
    List<Forcast> Days = [];
    var apiKey = '5a7d482b14cae03d7b6242c7aa8f51c8';
    // var apiKey = '0507284e820a6b9d25fa7acca7aea9dd';
    try {
      var response = await Dio().get(
          'https://api.openweathermap.org/data/2.5/forecast',
          queryParameters: {
            'lat': lat,
            'lon': lon,
            'appid': apiKey,
            'units': 'metric'
          });
      final formatter = DateFormat.MMMd();
      for (int i = 0; i < 40; i += 2) {
        var Model = response.data['list'][i];
        var dt = formatter.format(new DateTime.fromMillisecondsSinceEpoch(
          Model['dt'] * 1000,
          isUtc: false,
        ));
        String exact_time = Model['dt_txt'].split(" ")[1].substring(0, 5);
        Forcast Day = Forcast(
            dt,
            Model['main']['temp'],
            Model['weather'][0]['main'],
            Model['weather'][0]['description'],
            Model['weather'][0]['icon'],
            exact_time);
        Days.add(Day);
      }
      forcastDaysStream!.add(Days);
    } on DioError {}
  }

  Future<CurrentCityData> sendRequestForCurrentWeather(
      [String? currentCity]) async {
    var apiKey = '0507284e820a6b9d25fa7acca7aea9dd';
    // var apiKey = '5a7d482b14cae03d7b6242c7aa8f51c8';
    if (currentCity == null) {
      prefs = await SharedPreferences.getInstance();
      currentCity = prefs.getString('city');
      if (null==currentCity){
        currentCity=previousCity;
      }
    }
    try {
      var response = await Dio().get(
        'https://api.openweathermap.org/data/2.5/weather',
        queryParameters: {'q': currentCity, 'appid': apiKey, 'units': 'metric'},
        //we use  'units':'metric'   for get temperature in Celsius
      );
      lon = response.data['coord']['lon'];
      lat = response.data['coord']['lat'];
      getForcast(lon, lat);
      previousCity = currentCity;
      // currentCity = currentCity;
      citydata = CurrentCityData(
          response.data['name'],
          response.data['coord']['lon'],
          response.data['coord']['lat'],
          response.data['weather'][0]['id'],
          response.data['weather'][0]['description'],
          response.data['weather'][0]['icon'],
          response.data['main']['temp'],
          response.data['main']['temp_max'],
          response.data['main']['temp_min'],
          response.data['wind']['speed'],
          response.data['sys']['sunrise'],
          response.data['sys']['sunset'],
          response.data['main']['humidity']);
      return citydata;
    } on DioError {
      return citydata;
    }
  }

  isCityExist(String currentCity) async {
    
    try {
      var apiKey = '0507284e820a6b9d25fa7acca7aea9dd';
      var response = await Dio().get(
        'https://api.openweathermap.org/data/2.5/weather',
        queryParameters: {'q': currentCity, 'appid': apiKey, 'units': 'metric'},
        //we use  'units':'metric'   for get temperature in Celsius
      );
      isValid = true;
      cityFound = true;
    } catch (e) {
      isValid = false;
      cityFound = false;
    }
    setState(() {
      isValid=isValid;
      cityFound=cityFound;
    });
  }

  dynamic setIcon(String iconCode, double siz) {
    switch (iconCode) {
      case "01d":
        return Icon(
          CupertinoIcons.sun_max,
          size: siz,
          color: Colors.white,
        );
      case "01n":
        return Icon(CupertinoIcons.moon, size: siz, color: Colors.white);
      case "02d":
        return Icon(CupertinoIcons.cloud_sun, size: siz, color: Colors.white);
      case "02n":
        return Icon(CupertinoIcons.cloud_moon, size: siz, color: Colors.white);
      case "03d":
      case "03n":
        return Icon(CupertinoIcons.cloud, size: siz, color: Colors.white);
      case "o4d":
      case "04n":
        return Icon(CupertinoIcons.smoke, size: siz, color: Colors.white);
      case "09d":
      case "09n":
        return Icon(CupertinoIcons.cloud_rain, size: siz, color: Colors.white);
      case "10d":
        return Icon(CupertinoIcons.cloud_sun_rain,
            size: siz, color: Colors.white);
      case "10n":
        return Icon(CupertinoIcons.cloud_moon_rain,
            size: siz, color: Colors.white);
      case "11d":
      case "11n":
        return Icon(CupertinoIcons.cloud_bolt, size: siz, color: Colors.white);
      case "13d":
      case "13n":
        return Icon(CupertinoIcons.snow, size: siz, color: Colors.white);
      default:
        return Container(
            width: siz * 1.33,
            height: siz,
            child: Image.asset(
              "assets/images/other2.png",
              color: Colors.white,
              fit: BoxFit.fitHeight,
            ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      debugShowCheckedModeBanner: false,
      home:GestureDetector( 
          //using for close keyboard when you tap on screen
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: Colors.blue,
              title: Text('Weather App',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600),),
              elevation: 10,
              centerTitle: true,
              actions: [
                PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                    constraints: BoxConstraints.expand(width: 125, height: 96),
                    color: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                        onCanceled: () {
                          textEditingController2.text="";
                          isValid=true;
                        },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem(
                          height: 40,
                          child: Row(
                            children: [
                              Icon(Icons.location_pin,color: Colors.white),
                              Text(
                                "Default City",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ],
                          ),
                          onTap: () {
                            showDialog(

                                context: context,
                                builder: (context) {
                                  return AlertDialog.adaptive(
                                  
                                    title: Text(
                                      "Change Default City",
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    content: TextField(
                                      controller: textEditingController2,
                                      onSubmitted: (value) async {
                                        print("onsubmit");
                                          await isCityExist(
                                              textEditingController2.text.trim());
                                          setState(() {
                                            if (isValid) {
                                              prefs.setString(
                                                  'city',
                                                  textEditingController2.text
                                                      .trim());
                                          
                                              currentWeatherFuture =
                                                  sendRequestForCurrentWeather(
                                                      textEditingController2.text
                                                          .trim());
                                              textEditingController.text =
                                                  textEditingController2.text;
                                              Navigator.pop(context);
                                            } else {
                                          
                                            }
                                          });
                                        },
                                      decoration: InputDecoration(
                                        errorText:
                                            isValid ? null : "City not found",
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          isValid=true;
                                        });
                                      } 
                                    ),
                                    titlePadding:
                                        EdgeInsets.fromLTRB(15, 10, 25, 0),
                                    contentPadding:
                                        EdgeInsets.only(left: 15, right: 15),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          await isCityExist(
                                              textEditingController2.text.trim());
                                          setState(() {
                                            if (isValid) {
                                              prefs.setString(
                                                  'city',
                                                  textEditingController2.text
                                                      .trim());
                                          
                                              currentWeatherFuture =
                                                  sendRequestForCurrentWeather(
                                                      textEditingController2.text
                                                          .trim());
                                              textEditingController.text =
                                                  textEditingController2.text;
                                              Navigator.pop(context);
                                            } else {
                                          
                                            }
                                          });
                                        },
                                        child: Text("Change"),
                                      )
                                    ],
                                  );
                                });
                          },
                        ),
                        PopupMenuItem(
                            height: 40,
                            child: Row(
                              children: [
                                Icon(Icons.landscape,color: Colors.white),
                                Text(
                                  "BackGround",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ],
                            )),
                      ];
                    })
              ],
            ),
        
        
        
        
        
        
        
        
            body: FutureBuilder<CurrentCityData>(
              future: currentWeatherFuture,
              builder: (context, snapshot) {
                //snapshot corresponds to currentWeatherFuture
                if (snapshot.hasData) {
                  CurrentCityData? cityDataModel = snapshot.data;
                  getForcast(lon, lat);
                  // get sunrize time and sunset time
                  final formatter = DateFormat.jm();
                  var sunrise =
                      formatter.format(new DateTime.fromMillisecondsSinceEpoch(
                    cityDataModel!.sunrise! * 1000,
                    //if isUtc:true that shows time in London local time
                    isUtc: false,
                  ));
                  var sunset =
                      formatter.format(new DateTime.fromMillisecondsSinceEpoch(
                    cityDataModel.sunset! * 1000,
                    //if isUtc:true that shows time in London local time
                    isUtc: false,
                  ));
        
                  return Container(
                    // height: 1000000,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage("assets/images/galaxy.jpg"),
                          fit: BoxFit.cover),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Center(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(8, 8, 8, 20),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await isCityExist(
                                          textEditingController.text.trim());
                                      setState(() {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        currentWeatherFuture =
                                            sendRequestForCurrentWeather(
                                                textEditingController.text
                                                    .trim());

                                        if (!cityFound) {
                                          var snackbar = SnackBar(
                                            content: Text("City Not Found"),
                                            backgroundColor: Colors.blueAccent,
                                            duration: Duration(seconds: 3),
                                            showCloseIcon: true,
                                            closeIconColor: Colors.white,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackbar);
                                        } else {
                                        }
                                      });
                                    },
                                    child: Icon(
                                      Icons.search,
                                      color: Colors.yellow,
                                    ),
                                    style: TextButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(0, 14, 8, 0),
                                    child: TextField(
                                      controller: textEditingController,
                                      onSubmitted: (value)async {
                                      await isCityExist(
                                          textEditingController.text.trim());
                                      setState(() {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        currentWeatherFuture =
                                            sendRequestForCurrentWeather(
                                                textEditingController.text
                                                    .trim());

                                        if (!cityFound) {
                                          var snackbar = SnackBar(
                                            content: Text("City Not Found"),
                                            backgroundColor: Colors.blueAccent,
                                            duration: Duration(seconds: 3),
                                            showCloseIcon: true,
                                            closeIconColor: Colors.white,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackbar);
                                        } else {
                                        }
                                      });
                                    },
                                      style:
                                          TextStyle(color: Colors.orangeAccent),
                                      decoration: InputDecoration(
                                        labelText: 'Enter City Name',
                                        labelStyle:
                                            TextStyle(color: Colors.yellow),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              width: 1, color: Colors.yellow),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                width: 0.2,
                                                color: Colors.yellow)),
                                      ),
                                      cursorColor: Colors.orangeAccent,
                                      cursorHeight: 25,
                                      cursorWidth: 2,
                                      showCursor: true,
                                      cursorRadius: Radius.circular(1),
                                      maxLength: 20,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                  cityDataModel.currentCity
                                      .toString()
                                      .toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.white,
                                      letterSpacing: 3,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 15),
                              child: Text(
                                  cityDataModel.description
                                      .toString()
                                      .toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.grey,
                                      letterSpacing: 3,
                                      fontSize: 15)),
                            ),
                            SizedBox(height: 20),
                            setIcon(cityDataModel.icon!, 60),
        
                            //get icons directly from openweathermap.com
                            // Image.network('http://openweathermap.org/img/w/${cityDataModel.icon}.png',),
                            Text(
                              cityDataModel.temp.toString() + "\u2103",
                              style: TextStyle(color: Colors.white, fontSize: 50),
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(top: 15),
                                        child: Text("MAX",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: Text(
                                            cityDataModel.maxTemp.toString() +
                                                "\u2103",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(10, 15, 0, 0),
                                    child: Container(
                                      width: 2,
                                      height: 45,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(10, 15, 0, 0),
                                        child: Text("MIN",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(10, 10, 0, 0),
                                        child: Text(
                                            cityDataModel.minTemp.toString() +
                                                "\u2103",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ]),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 25, 0, 10),
                              child: Container(
                                width: double.infinity,
                                height: 1,
                                color: Colors.grey[800],
                              ),
                            ),
        
                            Container(
                                width: double.infinity,
                                height: 90,
                                child: Center(
                                  child: StreamBuilder<List<Forcast>>(
                                    stream: forcastDaysStream!.stream,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        List<Forcast>? forcasts = snapshot.data;
                                        return ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: 19,
                                            scrollDirection: Axis.horizontal,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              return Container(
                                                width: 70,
                                                child: Card(
                                                  color: Colors.transparent,
                                                  elevation: 0,
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        forcasts![index + 1]
                                                            .date
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.grey),
                                                      ),
                                                      Spacer(),
                                                      Text(
                                                        forcasts[index + 1]
                                                            .time
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.grey),
                                                      ),
                                                      Spacer(),
                                                      setIcon(
                                                          forcasts[index + 1]
                                                              .icon
                                                              .toString(),
                                                          20),
                                                      Spacer(),
                                                      Text(
                                                          forcasts[index + 1]
                                                                  .temp
                                                                  .toString() +
                                                              "\u2103",
                                                          style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            });
                                      } else {
                                        return Center(
                                          child:Padding(
                                            padding: EdgeInsets.all(10),
                                            child:LinearProgressIndicator(
                                            color:Colors.white,
                                            backgroundColor: Colors.blue,
                                            minHeight: 5,)
                                          )
                                        );
                                      }
                                    },
                                  ),
                                )),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 20),
                              child: Container(
                                width: double.infinity,
                                height: 1,
                                color: Colors.grey[800],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Icon(
                                      CupertinoIcons.wind,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                          cityDataModel.windSpeed.toString() +
                                              "m/s",
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: Container(
                                    width: 2,
                                    height: 45,
                                    color: Colors.grey,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Icon(
                                      CupertinoIcons.sunrise,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: Text(sunrise,
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: Container(
                                    width: 2,
                                    height: 45,
                                    color: Colors.grey,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Icon(
                                      CupertinoIcons.sunset,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: Text(sunset,
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: Container(
                                    width: 2,
                                    height: 45,
                                    color: Colors.grey,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Icon(
                                      CupertinoIcons.drop,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: Text(
                                          cityDataModel.humidity.toString() + "%",
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child:CircularProgressIndicator(color: Colors.blue[900],)
                  );
                }
              }, 
            ),
          ),
        ),
     
    );
  }
}
