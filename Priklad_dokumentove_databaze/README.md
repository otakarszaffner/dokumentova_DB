# Objednávkový Systém Obědů - CouchDB Příklad

## 1. Přehled

Toto je praktický příklad **dokumentové databáze** (CouchDB), který demonstruje reálný objednávkový systém pro obědů v korporátním prostředí. Systém ukazuje **výhody a nevýhody** dokumentových databází v porovnání se SQL.

### Téma: Lunch Order Management System
- **Zaměstnanci** - Mají různé preference a alergeny
- **Jídla (Meals)** - Různé kategorie, ingredience, nutriční informace
- **Objednávky** - Denormalizované dokumenty obsahující všechny relevantní informace
- **Statistiky** - Agregované údaje o objednávkách

## 2. Datový Model - Schéma

### 2.1 Zaměstnanci (Employee)

```json
{
  "_id": "employee_001",
  "type": "employee",
  "first_name": "Alena",
  "last_name": "Novotna",
  "email": "alena.novotna@company.cz",
  "department": "IT",
  "dietary_restrictions": ["bez_gluten"],
  "allergies": ["arašídy"],
  "favorite_meals": ["pizza", "kuřecí salát"],
  "created_date": "2024-01-10",
  "is_active": true
}
```

**Klíčové vlastnosti:**
- **`type: "employee"`** - Indexování podle typu dokumentu
- **`dietary_restrictions`** - Flexibilní seznam (může se lišit pro každého)
- **`allergies`** - Bezpečnostní důvod - nemusí být vyplněno
- **`favorite_meals`** - Běžné preference - mimo databází by toto byla separátní tabulka!

**Demonstrace flexibility:** Různí zaměstnanci mají různé pole. Nový zaměstnanec může mít dodatečná pole bez migrace databáze.

---

### 2.2 Jídla (Meals)

```json
{
  "_id": "meal_buddha_bowl",
  "type": "meal",
  "name": "Buddha Bowl",
  "description": "Zdravá miska s kvinojou...",
  "category": "hlavní chod",
  "price": 195,
  "currency": "CZK",
  "ingredients": [
    {"name": "quinoa", "allergen": false},
    {"name": "tahini", "allergen": "sezam"},
    ...
  ],
  "vegetarian": true,
  "vegan": true,
  "gluten_free": true,
  "available_until": "2024-05-31",
  "popularity_score": 4.6,
  "estimated_prep_time_minutes": 15
}
```

**Klíčové vlastnosti:**
- **`type: "meal"`** - Pro snadný filtr podle typu
- **`ingredients`** - Vnořené pole s informacemi o alergenech
- **`dietary_flags`** - boolean pole (vegetarian, vegan, gluten_free)
- **Hierarchická struktura** - Ingredience obsahují detaily alergenů

---

### 2.3 Objednávky (Orders) - **DENORMALIZACE!**

```json
{
  "_id": "order_2024_05_20_001",
  "type": "order",
  "order_date": "2024-05-20",
  "order_time": "11:15",
  "employee_id": "employee_001",
  "employee_name": "Alena Novotna",              // DENORMALIZOVANÉ
  "employee_email": "alena.novotna@company.cz", // DENORMALIZOVANÉ
  "employee_department": "IT",                  // DENORMALIZOVANÉ
  "delivery_date": "2024-05-20",
  "delivery_time": "12:00",
  "status": "delivered",
  "special_notes": "Bez gluten prosím - má celiakie",
  "items": [
    {
      "meal_id": "meal_buddha_bowl",
      "meal_name": "Buddha Bowl",              // DENORMALIZOVANÉ
      "quantity": 1,
      "price_per_unit": 195,                  // DENORMALIZOVANÉ (cena v čase objednávky)
      "special_requests": "Bez sezamu"
    },
    { ... }
  ],
  "total_price": 235,
  "currency": "CZK",
  "payment_method": "corporate_account",
  "payment_status": "paid",
  "feedback": {
    "rating": 5,
    "comment": "Výborný Buddha bowl!",
    "would_order_again": true
  }
}
```

**KLÍČOVÝ KONCEPT - Denormalizace:**

V **SQL databázi** bychom měli tabulky:
- `employees` - Informace o zaměstnanci
- `meals` - Informace o jídle
- `orders` - Metadata objednávky
- `order_items` - Položky v objednávce
- `feedback` - Zpětná vazba

Abychom dostali jednu objednávku se všemi detaily, museli bychom provést **4-5 JOINů**.

V **CouchDB (dokumentové DB)** máme **VŠE V JEDNOM DOKUMENTU**! To je hlavní výhoda:
- ✅ Jeden dotaz = všechna data
- ✅ Bez JOINů - mnohem rychlejší
- ✅ Atomicitou na úrovni dokumentu - objednávka je buď kompletní, nebo nebyla vytvořena
- ❌ Ale co když se změní jméno zaměstnance? Musíme aktualizovat všechny jeho objednávky!

