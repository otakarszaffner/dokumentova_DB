# Objednávkový Systém Obědů - Rychlý Start

## ⚡ Za 5 Minut do Běhu

### Krok 1: Spustit Docker

```bash
cd Priklad_dokumentove_databaze
docker-compose up -d
```

Ověřit:
```bash
docker ps | findstr couchdb
```

Měli byste vidět běžící CouchDB container.

---

### Krok 2: Importovat Data (PowerShell na Windows)

```powershell
# Nastavit执行 policy
PowerShell -ExecutionPolicy Bypass -File .\setup.ps1
```

**Výsledek:**
```
OK: Databaze vytvorena
OK: Import uspesny
   Importovano: 17 dokumentu
OK: Databaze je pripravena!
```

---

### Krok 3: Otevřít Fauxton (GUI)

Jděte na: **http://localhost:5984/_utils/**

Přihlaste se:
- **Uživatel:** admin
- **Heslo:** password

V levém menu by měla být databáze `lunch_orders` s 17 dokumenty.

---

## 🎯 Co Teď Zkusit?

### 1. Spustit Jednoduchý Dotaz

1. Klikněte na `lunch_orders` v levém menu
2. V rozbalovacím menu (kde je "All Documents") vyberte "Run a query"
3. Zkopírujte tento dotaz:

```json
{
  "selector": {
    "type": "order"
  },
  "limit": 5
}
```

4. Klikněte "Run Query"

**Měli byste vidět:** 5 objednávek s úplnými detaily

---

### 2. Filtrovat Objednávky Aleny

```json
{
  "selector": {
    "type": "order",
    "employee_name": "Alena Novotna"
  }
}
```

**Pozor na DENORMALIZACI!** Vidíte všechny detaily zaměstnance (jméno, oddělení) přímo v objednávce. V SQL by byl potřeba JOIN.

---

### 3. Najít Vegetariánská Jídla

```json
{
  "selector": {
    "type": "meal",
    "vegetarian": true
  },
  "fields": ["name", "price", "vegan"]
}
```

**Výsledek:** 5 vegetariánských jídel

---

## 📊 Datové Schéma - Co Máme?

### 👥 Zaměstnanci (4 dokumenty)
- Alena (IT, bez gluten)
- Petr (HR, vegetarián)
- Marie (Marketing, alergie na mlčo)
- Jan (Finance, bez cukru)

### 🍽️ Jídla (8 dokumentů)
- Pizza Margherita - 180 CZK
- Buddha Bowl - 195 CZK (vegan!)
- Kuřecí prsa - 220 CZK
- Vegetariánská pasta - 165 CZK
- Tiramisu - 85 CZK
- Ledový čaj - 40 CZK
- ... atd

### 🛒 Objednávky (5 dokumentů)
- Úplné objednávky s VŠÍM v jednom dokumentu:
  - Zaměstnanec (jméno, oddělení)
  - Položky (jídlo, cena v čase objednávky)
  - Doprava (čas, místo)
  - Platba (metoda, stav)
  - Zpětná vazba (rating, komentář)

### 📈 Statistika (1 dokument)
- Agregované údaje za květen

---

## 💡 Klíčové Koncepty

### Denormalizace
```json
{
  "_id": "order_2024_05_20_001",
  "employee_name": "Alena Novotna",          // ← Repetované z employee
  "employee_department": "IT",               // ← Repetované z employee
  "items": [
    {
      "meal_name": "Buddha Bowl",            // ← Repetované z meal
      "price_per_unit": 195,                 // ← Historická cena!
      ...
    }
  ]
}
```

**Výhoda:** Jeden dotaz = všechna data. Bez JOINů.
**Nevýhoda:** Pokud se změní jméno, musí se aktualizovat všechno.

### Hierarchické Struktury
```json
{
  "items": [                    // ← Pole
    { "meal_id": "...", ... },  // ← Vnořený objekt
    { "meal_id": "...", ... }
  ],
  "feedback": {                 // ← Vnořený objekt
    "rating": 5,
    "comment": "..."
  }
}
```

Tohle je v JSON přirozené. V relační DB by to byly separátní tabulky.

---

## 📚 Doporučené Soubory

1. **README.md** - Úplná dokumentace s vysvětlením
2. **MANGO_QUERIES.md** - 20 praktických dotazů
3. **SQL_vs_CouchDB.md** - Srovnání s SQL
4. **setup.ps1** - Automatizovaný setup

