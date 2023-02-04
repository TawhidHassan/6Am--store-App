import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/controller/auth_controller.dart';
import 'package:sixam_mart_store/controller/splash_controller.dart';
import 'package:sixam_mart_store/data/model/body/bluetoothPrinterBody.dart';
import 'package:sixam_mart_store/data/model/response/item_model.dart';
import 'package:sixam_mart_store/data/model/response/order_details_model.dart';
import 'package:sixam_mart_store/data/model/response/order_model.dart';
import 'package:sixam_mart_store/data/model/response/profile_model.dart';
import 'package:sixam_mart_store/helper/date_converter.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class InVoicePrintScreen extends StatefulWidget {
  final OrderModel order;
  final List<OrderDetailsModel> orderDetails;
  const InVoicePrintScreen({@required this.order, @required this.orderDetails});

  @override
  State<InVoicePrintScreen> createState() => _InVoicePrintScreenState();
}

class _InVoicePrintScreenState extends State<InVoicePrintScreen> {
  PrinterType _defaultPrinterType = PrinterType.bluetooth;
  bool _isBle = false;
  PrinterManager _printerManager = PrinterManager.instance;
  List<BluetoothPrinter> _devices = <BluetoothPrinter>[];
  StreamSubscription<PrinterDevice> _subscription;
  StreamSubscription<BTStatus> _subscriptionBtStatus;
  BTStatus _currentStatus = BTStatus.none;
  List<int> pendingTask;
  String _ipAddress = '';
  String _port = '9100';
  bool _paper80MM = true;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  BluetoothPrinter _selectedPrinter;

