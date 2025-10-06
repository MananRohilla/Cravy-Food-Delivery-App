import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'repositories/food_category_repository.dart';
import 'repositories/restaurant_repository.dart';
import 'services/order_service.dart';
import 'screens/home/home_screen.dart';
import 'shared/theme/app_theme.dart';
import 'state/home/home_bloc.dart';
import 'state/cart/cart_bloc.dart';
import 'state/order/order_bloc.dart';


void main() {
  const foodCategoryRepository = FoodCategoryRepository();
  const restaurantRepository = RestaurantRepository();
  final orderService = OrderService();

  runApp(
     AppScreen(
      foodCategoryRepository: foodCategoryRepository,
      restaurantRepository: restaurantRepository,
      orderService: orderService,
    ),
  );
}

class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.foodCategoryRepository,
    required this.restaurantRepository,
    required this.orderService,
  });

  final FoodCategoryRepository foodCategoryRepository;
  final RestaurantRepository restaurantRepository;
  final OrderService orderService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: foodCategoryRepository),
        RepositoryProvider.value(value: restaurantRepository),
        RepositoryProvider.value(value: orderService),
      ],
      child: MultiBlocProvider(
        providers: [
          // Global scope
          BlocProvider(
            create: (context) => HomeBloc(
              foodCategoryRepository: foodCategoryRepository,
              restaurantRepository: restaurantRepository,
            )..add(LoadHomeEvent()),
          ),
          BlocProvider(
            create: (context) => CartBloc(),
          ),
          BlocProvider(
            create: (context) => OrderBloc(
              orderService: orderService,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: AppTheme().themeData,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
