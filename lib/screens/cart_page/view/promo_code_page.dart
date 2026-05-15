import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/screens/cart_page/bloc/promo_code/promo_code_event.dart';
import 'package:hyper_local/screens/cart_page/bloc/promo_code/promo_code_state.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/services/feature_settings_service.dart';

import '../bloc/promo_code/promo_code_bloc.dart';
import '../widgets/coupon_card.dart';

class PromoCodePage extends StatefulWidget {
  const PromoCodePage({super.key});

  @override
  State<PromoCodePage> createState() => _PromoCodePageState();
}

class _PromoCodePageState extends State<PromoCodePage> {

  @override
  void initState() {
    // TODO: implement initState
    context.read<PromoCodeBloc>().add(FetchPromoCode());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    if (!FeatureSettingsService.instance.couponsEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.promoCodeCoupons ?? 'Coupons')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Coupons are currently unavailable',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    
    return CustomScaffold(
      showViewCart: false,
      appBar: AppBar(
        title: Text(l10n?.promoCodeCoupons ?? 'Promo Code & Coupons'),
      ),
      body: BlocBuilder<PromoCodeBloc, PromoCodeState>(
        builder: (BuildContext context, PromoCodeState state) {
          if(state is PromoCodeLoaded) {
            return ListView.builder(
              itemCount: state.promoCodeData.length,
              itemBuilder: (context, index){
                final coupon = state.promoCodeData[index];
                return CouponCard(
                  title: coupon.description ?? '',
                  subtitle: coupon.description ?? '',
                  couponCode: coupon.code ?? '',
                  isCollected: context.read<PromoCodeBloc>().selectedPromoCode == coupon.code,
                  onTap: (){
                    final code = coupon.code ?? '';
                    if(code.isNotEmpty){
                      context.read<PromoCodeBloc>().add(SelectPromoCode(code));
                      GoRouter.of(context).pop(code);
                    }
                  },
                );
              }
            );
          }
          return CustomCircularProgressIndicator();
        },
      )
    );
  }
}
