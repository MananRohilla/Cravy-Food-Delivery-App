import 'package:core/entities.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/restaurant_repository.dart';

part 'restaurant_details_event.dart';
part 'restaurant_details_state.dart';

class RestaurantDetailsBloc
    extends Bloc<RestaurantDetailsEvent, RestaurantDetailsState> {
  final IRestaurantRepository _restaurantRepository;

  RestaurantDetailsBloc({
    required IRestaurantRepository restaurantRepository,
  })  : _restaurantRepository = restaurantRepository,
        super(const RestaurantDetailsState()) {
    on<LoadRestaurantDetailsEvent>(_onLoadRestaurantDetails);
    on<RetryLoadRestaurantDetailsEvent>(_onRetryLoadRestaurantDetails);
  }

  Future<void> _onLoadRestaurantDetails(
    LoadRestaurantDetailsEvent event,
    Emitter<RestaurantDetailsState> emit,
  ) async {
    debugPrint('LoadRestaurantDetailsEvent: Loading restaurant ${event.restaurantId}');
    emit(state.copyWith(status: RestaurantDetailsStatus.loading));
    
    try {
      await _loadRestaurantData(event.restaurantId, emit);
    } catch (err) {
      debugPrint('LoadRestaurantDetailsEvent: Error - $err');
      emit(state.copyWith(
        status: RestaurantDetailsStatus.error,
        errorMessage: _getErrorMessage(err),
      ));
    }
  }

  Future<void> _onRetryLoadRestaurantDetails(
    RetryLoadRestaurantDetailsEvent event,
    Emitter<RestaurantDetailsState> emit,
  ) async {
    debugPrint('RetryLoadRestaurantDetailsEvent: Retrying load for ${event.restaurantId}');
    emit(state.copyWith(
      status: RestaurantDetailsStatus.loading,
      errorMessage: null,
    ));
    
    try {
      await _loadRestaurantData(event.restaurantId, emit);
    } catch (err) {
      debugPrint('RetryLoadRestaurantDetailsEvent: Error - $err');
      emit(state.copyWith(
        status: RestaurantDetailsStatus.error,
        errorMessage: _getErrorMessage(err),
      ));
    }
  }

  Future<void> _loadRestaurantData(
    String restaurantId,
    Emitter<RestaurantDetailsState> emit,
  ) async {
    final restaurant = await _restaurantRepository.fetchRestaurant(
      restaurantId: restaurantId,
    );

    if (restaurant == null) {
      throw RestaurantNotFoundException('Restaurant not found');
    }

    emit(
      state.copyWith(
        status: RestaurantDetailsStatus.loaded,
        restaurant: restaurant,
        errorMessage: null,
      ),
    );
    
    debugPrint('Successfully loaded restaurant details');
  }

  String _getErrorMessage(Object error) {
    if (error is RestaurantNotFoundException) {
      return 'Restaurant not found. Please try another one.';
    } else if (error is RestaurantFetchException) {
      return 'Unable to load restaurant details. Please try again.';
    } else {
      return 'Something went wrong. Please try again later.';
    }
  }
}