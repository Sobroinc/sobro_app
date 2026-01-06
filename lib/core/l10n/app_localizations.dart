import 'package:flutter/material.dart';

/// Supported locales.
const supportedLocales = [Locale('en'), Locale('ru')];

/// App localizations.
/// Per Flutter i18n docs: https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'warehouse': 'Warehouse',
      'newInventory': 'New Inventory',
      'auctions': 'Auctions',
      'sales': 'Sales',
      'clients': 'Clients',

      // Login
      'login': 'Login',
      'username': 'Username',
      'password': 'Password',
      'enterUsername': 'Enter username',
      'enterPassword': 'Enter password',
      'loginFailed': 'Login failed',
      'connectionError': 'Connection error',

      // Common
      'settings': 'Settings',
      'profile': 'Profile',
      'logout': 'Logout',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'noData': 'No data',
      'retry': 'Retry',

      // Warehouse/Products
      'products': 'Products',
      'productDetails': 'Product Details',
      'newProduct': 'New Product',
      'editProduct': 'Edit Product',
      'productName': 'Product Name',
      'description': 'Description',
      'price': 'Price',
      'quantity': 'Quantity',
      'category': 'Category',
      'status': 'Status',
      'photos': 'Photos',
      'addPhoto': 'Add Photo',

      // Inventory
      'inventory': 'Inventory',
      'inventoryDetails': 'Inventory Details',
      'newInventoryItem': 'New Inventory Item',
      'location': 'Location',
      'condition': 'Condition',
      'notes': 'Notes',

      // Clients
      'clientDetails': 'Client Details',
      'newClient': 'New Client',
      'clientName': 'Client Name',
      'phone': 'Phone',
      'email': 'Email',
      'address': 'Address',
      'clientType': 'Client Type',
      'buyer': 'Buyer',
      'seller': 'Seller',

      // Auctions
      'auctionDetails': 'Auction Details',
      'currentBid': 'Current Bid',
      'startingPrice': 'Starting Price',
      'endTime': 'End Time',
      'placeBid': 'Place Bid',
      'bidAmount': 'Bid Amount',

      // Sales/Operations
      'operations': 'Operations',
      'orders': 'Orders',
      'orderDetails': 'Order Details',
      'totalAmount': 'Total Amount',
      'paymentStatus': 'Payment Status',
      'paid': 'Paid',
      'pending': 'Pending',
      'completed': 'Completed',

      // Settings
      'language': 'Language',
      'theme': 'Theme',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'systemTheme': 'System',
      'notifications': 'Notifications',
      'about': 'About',
      'version': 'Version',

      // Confirmation dialogs
      'confirmDelete': 'Are you sure you want to delete?',
      'confirmLogout': 'Are you sure you want to logout?',
      'yes': 'Yes',
      'no': 'No',
    },
    'ru': {
      // Navigation
      'warehouse': 'Склад',
      'newInventory': 'Новый склад',
      'auctions': 'Аукцион',
      'sales': 'Продажи',
      'clients': 'Клиенты',

      // Login
      'login': 'Вход',
      'username': 'Имя пользователя',
      'password': 'Пароль',
      'enterUsername': 'Введите имя пользователя',
      'enterPassword': 'Введите пароль',
      'loginFailed': 'Ошибка входа',
      'connectionError': 'Ошибка соединения',

      // Common
      'settings': 'Настройки',
      'profile': 'Профиль',
      'logout': 'Выход',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'add': 'Добавить',
      'search': 'Поиск',
      'loading': 'Загрузка...',
      'error': 'Ошибка',
      'success': 'Успешно',
      'noData': 'Нет данных',
      'retry': 'Повторить',

      // Warehouse/Products
      'products': 'Товары',
      'productDetails': 'Детали товара',
      'newProduct': 'Новый товар',
      'editProduct': 'Редактировать товар',
      'productName': 'Название товара',
      'description': 'Описание',
      'price': 'Цена',
      'quantity': 'Количество',
      'category': 'Категория',
      'status': 'Статус',
      'photos': 'Фотографии',
      'addPhoto': 'Добавить фото',

      // Inventory
      'inventory': 'Инвентарь',
      'inventoryDetails': 'Детали инвентаря',
      'newInventoryItem': 'Новая позиция',
      'location': 'Местоположение',
      'condition': 'Состояние',
      'notes': 'Заметки',

      // Clients
      'clientDetails': 'Детали клиента',
      'newClient': 'Новый клиент',
      'clientName': 'Имя клиента',
      'phone': 'Телефон',
      'email': 'Email',
      'address': 'Адрес',
      'clientType': 'Тип клиента',
      'buyer': 'Покупатель',
      'seller': 'Продавец',

      // Auctions
      'auctionDetails': 'Детали аукциона',
      'currentBid': 'Текущая ставка',
      'startingPrice': 'Начальная цена',
      'endTime': 'Время окончания',
      'placeBid': 'Сделать ставку',
      'bidAmount': 'Сумма ставки',

      // Sales/Operations
      'operations': 'Операции',
      'orders': 'Заказы',
      'orderDetails': 'Детали заказа',
      'totalAmount': 'Итого',
      'paymentStatus': 'Статус оплаты',
      'paid': 'Оплачено',
      'pending': 'Ожидает',
      'completed': 'Завершено',

      // Settings
      'language': 'Язык',
      'theme': 'Тема',
      'darkMode': 'Тёмная тема',
      'lightMode': 'Светлая тема',
      'systemTheme': 'Системная',
      'notifications': 'Уведомления',
      'about': 'О приложении',
      'version': 'Версия',

      // Confirmation dialogs
      'confirmDelete': 'Вы уверены, что хотите удалить?',
      'confirmLogout': 'Вы уверены, что хотите выйти?',
      'yes': 'Да',
      'no': 'Нет',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Navigation
  String get warehouse => get('warehouse');
  String get newInventory => get('newInventory');
  String get auctions => get('auctions');
  String get sales => get('sales');
  String get clients => get('clients');

  // Login
  String get login => get('login');
  String get username => get('username');
  String get password => get('password');
  String get enterUsername => get('enterUsername');
  String get enterPassword => get('enterPassword');
  String get loginFailed => get('loginFailed');
  String get connectionError => get('connectionError');

  // Common
  String get settings => get('settings');
  String get profile => get('profile');
  String get logout => get('logout');
  String get save => get('save');
  String get cancel => get('cancel');
  String get delete => get('delete');
  String get edit => get('edit');
  String get add => get('add');
  String get search => get('search');
  String get loading => get('loading');
  String get error => get('error');
  String get success => get('success');
  String get noData => get('noData');
  String get retry => get('retry');

  // Warehouse/Products
  String get products => get('products');
  String get productDetails => get('productDetails');
  String get newProduct => get('newProduct');
  String get editProduct => get('editProduct');
  String get productName => get('productName');
  String get description => get('description');
  String get price => get('price');
  String get quantity => get('quantity');
  String get category => get('category');
  String get status => get('status');
  String get photos => get('photos');
  String get addPhoto => get('addPhoto');

  // Inventory
  String get inventory => get('inventory');
  String get inventoryDetails => get('inventoryDetails');
  String get newInventoryItem => get('newInventoryItem');
  String get location => get('location');
  String get condition => get('condition');
  String get notes => get('notes');

  // Clients
  String get clientDetails => get('clientDetails');
  String get newClient => get('newClient');
  String get clientName => get('clientName');
  String get phone => get('phone');
  String get email => get('email');
  String get address => get('address');
  String get clientType => get('clientType');
  String get buyer => get('buyer');
  String get seller => get('seller');

  // Auctions
  String get auctionDetails => get('auctionDetails');
  String get currentBid => get('currentBid');
  String get startingPrice => get('startingPrice');
  String get endTime => get('endTime');
  String get placeBid => get('placeBid');
  String get bidAmount => get('bidAmount');

  // Sales/Operations
  String get operations => get('operations');
  String get orders => get('orders');
  String get orderDetails => get('orderDetails');
  String get totalAmount => get('totalAmount');
  String get paymentStatus => get('paymentStatus');
  String get paid => get('paid');
  String get pending => get('pending');
  String get completed => get('completed');

  // Settings
  String get language => get('language');
  String get theme => get('theme');
  String get darkMode => get('darkMode');
  String get lightMode => get('lightMode');
  String get systemTheme => get('systemTheme');
  String get notifications => get('notifications');
  String get about => get('about');
  String get version => get('version');

  // Confirmation dialogs
  String get confirmDelete => get('confirmDelete');
  String get confirmLogout => get('confirmLogout');
  String get yes => get('yes');
  String get no => get('no');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
