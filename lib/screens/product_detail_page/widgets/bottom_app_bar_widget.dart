import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/add_to_cart/add_to_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/add_to_cart/add_to_cart_event.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/services/auth_guard.dart';
import '../model/product_detail_model.dart';

class BottomAppBarWidget extends StatelessWidget {
  final ProductData productData;
  const BottomAppBarWidget({super.key, required this.productData});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 8,
      child: Container(
        height: 80,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      '₹499',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '₹599',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        '50% OFF',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  ],
                ),
                Text(
                  '(inclusive of all tax)',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            CustomButton(
              onPressed: () async {
                if (await AuthGuard.ensureLoggedIn(context)) {
                  if(context.mounted){
                    context.read<AddToCartBloc>().add(AddItemToCart(
                        productVariantId: productData.variants.first.id,
                        storeId: productData.variants.first.storeId,
                        quantity: 1));
                  }
                }
              },
              child: Text(
                'Add',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
