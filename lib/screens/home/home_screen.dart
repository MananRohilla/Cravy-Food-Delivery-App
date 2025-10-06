import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/widgets/custom_action_chip.dart';
import '../../shared/widgets/main_nav_bar.dart';
import '../../shared/widgets/rating_modal.dart';
import '../../shared/widgets/restaurant_preview_card.dart';
import '../../shared/widgets/section_title.dart';
import '../../state/home/home_bloc.dart';

part '_home_app_bar.dart';
part '_home_featured_restaurants.dart';
part '_home_food_categories.dart';
part '_home_popular_restaurants.dart';
part '_home_restaurant_filters.dart';
part '_home_shops_nearby.dart';
// part '_home_error_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _HomeAppBar(),
      bottomNavigationBar: const MainNavBar(),
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          // Show snackbar for errors during refresh
          if (state.status == HomeStatus.loaded && 
              state.errorMessage != null &&
              state.errorMessage!.contains('refresh')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<HomeBloc>().add(const RefreshHomeEvent());
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == HomeStatus.initial ||
              state.status == HomeStatus.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16.0),
                  Text('Loading delicious food...'),
                ],
              ),
            );
          }
          
          if (state.status == HomeStatus.error) {
            return _HomeErrorWidget(
              errorMessage: state.errorMessage ?? 'Something went wrong!',
              onRetry: () {
                context.read<HomeBloc>().add(const RetryLoadHomeEvent());
              },
            );
          }
          
          if (state.status == HomeStatus.loaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(const RefreshHomeEvent());
                // Wait for the bloc to process
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _FoodCategories(),
                    SizedBox(height: 16.0),
                    _RestaurantFilters(),
                    _FeaturedRestaurants(),
                    _ShopsNearby(),
                    _PopularRestaurants(),
                  ],
                ),
              ),
            );
          }
          
          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}

class _HomeErrorWidget extends StatelessWidget {
  const _HomeErrorWidget({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80.0,
              color: colorScheme.error,
            ),
            const SizedBox(height: 24.0),
            Text(
              'Oops!',
              style: textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 32.0),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}