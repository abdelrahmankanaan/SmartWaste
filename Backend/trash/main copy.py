from openai import OpenAI

api_key = "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"
client = OpenAI(api_key=api_key)

completion = client.chat.completions.create(
  model="gpt-3.5-turbo", # gpt-4o 
  messages=[
    {"role": "developer", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"}
  ]
)

print(completion.choices[0].message)
