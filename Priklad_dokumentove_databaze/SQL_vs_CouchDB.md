# SQL vs CouchDB - Praktické Srovnání

## Úloha 1: Všechny objednávky zaměstnance s detaily

### Zadání
"Najděte všechny objednávky zaměstnance Alena Novotna včetně všech detailů o jídle a zpětné vazby."

---

### SQL Řešení

```sql
SELECT 
    o.id as order_id,
    o.order_date,
    o.status,
    e.first_name,
    e.last_name,
    e.department,
    oi.quantity,
    m.name as meal_name,
    m.price as meal_price,
    f.rating,
    f.comment
FROM orders o
INNER JOIN employees e ON o.employee_id = e.id
LEFT JOIN order_items oi ON o.id = oi.order_id
LEFT JOIN meals m ON oi.meal_id = m.id
LEFT JOIN feedback f ON o.id = f.order_id
WHERE e.first_name = 'Alena' AND e.last_name = 'Novotna'
ORDER BY o.order_date DESC;
```

**Analýza SQL:**
- ❌ **4 JOINy** (orders, employees, order_items, meals, feedback)
- ❌ **Komplexita:** 12 řádků kódu
- ❌ **Výkon:** Spojování tabulek pro každý řádek
- ✅ Data jsou normalizovaná - bez redundance

---

### CouchDB Řešení

```json
POST /lunch_orders/_find
{
  "selector": {
    "type": "order",
    "employee_name": "Alena Novotna"
  },
  "sort": ["order_date"]
}
```

**Analýza CouchDB:**
- ✅ **0 JOINů** - vše je v jednom dokumentu!
- ✅ **Jednoduchost:** 6 řádků
- ✅ **Výkon:** Jeden dotaz na jeden index
- ❌ Redundance dat - jméno zaměstnance opakováno v každé objednávce

**Vysvětlení:**
V CouchDB je objednávka denormalizovaný dokument:
```json
{
  "_id": "order_2024_05_20_001",
  "type": "order",
  "employee_id": "employee_001",
  "employee_name": "Alena Novotna",        // DENORMALIZOVANÉ
  "employee_department": "IT",              // DENORMALIZOVANÉ
  "items": [
    {
      "meal_id": "meal_buddha_bowl",
      "meal_name": "Buddha Bowl",          // DENORMALIZOVANÉ
      "price_per_unit": 195,               // DENORMALIZOVANÉ (historická cena!)
      ...
    }
  ],
  "feedback": {...}
}
```

Všechno je tu! Není potřeba žádný JOIN.

---

## Úloha 2: Statistika - Kolik objednávek připadá na oddělení?

### Zadání
"Spočítejte počet objednávek podle oddělení zaměstnanců."

---

### SQL Řešení

```sql
SELECT 
    e.department,
    COUNT(o.id) as order_count,
    SUM(o.total_price) as total_revenue,
    AVG(o.total_price) as avg_order_value
FROM orders o
INNER JOIN employees e ON o.employee_id = e.id
GROUP BY e.department
ORDER BY order_count DESC;
```

**Výsledek:**
```
department  | order_count | total_revenue | avg_order_value
-----------|------------|---------------|----------------
IT         | 2          | 480           | 240
HR         | 1          | 250           | 250
Marketing  | 1          | 220           | 220
Finance    | 1          | 260           | 260
```

---

### CouchDB Řešení - MapReduce View

**1. Vytvořit Design Document:**

```json
PUT /lunch_orders/_design/statistics
{
  "views": {
    "orders_by_department": {
      "map": "function(doc) { if (doc.type === 'order' && doc.employee_department) { emit(doc.employee_department, doc.total_price); } }",
      "reduce": "function(keys, values, rereduce) { return { count: values.length, total: sum(values), avg: Math.round(sum(values) / values.length) }; }"
    }
  }
}
```

**2. Dotazovat View:**

```
GET /lunch_orders/_design/statistics/_view/orders_by_department?group=true
```

**Výsledek:**
```json
{
  "rows": [
    {
      "key": "IT",
      "value": {
        "count": 2,
        "total": 480,
        "avg": 240
      }
    },
    {
      "key": "HR",
      "value": {
        "count": 1,
        "total": 250,
        "avg": 250
      }
    },
    ...
  ]
}
```

**Srovnání:**
- **SQL:** GROUP BY, agregační funkce - přirozené pro tuto úlohu
- **CouchDB:** MapReduce - flexibilnější, ale abstraktnější koncept

---

## Úloha 3: Najděte všechny zaměstnance s intolerancí lepku

### Zadání
"Kteří zaměstnanci mají lepkovou intolerancí (bez_gluten)?"

---

### SQL Řešení

```sql
SELECT 
    e.first_name,
    e.last_name,
    e.email,
    e.dietary_restrictions
FROM employees e
WHERE 'bez_gluten' = ANY(e.dietary_restrictions)
  OR dietary_restrictions LIKE '%bez_gluten%';
```

Problém: Arrays v SQL nejsou standardní. Řešení se liší podle DB (PostgreSQL, MySQL, atd.)

---

### CouchDB Řešení

