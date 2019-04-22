import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/utils/shared_preferences.dart';
import 'package:flutter_app/views/bored_page/clock_page/live_clock.dart';
import 'package:flutter_app/views/bored_page/clock_page/page_clock.dart';
import 'package:flutter_app/views/practice_page/page_indicator_page/page_dragger.dart';
import 'package:flutter_app/views/practice_page/page_indicator_page/page_reveal.dart';
import 'package:flutter_app/views/practice_page/page_indicator_page/pager_indicator.dart';
import 'package:flutter_app/views/practice_page/page_indicator_page/pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClockPage extends StatefulWidget {
  @override
  ClockPageState createState() => ClockPageState();
}

class ClockPageState extends State<ClockPage> with TickerProviderStateMixin {
  StreamController<SlideUpdate> slideUpdateStream;
  AnimatedPageDragger animatedPageDragger;

  int activeIndex = 0;
  SlideDirection slideDirection = SlideDirection.none;
  int nextPageIndex = 0;
  int waitingNextPageIndex = -1;

  double slidePercent = 0.0;

  ClockPageState() {
    slideUpdateStream = new StreamController<SlideUpdate>();

    slideUpdateStream.stream.listen((SlideUpdate event) {
      if (mounted) {
        setState(() {
          if (event.updateType == UpdateType.dragging) {
            slideDirection = event.direction;
            slidePercent = event.slidePercent;

            if (slideDirection == SlideDirection.leftToRight) {
              nextPageIndex = activeIndex - 1;
            } else if (slideDirection == SlideDirection.rightToLeft) {
              nextPageIndex = activeIndex + 1;
            } else {
              nextPageIndex = activeIndex;
            }
          } else if (event.updateType == UpdateType.doneDragging) {
            if (slidePercent > 0.5) {
              animatedPageDragger = new AnimatedPageDragger(
                slideDirection: slideDirection,
                transitionGoal: TransitionGoal.open,
                slidePercent: slidePercent,
                slideUpdateStream: slideUpdateStream,
                vsync: this,
              );
            } else {
              animatedPageDragger = new AnimatedPageDragger(
                slideDirection: slideDirection,
                transitionGoal: TransitionGoal.close,
                slidePercent: slidePercent,
                slideUpdateStream: slideUpdateStream,
                vsync: this,
              );

              waitingNextPageIndex = activeIndex;
            }

            animatedPageDragger.run();
          } else if (event.updateType == UpdateType.animating) {
            slideDirection = event.direction;
            slidePercent = event.slidePercent;
          } else if (event.updateType == UpdateType.doneAnimating) {
            if (waitingNextPageIndex != -1) {
              nextPageIndex = waitingNextPageIndex;
              waitingNextPageIndex = -1;
            } else {
              activeIndex = nextPageIndex;
            }

            slideDirection = SlideDirection.none;
            slidePercent = 0.0;

            animatedPageDragger.dispose();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    slideUpdateStream.close();
  }

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  String _userName = '';

  @override
  void initState() {
    super.initState();

    Future<String> _user = _prefs.then((SharedPreferences prefs) {
      return prefs.getString(SharedPreferencesKeys.UserId);
    });

    _user.then((String name) {
      new Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _userName = name;
        });
      });
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(),
      body: new Stack(
        children: [
          new PageClock(
            // page 的主要内容
            viewModel: pages_clock[activeIndex],
            percentVisible: 1.0,
          ),
          new PageReveal(
            revealPercent: slidePercent,
            child: new PageClock(
              viewModel: pages_clock[nextPageIndex],
              percentVisible: slidePercent,
            ),
          ),
          new PagerIndicator(
            viewModel: new PagerIndicatorViewModel(
              pages_clock,
              activeIndex,
              slideDirection,
              slidePercent,
            ),
          ),
          new PageDragger(
            canDragLeftToRight: activeIndex > 0,
            canDragRightToLeft: activeIndex < pages_clock.length - 1,
            slideUpdateStream: this.slideUpdateStream,
          ),
        ],
      ),
      drawer: _drawer,
    );
  }

  get _drawer => Drawer(
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(_userName),
              accountEmail: Text(_userName),
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person),
                backgroundColor: Colors.red,
              ),
              margin: EdgeInsets.zero,
            ),
            ListTile(
              onTap: () {
                _scaffoldKey.currentState.openEndDrawer();
              },
              title: Text("重设生日"),
            ),
            ListTile(
              onTap: () {
                _scaffoldKey.currentState.openEndDrawer();
              },
              title: Text("重设寿命"),
            ),
          ],
        ),
      );
}

final pages_clock = [
  PageViewClockModel(const Color(0xFFcd344f), 'assets/images/p1.png', "生命时钟",
      'assets/images/plane.png', 1),
  PageViewClockModel(const Color(0xFF638de3), 'assets/images/p1.png', "死亡时钟",
      'assets/images/calendar.png', 2),
];

class PageViewClockModel {
  final Color color;
  final String heroAssetPath;
  final String title;
  final String iconAssetPath;
  final int position;

  PageViewClockModel(
    this.color,
    this.heroAssetPath,
    this.title,
    this.iconAssetPath,
    this.position,
  );
}
