import 'package:bloc/bloc.dart';
import 'package:core/entities.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../repositories/food_category_repository.dart';
import '../../repositories/restaurant_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final IFoodCategoryRepository _foodCategoryRepository;
  final IRestaurantRepository _restaurantRepository;

  HomeBloc({
    required IFoodCategoryRepository foodCategoryRepository,
    required IRestaurantRepository restaurantRepository,
  })  : _foodCategoryRepository = foodCategoryRepository,
        _restaurantRepository = restaurantRepository,
        super(const HomeState()) {
    on<LoadHomeEvent>(_onLoadHome);
    on<RefreshHomeEvent>(_onRefreshHome);
    on<RetryLoadHomeEvent>(_onRetryLoadHome);
  }

  Future<void> _onLoadHome(
    LoadHomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    debugPrint('LoadHomeEvent: Starting to load home data');
    emit(state.copyWith(status: HomeStatus.loading));
    
    try {
      await _loadHomeData(emit);
    } catch (err) {
      debugPrint('LoadHomeEvent: Error - $err');
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: _getErrorMessage(err),
      ));
    }
  }

  Future<void> _onRefreshHome(
    RefreshHomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    debugPrint('RefreshHomeEvent: Refreshing home data');
    
    try {
      await _loadHomeData(emit);
    } catch (err) {
      debugPrint('RefreshHomeEvent: Error - $err');
      // Don't change to error state on refresh, keep current data visible
      emit(state.copyWith(
        status: HomeStatus.loaded,
        errorMessage: 'Failed to refresh. Showing cached data.',
      ));
    }
  }

  Future<void> _onRetryLoadHome(
    RetryLoadHomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    debugPrint('RetryLoadHomeEvent: Retrying to load home data');
    emit(state.copyWith(status: HomeStatus.loading, errorMessage: null));
    
    try {
      await _loadHomeData(emit);
    } catch (err) {
      debugPrint('RetryLoadHomeEvent: Error - $err');
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: _getErrorMessage(err),
      ));
    }
  }

  // Extracted method to avoid code duplication (DRY principle)
  Future<void> _loadHomeData(Emitter<HomeState> emit) async {
    final foodCategoriesFuture = _foodCategoryRepository.fetchFoodCategories();
    final popularRestaurantsFuture = _restaurantRepository.fetchPopularRestaurants();
    final featuredRestaurantsFuture = _restaurantRepository.fetchFeaturedRestaurants();

    final response = await Future.wait([
      foodCategoriesFuture,
      popularRestaurantsFuture,
      featuredRestaurantsFuture,
    ]);

    final foodCategories = response[0] as List<FoodCategory>;
    final popularRestaurants = response[1] as List<Restaurant>;
    final featuredRestaurants = response[2] as List<Restaurant>;
    
    final shopsNearby = [
      {
        'title': '7-Eleven',
        'subtitle': '10 mins',
        'imageUrl': 'assets/images/711.png',
      },
      {
        'title': 'Guardian',
        'subtitle': '15 mins',
        'imageUrl': 'assets/images/guardian.png',
      },
      {
        'title': 'Walgreens',
        'subtitle': '15 mins',
        'imageUrl': 'assets/images/walgreens.png',
      },
    ];

    emit(
      state.copyWith(
        status: HomeStatus.loaded,
        foodCategories: foodCategories,
        popularRestaurants: popularRestaurants,
        featuredRestaurants: featuredRestaurants,
        shopsNearby: shopsNearby,
        errorMessage: null,
      ),
    );
    
    debugPrint('Successfully loaded home data');
  }

  String _getErrorMessage(Object error) {
    if (error is FoodCategoryFetchException) {
      return 'Unable to load food categories. Please try again.';
    } else if (error is RestaurantFetchException) {
      return 'Unable to load restaurants. Please check your connection.';
    } else {
      return 'Something went wrong. Please try again later.';
    }
  }
}