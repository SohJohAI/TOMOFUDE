/// A model class representing a subscription plan.
///
/// This class contains information about a subscription plan, including
/// its ID, name, description, price, and points per month.
class SubscriptionPlan {
  /// The plan ID used in Stripe.
  final String id;

  /// The plan name (梅・竹・松).
  final String name;

  /// The plan description.
  final String description;

  /// The plan price in Japanese Yen.
  final int priceJpy;

  /// The number of points given per month.
  final int pointsPerMonth;

  /// Creates a new subscription plan.
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceJpy,
    required this.pointsPerMonth,
  });

  /// The 梅 (Ume) plan - Basic plan.
  static const ume = SubscriptionPlan(
    id: 'plan_ume',
    name: '梅プラン',
    description: '基本的な機能と月500ポイント',
    priceJpy: 500,
    pointsPerMonth: 500,
  );

  /// The 竹 (Take) plan - Standard plan.
  static const take = SubscriptionPlan(
    id: 'plan_take',
    name: '竹プラン',
    description: '全機能と月1000ポイント',
    priceJpy: 980,
    pointsPerMonth: 1000,
  );

  /// The 松 (Matsu) plan - Premium plan.
  static const matsu = SubscriptionPlan(
    id: 'plan_matsu',
    name: '松プラン',
    description: '全機能と月2000ポイント、優先サポート',
    priceJpy: 1980,
    pointsPerMonth: 2000,
  );

  /// All available plans.
  static const List<SubscriptionPlan> all = [ume, take, matsu];

  /// Get a plan by its ID.
  static SubscriptionPlan? getById(String id) {
    try {
      return all.firstWhere((plan) => plan.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Convert this plan to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priceJpy': priceJpy,
      'pointsPerMonth': pointsPerMonth,
    };
  }

  /// Create a plan from a map.
  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      priceJpy: map['priceJpy'],
      pointsPerMonth: map['pointsPerMonth'],
    );
  }
}
