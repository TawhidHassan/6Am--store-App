import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Function onPressed;
  final String buttonText;
  final bool transparent;
  final EdgeInsets margin;
  final double height;
  final double width;
  final double fontSize;
  final Color color;
  final IconData icon;
  CustomButton({this.onPressed, @required this.buttonText, this.transparent = false, this.margin,
    this.width, this.height, this.fontSize, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final ButtonStyle _flatButtonStyle = TextButton.styleFrom(
      backgroundColor: onPressed == null ? Theme.of(context).disabledColor : transparent
          ? Colors.transparent : color != null ? color : Theme.of(context).primaryColor,
      minimumSize: Size(width != null ? width : 1170, height != null ? height : 45),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
      ),
    );

    return Padding(
      padding: margin == null ? EdgeInsets.all(0) : margin,
      child: TextButton(
        onPressed: onPressed,
        style: _flatButtonStyle,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon != null ? Icon(icon, color: transparent ? Theme.of(context).primaryColor : Theme.of(context).cardColor) : SizedBox(),
          SizedBox(width: icon != null ? Dimensions.PADDING_SIZE_SMALL : 0),
          Text(buttonText ??'', textAlign: TextAlign.center, style: robotoBold.copyWith(
            color: transparent ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
            fontSize: fontSize != null ? fontSize : Dimensions.FONT_SIZE_LARGE,
          )),
        ]),
      ),
    );
  }
}
