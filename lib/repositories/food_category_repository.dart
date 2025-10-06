import 'package:core/entities.dart';

// Custom exception for food category errors
class FoodCategoryFetchException implements Exception {
  final String message;
  FoodCategoryFetchException(this.message);
  
  @override
  String toString() => 'FoodCategoryFetchException: $message';
}

// Abstract interface (Dependency Inversion Principle)
abstract class IFoodCategoryRepository {
  Future<List<FoodCategory>> fetchFoodCategories();
}

class FoodCategoryRepository implements IFoodCategoryRepository {
  const FoodCategoryRepository();

  @override
  Future<List<FoodCategory>> fetchFoodCategories() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return foodCategories.map((category) {
        return FoodCategory(
          id: category['id']!,
          name: category['name']!,
          imageUrl: category['imageUrl']!,
        );
      }).toList();
    } catch (err) {
      throw FoodCategoryFetchException('Error fetching food categories: $err');
    }
  }
}

const foodCategories = [
  {
    'id': 'category_1',
    'name': 'Pizza',
    'imageUrl': 'assets/icons/pizza.png',
  },
  {
    'id': 'category_2',
    'name': 'Burgers',
    'imageUrl': 'assets/icons/burger.png',
  },
  {
    'id': 'category_3',
    'name': 'Sushi',
    'imageUrl': 'assets/icons/sushi.png',
  },
  {
    'id': 'category_4',
    'name': 'Dessert',
    'imageUrl': 'assets/icons/cake.png',
  },
  {
    'id': 'category_5',
    'name': 'Fast Food',
    'imageUrl': 'assets/icons/fries.png',
  },
];