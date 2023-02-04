import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart_store/data/api/api_client.dart';
import 'package:sixam_mart_store/data/model/response/delivery_man_model.dart';
import 'package:sixam_mart_store/util/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class DeliveryManRepo {
  final ApiClient apiClient;
  DeliveryManRepo({@required this.apiClient});
  
  Future<Response> getDeliveryManList() async {
    return await apiClient.getData(AppConstants.DM_LIST_URI);
  }

  Future<Response> addDeliveryMan(DeliveryManModel deliveryMan, String pass, XFile image, List<XFile> identities, String token, bool isAdd) async {
    http.MultipartRequest request = http.MultipartRequest(
        'POST', Uri.parse('${AppConstants.BASE_URL}${isAdd ? AppConstants.ADD_DM_URI : '${AppConstants.UPDATE_DM_URI}${deliveryMan.id}'}',
    ));
    request.headers.addAll(<String,String>{'Authorization': 'Bearer $token'});
    if(GetPlatform.isMobile && image != null) {
      File _file = File(image.path);
      request.files.add(http.MultipartFile('image', _file.readAsBytes().asStream(), _file.lengthSync(), filename: _file.path.split('/').last));
    }
    if(GetPlatform.isMobile && identities != null && identities.length > 0) {
      identities.forEach((identity) {
        File _file = File(identity.path);
        request.files.add(http.MultipartFile('identity_image[]', _file.readAsBytes().asStream(), _file.lengthSync(), filename: _file.path.split('/').last));
      });
    }
    Map<String, String> _fields = Map();
    _fields.addAll(<String, String>{
      'f_name': deliveryMan.fName, 'l_name': deliveryMan.lName, 'email': deliveryMan.email, 'password': pass,
      'phone': deliveryMan.phone, 'identity_type': deliveryMan.identityType, 'identity_number': deliveryMan.identityNumber,
    });
    request.fields.addAll(_fields);
    print('=====> ${request.url.path}\n'+request.fields.toString());
    http.StreamedResponse response = await request.send();
    return Response(statusCode: response.statusCode, statusText: response.reasonPhrase);
  }

  Future<Response> updateDeliveryMan(DeliveryManModel deliveryManModel) async {
    return await apiClient.postData('${AppConstants.UPDATE_DM_URI}${deliveryManModel.id}', deliveryManModel.toJson());
  }

  Future<Response> deleteDeliveryMan(int deliveryManID) async {
    return await apiClient.postData(AppConstants.DELETE_DM_URI, {'_method': 'delete', 'delivery_man_id': deliveryManID});
  }

  Future<Response> updateDeliveryManStatus(int deliveryManID, int status) async {
    return await apiClient.getData('${AppConstants.UPDATE_DM_STATUS_URI}?delivery_man_id=$deliveryManID&status=$status');
  }

  Future<Response> getDeliveryManReviews(int deliveryManID) async {
    return await apiClient.getData('${AppConstants.DM_REVIEW_URI}?delivery_man_id=$deliveryManID');
  }

}