-- Dane testowe: użytkownicy, bary w okolicy Rynku, oceny, ulubione, ceny i potwierdzenia.
-- Uruchamiany raz, po 01_schema.sql i 02_seed.sql. Ponowne uruchomienie kończy się błędem duplikatu e-maila
-- i niczego nie zapisuje, bo cały blok DO jest jedną instrukcją.
--
-- Bary są fikcyjne i nie mają osm_id, więc nie kolidują z importem z OSM (B-03).
-- Hasła są zastąpione napisem 'test-hash', więc na te konta nie da się zalogować.
-- Konto do logowania zakłada się przez rejestrację w aplikacji.
--
-- Przypadki do sprawdzenia:
-- - Pod Ratuszem: dużo dobrych ocen, wygrywa ranking z Piwnicą Kupiecką (jedna piątka)
-- - Nocny Szlak i Kameralna: brak cen („brak danych”)
-- - Zielony Kufel: cena piwa bez potwierdzenia od 120 dni („do weryfikacji”)
-- - Pod Ratuszem i Bar Odrzański: historia cen, aktualna jest najnowsza aktywna
-- - Daleka Przystań: około 4 km od Rynku, poza promieniem 2 km (Q1)
-- - Zamknięty Lokal: wyłączony, nie pojawia się w widokach
-- - Top miesiąca: Zielony Kufel i Nocny Szlak mają po 3 zdarzenia, remis rozstrzyga średnia ocena

DO $$
DECLARE
    -- użytkownicy
    u_admin integer; u_ala integer; u_bartek integer; u_celina integer; u_darek integer; u_ewa integer;
    u_filip integer; u_gosia integer; u_henryk integer; u_iza integer; u_janek integer;
    -- bary
    b_ratusz integer; b_piwnica integer; b_kufel integer; b_nocny integer;
    b_odra integer; b_daleka integer; b_kameralna integer; b_zamkniety integer;
    -- napoje z 02_seed.sql
    d_beer integer; d_craft integer; d_mojito integer; d_aperol integer; d_vodka integer; d_wine integer;
    -- ceny
    p_ratusz_old integer; p_kufel_beer integer; p_kufel_craft integer; p_odra_new integer;
    p_ratusz_beer integer; p_piwnica_beer integer;
