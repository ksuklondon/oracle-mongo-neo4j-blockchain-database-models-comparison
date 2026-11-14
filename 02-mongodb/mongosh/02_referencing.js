// =====================================================================
// 02_referencing.js  -  the same orders with REFERENCES (ids only)
// Run:  mongosh "mongodb://localhost:27017/bd_lab" 02_referencing.js
// =====================================================================
db = db.getSiblingDB("bd_lab");
db.klienci.drop();
db.produkty.drop();
db.zamowienia_ref.drop();

// C2-C3. Every customer and every product is stored exactly once
db.klienci.insertMany([
  { _id: 1, imie: "Jan",   nazwisko: "Kowalski",  email: "jan.kowalski@example.com" },
  { _id: 2, imie: "Anna",  nazwisko: "Nowak",     email: "anna.nowak@example.com" },
  { _id: 3, imie: "Piotr", nazwisko: "Zielinski", email: "piotr.zielinski@example.com" }
]);

db.produkty.insertMany([
  { _id: 1, nazwa: "Laptop",     cena: 4200, stan_magazynowy: 10 },
  { _id: 2, nazwa: "Monitor",    cena: 1200, stan_magazynowy: 20 },
  { _id: 3, nazwa: "Klawiatura", cena: 250,  stan_magazynowy: 50 },
  { _id: 4, nazwa: "Mysz",       cena: 120,  stan_magazynowy: 80 }
]);

// C4. Orders hold only ids - from the order alone you cannot tell who bought what
db.zamowienia_ref.insertMany([
  { _id: 1, id_klienta: 1, data_zamowienia: ISODate("2026-09-25T10:00:00Z"), status: "NOWE",
    pozycje: [ { id_produktu: 1, ilosc: 1, cena: 4200 }, { id_produktu: 3, ilosc: 2, cena: 250 } ] },
  { _id: 2, id_klienta: 2, data_zamowienia: ISODate("2026-09-26T09:00:00Z"), status: "OPLACONE",
    pozycje: [ { id_produktu: 2, ilosc: 1, cena: 1200 }, { id_produktu: 4, ilosc: 2, cena: 120 } ] },
  { _id: 3, id_klienta: 3, data_zamowienia: ISODate("2026-09-26T12:00:00Z"), status: "WYSLANE",
    pozycje: [ { id_produktu: 1, ilosc: 1, cena: 4200 }, { id_produktu: 4, ilosc: 1, cena: 120 } ] }
]);

// C6. $lookup joins customers - result field "klient" is an ARRAY
printjson(db.zamowienia_ref.aggregate([
  { $lookup: { from: "klienci", localField: "id_klienta", foreignField: "_id", as: "klient" } }
]).toArray());

// C7. $unwind turns the one-element array into an object
printjson(db.zamowienia_ref.aggregate([
  { $lookup: { from: "klienci", localField: "id_klienta", foreignField: "_id", as: "klient" } },
  { $unwind: "$klient" }
]).toArray());

// Extra: full order incl. product names needs a second $lookup
printjson(db.zamowienia_ref.aggregate([
  { $lookup: { from: "klienci", localField: "id_klienta", foreignField: "_id", as: "klient" } },
  { $unwind: "$klient" },
  { $unwind: "$pozycje" },
  { $lookup: { from: "produkty", localField: "pozycje.id_produktu", foreignField: "_id", as: "produkt" } },
  { $unwind: "$produkt" },
  { $project: { _id: 0, zamowienie: "$_id", nazwisko: "$klient.nazwisko",
                produkt: "$produkt.nazwa", ilosc: "$pozycje.ilosc" } }
]).toArray());
