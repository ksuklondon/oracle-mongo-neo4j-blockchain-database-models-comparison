"""MongoDB -> pandas for both models.

Embedding: one DataFrame, nested list must be unpacked (explode + json_normalize).
Referencing: three DataFrames that the application must join (merge).

    pip install pymongo pandas
"""
import os

import pandas as pd
from pymongo import MongoClient

client = MongoClient(os.environ.get("MONGO_URI", "mongodb://localhost:27017/"))
db = client["bd_lab"]
print(db.list_collection_names())

# ---------- Embedding ----------
docs = list(db.zamowienia.find({"status": "NOWE"}, {"_id": 0}))
df = pd.DataFrame(docs)                       # 'klient' and 'pozycje' stay nested in cells

lines = df.explode("pozycje").reset_index(drop=True)
lines = pd.json_normalize(lines["pozycje"].tolist())   # columns: ilosc, cena, produkt.id, produkt.nazwa
lines["wartosc"] = lines["ilosc"] * lines["cena"]
print(lines)
print(lines.groupby("produkt.nazwa")["wartosc"].sum())

# ---------- Referencing ----------
orders = pd.DataFrame(list(db.zamowienia_ref.find({}, {"_id": 0})))
# Lesson learned: if customers are read with {"_id": 0}, the merge below fails
# with KeyError: '_id' - the join key must be kept.
customers = pd.DataFrame(list(db.klienci.find()))

joined = orders.merge(customers, left_on="id_klienta", right_on="_id", how="left")
print(joined[["id_klienta", "imie", "nazwisko", "status"]])

client.close()