  @override
  void initState() {
    if (Platform.isWindows) _defaultPrinterType = PrinterType.usb;
    super.initState();
    _portController.text = _port;
    _scan();

    // subscription to listen change status of bluetooth connection
    _subscriptionBtStatus = PrinterManager.instance.stateBluetooth.listen((status) {
      log(' ----------------- status bt $status ------------------ ');
      _currentStatus = status;

      if (status == BTStatus.connected && pendingTask != null) {
        if (Platform.isAndroid) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            PrinterManager.instance.send(type: PrinterType.bluetooth, bytes: pendingTask);
            pendingTask = null;
          });
        } else if (Platform.isIOS) {
          PrinterManager.instance.send(type: PrinterType.bluetooth, bytes: pendingTask);
          pendingTask = null;
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscriptionBtStatus?.cancel();
    _portController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  // method to scan devices according PrinterType
  void _scan() {
    _devices.clear();
    _subscription = _printerManager.discovery(type: _defaultPrinterType, isBle: _isBle).listen((device) {
      _devices.add(BluetoothPrinter(
        deviceName: device.name,
        address: device.address,
        isBle: _isBle,
        vendorId: device.vendorId,
        productId: device.productId,
        typePrinter: _defaultPrinterType,
      ));
      setState(() {});
    });
  }

  void _setPort(String value) {
    if (value.isEmpty) value = '9100';
    _port = value;
    var device = BluetoothPrinter(
      deviceName: value,
      address: _ipAddress,
      port: _port,
      typePrinter: PrinterType.network,
      state: false,
    );
    _selectDevice(device);
  }

  void _setIpAddress(String value) {
    _ipAddress = value;
    BluetoothPrinter _device = BluetoothPrinter(
      deviceName: value,
      address: _ipAddress,
      port: _port,
      typePrinter: PrinterType.network,
      state: false,
    );
    _selectDevice(_device);
  }

  void _selectDevice(BluetoothPrinter device) async {
    if (_selectedPrinter != null) {
      if ((device.address != _selectedPrinter.address) || (device.typePrinter == PrinterType.usb && _selectedPrinter.vendorId != device.vendorId)) {
        await PrinterManager.instance.disconnect(type: _selectedPrinter.typePrinter);
      }
    }

    _selectedPrinter = device;
    setState(() {});
  }

  String _priceDecimal(double price) {
    return price.toStringAsFixed(Get.find<SplashController>().configModel.digitAfterDecimalPoint);
  }


  Future _printReceipt() async {
    CapabilityProfile _profile = await CapabilityProfile.load();
    Generator _generator = Generator(_paper80MM ? PaperSize.mm80 : PaperSize.mm58, _profile);
    List<int> _bytes = [];

    Store _store = Get.find<AuthController>().profileModel.stores[0];
    _bytes += _generator.text(
      '${_store.name}',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    _bytes += _generator.text(
      '${_store.address}',
      styles: const PosStyles(align: PosAlign.center),
    );
    _bytes += _generator.text(
      '${_store.phone}',
      styles: const PosStyles(align: PosAlign.center),
    );
    _bytes += _generator.text(
      '${_store.email}',
      styles: const PosStyles(align: PosAlign.center),
    );
    _bytes += _generator.text(
      '..............................................................',
      styles: const PosStyles(align: PosAlign.center),
    );
    _bytes += _generator.text(' ', styles: const PosStyles(align: PosAlign.center));

    _bytes += _generator.row([
      PosColumn(
        text: '${'order_id'.tr.toUpperCase()}#${widget.order.id}',
        width: 6,
        styles: PosStyles(align: PosAlign.left, underline: true),
      ),

      PosColumn(
        text: 'payment_method'.tr,
        width: 6,
        styles: PosStyles(align: PosAlign.right, underline: true),
      ),
    ]);
    _bytes += _generator.row([
      PosColumn(
        text: '${DateConverter.dateTimeStringToMonthAndTime(widget.order.createdAt)}',
        width: 6,
        styles: PosStyles(align: PosAlign.left),
      ),

      PosColumn(
        text: widget.order.paymentMethod.tr,
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    if(widget.order.scheduled == 1) {
      _bytes += _generator.text(
        '${'scheduled_order_time'.tr} ${DateConverter.dateTimeStringToDateTime(widget.order.scheduleAt)}',
        styles: PosStyles(align: PosAlign.left),
      );
    }

    _bytes += _generator.text(' ');

    _bytes += _generator.text(
      '${widget.order.customer.fName} ${widget.order.customer.lName}',
      styles: const PosStyles(align: PosAlign.left),
    );
    _bytes += _generator.text(
      '${widget.order.deliveryAddress.address}',
      styles: const PosStyles(align: PosAlign.left),
    );
    _bytes += _generator.text(
      '${widget.order.customer.phone}',
      styles: const PosStyles(align: PosAlign.left),
    );

    _bytes += _generator.text(' ');

    _bytes += _generator.row([
      PosColumn(
        text: '${'sl'.tr.toUpperCase()}',
        width: 2,
        styles: PosStyles(align: PosAlign.left),
      ),

      PosColumn(
        text: 'item_info'.tr,
        width: 6,
        styles: PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: 'qty'.tr,
        width: 1,
        styles: PosStyles(align: PosAlign.right),
      ),
      PosColumn(
        text: 'price'.tr,
        width: 3,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);

    _bytes += _generator.text(
      '..............................................................',
      styles: const PosStyles(align: PosAlign.center),
    );

    for(int i =0; i< widget.orderDetails.length; i++) {

      String _variationText = '';
      print('=jdsfk=> ${widget.orderDetails[i].itemDetails.variations}');
      if(widget.orderDetails[i].itemDetails.variations != null){
        if(widget.orderDetails[i].itemDetails.variations.length > 0) {
          if(widget.orderDetails[i].itemDetails.variations.length > 0) {
            List<String> _variationTypes = widget.orderDetails[i].itemDetails.variations[0].type.split('-');
            if(_variationTypes.length == widget.orderDetails[i].itemDetails.choiceOptions.length) {
              int _index = 0;
              widget.orderDetails[i].itemDetails.choiceOptions.forEach((choice) {
                _variationText = _variationText + '${(_index == 0) ? '' : ',  '}${choice.title} - ${_variationTypes[_index]}';
                _index = _index + 1;
              });
            }else {
              _variationText = widget.orderDetails[i].itemDetails.variations[0].type;
            }
          }
        }
      }
      else if(widget.orderDetails[i].foodVariation.length > 0) {
        for(FoodVariation variation in widget.orderDetails[i].foodVariation) {
          _variationText += '${_variationText.isNotEmpty ? ', ' : ''}${variation.name} (';
          for(VariationValue value in variation.variationValues) {
            _variationText += '${_variationText.endsWith('(') ? '' : ', '}${value.level}';
          }
          _variationText += ')';
        }
      }

      print('------------------>> $_variationText');

      _bytes += _generator.row([
        PosColumn(
          text: '${i+1}',
          width: 1,
          styles: PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '${widget.orderDetails[i].itemDetails.name}',
          width: 7,
          styles: PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '${widget.orderDetails[i].quantity.toString()}',
          width: 1,
          styles: PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: '${widget.orderDetails[i].price * widget.orderDetails[i].quantity}',
          width: 3,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);

      if(_variationText != '' ){
        _bytes += _generator.row([
          PosColumn(
            text: '',
            width: 2,
            styles: PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: '$_variationText',
            width: 8,
            styles: PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: '',
            width: 2,
            styles: PosStyles(align: PosAlign.left),
          ),
        ]);
      }
    }

    _bytes += _generator.text(
      '..............................................................',
      styles: const PosStyles(align: PosAlign.center),
    );

    double _itemsPrice = 0;
    double _addOns = 0;
    if(widget.order.prescriptionOrder){
      double orderAmount = widget.order.orderAmount ?? 0;
      _itemsPrice = (orderAmount + widget.order.storeDiscountAmount) - (widget.order.totalTaxAmount + widget.order.deliveryCharge);
    }else{
      for(OrderDetailsModel orderDetails in widget.orderDetails) {
        for(AddOn addOn in orderDetails.addOns) {
          _addOns = _addOns + (addOn.price * addOn.quantity);
        }
        _itemsPrice = _itemsPrice + (orderDetails.price * orderDetails.quantity);
      }
    }
    _bytes += _generator.row([
      PosColumn(
        text: 'item_price'.tr,
        width: 6,
        styles: PosStyles(align: PosAlign.left),
      ),

      PosColumn(
        text: _priceDecimal(_itemsPrice),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);

    if(_addOns > 0){
      _bytes += _generator.row([
        PosColumn(
          text: 'addons'.tr,
          width: 6,
          styles: PosStyles(align: PosAlign.left,),
        ),

        PosColumn(
          text: _priceDecimal(_addOns),
          width: 6,
          styles: PosStyles(align: PosAlign.right,),
        ),
      ]);
    }

    _bytes += _generator.row([
      PosColumn(
        text: 'subtotal'.tr,
        width: 6,
        styles: PosStyles(align: PosAlign.left, bold: true),
      ),

      PosColumn(
        text: _priceDecimal(_itemsPrice + _addOns),
        width: 6,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    _bytes += _generator.row([
      PosColumn(
        text: 'discount'.tr,
        width: 6,
        styles: PosStyles(align: PosAlign.left),
      ),

      PosColumn(
        text: _priceDecimal(widget.order.storeDiscountAmount),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);

    if(widget.order.couponDiscountAmount > 0) {
      _bytes += _generator.row([
        PosColumn(
          text: 'coupon_discount'.tr,
          width: 6,
          styles: PosStyles(align: PosAlign.left),
        ),

        PosColumn(
          text: _priceDecimal(widget.order.couponDiscountAmount),
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    _bytes += _generator.row([
      PosColumn(
        text: 'vat_tax'.tr,
        width: 6,
        styles: PosStyles(align: PosAlign.left),
      ),

      PosColumn(
        text: _priceDecimal(widget.order.totalTaxAmount),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    _bytes += _generator.row([
      PosColumn(
        text: 'delivery_fee'.tr,
        width: 6,
        styles: PosStyles(align: PosAlign.left),
      ),

      PosColumn(
        text: _priceDecimal(widget.order.deliveryCharge),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);

    _bytes += _generator.text(
      '..............................................................',
      styles: const PosStyles(align: PosAlign.center),
    );

    _bytes += _generator.row([
      PosColumn(
        text: 'total_amount'.tr,
        width: 6,
        styles: PosStyles(align: PosAlign.left, bold: true),
      ),

      PosColumn(
        text: _priceDecimal(widget.order.orderAmount),
        width: 6,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    _bytes += _generator.text(
      '..............................................................',
      styles: const PosStyles(align: PosAlign.center),
    );

    _bytes += _generator.text(
      'thank_you'.tr,
      styles: const PosStyles(align: PosAlign.center),
    );

    _bytes += _generator.text(
      '..............................................................',
      styles: const PosStyles(align: PosAlign.center),
    );

    _bytes += _generator.text(
      '${Get.find<SplashController>().configModel.businessName}. ${Get.find<SplashController>().configModel.footerText}',
      styles: const PosStyles(align: PosAlign.center),
    );

    _printEscPos(_bytes, _generator);
  }

  /// print ticket
  void _printEscPos(List<int> bytes, Generator generator) async {
    if (_selectedPrinter == null) return;
    var bluetoothPrinter = _selectedPrinter;

    switch (bluetoothPrinter.typePrinter) {
      case PrinterType.usb:
        bytes += generator.feed(2);
        bytes += generator.cut();
        await _printerManager.connect(
          type: bluetoothPrinter.typePrinter,
          model: UsbPrinterInput(
            name: bluetoothPrinter.deviceName,
            productId: bluetoothPrinter.productId,
            vendorId: bluetoothPrinter.vendorId,
          ),
        );
        break;
      case PrinterType.bluetooth:
        bytes += generator.cut();
        await _printerManager.connect(
          type: bluetoothPrinter.typePrinter,
          model: BluetoothPrinterInput(
            name: bluetoothPrinter.deviceName,
            address: bluetoothPrinter.address,
            isBle: bluetoothPrinter.isBle ?? false,
          ),
        );
        pendingTask = null;
        if (Platform.isIOS || Platform.isAndroid) pendingTask = bytes;
        break;
      case PrinterType.network:
        bytes += generator.feed(2);
        bytes += generator.cut();
        await _printerManager.connect(
          type: bluetoothPrinter.typePrinter,
          model: TcpPrinterInput(ipAddress: bluetoothPrinter.address),
        );
        break;
      default:
    }
    if (bluetoothPrinter.typePrinter == PrinterType.bluetooth) {
      if (_currentStatus == BTStatus.connected) {
        _printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
        pendingTask = null;
      }
    } else {
      _printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context,  Orientation orientation) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(Dimensions.FONT_SIZE_LARGE),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Text('paper_size'.tr, style: robotoMedium),
            Row(children: [
              Expanded(child: RadioListTile(
                title: Text('80_mm'.tr),
                groupValue: _paper80MM,
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: true,
                onChanged: (bool value) {
                  _paper80MM = true;
                  setState(() {});
                },
              )),
              Expanded(child: RadioListTile(
                title: Text('58_mm'.tr),
                groupValue: _paper80MM,
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: false,
                onChanged: (bool value) {
                  _paper80MM = false;
                  setState(() {});
                },
              )),
            ]),
            SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

            ListView.builder(
              itemCount: _devices.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
                  child: InkWell(
                    onTap: () => _selectDevice(_devices[index]),
                    child: Stack(children: [

                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        Text('${_devices[index].deviceName}'),

                        Platform.isAndroid && _defaultPrinterType == PrinterType.usb ? null
                            : Visibility(visible: !Platform.isWindows, child: Text("${_devices[index].address}")),

                        OutlinedButton(
                          onPressed: _selectedPrinter == null || _devices[index].deviceName != _selectedPrinter?.deviceName ? null : () async {
                            _printReceipt();
                            if(Get.isDialogOpen) {
                              Get.back();
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 20),
                            child: Text("print_invoice".tr, textAlign: TextAlign.center),
                          ),
                        ),

                      ]),

                      (_selectedPrinter != null && ((_devices[index].typePrinter == PrinterType.usb && Platform.isWindows
                          ? _devices[index].deviceName == _selectedPrinter.deviceName
                          : _devices[index].vendorId != null && _selectedPrinter.vendorId == _devices[index].vendorId) ||
                          (_devices[index].address != null && _selectedPrinter.address == _devices[index].address))) ? Positioned(
                            top: 5, right: 5,
                            child: Icon(Icons.check, color: Colors.green),
                      ) : SizedBox(),

                    ]),
                  ),
                );
              },
            ),
            Visibility(
              visible: _defaultPrinterType == PrinterType.network && Platform.isWindows,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  controller: _ipController,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  decoration: InputDecoration(
                    label: Text('ip_address'.tr),
                    prefixIcon: Icon(Icons.wifi, size: 24),
                  ),
                  onChanged: _setIpAddress,
                ),
              ),
            ),
            Visibility(
              visible: _defaultPrinterType == PrinterType.network && Platform.isWindows,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  controller: _portController,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  decoration: InputDecoration(
                    label: Text('port'.tr),
                    prefixIcon: Icon(Icons.numbers_outlined, size: 24),
                  ),
                  onChanged: _setPort,
                ),
              ),
            ),
            Visibility(
              visible: _defaultPrinterType == PrinterType.network && Platform.isWindows,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: OutlinedButton(
                  onPressed: () async {
                    if (_ipController.text.isNotEmpty) _setIpAddress(_ipController.text);
                    _printReceipt();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 50),
                    child: Text("print_ticket".tr, textAlign: TextAlign.center),
                  ),
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}
