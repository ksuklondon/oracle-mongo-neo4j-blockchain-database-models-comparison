// =====================================================================
// 03_crud_constraints_recommendations.cypher  -  parts D and E
// Run each statement ONCE (CREATE statements are not idempotent).
// =====================================================================

// D1-D2. UPDATE
MATCH (z:Zamowienie {id: 1}) SET z.status = "OPLACONE" RETURN z;
MATCH (p:Produkt {nazwa: "Laptop"})
SET p.stan_magazynowy = p.stan_magazynowy - 1
RETURN p.nazwa, p.stan_magazynowy;                                   // 10 -> 9

// D3-D4. Add / remove a relationship (an order line)
MATCH (z:Zamowienie {id: 1}), (p:Produkt {nazwa: "Mysz"})
CREATE (z)-[:ZAWIERA {ilosc: 1, cena_pozycji: 120.00}]->(p);
MATCH (:Zamowienie {id: 1})-[r:ZAWIERA]->(:Produkt {nazwa: "Mysz"}) DELETE r;

// D5. A node with relationships needs DETACH DELETE (plain DELETE fails)
MATCH (z:Zamowienie {id: 1}) DETACH DELETE z;

// D6. Re-create order 1
MATCH (k:Klient {id: 1})
CREATE (z:Zamowienie {id: 1, data: date("2026-09-25"), status: "NOWE"})
CREATE (k)-[:ZAMOWIL]->(z)
WITH z
MATCH (p1:Produkt {id: 1}), (p3:Produkt {id: 3})
CREATE (z)-[:ZAWIERA {ilosc: 1, cena_pozycji: 4200.00}]->(p1)
CREATE (z)-[:ZAWIERA {ilosc: 2, cena_pozycji: 250.00}]->(p3);

// D7. Uniqueness constraints (each one also creates a backing index)
CREATE CONSTRAINT klient_id     IF NOT EXISTS FOR (k:Klient)     REQUIRE k.id IS UNIQUE;
CREATE CONSTRAINT produkt_id    IF NOT EXISTS FOR (p:Produkt)    REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT zamowienie_id IF NOT EXISTS FOR (z:Zamowienie) REQUIRE z.id IS UNIQUE;
SHOW CONSTRAINTS;

// D8. Expected to FAIL: Neo.ClientError.Schema.ConstraintValidationFailed
CREATE (:Klient {id: 1, imie: "Test", nazwisko: "Duplikat", email: "test@example.com"});

// D9. Index
CREATE INDEX produkt_nazwa IF NOT EXISTS FOR (p:Produkt) ON (p.nazwa);
SHOW INDEXES;

// E1. "Customers who bought a Laptop also bought..."  -> Klawiatura 1, Mysz 1
MATCH (k:Klient)-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA]->(:Produkt {nazwa: "Laptop"})
MATCH (k)-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA]->(p:Produkt)
WHERE p.nazwa <> "Laptop"
RETURN p.nazwa, count(*) AS popularnosc
ORDER BY popularnosc DESC;

// E2. Customer ranking  -> Kowalski 4700, Zielinski 4320, Nowak 1440
MATCH (k:Klient)-[:ZAMOWIL]->(:Zamowienie)-[r:ZAWIERA]->(:Produkt)
RETURN k.imie + " " + k.nazwisko AS klient, sum(r.ilosc * r.cena_pozycji) AS laczna_wartosc
ORDER BY laczna_wartosc DESC;

// E3. Products nobody ordered  -> no records
MATCH (p:Produkt) WHERE NOT (p)<-[:ZAWIERA]-() RETURN p.nazwa, p.cena;

// E4. Product list per customer
MATCH (k:Klient)-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA]->(p:Produkt)
RETURN k.imie + " " + k.nazwisko AS klient, collect(DISTINCT p.nazwa) AS produkty;

// E5. "Similar" customers (at least one common product)
//     -> Nowak-Zielinski (Mysz), Kowalski-Zielinski (Laptop)
MATCH (k1:Klient)-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA]->(p:Produkt)
      <-[:ZAWIERA]-(:Zamowienie)<-[:ZAMOWIL]-(k2:Klient)
WHERE elementId(k1) < elementId(k2)
WITH k1, k2, count(DISTINCT p) AS wspolne
RETURN k1.nazwisko, k2.nazwisko, wspolne
ORDER BY wspolne DESC;
