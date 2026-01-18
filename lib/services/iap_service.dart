
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../repositories/game_repository.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final GameRepository _repository = GameRepository();

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  final StreamController<List<PurchaseDetails>> _purchaseStreamController = StreamController.broadcast();

  // Product IDs
  static const String _productIdRemoveAds = 'com.carochess.remove_ads';
  static const String _productIdCoins100 = 'com.carochess.coins_100';
  static const String _productIdCoins500 = 'com.carochess.coins_500'; // Recommended
  static const String _productIdCoins1000 = 'com.carochess.coins_1000';

  static const Set<String> _kIds = {
    _productIdRemoveAds,
    _productIdCoins100,
    _productIdCoins500,
    _productIdCoins1000,
  };

  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseStreamController.stream;
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;

  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      await _loadProducts();
      _iap.purchaseStream.listen((purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      }, onDone: () {
        _purchaseStreamController.close();
      }, onError: (error) {
        debugPrint("IAP Error: $error");
      });
    } else {
        debugPrint("IAP Not Available");
    }
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(_kIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("IAP Products not found: ${response.notFoundIDs}");
      }
      _products = response.productDetails;
    } catch (e) {
      debugPrint("IAP Query Error: $e");
    }

    // MOCK PRODUCTS FOR DEBUGGING
    if (kDebugMode && _products.isEmpty) {
       debugPrint("IAP: Loading MOCK products for Debugging");
       _products = [
          ProductDetails(id: _productIdRemoveAds, title: 'Remove Ads', description: 'Remove all ads', price: '\$1.99', rawPrice: 1.99, currencyCode: 'USD'),
          ProductDetails(id: _productIdCoins100, title: '100 Coins', description: 'Stack of coins', price: '\$0.99', rawPrice: 0.99, currencyCode: 'USD'),
          ProductDetails(id: _productIdCoins500, title: '500 Coins', description: 'Bag of coins', price: '\$3.99', rawPrice: 3.99, currencyCode: 'USD'),
          ProductDetails(id: _productIdCoins1000, title: '1000 Coins', description: 'Chest of coins', price: '\$6.99', rawPrice: 6.99, currencyCode: 'USD'),
       ];
    }
  }

  Future<void> buyNonConsumable(ProductDetails product) async {
    if (kDebugMode) {
        _simulatePurchase(product);
        return;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> buyConsumable(ProductDetails product) async {
    if (kDebugMode) {
        _simulatePurchase(product);
        return;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: false); 
  }
  
  void _simulatePurchase(ProductDetails product) {
      debugPrint("IAP: Simulating purchase for ${product.id}");
      Future.delayed(const Duration(seconds: 1), () {
          final purchase = PurchaseDetails(
              productID: product.id,
              status: PurchaseStatus.purchased,
              transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
              verificationData: PurchaseVerificationData(localVerificationData: 'mock', serverVerificationData: 'mock', source: 'mock'),
          );
          _purchaseStreamController.add([purchase]);
      });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    _purchaseStreamController.add(purchaseDetailsList);
    
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI?
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint("Purchase Error: ${purchaseDetails.error}");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          await _deliverProduct(purchaseDetails);
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
     final productId = purchaseDetails.productID;

     if (productId == _productIdRemoveAds) {
         // Enable Premium
         await _repository.savePremiumStatus(true);
         debugPrint("IAP: Remove Ads Delivered");
     } else {
         // Consumables (Coins)
         int coins = 0;
         if (productId == _productIdCoins100) coins = 100;
         else if (productId == _productIdCoins500) coins = 500;
         else if (productId == _productIdCoins1000) coins = 1000;

         if (coins > 0) {
             debugPrint("IAP: $coins Coins Delivered");
         }
     }
  }
  
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
  
  // Helper to get specific product
  ProductDetails? getProduct(String id) {
      try {
          return _products.firstWhere((p) => p.id == id);
      } catch (e) {
          return null;
      }
  }
}
