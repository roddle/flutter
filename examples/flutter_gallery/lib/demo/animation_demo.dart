// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum _DragTarget {
  start,
  end
}

// How close a drag's start position must be to the target point. This is
// a distance squared.
const double _kTargetSlop = 2500.0;

// Used by the Painter classes.
const double _kPointRadius = 6.0;

class _DragHandler extends Drag {
  _DragHandler(this.onUpdate, this.onCancel, this.onEnd);

  final GestureDragUpdateCallback onUpdate;
  final GestureDragCancelCallback onCancel;
  final GestureDragEndCallback onEnd;

  @override
  void update(DragUpdateDetails details)  {
    onUpdate(details);
  }

  @override
  void cancel()  {
    onCancel();
  }

  @override
  void end(DragEndDetails details)  {
    onEnd(details);
  }
}

class _IgnoreDrag extends Drag {
}

class _PointDemoPainter extends CustomPainter {
  _PointDemoPainter({
    Animation<double> repaint,
    this.arc
  }) : _repaint = repaint, super(repaint: repaint);

  final MaterialPointArcTween arc;
  Animation<double> _repaint;

  void drawPoint(Canvas canvas, Point point, Color color) {
    final Paint paint = new Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, _kPointRadius, paint);
    paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(point, _kPointRadius + 1.0, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint();

    if (arc.center != null)
      drawPoint(canvas, arc.center, Colors.blue[400]);

    paint
      ..color = Colors.green[500].withOpacity(0.25)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    if (arc.center != null && arc.radius != null)
      canvas.drawCircle(arc.center, arc.radius, paint);
    else
      canvas.drawLine(arc.begin, arc.end, paint);

    drawPoint(canvas, arc.begin, Colors.green[500]);
    drawPoint(canvas, arc.end, Colors.red[500]);

    paint
      ..color = Colors.green[500]
      ..style = PaintingStyle.fill;
    canvas.drawCircle(arc.lerp(_repaint.value), _kPointRadius, paint);
  }

  @override
  bool hitTest(Point position) {
    return (arc.begin - position).distanceSquared < _kTargetSlop
        || (arc.end - position).distanceSquared < _kTargetSlop;
  }

  @override
  bool shouldRepaint(_PointDemoPainter oldPainter) => arc != oldPainter.arc;
}

class _PointDemo extends StatefulWidget {
  _PointDemo({ Key key, this.controller }) : super(key: key);

  final AnimationController controller;

  @override
  _PointDemoState createState() => new _PointDemoState();
}

class _PointDemoState extends State<_PointDemo> {
  final GlobalKey _painterKey = new GlobalKey();

  CurvedAnimation _animation;
  _DragTarget _dragTarget;
  Point _begin = const Point(180.0, 110.0);
  Point _end = const Point(37.0, 250.0);

  @override
  void initState() {
    super.initState();
    _animation = new CurvedAnimation(parent: config.controller, curve: Curves.ease);
  }

  @override
  void dispose() {
    config.controller.value = 0.0;
    super.dispose();
  }

  Drag _handleOnStart(Point position) {
    // TODO(hansmuller): allow the user to drag both points at the same time.
    if (_dragTarget != null)
      return new _IgnoreDrag();

    final RenderBox box = _painterKey.currentContext.findRenderObject();
    final double startOffset = (box.localToGlobal(_begin) - position).distanceSquared;
    final double endOffset = (box.localToGlobal(_end) - position).distanceSquared;
    setState(() {
      if (startOffset < endOffset && startOffset < _kTargetSlop)
        _dragTarget = _DragTarget.start;
      else if (endOffset < _kTargetSlop)
        _dragTarget = _DragTarget.end;
      else
        _dragTarget = null;
    });

    return new _DragHandler(_handleDragUpdate, _handleDragCancel, _handleDragEnd);
  }

  void _handleDragUpdate(DragUpdateDetails details)  {
    switch (_dragTarget) {
      case _DragTarget.start:
        setState(() {
          _begin = _begin + details.delta;
        });
        break;
      case _DragTarget.end:
        setState(() {
          _end = _end + details.delta;
        });
        break;
    }
  }

