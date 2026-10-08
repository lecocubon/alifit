import 'package:flutter/material.dart';

import '../../domain/nutrition/meal_type.dart';

IconData mealTypeIcon(MealType type) => switch (type) {
  MealType.desayuno => Icons.free_breakfast_outlined,
  MealType.colacion => Icons.cookie_outlined,
  MealType.almuerzo => Icons.lunch_dining_outlined,
  MealType.once => Icons.emoji_food_beverage_outlined,
  MealType.cena => Icons.dinner_dining_outlined,
  MealType.personalizada => Icons.restaurant_outlined,
};
