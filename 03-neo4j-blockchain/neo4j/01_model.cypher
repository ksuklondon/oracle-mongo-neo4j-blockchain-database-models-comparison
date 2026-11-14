// =====================================================================
// 01_model.cypher  -  the order problem as a GRAPH
//   (:Klient)-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA {ilosc, cena_pozycji}]->(:Produkt)
// Run each statement separately in Neo4j Browser (http://localhost:7474).
// =====================================================================

// B2. Clean start
MATCH (n) DETACH DELETE n;

// B3. Customers
CREATE (:Klient {id: 1, imie: "Jan",   nazwisko: "Kowalski",   email: "jan.kowalski@example.com"})
CREATE (:Klient {id: 2, imie: "Anna",  nazwisko: "Nowak",      email: "anna.nowak@example.com"})
CREATE (:Klient {id: 3, imie: "Piotr", nazwisko: "Zielinski",  email: "piotr.zielinski@example.com"})
CREATE (:Klient {id: 4, imie: "Maria", nazwisko: "Wiśniewska", email: "maria.wisniewska@example.com"});

// B4. Products
CREATE (:Produkt {id: 1, nazwa: "Laptop",     cena: 4200.00, stan_magazynowy: 10})
CREATE (:Produkt {id: 2, nazwa: "Monitor",    cena: 1200.00, stan_magazynowy: 20})
CREATE (:Produkt {id: 3, nazwa: "Klawiatura", cena: 250.00,  stan_magazynowy: 50})
CREATE (:Produkt {id: 4, nazwa: "Mysz",       cena: 120.00,  stan_magazynowy: 80});

// B5. Orders - an order line is not a table/array but a RELATIONSHIP with properties
MATCH (k:Klient {id: 1})
CREATE (z:Zamowienie {id: 1, data: date("2026-09-25"), status: "NOWE"})
CREATE (k)-[:ZAMOWIL]->(z)
WITH z
MATCH (p1:Produkt {id: 1}), (p3:Produkt {id: 3})
CREATE (z)-[:ZAWIERA {ilosc: 1, cena_pozycji: 4200.00}]->(p1)
CREATE (z)-[:ZAWIERA {ilosc: 2, cena_pozycji: 250.00}]->(p3);

MATCH (k:Klient {id: 2})
CREATE (z:Zamowienie {id: 2, data: date("2026-09-26"), status: "OPLACONE"})
CREATE (k)-[:ZAMOWIL]->(z)
WITH z
MATCH (p2:Produkt {id: 2}), (p4:Produkt {id: 4})
CREATE (z)-[:ZAWIERA {ilosc: 1, cena_pozycji: 1200.00}]->(p2)
CREATE (z)-[:ZAWIERA {ilosc: 2, cena_pozycji: 120.00}]->(p4);

MATCH (k:Klient {id: 3})
CREATE (z:Zamowienie {id: 3, data: date("2026-09-26"), status: "WYSŁANE"})
CREATE (k)-[:ZAMOWIL]->(z)
WITH z
MATCH (p1:Produkt {id: 1}), (p4:Produkt {id: 4})
CREATE (z)-[:ZAWIERA {ilosc: 1, cena_pozycji: 4200.00}]->(p1)
CREATE (z)-[:ZAWIERA {ilosc: 1, cena_pozycji: 120.00}]->(p4);

// B6. Verification: Klient 4, Produkt 4, Zamowienie 3 | ZAMOWIL 3, ZAWIERA 6
MATCH (n) RETURN labels(n) AS etykieta, count(*) AS liczba ORDER BY etykieta;
MATCH ()-[r]->() RETURN type(r) AS relacja, count(*) AS liczba ORDER BY relacja;

MATCH (k:Klient)-[:ZAMOWIL]->(z:Zamowienie)-[r:ZAWIERA]->(p:Produkt)
RETURN k.imie + " " + k.nazwisko AS klient, z.id AS zamowienie, z.status AS status,
       p.nazwa AS produkt, r.ilosc AS ilosc, r.cena_pozycji AS cena
ORDER BY z.id, p.nazwa;

// Whole graph (switch the result view to "Graph")
MATCH (n)-[r]->(m) RETURN n, r, m;
