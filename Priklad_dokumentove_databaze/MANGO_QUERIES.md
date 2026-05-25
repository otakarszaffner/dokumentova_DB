# Praktické Mango Queries - Zkopírujte a Vyzkoušejte v Fauxtonu

## Jak Použít

1. Otevřete Fauxton: http://localhost:5984/_utils/
2. Přejděte na databázi: `lunch_orders`
3. V levém menu klikněte na `Run a query` (nebo podobné)
4. Zkopírujte JSON dotaz níže
5. Vlepte do textového pole
6. Klikněte "Run Query" nebo Ctrl+Enter

---

## DOTAZ 1: Všechny objednávky

```json
{
  "selector": {
    "type": "order"
  }
}
```

**Co dělá:** Zobrazí všechny dokumenty typu "order"

---

## DOTAZ 2: Objednávky zaměstnance Alena Novotna

```json
{
  "selector": {
    "type": "order",
    "employee_name": "Alena Novotna"
  },
  "fields": ["_id", "order_date", "status", "items", "total_price"],
  "sort": ["order_date"]
}
```

**Co dělá:**
- Filtruje pouze objednávky Aleny
- Zobrazuje jen vybraná pole (`fields`)
- Řadí podle data objednávky

**Výsledek:** 2 objednávky (2024-05-20 a 2024-05-21)

---

## DOTAZ 3: Objednávky, které nejsou ještě dodány

```json
{
  "selector": {
    "type": "order",
    "status": {
      "$nin": ["delivered", "cancelled"]
    }
  },
  "fields": ["_id", "employee_name", "status", "order_date", "delivery_date"]
}
```

**Co dělá:**
- `$nin` = "not in" - vylučuje state "delivered" a "cancelled"
- Zobrazuje objednávky v přípravě nebo objednané

**Výsledek:** 2 objednávky (status: "in_preparation" a "ordered")

---

## DOTAZ 4: Objednávky s kladnou zpětnou vazbou (4+ hvězdičky)

```json
{
  "selector": {
    "type": "order",
    "feedback": {
      "$exists": true
    },
    "feedback.rating": {
      "$gte": 4
    }
  },
  "fields": ["_id", "employee_name", "feedback.rating", "feedback.comment"]
}
```

**Co dělá:**
- `$exists: true` - Pole zpětné vazby musí existovat
- `$gte: 4` = větší nebo rovno 4
- Zobrazuje jen objednávky s pozitivní zkušeností

**Výsledek:** 3 objednávky (všechny mají rating 5 nebo 4)

---

## DOTAZ 5: Všichni zaměstnanci

```json
{
  "selector": {
    "type": "employee"
  },
  "fields": ["_id", "first_name", "last_name", "department", "dietary_restrictions"]
}
```

**Co dělá:** Zobrazí všechny zaměstnance s jejich preferencemi

**Výsledek:** 4 zaměstnanci

---

## DOTAZ 6: Zaměstnanci s gluten intolerancí

```json
{
  "selector": {
    "type": "employee",
    "dietary_restrictions": {
      "$in": ["bez_gluten"]
    }
  },
  "fields": ["first_name", "last_name", "dietary_restrictions", "allergies"]
}
```

**Co dělá:**
- `$in: ["bez_gluten"]` - Pole "dietary_restrictions" obsahuje "bez_gluten"
- Filtruje zaměstnance s lepokem intolerancí

**Výsledek:** 1 zaměstnanec (Alena)

---

## DOTAZ 7: Zaměstnanci bez jakýchkoliv omezení

```json
{
  "selector": {
    "type": "employee",
    "dietary_restrictions": [],
    "allergies": []
  }
}
```

**Co dělá:** Filtruje zaměstnance bez dietních omezení a alergenů

**Výsledek:** Žádní (všichni mají nějaké omezení)

---

## DOTAZ 8: Všechna jídla (meals)

```json
{
  "selector": {
    "type": "meal"
  },
  "fields": ["name", "category", "price", "vegetarian", "vegan", "gluten_free"],
  "sort": ["price"]
}
```

**Co dělá:**
- Zobrazí všechny jídla
- Řadí podle ceny (od nejlevnějšího)

**Výsledek:** 6 jídel + 1 nápoj + 1 dezert

---

## DOTAZ 9: Vegetariánská jídla

```json
{
  "selector": {
    "type": "meal",
    "vegetarian": true
  },
  "fields": ["name", "price", "vegan", "gluten_free"]
}
```

**Co dělá:** Filtruje pouze vegetariánská jídla

**Výsledek:** 5 jídel

---

## DOTAZ 10: Vegánská jídla bez lepku

```json
{
  "selector": {
    "type": "meal",
    "vegan": true,
    "gluten_free": true
  }
}
```

**Co dělá:** Kombinuje dva filtry - musí být oba splněny

**Výsledek:** 1 jídlo (Buddha Bowl)

---

## DOTAZ 11: Jídla dražší než 150 CZK

```json
{
  "selector": {
    "type": "meal",
    "price": {
      "$gt": 150
    }
  },
  "fields": ["name", "price"],
  "sort": ["price"]
}
```

**Co dělá:**
- `$gt: 150` = greater than (větší než)
- Zobrazuje jídla nad 150 korun

**Výsledek:** 4 jídla

---

## DOTAZ 12: Populární jídla (skóre > 4.7)

```json
{
  "selector": {
    "type": "meal",
    "popularity_score": {
      "$gt": 4.7
    }
  },
  "fields": ["name", "popularity_score", "price"],
  "sort": ["popularity_score"]
}
```

