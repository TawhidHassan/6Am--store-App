import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart_store/controller/auth_controller.dart';
import 'package:sixam_mart_store/data/api/api_checker.dart';
import 'package:sixam_mart_store/data/api/api_client.dart';
import 'package:sixam_mart_store/data/model/body/notification_body.dart';
import 'package:sixam_mart_store/data/model/response/conversation_model.dart';
import 'package:sixam_mart_store/data/model/response/message_model.dart';
import 'package:sixam_mart_store/data/repository/chat_repo.dart';
import 'package:sixam_mart_store/helper/user_type.dart';

class ChatController extends GetxController implements GetxService{
  final ChatRepo chatRepo;
  ChatController({@required this.chatRepo});

  List<bool> _showDate;
  List<XFile> _imageFiles;
  bool _isSendButtonActive = false;
  bool _isSeen = false;
  bool _isSend = true;
  bool _isMe = false;
  bool _isLoading= false;
  List <XFile>_chatImage = [];
  int _pageSize;
  int _offset;
  ConversationsModel _conversationModel ;
  ConversationsModel _searchConversationModel;
  MessageModel _messageModel;

  bool get isLoading => _isLoading;
  List<bool> get showDate => _showDate;
  List<XFile> get imageFiles => _imageFiles;
  bool get isSendButtonActive => _isSendButtonActive;
  bool get isSeen => _isSeen;
  bool get isSend => _isSend;
  bool get isMe => _isMe;
  int get pageSize => _pageSize;
  int get offset => _offset;
  List<XFile> get chatImage => _chatImage;
  ConversationsModel get conversationModel => _conversationModel;
  ConversationsModel get searchConversationModel => _searchConversationModel;
  MessageModel get messageModel => _messageModel;

  Future<void> getConversationList(int offset) async{
    _searchConversationModel = null;
    Response response = await chatRepo.getConversationList(offset);
    if(response.statusCode == 200) {
      if(offset == 1) {
        _conversationModel = ConversationsModel.fromJson(response.body);
      }else {
        _conversationModel.totalSize = ConversationsModel.fromJson(response.body).totalSize;
        _conversationModel.offset = ConversationsModel.fromJson(response.body).offset;
        _conversationModel.conversations.addAll(ConversationsModel.fromJson(response.body).conversations);
      }
    }else {
      ApiChecker.checkApi(response);
    }
    update();

  }
  Future<void> searchConversation(String name) async {
    _searchConversationModel = ConversationsModel();
    update();
    Response response = await chatRepo.searchConversationList(name);
    if(response.statusCode == 200) {
      print(response.body);
      _searchConversationModel = ConversationsModel.fromJson(response.body);
    }else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  void removeSearchMode() {
    _searchConversationModel = null;
    update();
  }

  Future<void> getMessages(int offset, NotificationBody notificationBody, User user, int conversationID, {bool firstLoad = false}) async {
    Response _response;
    if(firstLoad) {
      _messageModel = null;
    }

    if(notificationBody.customerId != null || notificationBody.type == UserType.customer.name || notificationBody.type == UserType.user.name) {
      _response = await chatRepo.getMessages(offset, notificationBody.customerId, UserType.user, conversationID);
    }else if(notificationBody.deliveryManId != null || notificationBody.type == UserType.delivery_man.name) {
      _response = await chatRepo.getMessages(offset, notificationBody.deliveryManId, UserType.delivery_man, conversationID);
    }

    if (_response != null && _response.body['messages'] != {} && _response.statusCode == 200) {
      if (offset == 1) {
        if(Get.find<AuthController>().profileModel == null) {
          await Get.find<AuthController>().getProfile();
        }
        _messageModel = MessageModel.fromJson(_response.body);
        if(_messageModel.conversation == null && user != null) {
          _messageModel.conversation = Conversation(sender: User(
            id: Get.find<AuthController>().profileModel.id, image: Get.find<AuthController>().profileModel.image,
            fName: Get.find<AuthController>().profileModel.fName, lName: Get.find<AuthController>().profileModel.lName,
          ), receiver: user);
        }else if(_messageModel.conversation != null && _messageModel.conversation.receiverType == 'vendor') {
          User _receiver = _messageModel.conversation.receiver;
          _messageModel.conversation.receiver = _messageModel.conversation.sender;
          _messageModel.conversation.sender = _receiver;
        }
      }else {
        _messageModel.totalSize = MessageModel.fromJson(_response.body).totalSize;
        _messageModel.offset = MessageModel.fromJson(_response.body).offset;
        _messageModel.messages.addAll(MessageModel.fromJson(_response.body).messages);
      }
    } else {
      ApiChecker.checkApi(_response);
    }
    _isLoading = false;
    update();

  }


  void pickImage(bool isRemove) async {
    if(isRemove) {
      _imageFiles = [];
      _chatImage = [];
    }else {
      _imageFiles = await ImagePicker().pickMultiImage(imageQuality: 40);
      if (_imageFiles != null) {
        _chatImage = imageFiles;
        _isSendButtonActive = true;
      }
    }
    update();
  }
  void removeImage(int index){
    chatImage.removeAt(index);
    update();
  }

  Future<Response> sendMessage({@required String message, @required NotificationBody notificationBody, @required int conversationId}) async {
    Response _response;
    _isLoading = true;
    update();

    List<MultipartBody> _myImages = [];
    _chatImage.forEach((image) {
      _myImages.add(MultipartBody('image[]', image));
    });

    if(notificationBody != null && (notificationBody.customerId != null || notificationBody.type == UserType.customer.name)) {
      _response = await chatRepo.sendMessage(message, _myImages, conversationId , notificationBody.customerId, UserType.customer);
    }
    else if(notificationBody != null && (notificationBody.deliveryManId != null || notificationBody.type == UserType.delivery_man.name)){
      _response = await chatRepo.sendMessage(message, _myImages, conversationId , notificationBody.deliveryManId, UserType.delivery_man);
    }

    if (_response.statusCode == 200) {
      _imageFiles = [];
      _chatImage = [];
      _isSendButtonActive = false;
      _isLoading = false;
      _messageModel = MessageModel.fromJson(_response.body);
      if(_messageModel.conversation != null && _messageModel.conversation.receiverType == 'vendor') {
        User _receiver = _messageModel.conversation.receiver;
        _messageModel.conversation.receiver = _messageModel.conversation.sender;
        _messageModel.conversation.sender = _receiver;
      }
    }

    _imageFiles = [];
    _chatImage = [];
    update();
    return _response;
  }

  void toggleSendButtonActivity() {
    _isSendButtonActive = !_isSendButtonActive;
    update();
  }

  void setImageList(List<XFile> images) {
    _imageFiles = [];
    _imageFiles = images;
    _isSendButtonActive = true;
    update();
  }

  void setIsMe(bool value) {
    _isMe = value;
  }

}