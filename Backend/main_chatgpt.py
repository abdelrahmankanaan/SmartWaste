from openai import OpenAI
import pandas as pd 
import os 

def normalize_ingredients(ingredients, model="gpt-4o", temperature=0): 
  api_key = os.getenv("OPENAI_KEY")
  client = OpenAI(api_key=api_key)

  prompt = """
  **Objective:**  
  Clean and consolidate a list of ingredients from various dish recipes to standardize the data for use in a dish suggestion application.

  **Tasks:**

  1. **Normalize Formatting:**
    - Convert all ingredient names to lowercase.
    - Remove units of measurement (e.g., cups, tbsp, grams, liters, etc.).
    - Remove quantities and numerical values.
    - Remove descriptors and preparation notes (e.g., "chopped", "minced", "fresh", "extra virgin").

  2. **Standardize Ingredient Names:**
    - Convert synonyms and variants to a canonical form (e.g., “extra virgin olive oil” → oil”; “ground beef” → “beef”).
    - Keep the singular form (e.g., “tomatoes” → “tomato”). 
    - Use a consistent naming convention (e.g., “aubergine” vs. “eggplant” → “aubergine”).
    
  3. **Filter Out Generic/Non-Essential Ingredients:**
    - Remove common non-distinct ingredients that are typically present in most recipes and do not meaningfully differentiate dishes (e.g., water, salt, pepper, oil, sugar, juice).
    - Remove all spices and herbs that are not essential to the dish

  4. **Return Cleaned Output:**
    - Return only the result with comma separation.
    - Provide a clean, deduplicated list of standardized ingredients per dish.

  **Input Example:**
  Aubergine, yellow or white onion, diced, garlic cloves, minced, low-salt chickpeas, extra virgin olive oil, low-salt diced tomatoes, tomato paste, piquant post spicy mint blend, pita chips or crusty bread for dipping, salt and pepper to taste

  **Expected Cleaned Output:**
  aubergine, onion, garlic, chickpeas, oil, tomatoe, tomato paste, mint, chips, bread
  """
  
  
  completion = client.chat.completions.create(
    model= model, # gpt-3.5-turbo | gpt-4o 
    temperature=temperature,
    messages=[
      {"role": "developer", "content": prompt},
      {"role": "user", "content": ingredients}
    ]
  )

  if completion is not None and completion.choices is not None and len(completion.choices) > 0 and completion.choices[0].message is not None and completion.choices[0].message.content is not None:
    return completion.choices[0].message.content.strip()

  
if __name__ == "__main__":  
  df_lebanese_dishes = pd.read_csv("data/lebanese-dishes.csv")
  print(f"df_lebanese_dishes.shape: {df_lebanese_dishes.shape}")
  normalized_ingredients = []
  for idx, row in df_lebanese_dishes.iterrows(): 
    ingredients = normalize_ingredients(row['Ingredients'], model="gpt-4o", temperature=0) # gpt-3.5-turbo | gpt-4o
    print(idx, row['Ingredients'])
    print(idx, ingredients)
    normalized_ingredients.append(ingredients) 
    
  df_lebanese_dishes["Normalized Ingredients"] = normalized_ingredients
  
  df_lebanese_dishes.to_csv('data/normalized_ingredients_chatgpt.csv', index=False)


