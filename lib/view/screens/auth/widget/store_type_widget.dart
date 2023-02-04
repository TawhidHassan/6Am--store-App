// import 'package:flutter/material.dart';
// import 'package:sixam_mart_store/controller/auth_controller.dart';
// import 'package:sixam_mart_store/util/dimensions.dart';
// import 'package:sixam_mart_store/util/styles.dart';
// class StoreTypeWidget extends StatelessWidget {
//   final AuthController authController;
//   final String title;
//   final Function onTap;
//   const StoreTypeWidget({Key key, @required this.authController, @required this.title, @required this.onTap}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//             color: authController.vendorOwner ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
//             borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL)
//         ),
//         child: Center(child: Text(
//           title,
//           style: robotoMedium.copyWith(color: authController.vendorOwner ? Theme.of(context).cardColor : Theme.of(context).primaryColor),
//         )),
//       ),
//     );
//   }
// }