```json
POST /lunch_orders/_find
{
  "selector": {
    "type": "employee",
    "dietary_restrictions": {
      "$in": ["bez_gluten"]
    }
  },
  "fields": ["first_name", "last_name", "email", "dietary_restrictions"]
}
```

**Výhoda:**
- ✅ Pole (arrays) jsou přirozená v JSON
- ✅ Jednoduché operátory ($in, $all, etc.)
- ✅ Čitelné a intuitivní

---

## Úloha 4: Najděte "repeat customers" - zaměstnance, kteří si objednali více než jednou

### Zadání
"Kterí zaměstnanci si objednali minimálně 2x? Kolik toho utratili?"

---

### SQL Řešení

```sql
SELECT 
    e.first_name,
    e.last_name,
    COUNT(o.id) as order_count,
    SUM(o.total_price) as total_spent,
    AVG(o.total_price) as avg_order_value,
    MAX(o.order_date) as last_order
FROM orders o
INNER JOIN employees e ON o.employee_id = e.id
GROUP BY e.id, e.first_name, e.last_name
HAVING COUNT(o.id) >= 2
ORDER BY total_spent DESC;
```

---

### CouchDB Řešení

**Přístup 1: MapReduce View**

```javascript
// Map funkce
function(doc) {
  if (doc.type === 'order') {
    emit(doc.employee_name, doc.total_price);
  }
}

// Reduce funkce
function(keys, values, rereduce) {
  return {
    count: values.length,
    total: sum(values)
  };
}
```

Dotaz:
```
GET /lunch_orders/_design/repeat_customers/_view/by_employee?group=true
```

**Přístup 2: Mango Query + filtr v aplikaci**

```json
POST /lunch_orders/_find
{
  "selector": {
    "type": "order"
  }
}
```

Pak v aplikaci spočítáte objednávky na zaměstnance.

---

## Úloha 5: Najděte všechny objednávky s negativní zpětnou vazbou

### Zadání
"Najděte objednávky se skórem zpětné vazby nižším než 3 hvězdičky."

---

### SQL Řešení

```sql
SELECT 
    o.id,
    e.first_name,
    e.last_name,
    f.rating,
    f.comment,
    o.order_date
FROM orders o
INNER JOIN employees e ON o.employee_id = e.id
LEFT JOIN feedback f ON o.id = f.order_id
WHERE f.rating < 3
ORDER BY f.rating ASC;
```

---

### CouchDB Řešení

```json
POST /lunch_orders/_find
{
  "selector": {
    "type": "order",
    "feedback.rating": {
      "$lt": 3
    },
    "feedback": {
      "$exists": true
    }
  },
  "fields": ["_id", "employee_name", "feedback.rating", "feedback.comment", "order_date"],
  "sort": ["feedback.rating"]
}
```

**Výhoda:**
- Vnořené pole `feedback.rating` - přímý přístup
- Operátor `$exists` - ověří přítomnost pole

---

## Shrnutí Porovnání

| Kritérium | SQL | CouchDB |
|-----------|-----|---------|
| **Jednoduché JOINy (1-2 tabulky)** | ✅ Ideální | ⚠️ Je to redundantní |
| **Komplexní JOINy (3+ tabulek)** | ✅ Silné | ❌ Neefektivní |
| **Denormalizovaná data** | ❌ Redundance | ✅ Přirozené |
| **Agregace (GROUP BY, SUM)** | ✅ Přirozené | ⚠️ MapReduce složitější |
| **Vnořené pole (arrays)** | ❌ Složité | ✅ Jednoduché |
| **Flexibilní schéma** | ❌ Migrace nutné | ✅ Bez migrace |
| **Výkon čtení** | ✅ Dobrý | ✅ Dobrý (bez JOINů) |
| **Výkon zápisu** | ✅ Normalizace úspora | ❌ Redundance zpomaluje |
| **ACID transakce** | ✅ Multi-table | ❌ Jen v 1 dokumentu |
| **Offline sync** | ❌ Bez | ✅ Vestavěné |

---

## Kdy Vybrat Kterou?

### ✅ Vyberte **CouchDB** když:
1. Data jsou **hierarchická** (objednávka → položky → detaily)
2. **Schéma se mění** - nová pole, různé dokumenty
3. Výrazně více **čtení než zápisu**
4. Potřebujete **offline synchronizaci**
5. Horizontální **replikace mezi servery**
6. **Denormalizovaná data** jsou přirozená

### ✅ Vyberte **SQL** když:
1. Data jsou **silně normalizovaná**
2. Máte **komplexní dotazy** se spoustou JOINů
3. Potřebujete **ACID transakce** přes více tabulek
4. Vykonáváte **komplexní agregace** a analýzy
5. **Integritu dat** vynucujete databází
6. **Psaní dat** je intenzivní operace

---

## Praktické Cvičení

**Vyzkoušejte si všechny 5 úloh:**

1. Spusťte Docker Compose
2. Importujte `data.json` skriptem `setup.ps1`
3. Otevřete Fauxton: http://localhost:5984/_utils/
4. Zkusíte každý CouchDB dotaz z výše
5. Porovnejte výsledky se SQL verzemi
6. Diskutujte: Který přístup je lepší pro tento případ?