**Co dělá:** Filtruje jídla s vyšším skórem popularity

**Výsledek:** 2 jídla (Pizza 4.8, Tiramisu 4.9)

---

## DOTAZ 13: Objednávky od určitého data

```json
{
  "selector": {
    "type": "order",
    "order_date": {
      "$gte": "2024-05-21"
    }
  },
  "fields": ["_id", "employee_name", "order_date", "status"]
}
```

**Co dělá:**
- `$gte: "2024-05-21"` = greater than or equal (string porovnání - funguje s ISO datumi!)
- Objednávky od 21. května

**Výsledek:** 2 objednávky

---

## DOTAZ 14: Objednávky podle oddělení - IT

```json
{
  "selector": {
    "type": "order",
    "employee_department": "IT"
  },
  "fields": ["_id", "employee_name", "total_price", "status"]
}
```

**Co dělá:** Filtruje objednávky zaměstnanců z IT oddělení

**Výsledek:** 2 objednávky

---

## DOTAZ 15: Placené objednávky

```json
{
  "selector": {
    "type": "order",
    "payment_status": "paid"
  },
  "fields": ["_id", "employee_name", "total_price", "payment_status"]
}
```

**Co dělá:** Zobrazuje objednávky, které byly zaplaceny

**Výsledek:** 3 objednávky

---

## DOTAZ 16: Objednávky bez zpětné vazby

```json
{
  "selector": {
    "type": "order",
    "feedback": {
      "$exists": false
    }
  },
  "fields": ["_id", "employee_name", "order_date", "status"]
}
```

**Co dělá:**
- `$exists: false` = Pole "feedback" neexistuje
- Objednávky, kde zákazník ještě neohodnotil

**Výsledek:** 2 objednávky

---

## DOTAZ 17: Objednávky s vybraným jídlem (Buddha Bowl)

```json
{
  "selector": {
    "type": "order",
    "items": {
      "$elemMatch": {
        "meal_id": "meal_buddha_bowl"
      }
    }
  },
  "fields": ["_id", "employee_name", "items", "total_price"]
}
```

**Co dělá:**
- `$elemMatch` = Alespoň jeden prvek v poli "items" musí splňovat podmínku
- Objednávky obsahující Buddha Bowl

**Výsledek:** 1 objednávka (Alena)

---

## DOTAZ 18: Spojené objednávky (2+ položky)

```json
{
  "selector": {
    "type": "order"
  },
  "fields": ["_id", "employee_name", "items"]
}
```

Pak v aplikaci filtrujete: `items.length >= 2`

**V CouchDB čistě (komplikovanější):** Je potřeba MapReduce nebo aplikační logika

**Výsledek:** 2 objednávky (Alena a Jan mají 2 položky)

---

## DOTAZ 19: Statistika dokument

```json
{
  "selector": {
    "type": "statistics"
  }
}
```

**Co dělá:** Zobrazí agregovanou statistiku

**Výsledek:** 1 dokument se souhrnem

---

## DOTAZ 20: Vše - všechny dokumenty

```json
{
  "selector": {
    "type": {
      "$exists": true
    }
  }
}
```

**Co dělá:** Všechny dokumenty (ty, co mají pole "type")

**Výsledek:** Všech 17 dokumentů

---

## Operátory - Cheat Sheet

| Operátor | Příklad | Vysvětlení |
|----------|---------|-----------|
| `$eq` | `{"price": {"$eq": 180}}` | Rovná se |
| `$gt` | `{"price": {"$gt": 150}}` | Větší než |
| `$gte` | `{"price": {"$gte": 150}}` | Větší nebo rovno |
| `$lt` | `{"price": {"$lt": 100}}` | Menší než |
| `$lte` | `{"price": {"$lte": 100}}` | Menší nebo rovno |
| `$ne` | `{"status": {"$ne": "cancelled"}}` | Není rovno |
| `$exists` | `{"feedback": {"$exists": true}}` | Pole existuje |
| `$in` | `{"status": {"$in": ["paid", "pending"]}}` | Hodnota je v seznamu |
| `$nin` | `{"status": {"$nin": ["cancelled"]}}` | Hodnota NENÍ v seznamu |
| `$and` | `{"$and": [{"price": {"$gt": 100}}, {"type": "meal"}]}` | Všechny podmínky |
| `$or` | `{"$or": [{"vegetarian": true}, {"vegan": true}]}` | Alespoň jedna podmínka |
| `$elemMatch` | `{"items": {"$elemMatch": {"quantity": {"$gt": 1}}}}` | V poli prvek splňuje |

---

## Tipy pro Psaní Dotazů

1. **Začněte s `type`:** Vždy filtrujte podle typu dokumentu první
2. **Kombinujte podmínky:** Všechny v jednom `selector` objektu
3. **Používejte `fields`:** Vyberte jen potřebná pole - zvýší to výkon
4. **Řazení s `sort`:** Po filtru aplikujte řazení
5. **Index:** CouchDB si vytvoří indexy automaticky (pro _find se doporučuje)

---

## Vytvoření Indexu (Doporučeno)

Pokud chcete optimalizovat dotazy:

```json
POST /lunch_orders/_index
{
  "index": {
    "fields": ["type", "employee_department", "order_date"]
  },
  "name": "type-dept-date-idx",
  "ddoc": "_design/idx"
}
```

Pak CouchDB automaticky používá index pro dotazy s těmito poli.

