// =====================================================================
// 03_final_task.js  -  my own order in the embedding model (F1-F5)
// =====================================================================
db = db.getSiblingDB("bd_lab");

// F1. New customer + new order in one document
db.zamowienia.insertOne({
  _id: 5,
  klient: { id: 5, imie: "Ewa", nazwisko: "Mazur", email: "ewa.mazur@example.com" },
  data_zamowienia: ISODate("2026-10-28T12:00:00Z"),
  status: "NOWE",
  pozycje: [
    { produkt: { id: 1, nazwa: "Laptop" }, ilosc: 1, cena: 4200 },
    { produkt: { id: 4, nazwa: "Mysz" },   ilosc: 3, cena: 120 }
  ]
});

// F2. Filter on a nested field
printjson(db.zamowienia.find({ "klient.nazwisko": "Mazur" }).toArray());

// F3. Projection of nested fields and array elements
printjson(db.zamowienia.find(
  { "klient.nazwisko": "Mazur" },
  { _id: 0, "klient.imie": 1, "klient.nazwisko": 1, "pozycje.produkt.nazwa": 1, "pozycje.ilosc": 1 }
).toArray());

// F4. Newest NEW orders first
printjson(db.zamowienia.find(
  { status: "NOWE" },
  { "klient.nazwisko": 1, data_zamowienia: 1 }
).sort({ data_zamowienia: -1 }).toArray());                                          // 5 (Mazur), 4 (Wiśniewska)

// F5. Order value via aggregation pipeline -> 4560
printjson(db.zamowienia.aggregate([
  { $match: { "klient.nazwisko": "Mazur" } },
  { $unwind: "$pozycje" },
  { $group: { _id: "$_id", wartosc_zamowienia: { $sum: { $multiply: ["$pozycje.ilosc", "$pozycje.cena"] } } } }
]).toArray());
