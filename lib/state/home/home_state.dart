part of 'home_bloc.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<FoodCategory> foodCategories;
  final List<Restaurant> popularRestaurants;
  final List<Restaurant> featuredRestaurants;
  final List<dynamic> shopsNearby;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.foodCategories = const [],
    this.popularRestaurants = const [],
    this.featuredRestaurants = const [],
    this.shopsNearby = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<FoodCategory>? foodCategories,
    List<Restaurant>? popularRestaurants,
    List<Restaurant>? featuredRestaurants,
    List<dynamic>? shopsNearby,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      foodCategories: foodCategories ?? this.foodCategories,
      popularRestaurants: popularRestaurants ?? this.popularRestaurants,
      featuredRestaurants: featuredRestaurants ?? this.featuredRestaurants,
      shopsNearby: shopsNearby ?? this.shopsNearby,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        foodCategories,
        popularRestaurants,
        featuredRestaurants,
        shopsNearby,
        errorMessage,
      ];
}