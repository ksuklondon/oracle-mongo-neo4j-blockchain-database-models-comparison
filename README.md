# One problem, four data models: Oracle · MongoDB · Neo4j · Blockchain

The **same business problem** (customers, products, orders and order lines) implemented and
queried in three different database models, plus an educational blockchain showing how
hashes make tampering with history detectable.

Coursework from the *Big Data Processing* course (Computer Science), autumn 2026.
Everything runs locally in **Docker**; Python is used for analysis (pandas) and for the blockchain demo.

| Lab | Model | Technology | Key idea |
|---|---|---|---|
| [01-oracle](01-oracle/) | relational | Oracle AI Database 26ai Free, SQL, PL/SQL, python-oracledb | tables + JOIN + declarative integrity (PK/FK/CHECK, triggers, transactions) |
| [02-mongodb](02-mongodb/) | document | MongoDB 8, mongosh, Compass, PyMongo + pandas | embedding vs referencing |
| [03-neo4j-blockchain](03-neo4j-blockchain/) | graph + ledger | Neo4j 5 Community, Cypher; Python | nodes + relationships + paths; hash-linked blocks |

## The same order in every model

| | Oracle | MongoDB | Neo4j | Blockchain |
|---|---|---|---|---|
| Order stored as | 4 tables linked by keys | one document (embedding) or 3 collections (referencing) | `Klient` → `Zamowienie` → `Produkt` nodes, order line = `ZAWIERA` relationship | transactions in hash-linked blocks |
| Joining data | `JOIN` | `$lookup` + `$unwind` / `merge` in pandas | one `MATCH` pattern | none – each block points to the previous hash |
| Data integrity | PK, FK, NOT NULL, CHECK, triggers | none defined (application's job) | uniqueness constraints; a relationship always connects existing nodes | SHA-256 hash chain + comparison of replicas |
| Changing history | possible, no trace after `COMMIT` | possible | possible | detectable |
| Best at | consistency, transactions | reading whole objects | relationships, paths, recommendations | shared history between parties that don't trust one central database |

Order no. 4 (Monitor × 2, Klawiatura × 1) has the value **2650** in MongoDB (Compass aggregation and pandas)
and in Neo4j (Cypher): the models give the same answer, but reach it in very different ways.

## What I learned

- **Oracle** enforces only the rules you define, but those rules are applied every time: duplicate keys
  (`ORA-00001`), missing values (`ORA-01400`), invalid prices (`ORA-02290`) and orphan orders (`ORA-02291`)
  were all rejected by the database itself. Aggregations on 100,000 generated rows ran in ~0.01 s.
- **MongoDB embedding** returns a complete order in one read but duplicates data (the same Laptop is stored
  in several orders). **Referencing** stores everything once, but the application has to join it, and I hit a
  real `KeyError` in pandas when the join key had been projected away.
- **Neo4j** turns multi-level questions into one pattern: the shortest path between two customers
  without a common product (6 hops through another customer's order) is a single `shortestPath(...)` call.
  The same query in SQL would need recursion.
- **Blockchain**: a *hacker* who edits one block breaks the hash link (`is_valid() = False`), but an
  *insider* who recomputes all following hashes passes the local check (`is_valid() = True`), and only the
  comparison with the other replicas reveals the change. The hash protects a single chain, and
  **distribution** across independent nodes protects against someone who can rewrite it.

## Repository structure

```
01-oracle/            SQL scripts (basics, 100k dataset, orders schema, integrity, triggers, transactions) + Python
02-mongodb/           mongosh scripts (embedding, referencing, final task) + PyMongo/pandas
03-neo4j-blockchain/  Cypher scripts (model, paths, CRUD/constraints, recommendations, final task)
                      + blockchain tamper-detection demo + screenshots
```

## Running locally

Requirements: Docker Desktop; Python 3.10+ for the `python/` folders. Copy `.env.example` to `.env`
and set your own passwords. Each folder's README has the exact `docker run` command.

> The lab instructions, the provided datasets and the original interactive blockchain notebook were
> prepared by the course instructor and are **not** included here. All scripts in this repository are my
> own work done during the labs. `tamper_detection_demo.py` is my own re-implementation of the scenario.
