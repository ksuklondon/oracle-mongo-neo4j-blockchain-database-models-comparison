// =====================================================================
// 01_embedding.js  -  orders model with EMBEDDED customer and order lines
// Run:  mongosh "mongodb://localhost:27017/bd_lab" 01_embedding.js
// (in the lab I did the same steps interactively in MongoDB Compass)
// =====================================================================
db = db.getSiblingDB("bd_lab");
db.zamowienia.drop();

// B3. One document = one complete order
db.zamowienia.insertMany([
  {
    _id: 1,
    klient: { id: 1, imie: "Jan", nazwisko: "Kowalski", email: "jan.kowalski@example.com" },
    data_zamowienia: ISODate("2026-09-25T10:00:00Z"),
    status: "NOWE",
    pozycje: [
      { produkt: { id: 1, nazwa: "Laptop" },     ilosc: 1, cena: 4200 },
      { produkt: { id: 3, nazwa: "Klawiatura" }, ilosc: 2, cena: 250 }
    ]
  },
  {
    _id: 2,
    klient: { id: 2, imie: "Anna", nazwisko: "Nowak", email: "anna.nowak@example.com" },
    data_zamowienia: ISODate("2026-09-26T09:30:00Z"),
    status: "OPLACONE",
    pozycje: [
      { produkt: { id: 2, nazwa: "Monitor" }, ilosc: 1, cena: 1200 },
      { produkt: { id: 4, nazwa: "Mysz" },    ilosc: 2, cena: 120 }
    ]
  },
  {
    _id: 3,
    klient: { id: 3, imie: "Piotr", nazwisko: "Zielinski", email: "piotr.zielinski@example.com" },
    data_zamowienia: ISODate("2026-09-26T14:15:00Z"),
    status: "WYSLANE",
    pozycje: [
      { produkt: { id: 1, nazwa: "Laptop" }, ilosc: 1, cena: 4200 },
      { produkt: { id: 4, nazwa: "Mysz" },   ilosc: 1, cena: 120 }
    ]
  },
  // B3.4  order built from a text description
  {
    _id: 4,
    klient: { id: 4, imie: "Maria", nazwisko: "Wiśniewska", email: "maria.wisniewska@example.com" },
    data_zamowienia: ISODate("2026-09-26T16:30:00Z"),
    status: "NOWE",
    pozycje: [
      { produkt: { id: 2, nazwa: "Monitor" },    ilosc: 2, cena: 1200 },
      { produkt: { id: 3, nazwa: "Klawiatura" }, ilosc: 1, cena: 250 }
    ]
  }
]);

// B4. Filters - dot notation works for nested objects AND arrays
printjson(db.zamowienia.find({ status: "NOWE" }).toArray());                        // _id 1, 4
printjson(db.zamowienia.find({ "klient.nazwisko": "Nowak" }).toArray());            // _id 2
printjson(db.zamowienia.find({ "pozycje.produkt.nazwa": "Laptop" }).toArray());     // _id 1, 3
printjson(db.zamowienia.find({ status: "ANULOWANE" }).toArray());                   // []

// B5. Projection
printjson(db.zamowienia.find({ status: "NOWE" }, { _id: 0, klient: 1, status: 1 }).toArray());
printjson(db.zamowienia.find({ status: "NOWE" },
  { _id: 0, "klient.imie": 1, "klient.nazwisko": 1, pozycje: 1 }).toArray());

// B6-B7. Sort + limit
printjson(db.zamowienia.find({}, { "klient.nazwisko": 1, status: 1 })
  .sort({ "klient.nazwisko": -1 }).limit(2).toArray());                            // Zielinski, Wiśniewska

// B8. UPDATE a single field
db.zamowienia.updateOne({ _id: 1 }, { $set: { status: "OPLACONE" } });

// B9. Add an order line to the embedded array
db.zamowienia.updateOne(
  { _id: 1 },
  { $push: { pozycje: { produkt: { id: 4, nazwa: "Mysz" }, ilosc: 2, cena: 120 } } }
);

// B10. Order value: $unwind the array, $group by order, $sort
printjson(db.zamowienia.aggregate([
  { $unwind: "$pozycje" },
  { $group: { _id: "$_id", wartosc_zamowienia: { $sum: { $multiply: ["$pozycje.ilosc", "$pozycje.cena"] } } } },
  { $sort: { wartosc_zamowienia: -1 } }
]).toArray());
// -> 1: 4940, 3: 4320, 4: 2650, 2: 1440
