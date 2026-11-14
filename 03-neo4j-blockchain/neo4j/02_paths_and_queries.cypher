// =====================================================================
// 02_paths_and_queries.cypher  -  dependencies and paths (part C)
// =====================================================================

// C0. Filtering nodes
MATCH (k:Klient) WHERE k.nazwisko STARTS WITH "K" RETURN k.imie, k.nazwisko, k.email;
MATCH (p:Produkt) WHERE p.cena > 300 RETURN p.nazwa, p.cena ORDER BY p.cena DESC;

// C1. Who bought a Laptop?  -> Kowalski, Zielinski
MATCH (k:Klient)-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA]->(:Produkt {nazwa: "Laptop"})
RETURN DISTINCT k.imie, k.nazwisko, k.email;

// C2. Value of every order  -> 4700, 4320, 1440
MATCH (z:Zamowienie)-[r:ZAWIERA]->(:Produkt)
RETURN z.id AS zamowienie, z.status AS status, sum(r.ilosc * r.cena_pozycji) AS wartosc
ORDER BY wartosc DESC;

// C3. Path customer -> order -> product (in SQL: 4 tables, 3 JOINs)
MATCH path = (k:Klient)-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA]->(:Produkt)
WHERE k.nazwisko = "Kowalski"
RETURN path;

// C4. Products bought together
MATCH (p1:Produkt)<-[:ZAWIERA]-(:Zamowienie)-[:ZAWIERA]->(p2:Produkt)
WHERE elementId(p1) < elementId(p2)          // id() is deprecated in Neo4j 5
RETURN p1.nazwa, p2.nazwa, count(*) AS razem
ORDER BY razem DESC;

// C5. Bought X but not Y  -> Kowalski
MATCH (k:Klient)-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA]->(:Produkt {nazwa: "Laptop"})
WHERE NOT (k)-[:ZAMOWIL]->(:Zamowienie)-[:ZAWIERA]->(:Produkt {nazwa: "Mysz"})
RETURN k.imie, k.nazwisko;

// C6. Shortest path between two customers with NO common product:
//     Kowalski -> order 1 -> Laptop <- order 3 -> Mysz <- order 2 <- Nowak (6 hops)
//     In SQL this would need a recursive query.
MATCH path = shortestPath(
  (k1:Klient {nazwisko: "Kowalski"})-[:ZAMOWIL|ZAWIERA*1..6]-(k2:Klient {nazwisko: "Nowak"})
)
RETURN path;

// C7. Aggregations (grouping is implicit - by the non-aggregated columns)
MATCH (z:Zamowienie) RETURN z.status AS status, count(*) AS liczba ORDER BY liczba DESC;

MATCH (p:Produkt)<-[r:ZAWIERA]-()
RETURN p.nazwa, sum(r.ilosc) AS sprzedane_sztuki, sum(r.ilosc * r.cena_pozycji) AS przychod
ORDER BY przychod DESC;

// C8. My own queries ------------------------------------------------
// 1. How many customers placed an order with status "NOWE"?  -> 1
MATCH (k:Klient)-[:ZAMOWIL]->(:Zamowienie {status: "NOWE"})
RETURN count(DISTINCT k) AS liczba_klientow;

// 2. Total value of all lines containing "Monitor"?  -> 1200.0
MATCH (:Zamowienie)-[r:ZAWIERA]->(:Produkt {nazwa: "Monitor"})
RETURN sum(r.ilosc * r.cena_pozycji) AS wartosc_monitor;

// 3. Which product appears in the most orders?  -> TIE: Laptop 2, Mysz 2
//    Deliberately no LIMIT 1 - it would hide the tie and give an incomplete answer.
MATCH (z:Zamowienie)-[:ZAWIERA]->(p:Produkt)
RETURN p.nazwa AS produkt, count(DISTINCT z) AS liczba_zamowien
ORDER BY liczba_zamowien DESC;
