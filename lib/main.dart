import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PickedFile pickedImage;
  var text = '';

  bool imageLoading = false;
  bool recognizing = false;

  Future takePhoto() async {
    setState(() {
      imageLoading = true;
    });

    await ImagePicker()
        .getImage(source: ImageSource.camera)
        .then((image) => setState(() {
              pickedImage = image;
              imageLoading = false;
              text = '';
            }));
  }

  Future pickImage() async {
    setState(() {
      imageLoading = true;
    });

    await ImagePicker()
        .getImage(source: ImageSource.gallery)
        .then((image) => setState(() {
              pickedImage = image;
              imageLoading = false;
              text = '';
            }));
  }

  Future recognizeText() async {
    setState(() {
      text = '';
      recognizing = true;
    });

    FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFilePath(pickedImage.path);
    TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    VisionText visionText = await textRecognizer.processImage(visionImage);

    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          setState(() {
            text = text + word.text + ' ';
          });
        }
        text = text + '\n';
      }
    }
    textRecognizer.close();
    setState(() {
      recognizing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: imageLoading
                    ? Container(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : pickedImage == null
                        ? Container(
                            child: Center(
                              child: Text('Pick an image'),
                            ),
                          )
                        : Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(blurRadius: 16),
                                ],
                              ),
                              margin: EdgeInsets.all(8),
                              child: Image.file(
                                File(pickedImage.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
              ),
              SizedBox(height: 8.0),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FlatButton.icon(
                    icon: Icon(
                      Icons.photo_camera,
                    ),
                    label: Text(''),
                    textColor: Theme.of(context).primaryColor,
                    onPressed: () async {
                      await takePhoto().then((value) {
                        if (pickedImage != null) recognizeText();
                      });
                    },
                  ),
                  FlatButton.icon(
                    icon: Icon(
                      Icons.photo_album,
                    ),
                    label: Text(''),
                    textColor: Theme.of(context).primaryColor,
                    onPressed: () async {
                      await pickImage().then((value) {
                        if (pickedImage != null) recognizeText();
                      });
                    },
                  )
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: text == ''
                        ? recognizing
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8.0),
                                  Text(
                                    'recognizing text',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              )
                            : Text(
                                'no recognized text',
                                style: TextStyle(color: Colors.red),
                              )
                        : Text(
                            text,
                            style: TextStyle(
                              color: recognizing
                                  ? Colors.pinkAccent
                                  : Colors.grey.shade700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
