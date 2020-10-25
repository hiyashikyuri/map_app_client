import 'dart:convert';
import 'dart:async';

import 'package:map_app_client/providers/config.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _uid;
  int _userId;
  String _client;
  Timer _authTimer;

  bool get isAuth {
    return token != null;
  }

  String get token {
    if (_expiryDate != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }

    if (_token != null) {
      return _token;
    }
    return null;
  }

  int get userId {
    return _userId;
  }

  Future<void> setAuthorizationData(http.Response response) async {
    try {
      final responseData = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      _token = response.headers['access-token'];
      _uid = response.headers['uid'];
      _client = response.headers['client'];
      _userId = responseData['data']['id'];
      _expiryDate = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(response.headers['expiry']) * 1000);
      final userData = json.encode(
        {
          'access-token': _token,
          'user_id': _userId,
          'uid': _uid,
          'client': _client,
          'expiry': response.headers['expiry']
        },
      );
      prefs.setString('userData', userData);
    } catch(error) {
      print('------------------set sippai----');
      print(error);
      _token = null;
      _client = null;
      _uid = null;
      _userId = null;
      print('------------------set sippai----');
    }
  }

  Future<void> _authenticate(String prefix, Map<String, String> body) async {
    final url = '$apiPath/auth$prefix';
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (responseData['error'] != null) {
        print('---------------');
        print((responseData['error']['message']));
        print('---------------');
//        throw HttpException(responseData['error']['message']);
      }
      await setAuthorizationData(response);
      notifyListeners();
    } catch (error) {
      print(error);
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate('/',
      {
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  Future<void> login(String email, String password) async {
    return _authenticate('/sign_in', {
      'email': email,
      'password': password,
    },);
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    final extractedUserData = json.decode(prefs.getString('userData')) as Map<String, Object>;

    final expiryDate = DateTime.parse(extractedUserData['expiry']);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }

    // HTTPがgetなので個別で作成
    final response = await http.get('$apiPath/auth/validate_token?access-token=$_token&client=$_client&uid=$_uid', headers: {'Content-Type': 'application/json'},);
    final responseData = json.decode(response.body);
    print('---------------');
    if (responseData['error'] != null) {
      print((responseData['error']['message']));
      print('---------------');
      _token = null;
      _client = null;
      _uid = null;
      _userId = null;
      return false;
    }

    await setAuthorizationData(response);
    _autoLogout();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _uid = null;
    _client = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void _autoLogout() {
    print('try-logout-1');
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    print('try-logout-2');
    print(_authTimer);
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
    print(timeToExpiry);
    print('try-logout-3');
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
    print(_authTimer);
  }
}
