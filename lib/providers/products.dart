import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/http_exception.dart';
import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<Map<String, String>> getAuthorization() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return {};
    }
    final extractedUserData = json.decode(prefs.getString('userData')) as Map<String, Object>;

    return {
      'Content-Type': 'application/json',
      'access-token': extractedUserData['access-token'],
      'client': extractedUserData['client'],
      'uid': extractedUserData['uid']
    };
  }

  Future<void> fetchAndSetProducts() async {

    print('sentinel1');
    var url = 'http://10.0.2.2:3001/api/events';
    var headers = await getAuthorization();
    print('sentinel2');
    try {
      print('sentinel3');
      final response = await http.get(url, headers: headers);
      final extractedData = json.decode(response.body)['response'] as List;

      if (extractedData == null) {
        return;
      }
      print('sentinel4');
      final List<Product> loadedProducts = [];
      for (int i = 0; i < extractedData.length; i++) {
        loadedProducts.add(Product(
          id: extractedData[i]['id'].toString(),
          title: extractedData[i]['title'],
          description: extractedData[i]['body'],
          price: 10,
          isFavorite: false,
          imageUrl: 'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
        ));
      }
      print('sentinel5');
      _items = loadedProducts;
      print('sentinel5.5');
      notifyListeners();
      print('sentinel6');
    } catch (error) {
      print('sentinel7');
      throw (error);
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://shopapp-c1d6b.firebaseio.com/products.json?auth=$authToken';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': userId,
        }),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      // _items.insert(0, newProduct); // at the start of the list
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://shopapp-c1d6b.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://shopapp-c1d6b.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}
