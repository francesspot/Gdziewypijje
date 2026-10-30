# Baza danych

Skrypty SQL dla PostgreSQL 18 + PostGIS, zgodne z ERD z raportu etapu 2. Uruchamiane w tej kolejności:

1. `01_schema.sql` – 8 tabel, wyzwalacz `updated_at`, indeksy, widoki (`v_bar_stats`, `v_current_prices`, `v_top_month`) i funkcje (`register_user`, `report_price`, `confirm_price`)
2. `02_seed.sql` – katalog napojów
3. `03_testdata.sql` – dane testowe: użytkownicy, bary w okolicy Rynku, oceny, ulubione, ceny, potwierdzenia (opcjonalnie)

## Utworzenie bazy

W katalogu głównym repozytorium (wymaga Docker Desktop i pliku `.env`, wzór w `.env.example`):

```
docker compose up -d
docker compose exec db psql -U gdziewypije -d gdziewypije -v ON_ERROR_STOP=1 -f /db/01_schema.sql
docker compose exec db psql -U gdziewypije -d gdziewypije -v ON_ERROR_STOP=1 -f /db/02_seed.sql
docker compose exec db psql -U gdziewypije -d gdziewypije -v ON_ERROR_STOP=1 -f /db/03_testdata.sql
```

Katalog `db/` jest zamontowany w kontenerze jako `/db`. Jeśli `psql` zaraz po `up -d` zgłosi błąd połączenia, baza jeszcze startuje – wystarczy odczekać kilka sekund.

Dane zostają w wolumenie Dockera po `docker compose stop` i ponownym `up -d`. Skrypty uruchamia się raz:

- `01_schema.sql` przy istniejących tabelach kończy się błędem i niczego nie usuwa,
- `02_seed.sql` można uruchomić ponownie, pomija istniejące napoje,
- `03_testdata.sql` przy ponownym uruchomieniu kończy się błędem duplikatu i niczego nie zapisuje.

## Reset od zera

Usuwa wszystkie dane:

```
docker compose down -v
```

Potem ponownie komendy z sekcji „Utworzenie bazy”.

## Konsola SQL

```
docker compose exec db psql -U gdziewypije -d gdziewypije
```

Przykładowe zapytania z raportu etapu 2 (na danych testowych):

```sql
-- Q1: bary w promieniu 2 km od Rynku
SELECT b.name, s.avg_rating,
       ST_Distance(b.location, ST_MakePoint(17.032, 51.110)::geography) AS odleglosc_m
FROM bars b
JOIN v_bar_stats s ON s.bar_id = b.id
WHERE ST_DWithin(b.location, ST_MakePoint(17.032, 51.110)::geography, 2000)
ORDER BY odleglosc_m;

-- Q2: ranking według oceny ważonej
SELECT RANK() OVER (ORDER BY s.weighted_score DESC) AS miejsce,
       b.name, s.avg_rating, s.ratings_count, s.weighted_score
FROM bars b
JOIN v_bar_stats s ON s.bar_id = b.id
WHERE s.ratings_count > 0
ORDER BY miejsce;

-- Q3: top 3 miesiąca
SELECT name, activity, avg_rating FROM v_top_month LIMIT 3;
```

Wyjście z konsoli: `\q`.
