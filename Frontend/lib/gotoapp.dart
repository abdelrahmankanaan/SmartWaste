import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class gotoapp extends StatefulWidget {
  const gotoapp({Key? key}) : super(key: key);

  @override
  _gotoappState createState() => _gotoappState();
}

class _gotoappState extends State<gotoapp> {
  TextEditingController txtingredients = TextEditingController();
  List<String> ingredients = [];
  List<dynamic> recommendedRecipes = [];
  bool isLoading = false;
  String? authToken;
   List<String> allIngredients = [
     "akkawi cheese", "almond", "almond extract", "almonds", "aniseed", "aubergine", "baking powder", "baking soda", "beef", "bell pepper", "blossom water", "bread",
     "broad bean", "broth", "bulgur", "bulgur wheat", "butter", "cabbage", "caraway", "cardamom", "carrot", "cashew", "cauliflower", "cheese", "cherry", "chicken",
     "chickpea", "chickpeas", "chicory", "chili", "chili pepper", "chip", "cilantro", "cinnamon", "clove", "condensed milk", "coriander", "corn flour", "corn starch",
     "corn stretch", "cornstarch", "cream", "cucumber", "cumin", "date syrup", "dates", "debs roman", "dough", "egg", "egg whites", "fava bean", "fish", "fish stock",
     "flour", "flower water", "garlic", "garlic sauce", "ghee", "green bean", "green onion", "haricot bean", "hazelnut", "jameed", "jute leaves", "kallaj sheets", "kashta",
     "knefeh dough", "krefeh", "lamb", "lemon", "lemon blossom", "lemon juice", "lentil", "lettuce", "lime", "macaroni", "mahlab", "mastic", "meat", "milk", "mint", "molokhia",
     "mozzarella", "nutmeg", "nuts", "okra", "onion", "orange blossom", "orange blossom water", "orange zest", "parsley", "pastry", "pepper", "phyllo dough", "phyllo pastry",
     "pickles", "pine nut", "pine nuts", "pistachio", "pistachios", "pomegranate", "pomegranate molasses", "potato", "rabbit", "radish", "rice", "rose syrup", "rose water",
     "saffron", "sea bass", "semolina", "sesame seed", "shallot", "spinach", "starch", "stock", "sugar", "sugar syrup", "sumac", "syrup", "tahina", "tahini", "tamarind", "toast",
     "tomato", "tomato paste", "tomato sauce", "vanilla", "vegetable", "vegetables", "vermicelli", "vine leaf", "vinegar", "walnut", "walnuts", "wheat", "yeast", "yogurt", "zucchini"
   ];
  List<String> suggestions = [];
  String apiUrl = "http://127.0.0.1:8000"; // Replace with your actual backend URL

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      authToken = prefs.getString('auth_token');
    });
  }

  Future<void> addIngredients() async {
    if (txtingredients.text.isEmpty) return;

    setState(() {
      isLoading = true;
      ingredients.clear();
      recommendedRecipes.clear();
    });

    // Parse ingredients (comma separated)
    ingredients = txtingredients.text
        .split(',')
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();

    if (ingredients.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 5 ingredients allowed'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      await fetchRecommendations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchRecommendations() async {
    final response = await http.post(
      Uri.parse('$apiUrl/recommend'),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'ingredients': ingredients}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        recommendedRecipes = data['recommendations'];
      });
    } else {
      throw Exception('Failed to load recommendations: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart waste"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 10),
            // TEXT FIELD + AUTOCOMPLETE
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  TextField(
                    controller: txtingredients,
                    decoration: InputDecoration(
                      labelText: "Enter your ingredients",
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: addIngredients,
                      ),
                    ),
                    onChanged: (value) {
                      final parts = value.split(',');
                      final current = parts.last.trim();
                      setState(() {
                        suggestions = allIngredients
                            .where((ing) => ing.toLowerCase().startsWith(current.toLowerCase()) && current.isNotEmpty)
                            .toList();
                      });
                    },
                    onSubmitted: (value) {
                      if (suggestions.isNotEmpty) {
                        final parts = txtingredients.text.split(',');
                        parts[parts.length - 1] = suggestions.first;
                        txtingredients.text = parts.join(', ') + ', ';
                        setState(() {
                          suggestions = [];
                        });
                      }
                    },
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(suggestions[index]),
                            onTap: () {
                              final parts = txtingredients.text.split(',');
                              parts[parts.length - 1] = suggestions[index];
                              txtingredients.text = parts.join(', ') + ', ';
                              txtingredients.selection = TextSelection.fromPosition(
                                TextPosition(offset: txtingredients.text.length),
                              );
                              setState(() {
                                suggestions = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 20),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (recommendedRecipes.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: recommendedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recommendedRecipes[index];
                    return Card(
                      child: ListTile(
                        title: Text(recipe['dish']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recipe Fit: ${recipe['similarity']}%'),
                            Text(
                              'Ingredients: ${recipe['ingredients']}',
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (!isLoading && recommendedRecipes.isEmpty)
              Center(
                child: Text(
                  'Recipes',
                  style: TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}