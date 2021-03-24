import 'dart:async';

//import 'package:tensorflow_lite_flutter/models/result.dart';
import 'package:tflite/tflite.dart';

class TFliteHelper {
  static var modelLoaded = false;

  static Future<String> loadModel() async {
    return Tflite.loadModel(model: "assets/model.tflite");
  }void initState()P
  super.initState();
  TFLiteHelper.loadModel().then((value){
    setState((){
      modelLoaded = True
    });
  });
}


static void disposeModel(){
  Tflite.close();
  tfLiteResultsController.close();
}
