import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/repositories/food_category_repository.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/repositories/restaurant_repository.dart';

void main() {
  group('FoodCategoryRepository', () {
    late FoodCategoryRepository repository;

    setUp(() {
      repository = const FoodCategoryRepository();
    });

    test('fetchFoodCategories returns list of food categories', () async {
      // Act
      final result = await repository.fetchFoodCategories();

      // Assert
      expect(result, isNotEmpty);
      expect(result.length, 5);
      expect(result[0].name, 'Pizza');
      expect(result[1].name, 'Burgers');
    });

    test('food categories have required fields', () async {
      // Act
      final result = await repository.fetchFoodCategories();

      // Assert
      for (final category in result) {
        expect(category.id, isNotEmpty);
        expect(category.name, isNotEmpty);
        expect(category.imageUrl, isNotEmpty);
      }
    });
  });

  group('RestaurantRepository', () {
    late RestaurantRepository repository;

    setUp(() {
      repository = const RestaurantRepository();
    });

    test('fetchRestaurants returns list of restaurants', () async {
      // Act
      final result = await repository.fetchRestaurants();

      // Assert
      expect(result, isNotEmpty);
      expect(result.length, 2);
      expect(result[0].name, 'Mad Pizza');
      expect(result[1].name, 'Drip Burger');
    });

    test('fetchRestaurant returns correct restaurant by id', () async {
      // Act
      final result = await repository.fetchRestaurant(
        restaurantId: 'restaurant_1',
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'restaurant_1');
      expect(result.name, 'Mad Pizza');
      expect(result.rating, 4.5);
    });

    test('fetchRestaurant throws RestaurantNotFoundException for invalid id', () async {
      // Assert
      expect(
        () => repository.fetchRestaurant(restaurantId: 'invalid_id'),
        throwsA(isA<RestaurantNotFoundException>()),
      );
    });

    test('fetchPopularRestaurants returns restaurants with rating >= 4.0', () async {
      // Act
      final result = await repository.fetchPopularRestaurants();

      // Assert
      expect(result, isNotEmpty);
      for (final restaurant in result) {
        expect(restaurant.rating, greaterThanOrEqualTo(4.0));
      }
    });

    test('fetchFeaturedRestaurants returns list of restaurants', () async {
      // Act
      final result = await repository.fetchFeaturedRestaurants();

      // Assert
      expect(result, isNotEmpty);
      expect(result, isA<List>());
    });

    test('restaurant has all required fields', () async {
      // Act
      final result = await repository.fetchRestaurant(
        restaurantId: 'restaurant_1',
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.id, isNotEmpty);
      expect(result.name, isNotEmpty);
      expect(result.description, isNotEmpty);
      expect(result.rating, greaterThan(0));
      expect(result.reviewsCount, greaterThanOrEqualTo(0));
      expect(result.menu, isNotEmpty);
    });

    test('restaurant menu sections contain items', () async {
      // Act
      final result = await repository.fetchRestaurant(
        restaurantId: 'restaurant_1',
      );

      // Assert
      expect(result!.menu, isNotEmpty);
      expect(result.menu[0].items, isNotEmpty);
      
      final firstItem = result.menu[0].items[0];
      expect(firstItem.name, isNotEmpty);
      expect(firstItem.price, greaterThan(0));
    });

    test('featured menu items are populated', () async {
      // Act
      final result = await repository.fetchRestaurant(
        restaurantId: 'restaurant_1',
      );

      // Assert
      expect(result!.featuredMenuItems, isNotEmpty);
      expect(result.featuredMenuItems.length, 4);
    });

    test('restaurant has working hours', () async {
      // Act
      final result = await repository.fetchRestaurant(
        restaurantId: 'restaurant_1',
      );

      // Assert
      expect(result!.workingHours, isNotEmpty);
      
      final firstWorkingHour = result.workingHours[0];
      expect(firstWorkingHour.startTime, isNotEmpty);
      expect(firstWorkingHour.endTime, isNotEmpty);
      expect(firstWorkingHour.dayOfWeek, isNotEmpty);
    });

    test('restaurant has reviews', () async {
      // Act
      final result = await repository.fetchRestaurant(
        restaurantId: 'restaurant_1',
      );

      // Assert
      expect(result!.reviews, isNotEmpty);
      
      final firstReview = result.reviews![0];
      expect(firstReview.content, isNotEmpty);
      expect(firstReview.rating, greaterThan(0));
    });

    test('menu items have options when available', () async {
      // Act
      final result = await repository.fetchRestaurant(
        restaurantId: 'restaurant_1',
      );

      // Assert
      final margherita = result!.menu[0].items[0];
      expect(margherita.options, isNotEmpty);
      expect(margherita.options![0].name, 'Extra cheese');
      expect(margherita.options![0].additionalCost, greaterThan(0));
    });
  });
}