import 'dart:async';
import 'dart:io' as io;

import 'package:audioplayers/audioplayers.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(MaterialApp(
    title: 'EAPDA',
    theme: new ThemeData(scaffoldBackgroundColor: Colors.blue[300]),
    home: MyHomePage(),
  ));
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        body: SafeArea(
          child: new RecordScreen(),
        ),
      ),
    );
  }
}

class RecorderExample extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  RecorderExample({localFileSystem})
      : this.localFileSystem = localFileSystem ?? LocalFileSystem();

  @override
  State<StatefulWidget> createState() => new RecorderExampleState();
}

class RecorderExampleState extends State<RecorderExample> {
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;

  bool _fileReceived;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fileReceived = false;
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emotion Recognition Application"),
      ),
      body: Center(
        child: new Padding(
          padding: new EdgeInsets.all(8.0),
          child: new Column(children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(30),
              child: new MaterialButton(
                onPressed: _currentStatus == RecordingStatus.Recording
                    ? null
                    : () {
                        switch (_currentStatus) {
                          case RecordingStatus.Initialized:
                            {
                              _start();
                              break;
                            }
                          case RecordingStatus.Recording:
                            {
                              _pause();
                              break;
                            }
                          case RecordingStatus.Paused:
                            {
                              _resume();
                              break;
                            }
                          case RecordingStatus.Stopped:
                            {
                              _init();
                              break;
                            }
                          default:
                            break;
                        }
                      },
                color: Colors.indigo[500],
                textColor: Colors.white,
                child: Icon(
                  Icons.settings_voice,
                  size: 160,
                ),
                padding: EdgeInsets.all(32),
                shape: CircleBorder(),
                disabledColor: Colors.indigo[300],
                disabledTextColor: Colors.grey,
              ),
            ),
            new ButtonTheme(
              minWidth: 200,
              height: 100,
              child: FlatButton(
                onPressed: _fileReceived == false ? _stop : null,
                child: new Text("Stop",
                    style: TextStyle(color: Colors.white, fontSize: 48)),
                color: Colors.red,
                disabledColor: Colors.red[200],
              ),
            ),
            SizedBox(height: 10),
            new ButtonTheme(
              minWidth: 200,
              height: 100,
              child: FlatButton(
                onPressed: _fileReceived != true
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RecordScreen()),
                        );
                      },
                child: new Text("Results",
                    style: TextStyle(color: Colors.white, fontSize: 48)),
                color: Colors.green,
                disabledColor: Colors.green[200],
              ),
            ),
            SizedBox(height: 10),
            new Text("File path of the record: ${_current?.path}"),
            SizedBox(height: 10),
            new Text("Format: ${_current?.audioFormat}"),
            SizedBox(height: 10),
            new Text("Recording Duration : ${_current?.duration.toString()}",
                style: TextStyle(fontSize: 24))
          ]),
        ),
      ),
    );
  }

  _init() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/voice_recording';
        io.Directory appDocDirectory;
//        io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = appDocDirectory.path +
            customPath +
            DateTime.now().millisecondsSinceEpoch.toString();

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        print(current);
        // should be "Initialized", if all working fine
        setState(() {
          _current = current;
          _currentStatus = current.status;
          print(_currentStatus);
        });
      } else {
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  _start() async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
        _fileReceived = false;
      });

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        // print(current.status);
        setState(() {
          _current = current;
          _currentStatus = _current.status;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  _resume() async {
    await _recorder.resume();
    setState(() {});
  }

  _pause() async {
    await _recorder.pause();
    setState(() {});
  }

  _stop() async {
    var result = await _recorder.stop();
    print("Stop recording: ${result.path}");
    print("Stop recording: ${result.duration}");
    File file = widget.localFileSystem.file(result.path);
    print("File length: ${await file.length()}");
    setState(() {
      _current = result;
      _currentStatus = _current.status;
      _fileReceived = true;
    });
  }
}

class RecordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Emotion Recognition Application"),
        ),
        body: Center(
          child: new Padding(
            padding: new EdgeInsets.all(8.0),
            child: new Column(children: <Widget>[
              new Text("Finished Recording"),
            ]),
          ),
        ));
  }
}
