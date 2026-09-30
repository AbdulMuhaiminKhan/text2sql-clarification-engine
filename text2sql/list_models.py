"""Print the models your API key can use: python -m text2sql.list_models"""
from .llm import client

for m in sorted(client().models.list().data, key=lambda m: m.id):
    print(m.id)
