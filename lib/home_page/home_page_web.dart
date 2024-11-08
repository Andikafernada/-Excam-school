import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePageWeb extends StatefulWidget {
  const HomePageWeb({super.key});

  @override
  State<HomePageWeb> createState() => _HomePageWebState();
}

class _HomePageWebState extends State<HomePageWeb> {
  final player = AudioPlayer();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String currentEmail = '';
  final WebViewController webViewController = WebViewController();
  static const String reg =
      r'^(https?:\/\/)?((www\.)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}|localhost|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))(\/[^\s]*)?$';
  bool isValidate = true;
  static const MethodChannel platform = MethodChannel('kiosk_mode_channel');

  @override
  void dispose() {
    _nameController.dispose();
    webViewController.clearCache();
    super.dispose();
  }

  void webView(String url) {
    try {
      webViewController
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onHttpError: (error) {
              debugPrint('on http Error ');
              showAdaptiveDialog(
                context: context,
                builder: (context) {
                  return AlertDialog.adaptive(
                    title: const Text("on http error"),
                    content: Text(
                        "respon status code ${error.response!.statusCode}"),
                    actions: [
                      FloatingActionButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("yes"),
                      ),
                    ],
                  );
                },
              );
            },
            onWebResourceError: (error) {
              debugPrint('on web resourece error ');
              showAdaptiveDialog(
                context: context,
                builder: (context) {
                  return AlertDialog.adaptive(
                    title: const Text("error on web resource"),
                    content: Text("${error.description} "),
                    actions: [
                      FloatingActionButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("yes"),
                      ),
                    ],
                  );
                },
              );
            },
            onProgress: (progress) {
              showAdaptiveDialog(
                context: context,
                builder: (context) {
                  Future.delayed(
                    const Duration(seconds: 10),
                    () {
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                  );
                  return AlertDialog.adaptive(
                    title: const Text("Progress"),
                    content: Row(
                      children: [
                        Text(
                          "this process $progress",
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(
                          width: 50,
                        ),
                        const CircularProgressIndicator.adaptive(),
                      ],
                    ),
                  );
                },
              );
              debugPrint('on progress');
            },
          ),
        )
        ..addJavaScriptChannel(
          'Toaster',
          onMessageReceived: (JavaScriptMessage message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message.message)),
            );
          },
        )
        ..loadRequest(
          Uri.parse(url),
        );
    } catch (e, s) {
      debugPrint("$e");
      debugPrint("$s");
    }
  }

  void _sumbit(BuildContext content) {
    try {
      if (_formKey.currentState!.validate()) {
        webView(_nameController.text);
        debugPrint(currentEmail);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.white,
            content: Text(
              'Validation Successful',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        );
        setState(
          () {
            isValidate = false;
          },
        );
        Timer(
          const Duration(seconds: 10),
          () => start(context),
        );
      }
    } catch (e, s) {
      debugPrint("$e");
      debugPrint("$s");
    }
  }

  void audio() async {
    VolumeController().getVolume().then(
      (value) {
        debugPrint("$value");
        if (value < 1.0) {
          VolumeController().setVolume(0.5);
          debugPrint("$value < 1.0");
        }
      },
    );
    try {
      player.setAsset('assets/song/alert-audio.mp3');
      player.setVolume(1.0);
      player.setLoopMode(LoopMode.one);
      player.play();
      debugPrint("start");
      Timer(
        const Duration(seconds: 10),
        () {
          player.stop();
          debugPrint("stop");
        },
      );
    } catch (e, s) {
      debugPrint("$e");
      debugPrint("$s");
    }
  }

  void end(BuildContext context) async {
    try {
      await platform.invokeMethod("stopKioskMode");
      debugPrint("Kiosk Mode stopped");

      if (!context.mounted) {
        return;
      }
    } on PlatformException catch (e) {
      debugPrint("Error stopping kiosk mode: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to stop kiosk mode: ${e.message}")),
      );
    }
  }

  void start(BuildContext context) async {
    try {
      await platform.invokeMethod('startKioskMode');
      debugPrint("Kiosk Mode started");

      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          Future.delayed(
            const Duration(seconds: 10),
            () {
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pop();
            },
          );
          return const AlertDialog(
            title: Text('this kiosk mode is active'),
          );
        },
      );

      if (!context.mounted) {
        return;
      }
    } on PlatformException catch (e) {
      debugPrint("Error starting kiosk mode: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start kiosk mode: ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("EXCAM APP"),
        actions: [
          if (!isValidate)
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    audio();
                    showAdaptiveDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog.adaptive(
                          content: const Text("you want to leave"),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                end(context);
                                Navigator.of(context).pop();
                              },
                              child: const Text("yes"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("cancel"),
                            )
                          ],
                        );
                      },
                    );
                  },
                  child: const Text("EXIT"),
                ),
              ],
            ),
        ],
      ),
      body: Container(
        color: Colors.amber,
        child: Stack(
          children: [
            if (isValidate) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              focusColor: Colors.white,
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 2.0),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              border: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 2.0),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 2.0),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              hintText: 'web url',
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            keyboardType: TextInputType.url,
                            controller: _nameController,
                            validator: (value) {
                              if (!value!.contains(RegExp(reg))) {
                                return 'masukan url yang benar';
                              }
                              if (value.isEmpty) {
                                return 'input tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 20,
                              left: 10,
                              right: 10,
                            ),
                            child: ElevatedButton(
                              onPressed: () => _sumbit(context),
                              child: const Text("NEXT"),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              SingleChildScrollView(
                child: Column(children: [
                  Container(
                    width: size.width,
                    height: size.height,
                    color: Colors.blue[600],
                    child: WebViewWidget(controller: webViewController),
                  )
                ]),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                color: Colors.blue[50],
                height: 20,
                width: size.width,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("creator"),
                    SizedBox(
                      width: 20,
                    ),
                    Text("data"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
