import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart_store/controller/splash_controller.dart';
import 'package:sixam_mart_store/data/api/api_checker.dart';
import 'package:sixam_mart_store/data/model/body/module_permission_body.dart';
import 'package:sixam_mart_store/data/model/body/store_body.dart';
import 'package:sixam_mart_store/data/model/response/address_model.dart';
import 'package:sixam_mart_store/data/model/response/module_model.dart';
import 'package:sixam_mart_store/data/model/response/place_details_model.dart';
import 'package:sixam_mart_store/data/model/response/prediction_model.dart';
import 'package:sixam_mart_store/data/model/response/profile_model.dart';
import 'package:sixam_mart_store/data/model/response/response_model.dart';
import 'package:sixam_mart_store/data/model/response/zone_model.dart';
import 'package:sixam_mart_store/data/model/response/zone_response_model.dart';
import 'package:sixam_mart_store/data/repository/auth_repo.dart';
import 'package:sixam_mart_store/helper/route_helper.dart';
import 'package:sixam_mart_store/view/base/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AuthController extends GetxController implements GetxService {
  final AuthRepo authRepo;
  AuthController({@required this.authRepo}) {
   _notification = authRepo.isNotificationActive();
  }

  bool _isLoading = false;
  bool _notification = true;
  ProfileModel _profileModel;
  XFile _pickedFile;

  XFile _pickedLogo;
  XFile _pickedCover;
  LatLng _restaurantLocation;
  int _selectedZoneIndex = 0;
  List<ZoneModel> _zoneList;
  List<int> _zoneIds;
  List<PredictionModel> _predictionList = [];
  Position _pickPosition = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1);
  String _pickAddress = '';
  bool _loading = false;
  bool _inZone = false;
  int _zoneID = 0;
  List<String> _deliveryTimeTypeList = ['minute', 'hours', 'days'];
  int _deliveryTimeTypeIndex = 0;
  List<ModuleModel> _moduleList;
  int _selectedModuleIndex = 0;
  int _vendorTypeIndex = 0;
  ModulePermissionBody _modulePermissionBody;

  bool get isLoading => _isLoading;
  bool get notification => _notification;
  ProfileModel get profileModel => _profileModel;
  XFile get pickedFile => _pickedFile;

  XFile get pickedLogo => _pickedLogo;
  XFile get pickedCover => _pickedCover;
  LatLng get restaurantLocation => _restaurantLocation;
  int get selectedZoneIndex => _selectedZoneIndex;
  List<ZoneModel> get zoneList => _zoneList;
  List<int> get zoneIds => _zoneIds;
  List<PredictionModel> get predictionList => _predictionList;
  String get pickAddress => _pickAddress;
  bool get loading => _loading;
  bool get inZone => _inZone;
  int get zoneID => _zoneID;
  List<String> get deliveryTimeTypeList => _deliveryTimeTypeList;
  int get deliveryTimeTypeIndex => _deliveryTimeTypeIndex;
  List<ModuleModel> get moduleList => _moduleList;
  int get selectedModuleIndex => _selectedModuleIndex;
  int get vendorTypeIndex => _vendorTypeIndex;
  ModulePermissionBody get modulePermission => _modulePermissionBody;

  void changeVendorType(int index, {bool isUpdate = true}){
    _vendorTypeIndex = index;
    print(_vendorTypeIndex);
    if(isUpdate) {
      update();
    }
  }

  void selectModuleIndex(int index) {
    _selectedModuleIndex = index;
    update();
  }

  Future<ResponseModel> login(String email, String password, String type) async {
    _isLoading = true;
    update();
    Response response = await authRepo.login(email, password, type);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      authRepo.saveUserToken(response.body['token'], response.body['zone_wise_topic'], type);
      if(response.body['role'] != null && type == 'employee'){
      }
      await authRepo.updateToken();
      getProfile();
      responseModel = ResponseModel(true, 'successful');
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<void> getProfile() async {
    Response response = await authRepo.getProfileInfo();
    if (response.statusCode == 200) {
      _profileModel = ProfileModel.fromJson(response.body);
      Get.find<SplashController>().setModule(_profileModel.stores[0].module.id, _profileModel.stores[0].module.moduleType);
      authRepo.updateHeader(_profileModel.stores[0].module.id);
      allowModulePermission(_profileModel.roles);
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  void allowModulePermission(List<String> roles) {
    print('----------permission-------->>$roles');
    if(roles != null && roles.isNotEmpty){
      List<String> module = roles;
      print(module);
      _modulePermissionBody = ModulePermissionBody(
        item: module.contains('item'),
        order: module.contains('order'),
        storeSetup: module.contains('store_setup'),
        addon: module.contains('addon'),
        wallet: module.contains('wallet'),
        bankInfo: module.contains('bank_info'),
        employee: module.contains('employee'),
        myShop: module.contains('my_shop'),
        customRole: module.contains('custom_role'),
        campaign: module.contains('campaign'),
        reviews: module.contains('reviews'),
        pos: module.contains('pos'),
        chat: module.contains('chat'),
      );
    }else{
      _modulePermissionBody = ModulePermissionBody(item: true, order: true, storeSetup: true, addon: true, wallet: true,
        bankInfo: true, employee: true, myShop: true, customRole: true, campaign: true, reviews: true, pos: true, chat: true,
      );
    }
  }

  Future<bool> updateUserInfo(ProfileModel updateUserModel, String token) async {
    _isLoading = true;
    update();
    Response response = await authRepo.updateProfile(updateUserModel, _pickedFile, token);
    _isLoading = false;
    bool _isSuccess;
    if (response.statusCode == 200) {
      _profileModel = updateUserModel;
      showCustomSnackBar('profile_updated_successfully'.tr, isError: false);
      _isSuccess = true;
    } else {
      ApiChecker.checkApi(response);
      _isSuccess = false;
    }
    update();
    return _isSuccess;
  }

  void pickImage() async {
    XFile _picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(_picked != null) {
      _pickedFile = _picked;
    }
    update();
  }

  void pickImageForReg(bool isLogo, bool isRemove) async {
    if(isRemove) {
      _pickedLogo = null;
      _pickedCover = null;
    }else {
      if (isLogo) {
        _pickedLogo = await ImagePicker().pickImage(source: ImageSource.gallery);
      } else {
        _pickedCover = await ImagePicker().pickImage(source: ImageSource.gallery);
      }
      update();
    }
  }

  Future<bool> changePassword(ProfileModel updatedUserModel, String password) async {
    _isLoading = true;
    update();
    bool _isSuccess;
    Response response = await authRepo.changePassword(updatedUserModel, password);
    _isLoading = false;
    if (response.statusCode == 200) {
      Get.back();
      showCustomSnackBar('password_updated_successfully'.tr, isError: false);
      _isSuccess = true;
    } else {
      ApiChecker.checkApi(response);
      _isSuccess = false;
    }
    update();
    return _isSuccess;
  }

  Future<ResponseModel> forgetPassword(String email) async {
    _isLoading = true;
    update();
    Response response = await authRepo.forgetPassword(email);

    ResponseModel responseModel;
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<void> updateToken() async {
    await authRepo.updateToken();
  }

  Future<ResponseModel> verifyToken(String email) async {
    _isLoading = true;
    update();
    Response response = await authRepo.verifyToken(email, _verificationCode);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<ResponseModel> resetPassword(String resetToken, String email, String password, String confirmPassword) async {
    _isLoading = true;
    update();
    Response response = await authRepo.resetPassword(resetToken, email, password, confirmPassword);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  String _verificationCode = '';

  String get verificationCode => _verificationCode;

  void updateVerificationCode(String query) {
    _verificationCode = query;
    update();
  }


  bool _isActiveRememberMe = false;

  bool get isActiveRememberMe => _isActiveRememberMe;

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    update();
  }

  bool isLoggedIn() {
    return authRepo.isLoggedIn();
  }

  Future<bool> clearSharedData() async {
    Get.find<SplashController>().setModule(null, null);
    return await authRepo.clearSharedData();
  }

  void saveUserNumberAndPassword(String number, String password, String type) {
    authRepo.saveUserNumberAndPassword(number, password, type);
  }

  String getUserNumber() {
    return authRepo.getUserNumber() ?? "";
  }
  String getUserPassword() {
    return authRepo.getUserPassword() ?? "";
  }
  String getUserType() {
    return authRepo.getUserType() ?? "";
  }

  Future<bool> clearUserNumberAndPassword() async {
    return authRepo.clearUserNumberAndPassword();
  }

  String getUserToken() {
    return authRepo.getUserToken();
  }

  bool setNotificationActive(bool isActive) {
    _notification = isActive;
    authRepo.setNotificationActive(isActive);
    update();
    return _notification;
  }

  void initData() {
    _pickedFile = null;
  }

  Future<void> toggleStoreClosedStatus() async {
    Response response = await authRepo.toggleStoreClosedStatus();
    if (response.statusCode == 200) {
      getProfile();
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future removeVendor() async {
    _isLoading = true;
    update();
    Response response = await authRepo.deleteVendor();
    _isLoading = false;
    if (response.statusCode == 200) {
      showCustomSnackBar('your_account_remove_successfully'.tr,isError: false);
      Get.find<AuthController>().clearSharedData();
      Get.offAllNamed(RouteHelper.getSignInRoute());
    }else{
      Get.back();
      ApiChecker.checkApi(response);
    }
  }

  Future<void> getZoneList() async {
    _pickedLogo = null;
    _pickedCover = null;
    _selectedZoneIndex = 0;
    _restaurantLocation = null;
    _zoneIds = null;
    Response response = await authRepo.getZoneList();
    if (response.statusCode == 200) {
      _zoneList = [];
      response.body.forEach((zone) => _zoneList.add(ZoneModel.fromJson(zone)));
      print('zone list -----------$_zoneList');
      await getModules(_zoneList[0].id);
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> registerStore(StoreBody storeBody) async {
    _isLoading = true;
    update();
    Response response = await authRepo.registerRestaurant(storeBody, _pickedLogo, _pickedCover);
    if(response.statusCode == 200) {
      Get.offAllNamed(RouteHelper.getInitialRoute());
      showCustomSnackBar('restaurant_registration_successful'.tr, isError: false);
    }else {
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }

  Future<void> setZoneIndex(int index) async {
    _selectedZoneIndex = index;
    await getModules(zoneList[selectedZoneIndex].id);
    update();
  }

  void setLocation(LatLng location) async{
    ZoneResponseModel _response = await getZone(
      location.latitude.toString(), location.longitude.toString(), false,
    );
    if(_response != null && _response.isSuccess && _response.zoneIds.length > 0) {
      _restaurantLocation = location;
      _zoneIds = _response.zoneIds;
      for(int index=0; index<_zoneList.length; index++) {
        if(_zoneIds.contains(_zoneList[index].id)) {
          _selectedZoneIndex = index;
          break;
        }
      }
    }else {
      _restaurantLocation = null;
      _zoneIds = null;
    }
    update();
  }

  Future<void> zoomToFit(GoogleMapController controller, List<LatLng> list, {double padding = 0.5}) async {
    LatLngBounds _bounds = _computeBounds(list);
    LatLng _centerBounds = LatLng(
      (_bounds.northeast.latitude + _bounds.southwest.latitude)/2,
      (_bounds.northeast.longitude + _bounds.southwest.longitude)/2,
    );

    if(controller != null) {
      controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _centerBounds, zoom: GetPlatform.isWeb ? 10 : 16)));
    }

    bool keepZoomingOut = true;

    int _count = 0;
    while(keepZoomingOut) {
      _count++;
      final LatLngBounds screenBounds = await controller.getVisibleRegion();
      if(_fits(_bounds, screenBounds) || _count == 200) {
        keepZoomingOut = false;
        final double zoomLevel = await controller.getZoomLevel() - padding;
        controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: _centerBounds,
          zoom: zoomLevel,
        )));
        break;
      }
      else {
        // Zooming out by 0.1 zoom level per iteration
        final double zoomLevel = await controller.getZoomLevel() - 0.1;
        controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: _centerBounds,
          zoom: zoomLevel,
        )));
      }
    }
  }

  bool _fits(LatLngBounds fitBounds, LatLngBounds screenBounds) {
    final bool northEastLatitudeCheck = screenBounds.northeast.latitude >= fitBounds.northeast.latitude;
    final bool northEastLongitudeCheck = screenBounds.northeast.longitude >= fitBounds.northeast.longitude;

    final bool southWestLatitudeCheck = screenBounds.southwest.latitude <= fitBounds.southwest.latitude;
    final bool southWestLongitudeCheck = screenBounds.southwest.longitude <= fitBounds.southwest.longitude;

    return northEastLatitudeCheck && northEastLongitudeCheck && southWestLatitudeCheck && southWestLongitudeCheck;
  }

  LatLngBounds _computeBounds(List<LatLng> list) {
    assert(list.isNotEmpty);
    var firstLatLng = list.first;
    var s = firstLatLng.latitude,
        n = firstLatLng.latitude,
        w = firstLatLng.longitude,
        e = firstLatLng.longitude;
    for (var i = 1; i < list.length; i++) {
      var latlng = list[i];
      s = min(s, latlng.latitude);
      n = max(n, latlng.latitude);
      w = min(w, latlng.longitude);
      e = max(e, latlng.longitude);
    }
    return LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e));
  }

  Future<List<PredictionModel>> searchLocation(BuildContext context, String text) async {
    if(text != null && text.isNotEmpty) {
      Response response = await authRepo.searchLocation(text);
      if (response.statusCode == 200 && response.body['status'] == 'OK') {
        _predictionList = [];
        response.body['predictions'].forEach((prediction) => _predictionList.add(PredictionModel.fromJson(prediction)));
      } else {
        showCustomSnackBar(response.body['error_message'] ?? response.bodyString);
      }
    }
    return _predictionList;
  }

  Future<Position> setSuggestedLocation(String placeID, String address, GoogleMapController mapController) async {
    _isLoading = true;
    update();

    LatLng _latLng = LatLng(0, 0);
    Response response = await authRepo.getPlaceDetails(placeID);
    if(response.statusCode == 200) {
      PlaceDetailsModel _placeDetails = PlaceDetailsModel.fromJson(response.body);
      if(_placeDetails.status == 'OK') {
        _latLng = LatLng(_placeDetails.result.geometry.location.lat, _placeDetails.result.geometry.location.lng);
      }
    }

    _pickPosition = Position(
      latitude: _latLng.latitude, longitude: _latLng.longitude,
      timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1,
    );

    _pickAddress = address;

    if(mapController != null) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _latLng, zoom: 16)));
    }
    _isLoading = false;
    update();
    return _pickPosition;
  }

  Future<ZoneResponseModel> getZone(String lat, String long, bool markerLoad, {bool updateInAddress = false}) async {
    if(markerLoad) {
      _loading = true;
    }else {
      _isLoading = true;
    }

    if(!updateInAddress){
      update();
    }
    ZoneResponseModel _responseModel;
    Response response = await authRepo.getZone(lat, long);
    if(response.statusCode == 200) {
      _inZone = true;
      _zoneID = int.parse(jsonDecode(response.body['zone_id'])[0].toString());
      List<int> _zoneIds = [];
      jsonDecode(response.body['zone_id']).forEach((zoneId){
        _zoneIds.add(int.parse(zoneId.toString()));
      });
      _responseModel = ZoneResponseModel(true, '' , _zoneIds);

    }else {
      _inZone = false;
      _responseModel = ZoneResponseModel(false, response.statusText, []);
    }
    if(markerLoad) {
      _loading = false;
    }else {
      _isLoading = false;
    }
    update();
    return _responseModel;
  }

  Future<bool> saveUserAddress(AddressModel address) async {
    String userAddress = jsonEncode(address.toJson());
    return await authRepo.saveUserAddress(userAddress, address.zoneIds);
  }

  AddressModel getUserAddress() {
    AddressModel _addressModel;
    try {
      _addressModel = AddressModel.fromJson(jsonDecode(authRepo.getUserAddress()));
    }catch(e) {}
    return _addressModel;
  }

  void setDeliveryTimeTypeIndex(String type, bool notify) {
    _deliveryTimeTypeIndex = _deliveryTimeTypeList.indexOf(type);
    if(notify) {
      update();
    }
  }

  Future<void> getModules(int zoneId) async {
    Response response = await authRepo.getModules(zoneId);
    if (response.statusCode == 200) {
      _moduleList = [];
      response.body.forEach((storeCategory) => _moduleList.add(ModuleModel.fromJson(storeCategory)));
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }
}