---

## 3. Spuštění

### 3.1 Prerequisity
- Docker a Docker Compose
- Terminál / PowerShell

### 3.2 Kroky

```bash
# 1. Přejít do adresáře
cd Priklad_dokumentove_databaze

# 2. Spustit CouchDB
docker-compose up -d

# 3. Ověřit, že CouchDB běží
docker ps
# Měly byste vidět "couchdb" container

# 4. Čekat 5-10 sekund, až se CouchDB inicializuje

# 5. Importovat data (viz níže)
```

---

## 4. Import Dat

### Metoda A: Pomocí `curl` (Linux/Mac/WSL)

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -u admin:password \
  http://localhost:5984/lunch_orders/_bulk_docs \
  --data-binary @data.json
```

### Metoda B: Pomocí PowerShell (Windows)

```powershell
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:password"))
$headers = @{ Authorization = "Basic $auth" }
$data = Get-Content data.json -Raw

Invoke-WebRequest -Uri "http://localhost:5984/lunch_orders/_bulk_docs" `
  -Method POST `
  -Headers $headers `
  -Body $data `
  -ContentType "application/json" `
  -UseBasicParsing
```

### Metoda C: Přes Fauxton (GUI)

1. Otevřete http://localhost:5984/_utils/
2. Klikněte "Create Database" → `lunch_orders` → Create
3. Klikněte na "Import" (horní menu)
4. Vyberte `data.json` a importujte

---

## 5. Dotazování - Praktické Příklady

### 5.1 Mango Query - Všechny objednávky zaměstnance

```json
POST /lunch_orders/_find
{
  "selector": {
    "type": "order",
    "employee_id": "employee_001"
  },
  "fields": ["_id", "order_date", "items", "total_price", "status"]
}
```

**Odpověď:**
```json
{
  "docs": [
    {
      "_id": "order_2024_05_20_001",
      "order_date": "2024-05-20",
      "items": [...],
      "total_price": 235,
      "status": "delivered"
    },
    {
      "_id": "order_2024_05_21_002",
      "order_date": "2024-05-21",
      ...
    }
  ]
}
```

**Výhoda:** Jedním dotazem máme všechny informace! V SQL: museli bychom JOIN objednávky, položky, jídla.

---

### 5.2 Mango Query - Objednávky s kladnou zpětnou vazbou

```json
POST /lunch_orders/_find
{
  "selector": {
    "type": "order",
    "feedback": {
      "$exists": true,
      "$ne": null
    },
    "feedback.rating": {
      "$gte": 4
    }
  },
  "fields": ["_id", "employee_name", "feedback.rating", "feedback.comment"]
}
```

**Demonstrace:**
- `$exists` - Pole musí existovat
- `$gte` - Větší nebo rovno (greater than or equal)
- Vnořené pole - `feedback.rating` - přímý přístup bez JOINu

---

### 5.3 Mango Query - Zaměstnanci s vegetariánskou preferencí

```json
POST /lunch_orders/_find
{
  "selector": {
    "type": "employee",
    "dietary_restrictions": {
      "$in": ["vegetarián"]
    }
  }
}
```

---

### 5.4 MapReduce View - Počet objednávek podle oddělení

```javascript
// Design Document: _design/analytics

// Map funkce
function(doc) {
  if (doc.type === 'order' && doc.employee_department) {
    emit(doc.employee_department, 1);
  }
}

// Reduce funkce
_count
```

**Použití:**
```
GET /lunch_orders/_design/analytics/_view/orders_by_department?group=true
```

**Odpověď:**
```json
{
  "rows": [
    {"key": "Finance", "value": 1},
    {"key": "HR", "value": 1},
    {"key": "IT", "value": 2},
    {"key": "Marketing", "value": 1}
  ]
}
```

---

### 5.5 MapReduce View - Celkový objem prodejů

```javascript
// Map
function(doc) {
  if (doc.type === 'order' && doc.total_price) {
    emit(null, doc.total_price);
  }
}

// Reduce
_sum
```

---

## 6. Výhody CouchDB pro Tento Případ

| Výhoda | Vysvětlení |
|--------|-----------|
| **Denormalizace** | Objednávka obsahuje všechny detaily zaměstnance, jídel - bez JOINů |
| **Flexibilní schéma** | Zaměstnanec může mít "dietary_restrictions" nebo ne - bez migrace |
| **Hierarchická data** | Vnořené pole "items" s detaily |
| **Offline sync** | Mobilní aplikace může pracovat offline a synchronizovat později |
| **Snadné škálování** | Horizontální replikace mezi servery |
| **Rychlé čtení** | Všechna data objednávky v jednom dokumentu = jeden dotaz |

---

## 7. Nevýhody CouchDB pro Tento Případ

