// =====================================================================
// 04_final_task.cypher  -  new order for Maria Wiśniewska (customer id 4)
// =====================================================================

// 1. New order: Monitor x2, Klawiatura x1 (line price taken from the product node)
MATCH (k:Klient {id: 4})
CREATE (z:Zamowienie {id: 4, data: date("2026-11-14"), status: "NOWE"})
CREATE (k)-[:ZAMOWIL]->(z)
WITH z
MATCH (p2:Produkt {nazwa: "Monitor"}), (p3:Produkt {nazwa: "Klawiatura"})
CREATE (z)-[:ZAWIERA {ilosc: 2, cena_pozycji: p2.cena}]->(p2)
CREATE (z)-[:ZAWIERA {ilosc: 1, cena_pozycji: p3.cena}]->(p3);

// 2. Order value  -> 2 x 1200 + 1 x 250 = 2650.0
//    (the same order no. 4 gave 2650 in MongoDB too - same result, different model)
MATCH (:Klient {id: 4})-[:ZAMOWIL]->(z:Zamowienie {id: 4})-[r:ZAWIERA]->(p:Produkt)
RETURN z.id AS zamowienie,
       collect(p.nazwa + " x" + r.ilosc) AS pozycje,
       sum(r.ilosc * r.cena_pozycji) AS wartosc;

// 3. Customers with at least one product in common with Maria
//    -> Jan Kowalski (Klawiatura), Anna Nowak (Monitor)
MATCH (m:Klient {id: 4})-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA]->(p:Produkt)
      <-[:ZAWIERA]-(:Zamowienie)<-[:ZAMOWIL]-(k:Klient)
WHERE k <> m
RETURN k.imie + " " + k.nazwisko AS klient, collect(DISTINCT p.nazwa) AS wspolne_produkty;

// 4. Product list for EVERY customer (collect); OPTIONAL MATCH keeps customers without orders
MATCH (k:Klient)
OPTIONAL MATCH (k)-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA]->(p:Produkt)
RETURN k.imie + " " + k.nazwisko AS klient, collect(DISTINCT p.nazwa) AS produkty
ORDER BY klient;

// Conclusion: the graph model fits best data where the connections between
// objects matter most - recommendations and path finding - because relationships
// are stored directly instead of being rebuilt with JOINs.
