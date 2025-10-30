import requests

# URL of the FastAPI endpoint
url = "http://127.0.0.1:8000/ingredients"

try:
    response = requests.get(url)
    response.raise_for_status()  # Raise exception for HTTP errors

    data = response.json()
    ingredients = data.get("ingredients", [])

    print("Available ingredients:")
    for ingredient in ingredients:
        print(ingredient)

except requests.exceptions.RequestException as e:
    print("Error calling the web service:", e)
