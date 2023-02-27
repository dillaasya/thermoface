import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras[1];

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  File? image;
  final TextEditingController _name = new TextEditingController();
  bool showStatusBar = false;
  String nama = "";

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.high,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  Future<void> submit(String str) async {
    try {
      final service = ApiService();
      //await service.postImg(image!);
      final response = await service.postImg(image!, str);
      response!.stream.transform(utf8.decoder).listen((event) {
        print(event);
      });
    } catch (e) {
      print('EROR : $e');
    }
  }

  Future<void> submitRecog() async {
    try {
      final service = ApiService();
      final response = await service.postRecognition(image!);
      response!.stream.transform(utf8.decoder).listen((event) {
        print(event);
        final parsedJson = jsonDecode(event);
        nama = parsedJson['output'];
      });
    } catch (e) {
      print('EROR : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('THERMOMAFACE')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return Container(
              constraints: const BoxConstraints.expand(),
              child: _controller == null
                  ? const Center(child: null)
                  : Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CameraPreview(_controller),
                  //_buildResults(),
                  Align(
                    alignment: Alignment.center,
                    child: Image(
                      image: AssetImage("images/blue_rect.png"),
                      fit: BoxFit.fill,
                      width: 320,
                      height: 320,
                    ),
                  ),
                  !showStatusBar
                      ? Align()
                      : Align(
                    child: ListView(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(20),
                          margin: new EdgeInsets.only(
                            right: 0.0,
                            left: 0.0,
                            top: 0.0,
                          ),
                          width: 800.0,
                          height: 80.0,
                          alignment: Alignment.center,
                          color: Color.fromARGB(255, 52, 188, 157),
                          //color: getColor(xwarna),
                          child: Column(
                            //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Text(
                                nama,
                                style: TextStyle(
                                  decoration: TextDecoration.none,
                                  fontSize: 32,
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
            //CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton:
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          backgroundColor: Colors.blue,
          child: Icon(Icons.camera_alt),
          onPressed: () async {
            try {
              final image1 = await _controller.takePicture();
              image = File(image1.path);
              await submitRecog();
              setState(() {
                showStatusBar = true;
              });
            } catch (e) {
              print(e);
            }
          },
          heroTag: null,
        ),
        SizedBox(
          width: 10,
        ),
        FloatingActionButton(
          backgroundColor: Colors.blue,
          child: Icon(Icons.add),
          onPressed: () async {
            try {
              final image1 = await _controller.takePicture();
              image = File(image1.path);
              _addLabel();
            } catch (e) {
              print(e);
            }
          },
          heroTag: null,
        ),
        SizedBox(
          width: 10,
        ),
      ]),
    );
  }

  void _addLabel() {
    print("Adding new face");
    var alert = new AlertDialog(
      title: new Text("Add Face"),
      content: new Column(
        children: <Widget>[
          new Expanded(
            child: new TextField(
              controller: _name,
              autofocus: true,
              decoration: new InputDecoration(
                //labelText: "NAMA", icon: new Icon(Icons.face)),
                  border: OutlineInputBorder(),
                  labelText: "NAME"),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        new TextButton(
            child: Text("Send"),
            onPressed: () {
              submit(_name.text.toUpperCase());
              Navigator.pop(context);
            }),
        new TextButton(
          child: Text("Cancel"),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ],
    );
    showDialog(
        context: context,
        builder: (context) {
          return alert;
        });
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
        child: Column(
          children: [
            Text("str"),
            Image.file(File(imagePath)),
          ],
        ),
      ),
    );
  }
}
