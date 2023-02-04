
class ChatListModel {
  int totalSize;
  int limit;
  int offset;
  MessagesData messagesData;

  ChatListModel({this.totalSize, this.limit, this.offset, this.messagesData});

  ChatListModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
    messagesData = json['messages'] != null
        ? new MessagesData.fromJson(json['messages'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_size'] = this.totalSize;
    data['limit'] = this.limit;
    data['offset'] = this.offset;
    if (this.messagesData != null) {
      data['messages'] = this.messagesData.toJson();
    }
    return data;
  }
}

class MessagesData {
  int currentPage;
  List<Data> data;

  MessagesData({this.currentPage, this.data});

  MessagesData.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['current_page'] = this.currentPage;
    if (this.data != null) {
      data['data'] = this.data.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int orderId;
  int userId;
  int conversationsCount;
  Customer customer;

  Data({this.orderId, this.userId, this.conversationsCount, this.customer});

  Data.fromJson(Map<String, dynamic> json) {
    orderId = json['id'];
    userId = json['user_id'];
    conversationsCount = json['conversations_count'];
    customer = json['customer'] != null
        ? new Customer.fromJson(json['customer'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.orderId;
    data['user_id'] = this.userId;
    data['conversations_count'] = this.conversationsCount;
    if (this.customer != null) {
      data['customer'] = this.customer.toJson();
    }
    return data;
  }
}

class Customer {
  int id;
  String fName;
  String lName;
  String phone;
  String email;
  String image;
  String createdAt;
  String updatedAt;
  int loyaltyPoint;
  String refCode;

  Customer(
      {this.id,
        this.fName,
        this.lName,
        this.phone,
        this.email,
        this.image,
        this.createdAt,
        this.updatedAt,
        this.loyaltyPoint,
        this.refCode});

  Customer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
    image = json['image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    loyaltyPoint = json['loyalty_point'];
    refCode = json['ref_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['f_name'] = this.fName;
    data['l_name'] = this.lName;
    data['phone'] = this.phone;
    data['email'] = this.email;
    data['image'] = this.image;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['loyalty_point'] = this.loyaltyPoint;
    data['ref_code'] = this.refCode;
    return data;
  }
}
