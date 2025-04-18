import '../models/subscription_plan.dart';

/// Interface for Stripe payment service
///
/// This interface defines the contract for Stripe payment operations,
/// allowing for different implementations (e.g., production, mock, etc.)
abstract class StripeServiceInterface {
  /// Initialize the Stripe service
  ///
  /// This method should be called before using the service.
  Future<void> initialize();

  /// Create a payment intent for a subscription
  ///
  /// This method creates a payment intent for the given subscription plan.
  /// It returns a map containing the payment intent details.
  Future<Map<String, dynamic>> createPaymentIntent(SubscriptionPlan plan);

  /// Start the payment process
  ///
  /// This method starts the payment process for the given subscription plan.
  /// It returns true if the payment was successful, false otherwise.
  Future<bool> startPayment(SubscriptionPlan plan);

  /// Get the current subscription
  ///
  /// This method returns the current subscription plan for the authenticated user.
  /// It returns null if the user is not authenticated or has no subscription.
  Future<SubscriptionPlan?> getCurrentSubscription();

  /// Cancel the current subscription
  ///
  /// This method cancels the current subscription for the authenticated user.
  /// It returns true if the cancellation was successful, false otherwise.
  Future<bool> cancelSubscription();

  /// Check if the user has an active subscription
  ///
  /// This method checks if the authenticated user has an active subscription.
  /// It returns true if the user has an active subscription, false otherwise.
  Future<bool> hasActiveSubscription();
}