---

## 🔍 Praktické Cvičení

### Cvičení 1: Co dostanete za jeden dotaz?

Zkopírujte do Fauxtonu:
```json
{
  "selector": {
    "type": "order",
    "employee_name": "Alena Novotna"
  }
}
```

**Otázka:** Kolik informací máte v jednom dokumentu?
**Odpověď:** Všechno! Zaměstnanec, jídla, doprava, platba, zpětná vazba.

V SQL by bylo potřeba:
- SELECT z orders
- JOIN s employees
- JOIN s order_items
- JOIN s meals
- JOIN s feedback

### Cvičení 2: Jak velká je redundance?

Srovnejte:
- Kolika dokumentů se jméno zaměstnance "Alena Novotna" objevuje?
- **Odpověď:** V dokumentu `employee_001` + ve 2 objednávkách = 3x

V normalizované SQL databázi by bylo jen 1x.

### Cvičení 3: MapReduce agregace

Zkusíte vytvořit Design Document:

```json
PUT /lunch_orders/_design/stats
{
  "views": {
    "total_revenue": {
      "map": "function(doc) { if(doc.type==='order' && doc.payment_status==='paid') { emit(null, doc.total_price); } }",
      "reduce": "function(k,v,r) { return sum(v); }"
    }
  }
}
```

Pak dotaz:
```
GET /lunch_orders/_design/stats/_view/total_revenue
```

**Výsledek:** Celkový příjm = 1 145 CZK

---

## ❓ Často Kladené Otázky

### Proč jsou data v dokumentu opakovaná?

**Odpověď:** Denormalizace zvyšuje výkon čtení (žádné JOINy), ale zpomaluje zápis (aktualizovat musíte všude).

Vhodné pro systémy, kde je výrazně více čtení než zápisu (99% aplikací).

### Jak aktualizuji jméno zaměstnance?

V CouchDB:
1. Aktualizuj `employee_001` dokument
2. Musíš ručně aktualizovat všechny objednávky s jeho jménem

To je problém denormalizace. SQL má na to FOREIGN KEY constraints.

### Je CouchDB vhodné pro bankovnictví?

**Ne.** Banky potřebují:
- ACID transakce přes více účtů
- Relační integritu
- Složité JOINy

SQL je na to lépe.

### Je CouchDB vhodné pro e-commerce?

**Ano, částečně.**
- ✅ Katalogy produktů (flexibilní atributy)
- ✅ Objednávky (denormalizovaná data)
- ✅ Uživatelské profily
- ❌ Platby (vyžadují ACID)

Obvyklé řešení: **CouchDB + SQL** - CouchDB na objednávky, SQL na transakce.

---

## 🎓 Prezentační Body

### "Proč jsem vybral CouchDB?"

1. **Flexibilita** - Zaměstnanci mají různé atributy, objednávky různé položky
2. **Denormalizace** - Objednávka má vše potřebné v jednom dokumentu
3. **Offline** - Mobilní aplikace by mohla pracovat offline
4. **Skálování** - Horizontální replikace mezi servery
5. **Snadnost** - Bez migrations, bez komplexních JOINů

### "Jaké jsou problémy?"

1. **Redundance** - Jméno zaměstnance v každé objednávce
2. **Aktualizace** - Změna jména vyžaduje aktualizaci všech objednávek
3. **Bez ACID** - Multi-order transakce nejsou atomické
4. **Bez integritu** - Nic neubrání smazat zaměstnance se svými objednávkami

---

## 🚀 Další Kroky

1. **Spusťte setup** - Importujte data
2. **Prozkoumejte Fauxton** - Dívejte se na dokumenty
3. **Zkusíte dotazy** - Zkopírujte z MANGO_QUERIES.md
4. **Vytvořte view** - Zkuste MapReduce
5. **Diskutujte** - Kdy by jste použili CouchDB vs SQL?

---

## 📖 Kde Najít Pomoc

- **CouchDB Docs:** https://docs.couchdb.org/
- **Fauxton Help:** http://localhost:5984/_utils/ (Help v aplikaci)
- **Mango Query Guide:** https://docs.couchdb.org/en/stable/api/database/find.html

---

**Hotovi? Gratulujeme! 🎉**

Máte funkční CouchDB systém, který demonstruje všechny klíčové koncepty dokumentových databází.
