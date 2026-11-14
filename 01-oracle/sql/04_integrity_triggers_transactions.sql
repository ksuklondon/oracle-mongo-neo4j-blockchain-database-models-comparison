-- =====================================================================
-- 04_integrity_triggers_transactions.sql
-- Every statement in section H.6 is EXPECTED TO FAIL - that is the point.
-- =====================================================================

-- H.6.1 PRIMARY KEY  -> ORA-00001 (PK_KLIENCI)
INSERT INTO klienci (id_klienta, imie, nazwisko, email)
VALUES (1, 'Test', 'Duplikat', 'test@example.com');

-- H.6.2 UNIQUE       -> ORA-00001 (UQ_KLIENCI_EMAIL)
INSERT INTO klienci (imie, nazwisko, email) VALUES ('Jan', 'Inny', 'jan.kowalski@example.com');

-- H.6.3 NOT NULL     -> ORA-01400
INSERT INTO klienci (imie, nazwisko, email) VALUES (NULL, 'BezImienia', 'brak@example.com');

-- H.6.4 CHECK        -> ORA-02290 (CK_PRODUKTY_CENA)
INSERT INTO produkty (nazwa, cena, stan_magazynowy) VALUES ('Zly produkt', -100, 1);

-- H.6.5 FOREIGN KEY  -> ORA-02291 (FK_ZAMOWIENIA_KLIENT), parent key not found
INSERT INTO zamowienia (id_klienta, status) VALUES (999999, 'NOWE');


-- H.7 BEFORE trigger: stock can never go below zero (demo - CHECK covers it too)
CREATE OR REPLACE TRIGGER trg_produkty_stan
BEFORE INSERT OR UPDATE OF stan_magazynowy ON produkty
FOR EACH ROW
BEGIN
    IF :NEW.stan_magazynowy < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Stan magazynowy nie może być ujemny');
    END IF;
END;
/

UPDATE produkty SET stan_magazynowy = -1 WHERE id_produktu = 1;   -- ORA-20001

-- H.8 AFTER trigger: adding an order line decreases the stock automatically
CREATE OR REPLACE TRIGGER trg_pozycje_zamowien_magazyn
AFTER INSERT ON pozycje_zamowien
FOR EACH ROW
BEGIN
    UPDATE produkty
    SET    stan_magazynowy = stan_magazynowy - :NEW.ilosc
    WHERE  id_produktu = :NEW.id_produktu;
END;
/

SELECT nazwa, stan_magazynowy FROM produkty ORDER BY id_produktu;   -- Mysz: 80
INSERT INTO pozycje_zamowien VALUES (1, 4, 4, 120);                 -- Mysz x4
SELECT nazwa, stan_magazynowy FROM produkty ORDER BY id_produktu;   -- Mysz: 76
COMMIT;
-- Note: Laptop and Klawiatura were added before the trigger existed,
-- so their stock did not change - triggers do not work retroactively.


-- H.9 Transactions
UPDATE produkty SET stan_magazynowy = stan_magazynowy - 1 WHERE nazwa = 'Laptop';
SELECT stan_magazynowy FROM produkty WHERE nazwa = 'Laptop';        -- 9 (uncommitted)
ROLLBACK;
SELECT stan_magazynowy FROM produkty WHERE nazwa = 'Laptop';        -- back to 10

UPDATE produkty SET stan_magazynowy = stan_magazynowy - 1 WHERE nazwa = 'Laptop';
COMMIT;
SELECT stan_magazynowy FROM produkty WHERE nazwa = 'Laptop';        -- 9 (permanent)


-- H.11 Final task (example customer) - the same protections on new data
INSERT INTO klienci (imie, nazwisko, email) VALUES ('Ewa', 'Mazur', 'ewa.mazur@example.com');      -- OK
INSERT INTO klienci (imie, nazwisko, email) VALUES ('Ewa', 'Kopia', 'ewa.mazur@example.com');      -- ORA-00001
INSERT INTO produkty (nazwa, cena, stan_magazynowy) VALUES ('Kabel', -5, 10);                       -- ORA-02290
INSERT INTO zamowienia (id_klienta, status) VALUES (999999, 'NOWE');                                -- ORA-02291

INSERT INTO zamowienia (id_klienta, status)
SELECT id_klienta, 'NOWE' FROM klienci WHERE email = 'ewa.mazur@example.com';
INSERT INTO pozycje_zamowien (id_zamowienia, id_produktu, ilosc, cena)
SELECT MAX(id_zamowienia), 2, 2, 1200 FROM zamowienia;                                              -- Monitor x2, stock 20 -> 18
COMMIT;

UPDATE produkty SET cena = 999 WHERE nazwa = 'Klawiatura';
ROLLBACK;                                                                                           -- price back to 250

UPDATE zamowienia SET status = 'OPLACONE'
WHERE  id_zamowienia = (SELECT MAX(id_zamowienia) FROM zamowienia);
COMMIT;                                                                                             -- status change is permanent

-- Note: IDENTITY values are unique but not necessarily consecutive -
-- my new customer got id 23, because failed inserts also consume values.
