import 'package:bloc_test/bloc_test.dart';
import 'package:core/entities.dart';
import 'package:core/src/value_objects/address.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:food_ordering_app_with_flutter_and_bloc/repositories/food_category_repository.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/repositories/restaurant_repository.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/state/home/home_bloc.dart';

// Mock classes
class MockFoodCategoryRepository extends Mock implements IFoodCategoryRepository {}
class MockRestaurantRepository extends Mock implements IRestaurantRepository {}

void main() {
  late MockFoodCategoryRepository mockFoodCategoryRepository;
  late MockRestaurantRepository mockRestaurantRepository;
  late HomeBloc homeBloc;

  // Test data
  final testFoodCategories = [
    FoodCategory(id: '1', name: 'Pizza', imageUrl: 'pizza.png'),
    FoodCategory(id: '2', name: 'Burger', imageUrl: 'burger.png'),
  ];

  final testRestaurants = [
    Restaurant(
      id: '1',
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
    ),
  ];

  setUp(() {
    mockFoodCategoryRepository = MockFoodCategoryRepository();
    mockRestaurantRepository = MockRestaurantRepository();
    
    homeBloc = HomeBloc(
      foodCategoryRepository: mockFoodCategoryRepository,
      restaurantRepository: mockRestaurantRepository,
    );
  });

  tearDown(() {
    homeBloc.close();
  });

  group('HomeBloc', () {
    test('initial state should be HomeState with initial status', () {
      expect(homeBloc.state, const HomeState());
      expect(homeBloc.state.status, HomeStatus.initial);
    });

    blocTest<HomeBloc, HomeState>(
      'emits [loading, loaded] when LoadHomeEvent succeeds',
      build: () {
        when(() => mockFoodCategoryRepository.fetchFoodCategories())
            .thenAnswer((_) async => testFoodCategories);
        when(() => mockRestaurantRepository.fetchPopularRestaurants())
            .thenAnswer((_) async => testRestaurants);
        when(() => mockRestaurantRepository.fetchFeaturedRestaurants())
            .thenAnswer((_) async => testRestaurants);
        return homeBloc;
      },
      act: (bloc) => bloc.add(const LoadHomeEvent()),
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        HomeState(
          status: HomeStatus.loaded,
          foodCategories: testFoodCategories,
          popularRestaurants: testRestaurants,
          featuredRestaurants: testRestaurants,
          shopsNearby: const [
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
          ],
        ),
      ],
      verify: (_) {
        verify(() => mockFoodCategoryRepository.fetchFoodCategories()).called(1);
        verify(() => mockRestaurantRepository.fetchPopularRestaurants()).called(1);
        verify(() => mockRestaurantRepository.fetchFeaturedRestaurants()).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'emits [loading, error] when LoadHomeEvent fails with FoodCategoryFetchException',
      build: () {
        when(() => mockFoodCategoryRepository.fetchFoodCategories())
            .thenThrow(FoodCategoryFetchException('Network error'));
        when(() => mockRestaurantRepository.fetchPopularRestaurants())
            .thenAnswer((_) async => testRestaurants);
        when(() => mockRestaurantRepository.fetchFeaturedRestaurants())
            .thenAnswer((_) async => testRestaurants);
        return homeBloc;
      },
      act: (bloc) => bloc.add(const LoadHomeEvent()),
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        const HomeState(
          status: HomeStatus.error,
          errorMessage: 'Unable to load food categories. Please try again.',
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'emits [loading, error] when LoadHomeEvent fails with RestaurantFetchException',
      build: () {
        when(() => mockFoodCategoryRepository.fetchFoodCategories())
            .thenAnswer((_) async => testFoodCategories);
        when(() => mockRestaurantRepository.fetchPopularRestaurants())
            .thenThrow(RestaurantFetchException('Network error'));
        when(() => mockRestaurantRepository.fetchFeaturedRestaurants())
            .thenAnswer((_) async => testRestaurants);
        return homeBloc;
      },
       seed: () => const HomeState(
    status: HomeStatus.error,
    errorMessage: 'Previous error',
  ),
  act: (bloc) => bloc.add(const RetryLoadHomeEvent()),
  expect: () => [
    const HomeState(status: HomeStatus.loading),
    HomeState(
      status: HomeStatus.loaded,
      foodCategories: testFoodCategories,
      popularRestaurants: testRestaurants,
      featuredRestaurants: testRestaurants,
      shopsNearby: const [
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
      ],
    ),
  ],
);

blocTest<HomeBloc, HomeState>(
  'keeps data visible when RefreshHomeEvent fails',
  build: () {
    when(() => mockFoodCategoryRepository.fetchFoodCategories())
        .thenThrow(FoodCategoryFetchException('Network error'));
    when(() => mockRestaurantRepository.fetchPopularRestaurants())
        .thenAnswer((_) async => testRestaurants);
    when(() => mockRestaurantRepository.fetchFeaturedRestaurants())
        .thenAnswer((_) async => testRestaurants);
    return homeBloc;
  },
  seed: () => HomeState(
    status: HomeStatus.loaded,
    foodCategories: testFoodCategories,
    popularRestaurants: testRestaurants,
    featuredRestaurants: testRestaurants,
  ),
  act: (bloc) => bloc.add(const RefreshHomeEvent()),
  expect: () => [
    HomeState(
      status: HomeStatus.loaded,
      foodCategories: testFoodCategories,
      popularRestaurants: testRestaurants,
      featuredRestaurants: testRestaurants,
      errorMessage: 'Failed to refresh. Showing cached data.',
    ),
  ],
);
});
}