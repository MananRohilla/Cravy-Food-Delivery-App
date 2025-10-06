part of 'restaurant_details_bloc.dart';

enum RestaurantDetailsStatus { initial, loading, loaded, error }

class RestaurantDetailsState extends Equatable {
  final RestaurantDetailsStatus status;
  final Restaurant? restaurant;
  final String? errorMessage;

  const RestaurantDetailsState({
    this.status = RestaurantDetailsStatus.initial,
    this.restaurant,
    this.errorMessage,
  });

  RestaurantDetailsState copyWith({
    RestaurantDetailsStatus? status,
    Restaurant? restaurant,
    String? errorMessage,
  }) {
    return RestaurantDetailsState(
      status: status ?? this.status,
      restaurant: restaurant ?? this.restaurant,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, restaurant, errorMessage];
}