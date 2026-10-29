-- Schemat bazy Gdziewypije według ERD z raportu etapu 2.
-- Uruchamiany raz, na pustej bazie. Przy istniejących tabelach kończy się błędem i niczego nie usuwa.
-- Reset od zera: docker compose down -v (usuwa wolumen z danymi), potem ponownie skrypty.

CREATE EXTENSION IF NOT EXISTS postgis;


-- Tabele

CREATE TABLE users (
    id            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email         text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    role          text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    is_active     boolean NOT NULL DEFAULT true
);

-- Relacja 1:1 z users: klucz główny jest jednocześnie kluczem obcym
CREATE TABLE user_profiles (
    user_id      integer PRIMARY KEY REFERENCES users (id),
    -- PU.01: nazwa krótsza niż 2 znaki jest odrzucana
    display_name text NOT NULL CHECK (char_length(display_name) >= 2),
    points       integer NOT NULL DEFAULT 0 CHECK (points >= 0),
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    is_active    boolean NOT NULL DEFAULT true
);

CREATE TABLE bars (
    id            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Identyfikator OSM jest unikalny tylko w obrębie typu obiektu (node, way, relation).
    -- Bar dodany przez administratora nie ma odpowiednika w OSM, więc oba pola są puste.
    osm_type      text CHECK (osm_type IN ('node', 'way', 'relation')),
    osm_id        bigint,
    name          text NOT NULL,
    address       text,
    opening_hours text,
    -- geography liczy odległości w metrach (Q1); 4326 to układ współrzędnych GPS
    location      geography(Point, 4326) NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    is_active     boolean NOT NULL DEFAULT true,
    UNIQUE (osm_type, osm_id),
    CHECK ((osm_type IS NULL) = (osm_id IS NULL))
);

CREATE TABLE drinks (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       text NOT NULL,
    category   text NOT NULL CHECK (category IN ('beer', 'cocktail', 'shot', 'wine')),
    volume_ml  integer NOT NULL CHECK (volume_ml > 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    is_active  boolean NOT NULL DEFAULT true,
    UNIQUE (name, volume_ml)
);

-- Historia cen i jednocześnie tabela łącząca bars i drinks (n:n).
-- Aktualna cena to najnowszy aktywny wpis dla pary bar i napój.
CREATE TABLE prices (
    id                integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bar_id            integer NOT NULL REFERENCES bars (id),
    drink_id          integer NOT NULL REFERENCES drinks (id),
    amount            numeric(8, 2) NOT NULL CHECK (amount > 0),
    reported_by       integer NOT NULL REFERENCES users (id),
    created_at        timestamptz NOT NULL DEFAULT now(),
    -- Zgłoszenie liczy się jak pierwsze potwierdzenie; po 90 dniach bez potwierdzenia cena jest „do weryfikacji”
    last_confirmed_at timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    is_active         boolean NOT NULL DEFAULT true
);

-- Klucz złożony blokuje drugie potwierdzenie tej samej ceny przez tę samą osobę (T3)
CREATE TABLE price_confirmations (
    price_id   integer NOT NULL REFERENCES prices (id),
    user_id    integer NOT NULL REFERENCES users (id),
    -- confirm: cena się zgadza, change: cena jest inna (PU.03)
    kind       text NOT NULL DEFAULT 'confirm' CHECK (kind IN ('confirm', 'change')),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (price_id, user_id)
);

-- Jedna ocena użytkownika na bar; kolejna ją zastępuje (T4: ON CONFLICT)
CREATE TABLE ratings (
    user_id    integer NOT NULL REFERENCES users (id),
    bar_id     integer NOT NULL REFERENCES bars (id),
    value      smallint NOT NULL CHECK (value BETWEEN 1 AND 5),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    is_active  boolean NOT NULL DEFAULT true,
    PRIMARY KEY (user_id, bar_id)
);

-- Wyjątek od wyłączania przez is_active: ulubione usuwa się wierszem (T5)
CREATE TABLE favorites (
    user_id    integer NOT NULL REFERENCES users (id),
    bar_id     integer NOT NULL REFERENCES bars (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, bar_id)
);
