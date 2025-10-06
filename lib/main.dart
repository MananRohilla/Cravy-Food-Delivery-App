import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'repositories/food_category_repository.dart';
import 'repositories/restaurant_repository.dart';
import 'screens/home/home_screen.dart';
import 'shared/theme/app_theme.dart';
import 'state/home/home_bloc.dart';

void main() {
  // Initialize repositories (Dependency Inversion Principle)
  const IFoodCategoryRepository foodCategoryRepository = FoodCategoryRepository();
  const IRestaurantRepository restaurantRepository = RestaurantRepository();

  runApp(
    AppScreen(
      foodCategoryRepository: foodCategoryRepository,
      restaurantRepository: restaurantRepository,
    ),
  );
}

class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.foodCategoryRepository,
    required this.restaurantRepository,
  });

  final IFoodCategoryRepository foodCategoryRepository;
  final IRestaurantRepository restaurantRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Provide repositories using abstract interfaces
        RepositoryProvider<IFoodCategoryRepository>.value(
          value: foodCategoryRepository,
        ),
        RepositoryProvider<IRestaurantRepository>.value(
          value: restaurantRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Global scope BLoC
          BlocProvider(
            create: (context) => HomeBloc(
              foodCategoryRepository: foodCategoryRepository,
              restaurantRepository: restaurantRepository,
            )..add(const LoadHomeEvent()),
          ),
        ],
        child: MaterialApp(
          title: 'Food Ordering App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme().themeData,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}