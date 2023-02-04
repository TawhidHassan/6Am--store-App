import 'package:sixam_mart_store/controller/store_controller.dart';
import 'package:sixam_mart_store/data/model/response/item_model.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:sixam_mart_store/view/base/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodVariationView extends StatefulWidget {
  final StoreController storeController;
  final Item item;
  const FoodVariationView({Key key, @required this.storeController, @required this.item}) : super(key: key);

  @override
  State<FoodVariationView> createState() => _FoodVariationViewState();
}

class _FoodVariationViewState extends State<FoodVariationView> {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'variation'.tr,
        style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
      ),
      SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),

      widget.storeController.variationList.length > 0 ? ListView.builder(
        itemCount: widget.storeController.variationList.length,
        shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index){
          return Stack(children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
              padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
              decoration: BoxDecoration(border: Border.all(color: Theme.of(context).primaryColor), borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: CustomTextField(
                    hintText: 'name'.tr,
                    showTitle: true,
                    // showShadow: true,
                    controller: widget.storeController.variationList[index].nameController,
                  )),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(top: Dimensions.PADDING_SIZE_DEFAULT),
                    child: CheckboxListTile(
                      value: widget.storeController.variationList[index].required,
                      title: Text('required'.tr),
                      tristate: true,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value){
                        widget.storeController.setVariationRequired(index);
                      },
                    ),
                  )),
                ]),
                SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Text('select_type'.tr, style: robotoMedium),

                  Row( children: [
                    InkWell(
                      onTap: () =>  widget.storeController.changeSelectVariationType(index),
                      child: Row(children: [
                        Radio<bool>(
                          value: true,
                          groupValue: widget.storeController.variationList[index].isSingle,
                          onChanged: (bool value){
                            widget.storeController.changeSelectVariationType(index);
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        Text('single'.tr)
                      ]),
                    ),
                    SizedBox(width: Dimensions.PADDING_SIZE_LARGE),

                    InkWell(
                      onTap: () =>  widget.storeController.changeSelectVariationType(index),
                      child: Row(children: [
                        Radio<bool>(
                          value: false,
                          groupValue: widget.storeController.variationList[index].isSingle,
                          onChanged: (bool value){
                            widget.storeController.changeSelectVariationType(index);
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        Text('multiple'.tr)
                      ]),
                    ),
                  ]),
                ]),

                Visibility(
                  visible: !widget.storeController.variationList[index].isSingle,
                  child: Row(children: [
                    Flexible(child: CustomTextField(
                      hintText: 'minimum'.tr,
                      showTitle: true,
                      // showShadow: true,
                      inputType: TextInputType.number,
                      isNumber: true,
                      controller: widget.storeController.variationList[index].minController,
                    )),
                    SizedBox(width: Dimensions.PADDING_SIZE_SMALL),

                    Flexible(child: CustomTextField(
                      hintText: 'maximum'.tr,
                      inputType: TextInputType.number,
                      showTitle: true,
                      // showShadow: true,
                      isNumber: true,
                      controller: widget.storeController.variationList[index].maxController,
                    )),

                  ]),
                ),
                SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

                Container(
                  padding: EdgeInsets.all(Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).primaryColor, width: 0.5),
                    borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    ListView.builder(
                      itemCount: widget.storeController.variationList[index].options.length,
                      shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                          child: Row(children: [
                            Flexible(flex: 4, child: CustomTextField(
                              hintText: 'option_name'.tr,
                              showTitle: true,
                              // showShadow: true,
                              controller: widget.storeController.variationList[index].options[i].optionNameController,
                            )),
                            SizedBox(width: Dimensions.PADDING_SIZE_SMALL),

                            Flexible(flex: 4, child: CustomTextField(
                              hintText: 'additional_price'.tr,
                              showTitle: true,
                              // showShadow: true,
                              isAmount: true,
                              controller: widget.storeController.variationList[index].options[i].optionPriceController,
                              inputType: TextInputType.number,
                              inputAction: TextInputAction.done,
                            )),

                            Flexible(flex: 1, child: Padding(
                              padding: const EdgeInsets.only(top: Dimensions.PADDING_SIZE_SMALL),
                              child: widget.storeController.variationList[index].options.length > 1 ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () => widget.storeController.removeOptionVariation(index, i),
                              ) : SizedBox(),
                            )),
                          ]),
                        );
                      },
                    ),

                    SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

                    InkWell(
                      onTap: () {
                        widget.storeController.addOptionVariation(index);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_SMALL, vertical: Dimensions.PADDING_SIZE_SMALL),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL), border: Border.all(color: Theme.of(context).primaryColor)),
                        child: Text('add_new_option'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_DEFAULT)),
                      ),
                    ),
                  ]),
                ),

              ]),
            ),

            Align(alignment: Alignment.topRight, child: IconButton(icon: Icon(Icons.clear),
              onPressed: () => widget.storeController.removeVariation(index),
            )),
          ]);
        },
      ) : SizedBox(),


      SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),

      InkWell(
        onTap: () {
          widget.storeController.addVariation();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_SMALL, vertical: Dimensions.PADDING_SIZE_SMALL),
          decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL)),
          child: Text('${widget.storeController.variationList.length > 0 ? 'add_new_variation'.tr : 'add_variation'.tr}', style: robotoMedium.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.FONT_SIZE_DEFAULT)),
        ),
      ),

      SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

    ]);
  }
}