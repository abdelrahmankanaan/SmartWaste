class Recipe {
  final String name;
  final double percentage;
  final List<String> ingredients;

  Recipe({
    required this.name,
    required this.percentage,
    required this.ingredients,
  });

  // Optional: A method to display the recipe nicely
  @override
  String toString() {
    return 'Recipe: $name | Similarity: ${percentage.toStringAsFixed(2)}% | Ingredients: ${ingredients.join(", ")}';
  }
}