| Nevýhoda | Problém |
|----------|---------|
| **Denormalizace = redundance** | Pokud se jméno zaměstnance změní, musíme aktualizovat všechny jeho objednávky |
| **Bez JOINů** | Pokud potřebujeme složité analýzy přes více entit, je to komplikované |
| **Omezené transakce** | ACID na úrovni jednoho dokumentu - víceobjednávková transakce by byla problém |
| **Integrity** | Nic neumožňuje smazat zaměstnance, pokud na něj odkazují objednávky |
| **Disk space** | Redundance zabírá více místa |

---

## 8. SQL vs CouchDB - Konkrétní Příklad

### Úloha: Najděte všechny objednávky zaměstnance "Alena Novotna" s feedback

### SQL řešení:

```sql
SELECT 
  o._id,
  o.order_date,
  o.status,
  ARRAY_AGG(
    JSON_BUILD_OBJECT(
      'meal_id', oi.meal_id,
      'meal_name', m.name,
      'quantity', oi.quantity,
      'price', oi.price_per_unit
    )
  ) as items,
  f.rating,
  f.comment
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id
LEFT JOIN meals m ON oi.meal_id = m.id
LEFT JOIN feedback f ON o.id = f.order_id
WHERE o.employee_id = (
  SELECT id FROM employees WHERE name = 'Alena Novotna'
)
AND f.rating IS NOT NULL;
```

**Problémy:**
- 4 JOINy
- Complexity: 12+ řádků kódu
- Výkon: JOIN přes 4 tabulky = pomalé pro velké datašet

### CouchDB řešení:

```json
POST /lunch_orders/_find
{
  "selector": {
    "type": "order",
    "employee_name": "Alena Novotna",
    "feedback": {
      "$exists": true,
      "$ne": null
    }
  }
}
```

**Výhody:**
- ✅ Jednoduchý dotaz
- ✅ Všechna data jsou v dokumentu
- ✅ Jeden dotaz = všechny informace
- ✅ Lepší čitelnost

---

## 9. Kdy Použít CouchDB vs SQL

### ✅ Používejte CouchDB když:

1. Máte **hierarchická a denormalizovaná data** (objednávka s položkami, zaměstnanec s adresou)
2. **Schéma se mění** - přidáváte nová pole, různé dokumenty mají různou strukturu
3. Potřebujete **offline synchronizaci** (mobilní aplikace)
4. Data jsou primárně **čtena, ne modifikována** (analytics, reporting)
5. Chcete **horizontální škálování** - replikace mezi servery

### ✅ Používejte SQL/Relační DB když:

1. Máte **komplexní transakce** - bankovnictví, rezervační systémy
2. Potřebujete **relační integritu** - cizí klíče, constraints
3. Data jsou **normalizovaná** - mnoho malých tabulek s JOINy
4. Vykonáváte **komplexní agregace** - GROUP BY, HAVING, window functions
5. Aplikace má **silné ACID požadavky** - víceobjednávkové transakce

---

## 10. Praktické Úkoly - Co Vyzkoušet

### Úkol 1: Najděte všechny objednávky, které nejsou ještě dodány

```json
POST /lunch_orders/_find
{
  "selector": {
    "type": "order",
    "status": {
      "$nin": ["delivered", "cancelled"]
    }
  }
}
```

### Úkol 2: Najděte všechny zaměstnance s gluten intolerancí

```json
POST /lunch_orders/_find
{
  "selector": {
    "type": "employee",
    "dietary_restrictions": {
      "$in": ["bez_gluten"]
    }
  }
}
```

### Úkol 3: Vypočítejte průměrné skóre popularity jídel

Zde byste měli vytvořit MapReduce view:

```javascript
// Map
function(doc) {
  if (doc.type === 'meal' && doc.popularity_score) {
    emit(null, doc.popularity_score);
  }
}

// Reduce
function(keys, values, rereduce) {
  return {
    avg: Math.round(sum(values) / values.length * 10) / 10,
    count: values.length,
    total: sum(values)
  };
}
```

---

## 11. Shrnutí

Tento příklad demonstruje:

- ✅ **Flexibilní schéma** - Zaměstnanci mají různá pole
- ✅ **Denormalizaci** - Objednávka obsahuje vše potřebné
- ✅ **Hierarchické struktury** - Vnořené itemy v objednávce
- ✅ **Dotazování bez JOINů** - Mango queries jsou jednoduché
- ✅ **MapReduce agregace** - Pro statistiky
- ✅ **Realný případ** - Faktické tísnění obědů v korporátu

CouchDB je ideální pro **CMS, katalogy, uživatelské profily, objednávkové systémy** s denormalizovanými daty.

---

## 12. Další Zdroje

- [CouchDB Dokumentace](https://docs.couchdb.org/)
- [Mango Query Language](https://docs.couchdb.org/en/stable/api/database/find.html)
- [MapReduce Views](https://docs.couchdb.org/en/stable/ddocs/ddocs.html)
- [Fauxton - CouchDB Admin](http://localhost:5984/_utils/)
