import 'package:core/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/restaurant_repository.dart';
import '../../shared/widgets/section_title.dart';
import '../../state/restaurant_details/restaurant_details_bloc.dart';

part '_restaurant_details_app_bar.dart';
part '_restaurant_details_information.dart';
part '_restaurant_details_featured_menu_items.dart';
part '_restaurant_details_menu_sections.dart';
// part '_restaurant_details_error_widget.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  const RestaurantDetailsScreen({
    super.key,
    required this.restaurantId,
  });

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RestaurantDetailsBloc(
        restaurantRepository: context.read<IRestaurantRepository>(),
      )..add(LoadRestaurantDetailsEvent(restaurantId: restaurantId)),
      child: RestaurantDetailsView(restaurantId: restaurantId),
    );
  }
}

class RestaurantDetailsView extends StatelessWidget {
  const RestaurantDetailsView({
    super.key,
    required this.restaurantId,
  });

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _RestaurantDetailsAppBar(),
      body: BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
        builder: (context, state) {
          if (state.status == RestaurantDetailsStatus.initial ||
              state.status == RestaurantDetailsStatus.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16.0),
                  Text('Loading restaurant details...'),
                ],
              ),
            );
          }
          
          if (state.status == RestaurantDetailsStatus.error) {
            return _RestaurantDetailsErrorWidget(
              errorMessage: state.errorMessage ?? 'Failed to load restaurant',
              onRetry: () {
                context.read<RestaurantDetailsBloc>().add(
                  RetryLoadRestaurantDetailsEvent(restaurantId: restaurantId),
                );
              },
              onGoBack: () {
                Navigator.pop(context);
              },
            );
          }
          
          if (state.status == RestaurantDetailsStatus.loaded &&
              state.restaurant != null) {
            return const SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
                top: 60.0,
              ),
              child: Column(
                children: [
                  _RestaurantInformation(),
                  _FeaturedMenuItems(),
                  _MenuSections(),
                ],
              ),
            );
          }
          
          return const Center(
            child: Text('Restaurant not found'),
          );
        },
      ),
    );
  }
}

class _RestaurantDetailsErrorWidget extends StatelessWidget {
  const _RestaurantDetailsErrorWidget({
    required this.errorMessage,
    required this.onRetry,
    required this.onGoBack,
  });

  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onGoBack;

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
              Icons.restaurant_outlined,
              size: 80.0,
              color: colorScheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: 24.0),
            Text(
              'Unable to Load Restaurant',
              style: textTheme.headlineSmall!.copyWith(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                TextButton.icon(
                  onPressed: onGoBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}