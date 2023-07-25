import 'package:fl_pip/fl_pip.dart';
import 'package:flutter/material.dart';
import 'package:pip_view/pip_view.dart';
import 'package:pod_player/pod_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FirstScreen(),
    );
  }
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key, this.enable = true});

  final bool enable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(),
        floatingActionButton: FloatingActionButton(
          onPressed: enable
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PlayVideoFromYoutube()),
                  );
                }
              : null,
          child: const Icon(Icons.arrow_right),
        ));
  }
}

class PlayVideoFromYoutube extends StatefulWidget {
  const PlayVideoFromYoutube({Key? key}) : super(key: key);

  @override
  State<PlayVideoFromYoutube> createState() => _PlayVideoFromYoutubeState();
}

class _PlayVideoFromYoutubeState extends State<PlayVideoFromYoutube>
    with WidgetsBindingObserver {
  late final PodPlayerController controller;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    if (VideoOverlay.showing() && VideoOverlay.controller() != null) {
      controller = VideoOverlay.controller()!;
    } else {
      controller = PodPlayerController(
        playVideoFrom: PlayVideoFrom.youtube(
            'https://www.youtube.com/watch?v=tlJHdLvLtfM&ab_channel=GTX1050Ti'),
      )..initialise();
    }
    VideoOverlay.hide();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!VideoOverlay.showing()) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final isBackground = state == AppLifecycleState.inactive;
    if (isBackground) {
      pipState?.stopFloating();
      if (FlPiP().status.value != PiPStatus.enabled) {
        FlPiP().enable(
            iosConfig: FlPiPiOSConfig(),
            androidConfig:
                FlPiPAndroidConfig(aspectRatio: const Rational(90, 160)));
      }
    }
  }

  PIPViewState? pipState;

  @override
  Widget build(BuildContext context) => PiPBuilder(
      pip: FlPiP(),
      builder: (PiPStatus status) {
        return Scaffold(
          appBar: FlPiP().status.value == PiPStatus.enabled
              ? null
              : AppBar(
                  leading: IconButton(
                      onPressed: () {
                        VideoOverlay.showOverlay(context, controller);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_left_outlined)),
                ),
          body: player,
        );
      });

  Widget get player => PodVideoPlayer(
        controller: controller,
        overlayBuilder: (_) => const SizedBox(),
      );

  Widget get builderDisabled => PodVideoPlayer(
        controller: controller,
        overlayBuilder: (_) => const SizedBox(),
      );

  Widget get buildUnavailable => Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            FlPiP().isAvailable;
          },
          label: const Text('PiP unavailable')),
      appBar: AppBar(title: const Text("PiP unavailable")));
}

class VideoOverlay {
  static final VideoOverlay _instance = VideoOverlay();
  OverlayEntry? _overlay;
  PodPlayerController? _controller;

  static showOverlay(BuildContext context, PodPlayerController controller) {
    hide();
    _instance._controller = controller;
    _instance._overlay = OverlayEntry(
        builder: (context) => DraggableOverlayWidget(
              height: 90 * 2,
              width: 160 * 2,
              snapThreshold: MediaQuery.of(context).size.height,
              child: PodVideoPlayer(controller: _instance._controller!),
            ));
    Overlay.maybeOf(context)?.insert(_instance._overlay!);
  }

  static hide() {
    _instance._controller = null;
    _instance._overlay?.remove();
    _instance._overlay = null;
  }

  static bool showing() {
    return _instance._overlay?.mounted ?? false;
  }

  static PodPlayerController? controller() {
    return _instance._controller;
  }
}

class DraggableOverlayWidget extends StatefulWidget {
  const DraggableOverlayWidget(
      {super.key,
      required this.child,
      required this.height,
      required this.width,
      required this.snapThreshold});

  final Widget child;
  final double height;
  final double width;
  final double snapThreshold;

  @override
  _DraggableOverlayWidgetState createState() => _DraggableOverlayWidgetState();
}

class _DraggableOverlayWidgetState extends State<DraggableOverlayWidget> {
  Offset _offset = const Offset(100, 100);
  bool _snap = false;

  _DraggableOverlayWidgetState();

  void _snapToEdge(Size screenSize) {
    double x = _offset.dx;
    double y = _offset.dy;

    if (x < widget.snapThreshold) {
      x = 0;
    } else if (x > screenSize.width - widget.snapThreshold - widget.width) {
      x = screenSize.width - widget.width;
    }
    setState(() {
      _offset = Offset(x, y);
      _snap = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return AnimatedPositioned(
      left: _offset.dx,
      top: _offset.dy,
      duration: Duration(milliseconds: _snap ? 200 : 0),
      onEnd: () {
        _snap = false;
      },
      child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _offset = Offset(
                _offset.dx + details.delta.dx,
                _offset.dy + details.delta.dy,
              );
            });
          },
          onPanEnd: (_) {
            _snapToEdge(screenSize);
          },
          child: SizedBox(
              width: widget.width, height: widget.height, child: widget.child)),
    );
  }
}
