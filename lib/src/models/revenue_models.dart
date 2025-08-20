/// Base class for revenue tracking
abstract class IaRevenueEvent {
  final String eventName;
  final double amount;
  final String currency;
  final Map<String, dynamic> properties;

  IaRevenueEvent({
    required this.eventName,
    required this.amount,
    required this.currency,
    Map<String, dynamic>? properties,
  }) : properties = Map.unmodifiable(properties ?? {});

  Map<String, dynamic> toMap();

  /// Validate revenue event data
  List<String> validate() {
    final errors = <String>[];
    
    if (eventName.isEmpty) {
      errors.add('Event name cannot be empty');
    }
    
    if (amount < 0) {
      errors.add('Amount cannot be negative');
    }
    
    if (currency.isEmpty) {
      errors.add('Currency cannot be empty');
    }
    
    if (currency.length != 3) {
      errors.add('Currency must be a 3-letter ISO code (e.g., USD, EUR)');
    }
    
    return errors;
  }
}

/// Simple revenue event
class IaRevenue extends IaRevenueEvent {
  IaRevenue({
    required String eventName,
    required double amount,
    required String currency,
    Map<String, dynamic>? properties,
  }) : super(
          eventName: eventName,
          amount: amount,
          currency: currency,
          properties: properties,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'eventName': eventName,
      'amount': amount,
      'currency': currency,
      'properties': {
        ...properties,
        'is_revenue_event': true,
        'r': amount,
        'pcc': currency,
      },
    };
  }
}

/// Enhanced revenue event with product details
class IaRevenueWithProduct extends IaRevenueEvent {
  final String? productSku;
  final String? productName;
  final String? productCategory;
  final int quantity;
  final double? unitPrice;

  IaRevenueWithProduct({
    required String eventName,
    required double amount,
    required String currency,
    this.productSku,
    this.productName,
    this.productCategory,
    this.quantity = 1,
    this.unitPrice,
    Map<String, dynamic>? properties,
  }) : super(
          eventName: eventName,
          amount: amount,
          currency: currency,
          properties: properties,
        );

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'eventName': eventName,
      'amount': amount,
      'currency': currency,
      'quantity': quantity,
      'properties': <String, dynamic>{
        ...properties,
        'is_revenue_event': true,
        'r': amount,
        'pcc': currency,
        'product_quantity': quantity,
      },
    };

    if (productSku != null) {
      map['productSku'] = productSku!;
      (map['properties'] as Map<String, dynamic>)['product_sku'] = productSku!;
    }
    
    if (productName != null) {
      map['productName'] = productName!;
      (map['properties'] as Map<String, dynamic>)['product_name'] = productName!;
    }
    
    if (productCategory != null) {
      map['productCategory'] = productCategory!;
      (map['properties'] as Map<String, dynamic>)['product_category'] = productCategory!;
    }
    
    if (unitPrice != null) {
      map['unitPrice'] = unitPrice!;
      (map['properties'] as Map<String, dynamic>)['product_price'] = unitPrice!;
    }

    return map;
  }

  @override
  List<String> validate() {
    final errors = super.validate();
    
    if (quantity <= 0) {
      errors.add('Quantity must be greater than 0');
    }
    
    if (unitPrice != null && unitPrice! < 0) {
      errors.add('Unit price cannot be negative');
    }
    
    return errors;
  }
}

/// Base class for In-App Purchase events
abstract class IaInAppPurchase extends IaRevenueEvent {
  IaInAppPurchase({
    required String eventName,
    required double amount,
    required String currency,
    Map<String, dynamic>? properties,
  }) : super(
          eventName: eventName,
          amount: amount,
          currency: currency,
          properties: properties,
        );
}

/// iOS In-App Purchase event
class IaIOSInAppPurchase extends IaInAppPurchase {
  final String productId;
  final String transactionId;
  final String receiptData;

  IaIOSInAppPurchase({
    required String eventName,
    required double amount,
    required String currency,
    required this.productId,
    required this.transactionId,
    required this.receiptData,
    Map<String, dynamic>? properties,
  }) : super(
          eventName: eventName,
          amount: amount,
          currency: currency,
          properties: properties,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'eventName': eventName,
      'amount': amount,
      'currency': currency,
      'productId': productId,
      'transactionId': transactionId,
      'receiptData': receiptData,
      'platform': 'ios',
      'properties': {
        ...properties,
        'is_revenue_event': true,
        'r': amount,
        'pcc': currency,
        'pk': productId,           // product key
        'pti': transactionId,      // purchase transaction id
        'ptr': receiptData,        // purchase transaction receipt
      },
    };
  }

  @override
  List<String> validate() {
    final errors = super.validate();
    
    if (productId.isEmpty) {
      errors.add('Product ID cannot be empty');
    }
    
    if (transactionId.isEmpty) {
      errors.add('Transaction ID cannot be empty');
    }
    
    if (receiptData.isEmpty) {
      errors.add('Receipt data cannot be empty');
    }
    
    return errors;
  }
}

/// Android In-App Purchase event
class IaAndroidInAppPurchase extends IaInAppPurchase {
  final String productId;
  final String purchaseToken;
  final String signature;
  final String purchaseData;

  IaAndroidInAppPurchase({
    required String eventName,
    required double amount,
    required String currency,
    required this.productId,
    required this.purchaseToken,
    required this.signature,
    required this.purchaseData,
    Map<String, dynamic>? properties,
  }) : super(
          eventName: eventName,
          amount: amount,
          currency: currency,
          properties: properties,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'eventName': eventName,
      'amount': amount,
      'currency': currency,
      'productId': productId,
      'purchaseToken': purchaseToken,
      'signature': signature,
      'purchaseData': purchaseData,
      'platform': 'android',
      'properties': {
        ...properties,
        'is_revenue_event': true,
        'r': amount,
        'pcc': currency,
        'product_id': productId,
        'purchase_token': purchaseToken,
        'receipt_signature': signature,
        'receipt': purchaseData,
      },
    };
  }

  @override
  List<String> validate() {
    final errors = super.validate();
    
    if (productId.isEmpty) {
      errors.add('Product ID cannot be empty');
    }
    
    if (purchaseToken.isEmpty) {
      errors.add('Purchase token cannot be empty');
    }
    
    if (signature.isEmpty) {
      errors.add('Signature cannot be empty');
    }
    
    if (purchaseData.isEmpty) {
      errors.add('Purchase data cannot be empty');
    }
    
    return errors;
  }
}