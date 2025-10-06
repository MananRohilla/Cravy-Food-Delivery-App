import 'package:bloc_test/bloc_test.dart';
import 'package:core/entities.dart';
import 'package:core/src/value_objects/address.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:food_ordering_app_with_flutter_and_bloc/repositories/restaurant_repository.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/state/restaurant_details/restaurant_details_bloc.dart';

// Mock class
class MockRestaurantRepository extends Mock implements IRestaurantRepository {}

void main() {
  late MockRestaurantRepository mockRestaurantRepository;
  late RestaurantDetailsBloc restaurantDetailsBloc;

  // Test data
  final testRestaurant = Restaurant(
    id: 'restaurant_1',
    name: 'Test Restaurant',
    description: 'Test Description',
    imageUrl: 'test.jpg',
    rating: 4.5,
    reviewsCount: 10,
    category: FoodCategory(id: '1', name: 'Pizza', imageUrl: 'pizza.png'),
    address: Address.empty,
    menu: [],
    featuredMenuItems: [],
    workingHours: [],
    reviews: [],
  );

  setUp(() {
    mockRestaurantRepository = MockRestaurantRepository();
    
    restaurantDetailsBloc = RestaurantDetailsBloc(
      restaurantRepository: mockRestaurantRepository,
    );
  });

  tearDown(() {
    restaurantDetailsBloc.close();
  });

  group('RestaurantDetailsBloc', () {
    test('initial state should be RestaurantDetailsState with initial status', () {
      expect(restaurantDetailsBloc.state, const RestaurantDetailsState());
      expect(restaurantDetailsBloc.state.status, RestaurantDetailsStatus.initial);
    });

    blocTest<RestaurantDetailsBloc, RestaurantDetailsState>(
      'emits [loading, loaded] when LoadRestaurantDetailsEvent succeeds',
      build: () {
        when(() => mockRestaurantRepository.fetchRestaurant(
          restaurantId: 'restaurant_1',
        )).thenAnswer((_) async => testRestaurant);
        return restaurantDetailsBloc;
      },
      act: (bloc) => bloc.add(
        const LoadRestaurantDetailsEvent(restaurantId: 'restaurant_1'),
      ),
      expect: () => [
        const RestaurantDetailsState(status: RestaurantDetailsStatus.loading),
        RestaurantDetailsState(
          status: RestaurantDetailsStatus.loaded,
          restaurant: testRestaurant,
        ),
      ],
      verify: (_) {
        verify(() => mockRestaurantRepository.fetchRestaurant(
          restaurantId: 'restaurant_1',
        )).called(1);
      },
    );

    blocTest<RestaurantDetailsBloc, RestaurantDetailsState>(
      'emits [loading, error] when LoadRestaurantDetailsEvent fails with RestaurantNotFoundException',
      build: () {
        when(() => mockRestaurantRepository.fetchRestaurant(
          restaurantId: 'invalid_id',
        )).thenThrow(RestaurantNotFoundException('Not found'));
        return restaurantDetailsBloc;
      },
      act: (bloc) => bloc.add(
        const LoadRestaurantDetailsEvent(restaurantId: 'invalid_id'),
      ),
      expect: () => [
        const RestaurantDetailsState(status: RestaurantDetailsStatus.loading),
        const RestaurantDetailsState(
          status: RestaurantDetailsStatus.error,
          errorMessage: 'Restaurant not found. Please try another one.',
        ),
      ],
    );

    blocTest<RestaurantDetailsBloc, RestaurantDetailsState>(
      'emits [loading, error] when LoadRestaurantDetailsEvent fails with RestaurantFetchException',
      build: () {
        when(() => mockRestaurantRepository.fetchRestaurant(
          restaurantId: 'restaurant_1',
        )).thenThrow(RestaurantFetchException('Network error'));
        return restaurantDetailsBloc;
      },
      act: (bloc) => bloc.add(
        const LoadRestaurantDetailsEvent(restaurantId: 'restaurant_1'),
      ),
      expect: () => [
        const RestaurantDetailsState(status: RestaurantDetailsStatus.loading),
        const RestaurantDetailsState(
          status: RestaurantDetailsStatus.error,
          errorMessage: 'Unable to load restaurant details. Please try again.',
        ),
      ],
    );

    blocTest<RestaurantDetailsBloc, RestaurantDetailsState>(
      'emits [loading, error] when restaurant is null',
      build: () {
        when(() => mockRestaurantRepository.fetchRestaurant(
          restaurantId: 'restaurant_1',
        )).thenAnswer((_) async => null);
        return restaurantDetailsBloc;
      },
      act: (bloc) => bloc.add(
        const LoadRestaurantDetailsEvent(restaurantId: 'restaurant_1'),
      ),
      expect: () => [
        const RestaurantDetailsState(status: RestaurantDetailsStatus.loading),
        const RestaurantDetailsState(
          status: RestaurantDetailsStatus.error,
          errorMessage: 'Restaurant not found. Please try another one.',
        ),
      ],
    );

    blocTest<RestaurantDetailsBloc, RestaurantDetailsState>(
      'emits [loading, loaded] when RetryLoadRestaurantDetailsEvent succeeds after error',
      build: () {
        when(() => mockRestaurantRepository.fetchRestaurant(
          restaurantId: 'restaurant_1',
        )).thenAnswer((_) async => testRestaurant);
        return restaurantDetailsBloc;
      },
      seed: () => const RestaurantDetailsState(
        status: RestaurantDetailsStatus.error,
        errorMessage: 'Previous error',
      ),
      act: (bloc) => bloc.add(
        const RetryLoadRestaurantDetailsEvent(restaurantId: 'restaurant_1'),
      ),
      expect: () => [
        const RestaurantDetailsState(status: RestaurantDetailsStatus.loading),
        RestaurantDetailsState(
          status: RestaurantDetailsStatus.loaded,
          restaurant: testRestaurant,
        ),
      ],
    );

    blocTest<RestaurantDetailsBloc, RestaurantDetailsState>(
      'emits [loading, error] when RetryLoadRestaurantDetailsEvent still fails',
      build: () {
        when(() => mockRestaurantRepository.fetchRestaurant(
          restaurantId: 'restaurant_1',
        )).thenThrow(RestaurantFetchException('Still failing'));
        return restaurantDetailsBloc;
      },
      seed: () => const RestaurantDetailsState(
        status: RestaurantDetailsStatus.error,
        errorMessage: 'Previous error',
      ),
      act: (bloc) => bloc.add(
        const RetryLoadRestaurantDetailsEvent(restaurantId: 'restaurant_1'),
      ),
      expect: () => [
        const RestaurantDetailsState(status: RestaurantDetailsStatus.loading),
        const RestaurantDetailsState(
          status: RestaurantDetailsStatus.error,
          errorMessage: 'Unable to load restaurant details. Please try again.',
        ),
      ],
    );
  });
}