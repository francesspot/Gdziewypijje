-- Dane początkowe: katalog napojów (raport etapu 2: piwo, drinki, shoty, wino; 10–20 pozycji).
-- Uruchamiany po 01_schema.sql. Ponowne uruchomienie pomija napoje, które już są w bazie.

INSERT INTO drinks (name, category, volume_ml) VALUES
    ('Piwo lane',          'beer',     500),
    ('Piwo lane',          'beer',     300),
    ('Piwo butelkowe',     'beer',     500),
    ('Piwo kraftowe',      'beer',     400),
    ('Piwo bezalkoholowe', 'beer',     500),
    ('Mojito',             'cocktail', 300),
    ('Aperol Spritz',      'cocktail', 300),
    ('Cuba Libre',         'cocktail', 300),
    ('Gin z tonikiem',     'cocktail', 300),
    ('Margarita',          'cocktail', 200),
    ('Wódka',              'shot',      40),
    ('Wódka smakowa',      'shot',      40),
    ('Tequila',            'shot',      40),
    ('Rum',                'shot',      40),
    ('Wino czerwone',      'wine',     150),
    ('Wino białe',         'wine',     150),
    ('Prosecco',           'wine',     150)
-- UNIQUE (name, volume_ml) w tabeli drinks rozpoznaje napój, który już istnieje
ON CONFLICT (name, volume_ml) DO NOTHING;
