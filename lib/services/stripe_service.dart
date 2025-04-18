import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../models/subscription_plan.dart';
import '../utils/error_handler.dart';
import 'stripe_service_interface.dart';
import 'supabase_service_interface.dart';
import 'service_locator.dart';

/// Service for handling Stripe payment operations.
///
/// This service provides methods for creating payment intents,
/// starting the payment process, and managing subscriptions.
class StripeService implements StripeServiceInterface {
  /// Singleton instance
  static final StripeService _instance = StripeService._internal();

  /// Factory constructor to return the same instance
  factory StripeService() => _instance;

  /// The Supabase service
  final SupabaseServiceInterface _supabaseService;

  /// The backend API URL for Stripe operations
  final String _apiUrl;

  /// Private constructor
  StripeService._internal()
      : _supabaseService = serviceLocator<SupabaseServiceInterface>(),
        _apiUrl = kReleaseMode
            ? 'https://your-production-api.com' // Replace with your production API URL
            : 'http://localhost:3000'; // Replace with your development API URL

  /// Initialize the Stripe service
  @override
  Future<void> initialize() async {
    return errorHandler.handleAsync(
      () async {
        // Initialize Stripe
        Stripe.publishableKey = kReleaseMode
            ? 'pk_live_your_publishable_key' // Replace with your production publishable key
            : 'pk_test_your_test_publishable_key'; // Replace with your test publishable key

        // Set merchant identifier (for Apple Pay)
        await Stripe.instance.applySettings();

        print('Stripe service initialized');
      },
      'StripeService.initialize',
      '決済サービスの初期化中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
      },
    );
  }

  /// Create a payment intent for a subscription
  @override
  Future<Map<String, dynamic>> createPaymentIntent(
      SubscriptionPlan plan) async {
    final result = await errorHandler.handleAsync<Map<String, dynamic>>(
      () async {
        // Check if the user is authenticated
        final user = _supabaseService.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Create payment intent on the server
        final response = await http.post(
          Uri.parse('$_apiUrl/create-payment-intent'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'amount': plan.priceJpy,
            'currency': 'jpy',
            'payment_method_types': ['card'],
            'metadata': {
              'userId': user.id,
              'planId': plan.id,
              'planName': plan.name,
            },
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to create payment intent: ${response.body}');
        }

        return jsonDecode(response.body);
      },
      'StripeService.createPaymentIntent',
      '決済情報の作成中にエラーが発生しました',
    );

    if (result == null) {
      throw Exception('Failed to create payment intent');
    }

    return result;
  }

  /// Start the payment process
  @override
  Future<bool> startPayment(SubscriptionPlan plan) async {
    final result = await errorHandler.handleAsync<bool>(
      () async {
        // Create payment intent
        final paymentIntentData = await createPaymentIntent(plan);
        final clientSecret = paymentIntentData['clientSecret'];

        // Initialize payment sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'TOMOFUDE',
            style: ThemeMode.system,
          ),
        );

        // Present payment sheet
        await Stripe.instance.presentPaymentSheet();

        // Payment successful
        return true;
      },
      'StripeService.startPayment',
      '決済処理中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return false;
      },
    );

    return result ?? false;
  }

  /// Get the current subscription
  @override
  Future<SubscriptionPlan?> getCurrentSubscription() async {
    return errorHandler.handleAsync<SubscriptionPlan?>(
      () async {
        // Check if the user is authenticated
        final user = _supabaseService.currentUser;
        if (user == null) {
          return null;
        }

        // Get user data from Supabase
        final userData = await _supabaseService.client
            .from('users')
            .select('plan')
            .eq('id', user.id)
            .maybeSingle();

        if (userData == null) {
          return null;
        }

        final planId = userData['plan'] as String?;
        if (planId == null) {
          return null;
        }

        // Get subscription plan by ID
        return SubscriptionPlan.getById(planId);
      },
      'StripeService.getCurrentSubscription',
      'サブスクリプション情報の取得中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return null;
      },
    );
  }

  /// Cancel the current subscription
  @override
  Future<bool> cancelSubscription() async {
    final result = await errorHandler.handleAsync<bool>(
      () async {
        // Check if the user is authenticated
        final user = _supabaseService.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Cancel subscription on the server
        final response = await http.post(
          Uri.parse('$_apiUrl/cancel-subscription'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'userId': user.id,
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to cancel subscription: ${response.body}');
        }

        // Update user data in Supabase
        await _supabaseService.client.from('users').update({
          'plan': 'free',
        }).eq('id', user.id);

        return true;
      },
      'StripeService.cancelSubscription',
      'サブスクリプションのキャンセル中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return false;
      },
    );

    return result ?? false;
  }

  /// Check if the user has an active subscription
  @override
  Future<bool> hasActiveSubscription() async {
    final result = await errorHandler.handleAsync<bool>(
      () async {
        final subscription = await getCurrentSubscription();
        return subscription != null && subscription.id != 'free';
      },
      'StripeService.hasActiveSubscription',
      'サブスクリプション状態の確認中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return false;
      },
    );

    return result ?? false;
  }
}