BEGIN
    -- Użytkownicy (T1)
    u_admin  := register_user('admin@gdziewypije.pl', 'test-hash', 'Administrator');
    u_ala    := register_user('ala@test.pl',    'test-hash', 'Ala');
    u_bartek := register_user('bartek@test.pl', 'test-hash', 'Bartek');
    u_celina := register_user('celina@test.pl', 'test-hash', 'Celina');
    u_darek  := register_user('darek@test.pl',  'test-hash', 'Darek');
    u_ewa    := register_user('ewa@test.pl',    'test-hash', 'Ewa');
    u_filip  := register_user('filip@test.pl',  'test-hash', 'Filip');
    u_gosia  := register_user('gosia@test.pl',  'test-hash', 'Gosia');
    u_henryk := register_user('henryk@test.pl', 'test-hash', 'Henryk');
    u_iza    := register_user('iza@test.pl',    'test-hash', 'Iza');
    u_janek  := register_user('janek@test.pl',  'test-hash', 'Janek');
    UPDATE users SET role = 'admin' WHERE id = u_admin;

    -- Bary (Rynek to około 17.032, 51.110; ST_MakePoint przyjmuje długość, potem szerokość)
    INSERT INTO bars (name, address, opening_hours, location)
    VALUES ('Pod Ratuszem', 'Rynek 1', 'Mo-Su 12:00-02:00', ST_MakePoint(17.0320, 51.1100)::geography)
    RETURNING id INTO b_ratusz;
    INSERT INTO bars (name, address, location)
    VALUES ('Piwnica Kupiecka', 'Rynek 15', ST_MakePoint(17.0335, 51.1095)::geography)
    RETURNING id INTO b_piwnica;
    INSERT INTO bars (name, address, opening_hours, location)
    VALUES ('Zielony Kufel', 'ul. Kuźnicza 10', 'Mo-Sa 16:00-01:00', ST_MakePoint(17.0290, 51.1120)::geography)
    RETURNING id INTO b_kufel;
    INSERT INTO bars (name, address, location)
    VALUES ('Nocny Szlak', 'ul. Ruska 40', ST_MakePoint(17.0410, 51.1080)::geography)
    RETURNING id INTO b_nocny;
    INSERT INTO bars (name, address, location)
    VALUES ('Bar Odrzański', 'ul. Odrzańska 20', ST_MakePoint(17.0450, 51.1150)::geography)
    RETURNING id INTO b_odra;
    INSERT INTO bars (name, address, location)
    VALUES ('Daleka Przystań', 'ul. Daleka 5', ST_MakePoint(17.0800, 51.1300)::geography)
    RETURNING id INTO b_daleka;
    INSERT INTO bars (name, location)
    VALUES ('Kameralna', ST_MakePoint(17.0250, 51.1050)::geography)
    RETURNING id INTO b_kameralna;
    INSERT INTO bars (name, location, is_active)
    VALUES ('Zamknięty Lokal', ST_MakePoint(17.0330, 51.1110)::geography, false)
    RETURNING id INTO b_zamkniety;

    -- Oceny (T4) dodane w tym miesiącu
    INSERT INTO ratings (user_id, bar_id, value) VALUES
        (u_ala, b_ratusz, 5), (u_bartek, b_ratusz, 5), (u_celina, b_ratusz, 4), (u_darek, b_ratusz, 5),
        (u_ewa, b_ratusz, 4), (u_filip, b_ratusz, 5), (u_gosia, b_ratusz, 4), (u_henryk, b_ratusz, 5),
        (u_ala, b_piwnica, 5),
        (u_ala, b_kufel, 4), (u_bartek, b_kufel, 4), (u_celina, b_kufel, 5),
        (u_darek, b_nocny, 3), (u_ewa, b_nocny, 2), (u_filip, b_nocny, 3),
        (u_gosia, b_odra, 4), (u_henryk, b_odra, 5), (u_iza, b_odra, 4), (u_janek, b_odra, 4),
        (u_iza, b_daleka, 5), (u_janek, b_daleka, 4),
        (u_ala, b_zamkniety, 5);

    -- Oceny z poprzednich miesięcy: liczą się do średniej, ale nie do top miesiąca
    INSERT INTO ratings (user_id, bar_id, value, created_at, updated_at) VALUES
        (u_darek, b_kufel, 3, now() - interval '2 months', now() - interval '2 months'),
        (u_ewa,   b_kufel, 4, now() - interval '2 months', now() - interval '2 months');

    -- T4: druga ocena tej samej osoby zastępuje pierwszą
    INSERT INTO ratings (user_id, bar_id, value) VALUES (u_janek, b_odra, 5)
    ON CONFLICT (user_id, bar_id) DO UPDATE SET value = 5;

    -- Ulubione (T5)
    INSERT INTO favorites (user_id, bar_id) VALUES
        (u_ala, b_ratusz), (u_bartek, b_ratusz), (u_iza, b_ratusz),
        (u_gosia, b_odra), (u_henryk, b_odra),
        (u_ala, b_kufel);
    -- T5: usunięcie z ulubionych
    DELETE FROM favorites WHERE user_id = u_ala AND bar_id = b_kufel;

    -- Napoje z 02_seed.sql
    SELECT id INTO d_beer   FROM drinks WHERE name = 'Piwo lane'     AND volume_ml = 500;
    SELECT id INTO d_craft  FROM drinks WHERE name = 'Piwo kraftowe' AND volume_ml = 400;
    SELECT id INTO d_mojito FROM drinks WHERE name = 'Mojito'        AND volume_ml = 300;
    SELECT id INTO d_aperol FROM drinks WHERE name = 'Aperol Spritz' AND volume_ml = 300;
    SELECT id INTO d_vodka  FROM drinks WHERE name = 'Wódka'         AND volume_ml = 40;
    SELECT id INTO d_wine   FROM drinks WHERE name = 'Wino czerwone' AND volume_ml = 150;

    -- Ceny (T2). Starsze daty ustawiane po zgłoszeniu, bo report_price zapisuje bieżący czas.
    p_ratusz_old := report_price(b_ratusz, d_beer, 12.00, u_ala);
    UPDATE prices SET created_at = now() - interval '120 days', last_confirmed_at = now() - interval '120 days'
    WHERE id = p_ratusz_old;
    p_ratusz_beer := report_price(b_ratusz, d_beer, 14.00, u_bartek);
    PERFORM report_price(b_ratusz, d_mojito, 28.00, u_celina);
    PERFORM report_price(b_ratusz, d_vodka, 9.00, u_celina);

    p_piwnica_beer := report_price(b_piwnica, d_beer, 13.00, u_darek);
    PERFORM report_price(b_piwnica, d_aperol, 30.00, u_darek);

    p_kufel_beer := report_price(b_kufel, d_beer, 11.00, u_ewa);
    UPDATE prices SET created_at = now() - interval '120 days', last_confirmed_at = now() - interval '120 days'
    WHERE id = p_kufel_beer;
    p_kufel_craft := report_price(b_kufel, d_craft, 18.00, u_ewa);
    UPDATE prices SET created_at = now() - interval '100 days', last_confirmed_at = now() - interval '100 days'
    WHERE id = p_kufel_craft;

    PERFORM report_price(b_odra, d_beer, 10.50, u_gosia);
    PERFORM report_price(b_odra, d_wine, 16.00, u_gosia);
    -- Nowsza cena wyłączona przez administratora: aktualna zostaje 10.50
    p_odra_new := report_price(b_odra, d_beer, 9.99, u_henryk);
    UPDATE prices SET is_active = false WHERE id = p_odra_new;

    PERFORM report_price(b_daleka, d_beer, 9.00, u_iza);

    -- Potwierdzenia (T3). Piwo kraftowe w Zielonym Kuflu po potwierdzeniu traci „do weryfikacji”.
    PERFORM confirm_price(p_kufel_craft, u_filip);
    PERFORM confirm_price(p_ratusz_beer, u_ala);
    PERFORM confirm_price(p_ratusz_beer, u_darek);
    PERFORM confirm_price(p_piwnica_beer, u_ala);
    -- Sprzeciw: cena piwa w Zielonym Kuflu dalej jest „do weryfikacji”
    PERFORM confirm_price(p_kufel_beer, u_bartek, 'change');
END;
$$;