  void _handleDragCancel()  {
    _dragTarget = null;
    config.controller.value = 0.0;
  }

  void _handleDragEnd(DragEndDetails details)  {
    _dragTarget = null;
  }

  @override
  Widget build(BuildContext context) {
    final MaterialPointArcTween arc = new MaterialPointArcTween(begin: _begin, end: _end);
    return new RawGestureDetector(
      behavior: _dragTarget == null ? HitTestBehavior.deferToChild : HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        ImmediateMultiDragGestureRecognizer: (ImmediateMultiDragGestureRecognizer recognizer) {
          return (recognizer ??= new ImmediateMultiDragGestureRecognizer())
            ..onStart = _handleOnStart;
        }
      },
      child: new ClipRect(
        child: new CustomPaint(
          key: _painterKey,
          foregroundPainter: new _PointDemoPainter(
            repaint: _animation,
            arc: arc
          ),
          // Watch out: if this IgnorePointer is left out, then gestures that
          // fail _PointDemoPainter.hitTest() will still be recognized because
          // they do overlap this child, which is as big as the CustomPaint.
          child: new IgnorePointer(
            child: new Padding(
              padding: const EdgeInsets.all(16.0),
              child: new Text(
                "Tap the refresh button to run the animation. Drag the green "
                "and red points to change the animation's path.",
                style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16.0)
              )
            )
          )
        )
      )
    );
  }
}

class _RectangleDemoPainter extends CustomPainter {
  _RectangleDemoPainter({
    Animation<double> repaint,
    this.arc
  }) : _repaint = repaint, super(repaint: repaint);

  final MaterialRectArcTween arc;
  Animation<double> _repaint;

  void drawPoint(Canvas canvas, Point p, Color color) {
    final Paint paint = new Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p, _kPointRadius, paint);
    paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(p, _kPointRadius + 1.0, paint);
  }

  void drawRect(Canvas canvas, Rect rect, Color color) {
    final Paint paint = new Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, paint);
    drawPoint(canvas, rect.center, color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    drawRect(canvas, arc.begin, Colors.green[500]);
    drawRect(canvas, arc.end, Colors.red[500]);
    drawRect(canvas, arc.lerp(_repaint.value), Colors.blue[500]);
  }

  @override
  bool hitTest(Point position) {
    return (arc.begin.center - position).distanceSquared < _kTargetSlop
        || (arc.end.center - position).distanceSquared < _kTargetSlop;
  }

  @override
  bool shouldRepaint(_RectangleDemoPainter oldPainter) => arc != oldPainter.arc;
}

class _RectangleDemo extends StatefulWidget {
  _RectangleDemo({ Key key, this.controller }) : super(key: key);

  final AnimationController controller;

  @override
  _RectangleDemoState createState() => new _RectangleDemoState();
}

class _RectangleDemoState extends State<_RectangleDemo> {
  final GlobalKey _painterKey = new GlobalKey();

  CurvedAnimation _animation;
  _DragTarget _dragTarget;
  Rect _begin = new Rect.fromLTRB(180.0, 100.0, 330.0, 200.0);
  Rect _end = new Rect.fromLTRB(32.0, 275.0, 132.0, 425.0);

  @override
  void initState() {
    super.initState();
    _animation = new CurvedAnimation(parent: config.controller, curve: Curves.ease);
  }

  @override
  void dispose() {
    config.controller.value = 0.0;
    super.dispose();
  }

  Drag _handleOnStart(Point position) {
    // TODO(hansmuller): allow the user to drag both points at the same time.
    if (_dragTarget != null)
      return new _IgnoreDrag();

    final RenderBox box = _painterKey.currentContext.findRenderObject();
    final double startOffset = (box.localToGlobal(_begin.center) - position).distanceSquared;
    final double endOffset = (box.localToGlobal(_end.center) - position).distanceSquared;
    setState(() {
      if (startOffset < endOffset && startOffset < _kTargetSlop)
        _dragTarget = _DragTarget.start;
      else if (endOffset < _kTargetSlop)
        _dragTarget = _DragTarget.end;
      else
        _dragTarget = null;
    });
    return new _DragHandler(_handleDragUpdate, _handleDragCancel, _handleDragEnd);
  }

