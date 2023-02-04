import 'dart:async';
import 'package:photo_view/photo_view.dart';
import 'package:sixam_mart_store/controller/auth_controller.dart';
import 'package:sixam_mart_store/controller/localization_controller.dart';
import 'package:sixam_mart_store/controller/order_controller.dart';
import 'package:sixam_mart_store/controller/splash_controller.dart';
import 'package:sixam_mart_store/data/model/body/notification_body.dart';
import 'package:sixam_mart_store/data/model/response/conversation_model.dart';
import 'package:sixam_mart_store/data/model/response/order_details_model.dart';
import 'package:sixam_mart_store/data/model/response/order_model.dart';
import 'package:sixam_mart_store/helper/date_converter.dart';
import 'package:sixam_mart_store/helper/price_converter.dart';
import 'package:sixam_mart_store/helper/responsive_helper.dart';
import 'package:sixam_mart_store/helper/route_helper.dart';
import 'package:sixam_mart_store/util/app_constants.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:sixam_mart_store/view/base/confirmation_dialog.dart';
import 'package:sixam_mart_store/view/base/custom_app_bar.dart';
import 'package:sixam_mart_store/view/base/custom_button.dart';
import 'package:sixam_mart_store/view/base/custom_image.dart';
import 'package:sixam_mart_store/view/base/custom_snackbar.dart';
import 'package:sixam_mart_store/view/screens/order/invoice_print_screen.dart';
import 'package:sixam_mart_store/view/screens/order/widget/order_item_widget.dart';
import 'package:sixam_mart_store/view/screens/order/widget/slider_button.dart';
import 'package:sixam_mart_store/view/screens/order/widget/verify_delivery_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final bool isRunningOrder;
  final bool fromNotification;
  OrderDetailsScreen({@required this.orderId, @required this.isRunningOrder, this.fromNotification = false});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> with WidgetsBindingObserver{
  Timer _timer;

  Future<void> loadData() async {
    await Get.find<OrderController>().getOrderDetails(widget.orderId); ///order

    Get.find<OrderController>().getOrderItemsDetails(widget.orderId); ///order details

    _startApiCalling();
  }

  void _startApiCalling(){
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      Get.find<OrderController>().getOrderDetails(widget.orderId);
    });
  }

  @override
  void initState() {
    super.initState();

    Get.find<OrderController>().clearPreviousData();
    loadData();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startApiCalling();
    }else if(state == AppLifecycleState.paused){
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);

    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    bool _cancelPermission = Get.find<SplashController>().configModel.canceledByStore;
    bool _selfDelivery = Get.find<AuthController>().profileModel.stores[0].selfDeliverySystem == 1;

    return WillPopScope(
      onWillPop: () async{
        if(widget.fromNotification) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
          return true;
        } else {
          Get.back();
          return true;
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(title: 'order_details'.tr, onTap: (){
          if(widget.fromNotification) {
            Get.offAllNamed(RouteHelper.getInitialRoute());
          } else {
            Get.back();
          }
        }),
        body: GetBuilder<OrderController>(builder: (orderController) {

          OrderModel _controllerOrderModer = orderController.orderModel;

          bool _restConfModel = Get.find<SplashController>().configModel.orderConfirmationModel != 'deliveryman';
          bool _showSlider = _controllerOrderModer != null ? (_controllerOrderModer.orderStatus == 'pending' && (_controllerOrderModer.orderType == 'take_away' || _restConfModel || _selfDelivery))
              || _controllerOrderModer.orderStatus == 'confirmed' || _controllerOrderModer.orderStatus == 'processing'
              || (_controllerOrderModer.orderStatus == 'accepted' && _controllerOrderModer.confirmed != null)
              || (_controllerOrderModer.orderStatus == 'handover' && (_selfDelivery || _controllerOrderModer.orderType == 'take_away')) : false;
          bool _showBottomView = _controllerOrderModer != null ? _showSlider || _controllerOrderModer.orderStatus == 'picked_up' || widget.isRunningOrder : false;

          double _deliveryCharge = 0;
          double _itemsPrice = 0;
          double _discount = 0;
          double _couponDiscount = 0;
          double _tax = 0;
          double _addOns = 0;
          double _dmTips = 0;
          bool _isPrescriptionOrder = false;
          OrderModel _order = _controllerOrderModer;
          if(_order != null && orderController.orderDetailsModel != null) {
            if(_order.orderType == 'delivery') {
              _deliveryCharge = _order.deliveryCharge;
              _dmTips = _order.dmTips;
              _isPrescriptionOrder = _order.prescriptionOrder;
            }
            _discount = _order.storeDiscountAmount;
            _tax = _order.totalTaxAmount;
            _couponDiscount = _order.couponDiscountAmount;
            if(_isPrescriptionOrder){
              double orderAmount = _order.orderAmount ?? 0;
              _itemsPrice = (orderAmount + _discount) - (_tax + _deliveryCharge );
            }else {
              for (OrderDetailsModel orderDetails in orderController.orderDetailsModel) {
                for (AddOn addOn in orderDetails.addOns) {
                  _addOns = _addOns + (addOn.price * addOn.quantity);
                }
                _itemsPrice = _itemsPrice + (orderDetails.price * orderDetails.quantity);
              }
            }
          }
          double _subTotal = _itemsPrice + _addOns;
          double _total = _itemsPrice + _addOns - _discount + _tax + _deliveryCharge - _couponDiscount + _dmTips;

          return (orderController.orderDetailsModel != null && _controllerOrderModer != null) ? Column(children: [

            Expanded(child: Scrollbar(child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
              child: Center(child: SizedBox(width: 1170, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Row(children: [
                  Text('${'order_id'.tr}:', style: robotoRegular),
                  SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  Text(_order.id.toString(), style: robotoMedium),
                  SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  Expanded(child: SizedBox()),
                  Icon(Icons.watch_later, size: 17),
                  SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  Text(
                    DateConverter.dateTimeStringToDateTime(_order.createdAt),
                    style: robotoRegular,
                  ),
                ]),
                SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

                _order.scheduled == 1 ? Row(children: [
                  Text('${'scheduled_at'.tr}:', style: robotoRegular),
                  SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  Text(DateConverter.dateTimeStringToDateTime(_order.scheduleAt), style: robotoMedium),
                ]) : SizedBox(),
                SizedBox(height: _order.scheduled == 1 ? Dimensions.PADDING_SIZE_SMALL : 0),

                Row(children: [
                  Text(_order.orderType.tr, style: robotoMedium),
                  Expanded(child: SizedBox()),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_SMALL, vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                    ),
                    child: Text(
                      _order.paymentMethod == 'cash_on_delivery' ? 'cash_on_delivery'.tr : _order.paymentMethod == 'wallet' ? 'wallet_payment' : 'digital_payment'.tr,
                      style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.FONT_SIZE_EXTRA_SMALL),
                    ),
                  ),
                ]),
                Divider(height: Dimensions.PADDING_SIZE_LARGE),

                Padding(
                  padding: EdgeInsets.symmetric(vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  child: Row(children: [
                    Text('${'item'.tr}:', style: robotoRegular),
                    SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                    Text(
                      orderController.orderDetailsModel.length.toString(),
                      style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                    ),
                    Expanded(child: SizedBox()),
                    Container(height: 7, width: 7, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),

                    Text(
                      _order.orderStatus == 'delivered' ? '${'delivered_at'.tr} ${_order.delivered != null ? DateConverter.dateTimeStringToDateTime(_order.delivered) : ''}'
                          : _order.orderStatus.tr,
                      style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL),
                    ),
                  ]),
                ),
                Divider(height: Dimensions.PADDING_SIZE_LARGE),
                SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: orderController.orderDetailsModel.length,
                  itemBuilder: (context, index) {
                    return OrderItemWidget(order: _order, orderDetails: orderController.orderDetailsModel[index]);
                  },
                ),

                (_order.orderNote  != null && _order.orderNote.isNotEmpty) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('additional_note'.tr, style: robotoRegular),
                  SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

                  Container(
                    width: 1170,
                    padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                      border: Border.all(width: 1, color: Theme.of(context).disabledColor),
                    ),
                    child: Text(
                      _order.orderNote,
                      style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                    ),
                  ),
                  SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
                ]) : SizedBox(),

                (Get.find<SplashController>().getModuleConfig(_order.moduleType).orderAttachment && _order.orderAttachment != null
                && _order.orderAttachment.isNotEmpty) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('prescription'.tr, style: robotoRegular),
                  SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

                  GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        childAspectRatio: 1,
                        crossAxisCount: ResponsiveHelper.isTab(context) ? 5 : 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 5,
                      ),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _order.orderAttachment.length,
                      itemBuilder: (BuildContext context, index) {
                        print('---> ${Get.find<SplashController>().configModel.baseUrls.orderAttachmentUrl}/${_order.orderAttachment[index]}');
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => openDialog(context, '${Get.find<SplashController>().configModel.baseUrls.orderAttachmentUrl}/${_order.orderAttachment[index]}'),
                            child: Center(child: ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                              child: CustomImage(
                                image: '${Get.find<SplashController>().configModel.baseUrls.orderAttachmentUrl}/${_order.orderAttachment[index]}',
                                width: 100, height: 100,
                              ),
                            )),
                          ),
                        );
                      }),

                  SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
                ]) : SizedBox(),

                Text('customer_details'.tr, style: robotoRegular),
                SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),

                _order.deliveryAddress != null ? Row(children: [
                  SizedBox(
                    height: 35, width: 35,
                    child: ClipOval(child: CustomImage(
                      image: '${Get.find<SplashController>().configModel.baseUrls.customerImageUrl}/${_order.customer != null ?_order.customer.image : ''}',
                      height: 35, width: 35, fit: BoxFit.cover,
                    )),
                  ),
                  SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _order.deliveryAddress.contactPersonName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL),
                    ),
                    Text(
                      _order.deliveryAddress.address ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                    ),

                    Wrap(children: [
                      (_order.deliveryAddress.streetNumber != null && _order.deliveryAddress.streetNumber.isNotEmpty) ? Text('street_number'.tr+ ': ' + _order.deliveryAddress.streetNumber  + ', ',
                        style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_EXTRA_SMALL, color: Theme.of(context).disabledColor), maxLines: 1, overflow: TextOverflow.ellipsis,
                      ) : SizedBox(),

                      (_order.deliveryAddress.house != null && _order.deliveryAddress.house.isNotEmpty) ? Text('house'.tr +': ' + _order.deliveryAddress.house  + ', ',
                        style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_EXTRA_SMALL, color: Theme.of(context).disabledColor), maxLines: 1, overflow: TextOverflow.ellipsis,
                      ) : SizedBox(),

                      (_order.deliveryAddress.floor != null && _order.deliveryAddress.floor.isNotEmpty) ? Text('floor'.tr+': ' + _order.deliveryAddress.floor ,
                        style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_EXTRA_SMALL, color: Theme.of(context).disabledColor), maxLines: 1, overflow: TextOverflow.ellipsis,
                      ) : SizedBox(),
                    ]),

                  ])),

                  (_order.orderType == 'take_away' && (_order.orderStatus == 'pending' || _order.orderStatus == 'confirmed' || _order.orderStatus == 'processing')) ? TextButton.icon(
                    onPressed: () async {
                      String url ='https://www.google.com/maps/dir/?api=1&destination=${_order.deliveryAddress.latitude}'
                          ',${_order.deliveryAddress.longitude}&mode=d';
                      if (await canLaunchUrlString(url)) {
                        await launchUrlString(url, mode: LaunchMode.externalApplication);
                      }else {
                        showCustomSnackBar('unable_to_launch_google_map'.tr);
                      }
                    },
                    icon: Icon(Icons.directions), label: Text('direction'.tr),
                  ) : SizedBox(),
                  SizedBox(width: Dimensions.PADDING_SIZE_SMALL),

                  (_order.orderStatus != 'delivered' && _order.orderStatus != 'failed' && Get.find<AuthController>().modulePermission.chat
                  && _order.orderStatus != 'canceled' && _order.orderStatus != 'refunded') ? TextButton.icon(
                    onPressed: () async {
                      _timer.cancel();
                      await Get.toNamed(RouteHelper.getChatRoute(
                        notificationBody: NotificationBody(
                          orderId: _order.id, customerId: _order.customer.id,
                        ),
                        user: User(
                          id: _order.customer.id, fName: _order.customer.fName,
                          lName: _order.customer.lName, image: _order.customer.image,
                        ),
                      ));
                      _startApiCalling();
                    },
                    icon: Icon(Icons.message, color: Theme.of(context).primaryColor, size: 20),
                    label: Text(
                      'chat'.tr,
                      style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).primaryColor),
                    ),
                  ) : SizedBox(),
                ]) : SizedBox(),
                SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

                _order.deliveryMan != null ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Text('delivery_man'.tr, style: robotoRegular),
                  SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

                  Row(children: [

                    ClipOval(child: CustomImage(
                      image: _order.deliveryMan != null ?'${Get.find<SplashController>().configModel.baseUrls.deliveryManImageUrl}/${_order.deliveryMan.image}' : '',
                      height: 35, width: 35, fit: BoxFit.cover,
                    )),
                    SizedBox(width: Dimensions.PADDING_SIZE_SMALL),

                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '${_order.deliveryMan.fName} ${_order.deliveryMan.lName}', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL),
                      ),
                      Text(
                        _order.deliveryMan.email, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                      ),
                    ])),

                    (_controllerOrderModer.orderStatus != 'delivered' && _controllerOrderModer.orderStatus != 'failed'
                    && _controllerOrderModer.orderStatus != 'canceled' && _controllerOrderModer.orderStatus != 'refunded') ? TextButton.icon(
                      onPressed: () async {
                        if(await canLaunchUrlString('tel:${_order.deliveryMan.phone != null ? _order.deliveryMan.phone : '' }')) {
                          launchUrlString('tel:${_order.deliveryMan.phone != null ? _order.deliveryMan.phone : '' }', mode: LaunchMode.externalApplication);
                        }else {
                          showCustomSnackBar('${'can_not_launch'.tr} ${_order.deliveryMan.phone != null ? _order.deliveryMan.phone : ''}');
                        }
                      },
                      icon: Icon(Icons.call, color: Theme.of(context).primaryColor, size: 20),
                      label: Text(
                        'call'.tr,
                        style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).primaryColor),
                      ),
                    ) : SizedBox(),

                    (_controllerOrderModer.orderStatus != 'delivered' && _controllerOrderModer.orderStatus != 'failed' && _controllerOrderModer.orderStatus != 'canceled'
                    && _controllerOrderModer.orderStatus != 'refunded' && Get.find<AuthController>().modulePermission.chat) ? TextButton.icon(
                      onPressed: () async {
                        _timer.cancel();
                        await Get.toNamed(RouteHelper.getChatRoute(
                          notificationBody: NotificationBody(
                            orderId: _controllerOrderModer.id, deliveryManId: _order.deliveryMan.id,
                          ),
                          user: User(
                            id: _controllerOrderModer.deliveryMan.id, fName: _controllerOrderModer.deliveryMan.fName,
                            lName: _controllerOrderModer.deliveryMan.lName, image: _controllerOrderModer.deliveryMan.image,
                          ),
                        ));
                        _startApiCalling();
                      },
                      icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor, size: 20),
                      label: Text(
                        'chat'.tr,
                        style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).primaryColor),
                      ),
                    ) : SizedBox(),

                  ]),

                  SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                ]) : SizedBox(),

                // Total
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('item_price'.tr, style: robotoRegular),
                  Text(PriceConverter.convertPrice(_itemsPrice), style: robotoRegular),
                ]),
                SizedBox(height: 10),

                Get.find<SplashController>().getModuleConfig(_order.moduleType).addOn ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('addons'.tr, style: robotoRegular),
                    Text('(+) ${PriceConverter.convertPrice(_addOns)}', style: robotoRegular),
                  ],
                ) : SizedBox(),

                Get.find<SplashController>().getModuleConfig(_order.moduleType).addOn ? Divider(
                  thickness: 1, color: Theme.of(context).hintColor.withOpacity(0.5),
                ) : SizedBox(),

                Get.find<SplashController>().getModuleConfig(_order.moduleType).addOn ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('subtotal'.tr, style: robotoMedium),
                    Text(PriceConverter.convertPrice(_subTotal), style: robotoMedium),
                  ],
                ) : SizedBox(),
                SizedBox(height: Get.find<SplashController>().getModuleConfig(_order.moduleType).addOn ? 10 : 0),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('discount'.tr, style: robotoRegular),
                  Text('(-) ${PriceConverter.convertPrice(_discount)}', style: robotoRegular),
                ]),
                SizedBox(height: 10),

                _couponDiscount > 0 ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('coupon_discount'.tr, style: robotoRegular),
                  Text(
                    '(-) ${PriceConverter.convertPrice(_couponDiscount)}',
                    style: robotoRegular,
                  ),
                ]) : SizedBox(),
                SizedBox(height: _couponDiscount > 0 ? 10 : 0),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('vat_tax'.tr, style: robotoRegular),
                  Text('(+) ${PriceConverter.convertPrice(_tax)}', style: robotoRegular),
                ]),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('delivery_man_tips'.tr, style: robotoRegular),
                    Text('(+) ${PriceConverter.convertPrice(_dmTips)}', style: robotoRegular),
                  ],
                ),
                SizedBox(height: 10),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('delivery_fee'.tr, style: robotoRegular),
                  Text('(+) ${PriceConverter.convertPrice(_deliveryCharge)}', style: robotoRegular),
                ]),

                Padding(
                  padding: EdgeInsets.symmetric(vertical: Dimensions.PADDING_SIZE_SMALL),
                  child: Divider(thickness: 1, color: Theme.of(context).hintColor.withOpacity(0.5)),
                ),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('total_amount'.tr, style: robotoMedium.copyWith(
                    fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).primaryColor,
                  )),
                  Text(
                    PriceConverter.convertPrice(_total),
                    style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).primaryColor),
                  ),
                ]),

              ]))),
            ))),

            _showBottomView ? (_controllerOrderModer.orderStatus == 'picked_up') ? Container(
              padding: EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                border: Border.all(width: 1),
              ),
              alignment: Alignment.center,
              child: Text('item_is_on_the_way'.tr, style: robotoMedium),
            ) : _showSlider ? (_controllerOrderModer.orderStatus == 'pending' && (_controllerOrderModer.orderType == 'take_away'
            || _restConfModel || _selfDelivery) && _cancelPermission) ? Padding(
              padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
              child: Row(children: [

                Expanded(child: TextButton(
                  onPressed: () => Get.dialog(ConfirmationDialog(
                    icon: Images.warning, title: 'are_you_sure_to_cancel'.tr, description: 'you_want_to_cancel_this_order'.tr,
                    onYesPressed: () {
                      orderController.updateOrderStatus(widget.orderId, AppConstants.CANCELED, back: true);
                    },
                  ), barrierDismissible: false),
                  style: TextButton.styleFrom(
                    minimumSize: Size(1170, 40), padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                      side: BorderSide(width: 1, color: Theme.of(context).textTheme.bodyText1.color),
                    ),
                  ),
                  child: Text('cancel'.tr, textAlign: TextAlign.center, style: robotoRegular.copyWith(
                    color: Theme.of(context).textTheme.bodyText1.color,
                    fontSize: Dimensions.FONT_SIZE_LARGE,
                  )),
                )),
                SizedBox(width: Dimensions.PADDING_SIZE_SMALL),

                Expanded(child: CustomButton(
                  buttonText: 'confirm'.tr, height: 40,
                  onPressed: () {
                    Get.dialog(ConfirmationDialog(
                      icon: Images.warning, title: 'are_you_sure_to_confirm'.tr, description: 'you_want_to_confirm_this_order'.tr,
                      onYesPressed: () {
                        orderController.updateOrderStatus(widget.orderId, AppConstants.CONFIRMED, back: true);
                      },
                    ), barrierDismissible: false);
                  },
                )),

              ]),
            ) : SliderButton(
              action: () {

                if(_controllerOrderModer.orderStatus == 'pending' && (_controllerOrderModer.orderType == 'take_away'
                    || _restConfModel || _selfDelivery))  {
                  Get.dialog(ConfirmationDialog(
                    icon: Images.warning, title: 'are_you_sure_to_confirm'.tr, description: 'you_want_to_confirm_this_order'.tr,
                    onYesPressed: () {
                      orderController.updateOrderStatus(widget.orderId, AppConstants.CONFIRMED, back: true);
                    },
                    onNoPressed: () {
                      if(_cancelPermission) {
                        orderController.updateOrderStatus(widget.orderId, AppConstants.CANCELED, back: true);
                      }else {
                        Get.back();
                      }
                    },
                  ), barrierDismissible: false);
                }

                else if(_controllerOrderModer.orderStatus == 'processing') {
                  Get.find<OrderController>().updateOrderStatus(widget.orderId, AppConstants.HANDOVER);
                }

                else if(_controllerOrderModer.orderStatus == 'confirmed' || (_controllerOrderModer.orderStatus == 'accepted'
                    && _controllerOrderModer.confirmed != null)) {
                  print('accepted & confirm call----------------');
                  Get.find<OrderController>().updateOrderStatus(_controllerOrderModer.id, AppConstants.PROCESSING);
                }

                else if((_controllerOrderModer.orderStatus == 'handover' && (_controllerOrderModer.orderType == 'take_away'
                    || _selfDelivery))) {
                  if (Get.find<SplashController>().configModel.orderDeliveryVerification || _controllerOrderModer.paymentMethod == 'cash_on_delivery') {
                    Get.bottomSheet(VerifyDeliverySheet(
                      orderID: _controllerOrderModer.id, verify: Get.find<SplashController>().configModel.orderDeliveryVerification,
                      orderAmount: _controllerOrderModer.orderAmount, cod: _controllerOrderModer.paymentMethod == 'cash_on_delivery',
                    ), isScrollControlled: true);
                  } else {
                    Get.find<OrderController>().updateOrderStatus(_controllerOrderModer.id, AppConstants.DELIVERED);
                  }
                }

              },
              label: Text(
                (_controllerOrderModer.orderStatus == 'pending' && (_controllerOrderModer.orderType == 'take_away' || _restConfModel || _selfDelivery)) ? 'swipe_to_confirm_order'.tr
                    : (_controllerOrderModer.orderStatus == 'confirmed' || (_controllerOrderModer.orderStatus == 'accepted' && _controllerOrderModer.confirmed != null))
                    ? Get.find<SplashController>().configModel.moduleConfig.module.showRestaurantText ? 'swipe_to_cooking'.tr : 'swipe_to_process'.tr
                    : (_controllerOrderModer.orderStatus == 'processing') ? 'swipe_if_ready_for_handover'.tr
                    : (_controllerOrderModer.orderStatus == 'handover' && (_controllerOrderModer.orderType == 'take_away' || _selfDelivery)) ? 'swipe_to_deliver_order'.tr : '',
                style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).primaryColor),
              ),
              dismissThresholds: 0.5, dismissible: false, shimmer: true,
              width: 1170, height: 60, buttonSize: 50, radius: 10,
              icon: Center(child: Icon(
                Get.find<LocalizationController>().isLtr ? Icons.double_arrow_sharp : Icons.keyboard_arrow_left,
                color: Colors.white, size: 20.0,
              )),
              isLtr: Get.find<LocalizationController>().isLtr,
              boxShadow: BoxShadow(blurRadius: 0),
              buttonColor: Theme.of(context).primaryColor,
              backgroundColor: Color(0xffF4F7FC),
              baseColor: Theme.of(context).primaryColor,
            ) : SizedBox() : SizedBox(),

            Padding(
              padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
              child: CustomButton(
                onPressed: () {
                  Get.dialog(Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL)),
                    child: InVoicePrintScreen(order: _order, orderDetails: orderController.orderDetailsModel),
                  ));
                },
                icon: Icons.local_print_shop,
                buttonText: 'print_invoice'.tr,
              ),
            ),


          ]) : Center(child: CircularProgressIndicator());
        }),
      ),
    );
  }

  void openDialog(BuildContext context, String imageUrl) => showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE)),
        child: Stack(children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE),
            child: PhotoView(
              tightMode: true,
              imageProvider: NetworkImage(imageUrl),
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
            ),
          ),

          Positioned(top: 0, right: 0, child: IconButton(
            splashRadius: 5,
            onPressed: () => Get.back(),
            icon: Icon(Icons.cancel, color: Colors.red),
          )),

        ]),
      );
    },
  );
}
