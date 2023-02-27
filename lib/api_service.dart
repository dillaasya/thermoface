import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  String path = 'http://13.214.179.175/regis-photo';
  String pathRecog = 'http://13.214.179.175/recog-photo';

  Future<http.StreamedResponse?> postImg(File img, String title) async {
    http.StreamedResponse? response;
    //String title = 'Sigit Riyanto';
    try {
      var request = http.MultipartRequest('POST', Uri.parse(path));

      request.fields['name'] = title;
      request.files.add(http.MultipartFile.fromBytes(
          'file', File(img.path).readAsBytesSync(),
          filename: img.path));

      response = await request.send();

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('success add user!');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Can not add new user $e');
      }
    }
    return response;
  }

  Future<http.StreamedResponse?> postRecognition(File img) async {
    http.StreamedResponse? response;
    //String title = 'Adilla Syafira Putri';
    try {
      var request = http.MultipartRequest('POST', Uri.parse(pathRecog));

      //request.fields['name'] = title;
      request.files.add(http.MultipartFile.fromBytes(
          'file', File(img.path).readAsBytesSync(),
          filename: img.path));

      response = await request.send();
      /*response.stream.transform(utf8.decoder).listen((event) {
        print(event);
      });*/

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('success!');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Can not add new user $e');
      }
    }
    return response;
  }
}
