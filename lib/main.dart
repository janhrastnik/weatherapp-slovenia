import 'dart:convert';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'package:http/http.dart' as http;
import 'package:pinnable_listview/pinnable_listview.dart';
import 'tile.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Slovenija Vreme',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: TextTheme(
          bodyText2: TextStyle(color: Colors.white)
        ),
        accentColor: Colors.white
      ),
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  PinController pinController = PinController();
  List<GlobalKey<AppExpansionTileState>> globals = List();

  List locations;

  addKey(GlobalKey<AppExpansionTileState> key) {
    globals.add(key);
  }

  collapseTiles() {
    for (GlobalKey<AppExpansionTileState> key in globals) {
      key.currentState.collapse();
    }
  }

  getData() async {
    String link = "http://meteo.arso.gov.si/uploads/probase/www/observ/surface/text/sl/observation_si_latest.xml";
    dynamic response = await http.get(link, headers: {'Content-Type': 'application/xml; charset=UTF-8'});
    return response.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Vreme")),
      body: FutureBuilder(
        future: getData(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            xml.XmlDocument doc = xml.parse(utf8.decode(snapshot.data));
            locations = doc.findAllElements("metData").toList();
            return PinnableListView(
              pinController: pinController,
              children: Iterable<int>.generate(locations.length).map((i) {
                xml.XmlElement location = locations[i];
                String name = location.findAllElements('domain_longTitle').first.text;
                String temp = "${location.findAllElements('t_degreesC').first.text} °C";
                String humidity = "${location.findAllElements('rh').first.text} %";
                String region = location.findAllElements('domain_parentId').first.text;
                String situation;
                situation = location.findAllElements('nn_icon-wwsyn_icon').first.text;
                if (situation.contains("_")) {
                  situation = situation.split("_")[1];
                }
                String windSpeed = "${ location.findAllElements('ff_val_kmh').first.text} km/h";
                return WeatherCard(
                    name: name,
                    temp: temp,
                    situation: situation,
                    humidity: humidity,
                    windSpeed: windSpeed,
                    region: region,
                    addKey: addKey,
                    collapseTiles: collapseTiles,
                    pinController: pinController,
                    index: i
                );
              }).toList()
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class WeatherCard extends StatefulWidget {
  WeatherCard({
    Key key, this.name, this.temp, this.situation, this.humidity,
    this.windSpeed, this.region, this.addKey, this.collapseTiles,
    this.pinController, this.index
  }) : super(key: key);

  final String name;
  final String temp;
  final String situation;
  final String humidity;
  final String windSpeed;
  final String region;
  final Function(GlobalKey<AppExpansionTileState> key) addKey;
  final Function collapseTiles;
  final PinController pinController;
  final int index;

  @override
  WeatherCardState createState() => WeatherCardState();
}

class WeatherCardState extends State<WeatherCard> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  ScrollController _titleScroll;
  bool scrolling = false;
  bool reverse = false;
  bool visible = true;
  GlobalKey<AppExpansionTileState> expansionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 200)
    );
    widget.addKey(expansionKey);
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleScroll.dispose();
    scrolling = false;
    super.dispose();
  }

  Widget loadImage() {
    /*
      FG lightFG modFG heavyFG DZ lightDZ modDZ heavyDZ FZDZ lightFZDZ modFZDZ
       heavyFZDZ RA lightRA modRA heavyRA FZRA lightFZRA modFZRA heavyFZRA RASN
        lightRASN modRASN heavyRASN SN lightSN modSN heavySN SHRA lightSHRA
         modSHRA heavySHRA SHRASN lightSHRASN modSHRASN heavySHRASN SHSN
         lightSHSN modSHSN heavySHSN SHGR lightSHGR modSHGR heavySHGR TS lightTS
          modTS heavyTS TSRA lightTSRA modTSRA heavyTSRA TSRASN lightTSRASN
          modTSRASN heavyTSRASN TSSN lightTSSN modTSSN heavyTSSN TSGR
          lightTSGR modTSGR heavyTSGR

          clear, mostClear, slightCloudy, partCloudy, modCloudy, prevCloudy, overcast, FG
    */
    Widget image = Container();
    if (['FG', 'lightFG', 'modFG', 'heavyFG', 'DZ', 'lightDZ', 'modDZ', 'heavyDZ',
      'FZDZ', 'lightFZDZ', 'modFZDZ', 'heavyFZDZ'].contains(widget.situation)) {
      image = Image.asset("assets/fog.png", color: Colors.white);
    } else if (['RA', 'lightRA', 'modRA', 'heavyRA', 'FZRA', 'lightFZRA',
      'modFZRA', 'heavyFZRA', 'SHRA', 'lightSHRA', 'modSHRA', 'heavySHRA',
      'SHRASN', 'lightSHRASN', 'modSHRASN', 'heavySHRASN', 'SHGR', 'lightSHGR',
      'modSHGR', 'heavySHGR'].contains(widget.situation)) {
      image = Image.asset("assets/rain.png", color: Colors.white);
    } else if (['SN', 'lightSN', 'modSN', 'heavySN', 'RASN', 'lightRASN', 'modRASN',
      'heavyRASN', 'SHSN', 'lightSHSN', 'modSHSN', 'heavySHSN'].contains(widget.situation)) {
      image = Image.asset("assets/snow.png", color: Colors.white);
    } else if (['TS', 'lightTS', 'modTS', 'heavyTS', 'TSRA', 'lightTSRA',
      'modTSRA', 'heavyTSRA', 'TSRASN', 'lightTSRASN', 'modTSRASN', 'heavyTSRASN',
      'TSSN', 'lightTSSN', 'modTSSN', 'heavyTSSN', 'TSGR', 'lightTSGR', 'modTSGR',
      'heavyTSGR'].contains(widget.situation)) {
      image = Image.asset("assets/thunder.png", color: Colors.white);
    } else if (['clear', 'mostClear'].contains(widget.situation)) {
      image = Image.asset("assets/sun.png", color: Colors.white);
    } else if (['slightCloudy', 'partCloudy', 'modCloudy', 'prevCloudy'].contains(widget.situation)) {
      image = Image.asset("assets/cloud-sun.png", color: Colors.white);
    } else if (widget.situation == 'overcast') {
      image = Image.asset("assets/cloud.png", color: Colors.white);
    }
    return image;
  }

  Future getForecast() async {
    String link = "http://meteo.arso.gov.si/uploads/probase/www/fproduct/text/sl/forecast_${widget.region}latest.xml";
    dynamic response = await http.get(link, headers: {'Content-Type': 'application/xml; charset=UTF-8'});
    return response.bodyBytes;
  }

  Future loadForecast() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Napoved"),
            content: FutureBuilder(
              future: getForecast(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  xml.XmlDocument doc = xml.parse(utf8.decode(snapshot.data));
                  List<xml.XmlElement> days = doc.findAllElements("metData").toList();
                  List<List> dataList = Iterable.generate(2, (i) => []).toList();
                  for (xml.XmlElement day in days) {
                    dataList[0].add(day.findAllElements("valid_day").first.text);
                    dataList[1].add(day.findAllElements("td").first.text);
                  }
                  return DataTable(
                    columns: dataList[0].map((day) => DataColumn(label: Text(day))).toList(),
                    rows: dataList.sublist(1).map((l) => DataRow(cells: l.map((data) => DataCell(Text(data))).toList())).toList(),
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, _) {
        double scale = 1 + (_animationController.value * 0.3);
        return Card(
          color: Colors.green,
          margin: EdgeInsets.only(
            left: MediaQuery.of(context).size.width*0.05,
            right: MediaQuery.of(context).size.width*0.05,
            top: 10.0,
            bottom: 10.0
          ),
          child: Stack(
            children: <Widget>[
              AppExpansionTile(
                key: expansionKey,
                backgroundColor: Colors.deepPurple,
                onExpansionChanged: (_) {
                  setState(() {
                    visible = !visible;
                  });
                  if (reverse) {
                    _animationController.reverse();
                    reverse = false;
                  } else {
                    _animationController.forward();
                    reverse = true;
                  }
                },
                leading: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Transform(
                        transform: Matrix4.identity()
                          ..translate(5.0 * _animationController.value, -5.0 * _animationController.value)
                          ..scale(scale),
                        child: loadImage()
                    )

                ),
                title: Padding(
                    padding: EdgeInsets.only(right: 50.0),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..scale(scale)
                        ..translate(15.0 * _animationController.value, -2.0 * _animationController.value),
                      child: Text(
                          widget.name, style: TextStyle(color: Colors.white, fontSize: 16.0)
                      ),
                    ),
                ),
                trailing: Visibility(
                  visible: visible,
                  child: GestureDetector(
                    child: Icon(widget.index == widget.pinController.pinned ? Icons.star : Icons.star_border, color: Colors.white),
                    onTap: () {
                      setState(() {
                        widget.collapseTiles();
                        widget.pinController.pin(widget.index);
                      });
                    },
                  ),
                ),
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          color: Colors.deepPurple[700],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Divider(color: Colors.deepPurple, height: 0.0), // bit of a hack to force max width on column, fix later
                              Padding(padding: EdgeInsets.all(8.0), child: Text("Vlažnost: ${widget.humidity}")),
                              Padding(padding: EdgeInsets.all(8.0), child: Text("Veter: ${widget.windSpeed}")),
                              Padding(padding: EdgeInsets.only(left: 8.0), child: FlatButton(
                                child: Text("Napovedi", style: TextStyle(color: Colors.white)),
                                color: Colors.green,
                                onPressed: () {
                                  print(widget.region);
                                  loadForecast();
                                },
                              ))
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    expansionKey.currentState.expand();
                  },
                  child: Transform(
                    transform: Matrix4.identity()
                      ..scale(scale)
                      ..translate(-50.0 + 25.0 * _animationController.value, 55.0 * _animationController.value),
                    child: CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 30.0,
                        child: Text(widget.temp, style: TextStyle(color: Colors.white))),
                  ),
                ),
              )
            ],
          )
        );
      },
    );
  }
}