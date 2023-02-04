import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCard extends StatelessWidget {
  final String title;
  final String data;
  ProfileCard({@required this.data, @required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 200], blurRadius: 5, spreadRadius: 1)],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(data, style: robotoMedium.copyWith(
          fontSize: Dimensions.FONT_SIZE_EXTRA_LARGE, color: Theme.of(context).primaryColor,
        )),
        SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
        Text(title, style: robotoRegular.copyWith(
          fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor,
        )),
      ]),
    ));
  }
}