  void _handleDragUpdate(DragUpdateDetails details)  {
    switch (_dragTarget) {
      case _DragTarget.start:
        setState(() {
          _begin = _begin.shift(details.delta);
        });
        break;
      case _DragTarget.end:
        setState(() {
          _end = _end.shift(details.delta);
        });
        break;
    }
  }

  void _handleDragCancel()  {
    _dragTarget = null;
    config.controller.value = 0.0;
  }

  void _handleDragEnd(DragEndDetails details)  {
    _dragTarget = null;
  }

  @override
  Widget build(BuildContext context) {
    final MaterialRectArcTween arc = new MaterialRectArcTween(begin: _begin, end: _end);
    return new RawGestureDetector(
      behavior: _dragTarget == null ? HitTestBehavior.deferToChild : HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        ImmediateMultiDragGestureRecognizer: (ImmediateMultiDragGestureRecognizer recognizer) {
          return (recognizer ??= new ImmediateMultiDragGestureRecognizer())
            ..onStart = _handleOnStart;
        }
      },
      child: new ClipRect(
        child: new CustomPaint(
          key: _painterKey,
          foregroundPainter: new _RectangleDemoPainter(
            repaint: _animation,
            arc: arc
          ),
          // Watch out: if this IgnorePointer is left out, then gestures that
          // fail _RectDemoPainter.hitTest() will still be recognized because
          // they do overlap this child, which is as big as the CustomPaint.
          child: new IgnorePointer(
            child: new Padding(
              padding: const EdgeInsets.all(16.0),
              child: new Text(
                "Tap the refresh button to run the animation. Drag the rectangles "
                "to change the animation's path.",
                style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16.0)
              )
            )
          )
        )
      )
    );
  }
}

typedef Widget _DemoBuilder(_ArcDemo demo);

class _ArcDemo {
  _ArcDemo(String _title, this.builder) : title = _title, key = new GlobalKey(debugLabel: _title);

  final AnimationController controller = new AnimationController(duration: const Duration(milliseconds: 500));
  final String title;
  final _DemoBuilder builder;
  final GlobalKey key;
}

class AnimationDemo extends StatefulWidget {
  AnimationDemo({ Key key }) : super(key: key);

  static const String routeName = '/animation';

  @override
  _AnimationDemoState createState() => new _AnimationDemoState();
}

class _AnimationDemoState extends State<AnimationDemo> {
  static final GlobalKey<TabBarSelectionState<_ArcDemo>> _tabsKey = new GlobalKey<TabBarSelectionState<_ArcDemo>>();

  static final List<_ArcDemo> _allDemos = <_ArcDemo>[
    new _ArcDemo('POINT', (_ArcDemo demo) {
      return new _PointDemo(
        key: demo.key,
        controller: demo.controller
      );
    }),
    new _ArcDemo('RECTANGLE', (_ArcDemo demo) {
      return new _RectangleDemo(
        key: demo.key,
        controller: demo.controller
      );
    })
  ];

  Future<Null> _play() async {
    _ArcDemo demo = _tabsKey.currentState.value;
    await demo.controller.forward();
    if (demo.key.currentState != null && demo.key.currentState.mounted)
      demo.controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return new TabBarSelection<_ArcDemo>(
      key: _tabsKey,
      values: _allDemos,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('Animation'),
          bottom: new TabBar<_ArcDemo>(
            labels: new Map<_ArcDemo, TabLabel>.fromIterable(_allDemos, value: (_ArcDemo demo) {
              return new TabLabel(text: demo.title);
            })
          )
        ),
        floatingActionButton: new FloatingActionButton(
          onPressed: _play,
          child: new Icon(Icons.refresh)
        ),
        body: new TabBarView<_ArcDemo>(
          children: _allDemos.map((_ArcDemo demo) => demo.builder(demo)).toList()
        )
      )
    );
  }
}
