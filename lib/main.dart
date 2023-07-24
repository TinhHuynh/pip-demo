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
    controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.youtube(
          'https://www.youtube.com/watch?v=tlJHdLvLtfM&ab_channel=GTX1050Ti'),
    )..initialise();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final isBackground = state == AppLifecycleState.inactive;
    if (isBackground) {
      pipState?.stopFloating();
      if(FlPiP().status.value != PiPStatus.enabled){
        FlPiP().enable(
            iosConfig: FlPiPiOSConfig(),
            androidConfig:
            FlPiPAndroidConfig(aspectRatio: const Rational.vertical()));
      }
    }
  }

  PIPViewState? pipState;

  @override
  Widget build(BuildContext context) => PIPView(builder: (context, isFloating) {
        return PiPBuilder(
            pip: FlPiP(),
            builder: (PiPStatus status) {
              return Scaffold(
                appBar: isFloating || FlPiP().status.value == PiPStatus.enabled
                    ? null
                    : AppBar(
                        leading: IconButton(
                            onPressed: () {
                              FlPiP().enable(
                                  iosConfig: FlPiPiOSConfig(),
                                  androidConfig:
                                  FlPiPAndroidConfig(aspectRatio: const Rational.vertical()));
                            },
                            icon: const Icon(Icons.arrow_left_outlined)),
                      ),
                body: player,
              );
            });
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
