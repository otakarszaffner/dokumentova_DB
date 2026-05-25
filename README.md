# Dokumentová databáze

## Co je dokumentová databáze
Dokumentová databáze je typ **NoSQL databáze**, která ukládá data ve formě **dokumentů** místo klasických tabulek a řádků jako relační databáze (např. MySQL nebo PostgreSQL).

Dokumenty jsou nejčastěji ve formátu:
- JSON
- BSON (Binary JSON)
- XML

Každý dokument obsahuje kompletní záznam jedné entity, například uživatele, produktu nebo objednávky.

---

## Datový model

Dokumentové databáze ukládají data jako struktury typu **klíč–hodnota**.

- **Klíč (key)** – název položky, např. `"name"` nebo `"age"`
- **Hodnota (value)** – samotná data

Hodnota může být:
- číslo
- text
- boolean (`true/false`)
- datum
- pole (`array`)
- vnořený dokument (`object`)
   

## Hlavní vlastnosti dokumentových databází

### 1. Flexibilní schéma
Dokumentové databáze nemají pevně definované schéma jako relační databáze.

To znamená:
- různé dokumenty mohou mít různá pole
- lze snadno přidávat nebo odebírat data
- není potřeba používat `ALTER TABLE`

Například jeden uživatel může mít pole `email` a jiný ne.

---

### 2. Přirozené mapování na objekty
JSON struktura se velmi dobře mapuje na objekty v programovacích jazycích.

Proto se dokumentové databáze často používají s:
- JavaScriptem
- TypeScriptem
- Node.js
- REST API
- mikroservisami

JSON dokument ≈ objekt v aplikaci.

---

### 3. Denormalizace dat
V relačních databázích se data rozdělují do více tabulek (normalizace).

Dokumentové databáze často používají **denormalizaci**:
- související data jsou uložená společně v jednom dokumentu
- není potřeba provádět JOIN operace

Například adresa může být přímo uvnitř dokumentu uživatele.

Výhoda:
- rychlejší čtení dat
- jednodušší dotazy

Nevýhoda:
- mohou vznikat duplicity dat

---

### 4. Hierarchická data
Díky vnořeným dokumentům a polím jsou dokumentové databáze vhodné pro:
- stromové struktury
- JSON data
- složitá hierarchická data

---

### 5. Horizontální škálování
Dokumentové databáze bývají navržené pro:
- distribuované systémy
- cloudová řešení
- velké objemy dat
- vysoký počet požadavků

Data lze rozdělit mezi více serverů (sharding).

---

## Kolekce
Dokumenty jsou seskupeny do **kolekcí**.

Kolekce je podobná tabulce v relační databázi, ale:
- nemusí mít pevné schéma
- dokumenty v jedné kolekci mohou být rozdílné

---

# Výhody dokumentových databází

## Flexibilita
- snadná změna struktury dat
- vhodné pro agilní vývoj
- rychlé přizpůsobení novým požadavkům

---

## Jednodušší vývoj
- přirozená práce s JSON
- méně komplikací s ORM
- rychlejší vývoj aplikací

---

## Výkon
Díky denormalizaci:
- rychlé čtení dat
- méně JOIN operací
- dobrý výkon při zápisu i čtení

---

## Škálovatelnost
- dobrá podpora horizontálního škálování
- vhodné pro cloud a velké aplikace

---

# Nevýhody dokumentových databází

## Omezené ACID transakce
Relační databáze poskytují silné ACID vlastnosti:
- Atomicity
- Consistency
- Isolation
- Durability

Dokumentové databáze často garantují ACID pouze na úrovni jednoho dokumentu.

Transakce mezi více dokumenty:
- bývají složitější
- mohou být méně výkonné
- někdy nejsou podporované

Například:
- CouchDB podporuje ACID jen pro jeden dokument
- MongoDB podporuje multi-document transakce od verze 4.0

---

## Složitější práce se vztahy
Neexistuje klasický SQL JOIN.

Vztahy se řeší:
- vnořením dokumentů
- referencemi pomocí ID

Pokud potřebujeme propojit více dokumentů:
- často musíme použít více dotazů
- spojování dat řeší aplikace

---

## Horší relační integrita
Relační databáze umožňují:
- cizí klíče
- kontrolu integrity dat

Dokumentové databáze toto většinou neumí automaticky.
Kontroly je potřeba řešit v aplikaci.

---

## Další nevýhody
- duplicity dat
- složitější reporting
- někdy vyšší paměťové nároky

---

# Příklady dokumentových databází

## MongoDB
Nejpoužívanější dokumentová databáze.

Vlastnosti:
- BSON formát
- bohatý dotazovací jazyk
- indexy
- replikace
- sharding
- multi-document transakce

---

## CouchDB
Zaměřuje se na:
- spolehlivost
- synchronizaci
- offline režim

Používá:
- JSON
- HTTP API

Často se používá pro mobilní aplikace.

---

## Couchbase
Kombinuje:
- key-value databázi
- dokumentovou databázi

Vhodná pro:
- caching
- aplikace s nízkou latencí

---

## Amazon DocumentDB
Cloudová služba od AWS kompatibilní s MongoDB.

---

## Azure Cosmos DB
Multi-model databáze od Microsoftu podporující i dokumentový model.

---

# Kdy se dokumentové databáze hodí

## Dobré použití

### Webové aplikace
- uživatelské profily
- sociální sítě
- katalogy produktů

---

### CMS systémy
- články
- blogy
- stránky s různou strukturou

---

### Event data
- logy
- analytika
- IoT data

---

### Rychlý vývoj
- startupy
- agilní vývoj
- mikroservisy

---

### Mobilní aplikace
- offline synchronizace
- práce bez internetu

---

# Kdy se dokumentové databáze nehodí

## Finanční systémy
Například:
- bankovní aplikace
- účetnictví

Důvod:
- potřeba silných ACID transakcí

---

## Aplikace s vysokou relační integritou
Pokud je potřeba:
- cizí klíče
- kontrola vazeb mezi daty

lepší volbou bývá relační databáze.

---

## Velmi komplexní vztahy
Pokud aplikace pracuje s:
- mnoha propojenými vztahy
- složitými JOIN operacemi

může být vhodnější:
- relační databáze
- nebo grafová databáze.

