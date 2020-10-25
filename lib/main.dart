import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './screens/splash_screen.dart';
import './screens/products_overview_screen.dart';
import './screens/product_detail_screen.dart';
import './providers/products.dart';
import './providers/auth.dart';
import './screens/user_products_screen.dart';
import './screens/edit_product_screen.dart';
import './screens/auth_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Auth(),
        ),
        ChangeNotifierProxyProvider<Auth, Products>(
          update: (ctx, auth, previousProducts) => Products(
            auth.token,
            auth.userId,
            previousProducts == null ? [] : previousProducts.items,
          ),
        ),
      ],
      child: Consumer<Auth>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'イベントアプリ',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            accentColor: Colors.black54,
            fontFamily: 'Lato',
          ),
          // TOOD, auth.tryAutoLogin() ? x : y でいいのでは＞？
          home: FutureBuilder(
            future: auth.tryAutoLogin(),
            builder: (ctx, authResultSnapshot) {
              if(auth.isAuth) {
                print('----snapshow----');
                print(auth.isAuth);
                print(authResultSnapshot.hasData);
                print('----snapshow----');
                return ProductsOverviewScreen();
              }
              return AuthScreen();
            }
          ),
          routes: {
            ProductDetailScreen.routeName: (ctx) => ProductDetailScreen(),
            UserProductsScreen.routeName: (ctx) => UserProductsScreen(),
            EditProductScreen.routeName: (ctx) => EditProductScreen(),
          },
        ),
      ),
    );
  }
}

//
//auth.isAuth
//? ProductsOverviewScreen()
//    : FutureBuilder(
//future: auth.tryAutoLogin(),
//builder: (ctx, authResultSnapshot) =>
//authResultSnapshot.connectionState == ConnectionState.waiting
//? SplashScreen()
//    : AuthScreen(),
//),
