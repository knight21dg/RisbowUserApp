import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/shopping_list_page/bloc/shopping_list_bloc/shopping_list_bloc.dart';
import 'package:hyper_local/screens/shopping_list_page/widgets/shopping_list_widget.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/l10n/app_localizations.dart';

class ShoppingListResultPage extends StatefulWidget {
  const ShoppingListResultPage({super.key});

  @override
  State<ShoppingListResultPage> createState() => _ShoppingListResultPageState();
}

class _ShoppingListResultPageState extends State<ShoppingListResultPage> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: true,
      title: AppLocalizations.of(context)!.shoppingList,
      showAppBar: true,
      body: BlocBuilder<ShoppingListBloc, ShoppingListState>(
        builder: (BuildContext context, ShoppingListState state) {
          if(state is ShoppingListLoaded) {
            final filteredList = state.shoppingListData.where((item) => item.totalProducts != null && item.totalProducts! > 0).toList();
            return filteredList.isNotEmpty ? ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: ShoppingListWidget(
                      product: filteredList[index].products!,
                      title: filteredList[index].keyword ?? '',
                      totalProducts: filteredList[index].totalProducts ?? 0,
                    ),
                  );
                }
            ) : NoProductPage();
          }
          return CustomCircularProgressIndicator();
        },
      )
    );
  }
}
