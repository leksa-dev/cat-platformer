# Cat Platformer — plan

Platformówka 2D pixel art w Godot 4. Gramy kotem: biega, skacze, wspina się, robi dash, drapie i pierdzi.
Cel poziomu: dojść do legowiska. Pasek HP (6) i 3 życia (serduszka). Wrogowie: patrz `enemies.md`.

## Sterowanie

| Akcja | Klawiatura | DualShock 4 |
|---|---|---|
| Ruch / wspinanie / pływanie | A D W S / strzałki | lewa gałka / krzyżak |
| Skok, potwierdzenie | Spacja | ✕ |
| Dash | Shift | ○ |
| Drapanie (trzymaj) | J / X | □ |
| Atak pierdem | K / C | △ |
| Rzut włóczką (też w skoku) | L / V | R1 |
| Pełny ekran | F / F11 (albo Opcje) | — |
| Pauza | Esc / P | Options |
| (podpowiedzi pokazują klawisze tego, czym grasz ostatnio: klawiatury albo pada) | | |
| Menu: wybór / wstecz | Spacja, Enter / Backspace, Esc | ✕ / ○ |
| Menu DEV | F1 (albo Pauza → OPCJE → DEV) | — |

## Zrobione

- [x] **1. Szkielet projektu** — 320×180 pixel-perfect, klawisze, autoload `Game`
- [x] **2. Kot: bieg + skok** — coyote time, jump buffer, zmienna wysokość skoku
- [x] **3. Poziom, życia, meta** — kafelki z terrain (autotiling), 3 serduszka, Game Over, legowisko
- [x] **4. Wspinanie + wall-jump** — drzewa (korona = platforma), pnącze, ślizg i odbicie od ścian
- [x] **5. Dash** — 1 w powietrzu, odczepia od drzewa, z drzewa na drzewo
- [x] **6. Kocimiętka** — 4 s szybszego biegu i wyższego skoku
- [x] **7. Wściekłe drapanie** — seria machnięć, sygnał `hit` gotowy pod wrogów
- [x] **Extra: atak pierdem** — kot odwraca się tyłem do celu, chmura leci w stronę celu
- [x] **Extra: rzut włóczką** — kłębek leci niskim łukiem, odbija się od ziemi, trafiony wróg traci 1 HP i jest zaplątany (ogłuszony 2 s); potem kłębek leży chwilę i znika
- [x] **Extra: grafika** — kafelki, kot, tło, drzewa, pnącze, dekoracje wycięte z podglądów; mur z nieregularnych kamieni
- [x] **Extra: DualShock 4**
- [x] **Extra: woda** — kot pływa wolniej, Spacja/✕ = ruch pływacki, wyskok na brzeg
- [x] **Poziom 1 wg szkicu** — plaża i morze, dwa drzewa, basen, dziura, schodek, 3 wysepki, szyb do wall-jumpa, drzewo, stół z pnączem i legowiskiem, morze na końcu

## Dalej

- [x] **8. Przeciwnicy** (`enemies.md`)
  - [x] baza `enemy.gd` (HP, trafienia, odrzut, ogłuszenie, śmierć, dotyk, skok na głowę)
  - [x] 🐶 pies — patrol, pościg, szczekanie pod drzewem, ugryzienie; 2 psy (plaża, drzewo za szybem)
  - [x] 🐭 szczur — doskok z gryzieniem, odskok; można na niego skoczyć (pod stołem)
  - [x] 🐦 wrona — ustawia się nad kotem, nurkuje w miejsce z początku nurkowania (nad kamiennymi platformami)
  - [x] 🐝 osa — podlatuje, zawisa, szybkie ukłucie, odskok (przy kwiatach przed 2. dziurą)
  - [x] 🐸 żabol — skacze, pływa w basenie, język z własnym hitboxem; można na niego skoczyć
  - [x] 🦀 krab — chodzi bokiem, podchodzi do kota, unosi szczypce i szczypie; skok na niego rani kota (poziom 2 zamiast szczurów)
- [~] **9. Obrażenia i śmierć**
  - [x] pasek HP kota w HUD (ramka z `hud.png`), odrzut i 1 s nietykalności po trafieniu, HP 0 = utrata życia
  - [x] checkpointy (flagi): po utracie życia kot wraca do ostatniej flagi
  - [x] nowy kot (`assets/new_cat.png` + `assets/cat_scratch_climb.png` → `assets/game/cat.png`, 119 klatek): chód, bieg, skok, opadanie, lądowanie, dash, pierd, drapanie (ziemia/powietrze), wspinaczka (start, góra, dół, bezruch, zeskok, upadek), oberwanie, śmierć, zawracanie, zabawa włóczką po 6 s bezczynności, picie
  - [ ] kolce
- [x] **10. Dźwięk** — 23 efekty retro i 2 podkłady chiptune (las: menu + poziom 1, plaża: poziom 2), wygenerowane w `assets/game/audio/`; głośność muzyki i efektów w opcjach
- [x] **11. Menu i ekrany** — menu główne (GRAJ / OPCJE / WYJŚCIE), pauza (WZNÓW / OPCJE / OD NOWA / MENU), komunikaty w okienku z kotem, tabliczka „POZIOM N”, pikselowy font z polskimi znakami (`assets/game/ui/font.fnt`)
- [~] **12. Więcej poziomów**
  - [x] **Poziom 2 — wyspy** (`level_02.tscn`): plaża z piaszczystym pagórkiem → surfowanie → wyspa z barem (drink = pełne HP), basenem, ogrodem i pomostem → surfowanie (w obie strony, niski skok, rekiny, ryby, skały) → dżungla (drzewa, pnącze, sadzawka z żabolem) → surfowanie → pustynia (kaktusy ranią) → legowisko
  - [x] kokosy na palmach: spadają, gdy kot przechodzi pod spodem; trafiony traci HP, uskoczony kokos zostaje jako przekąska (+1 HP)
  - [x] rozbudowa poziomu 1: górna ścieżka nad plażą z przekąską, łańcuch 3 drzew nad przepaścią (dash), zejście z filaru po półkach i pnączu
  - [x] rozbudowa poziomu 2: pomost, wysoka wydma, wysepka-przystanek na morzu, dżungla z gęstych palm i krzaków (palmy do wspinania, 2 sadzawki), pustynia z dużymi kaktusami, dołem, ruinami i zasadzką krabów
  - [ ] poziom 3, nowe obiekty do wspinania (rury, płoty)
  - [ ] **Poziomy 4–5 — Kraków, Podgórze** (doklejone po ściekach; lore do ustalenia)
    - poziom 4 „Krzemionki”: Kopiec Krakusa (fort i kościółek św. Benedykta) → kładka → kamieniołom Libana → Park Bednarskiego
    - poziom 5 „Podgórze”: Rynek Podgórski z kościołem św. Józefa → Nadwiśle (bulwary) → kładka Bernatka (meta)
    - przeszkadzajki: rowerzyści i kukiryniarze (monocykle elektryczne) jeżdżą po ścieżce
    - nowi wrogowie: gołąb, kawka, pies na smyczy
    - grafika generowana; najpierw szary poziom (gra się w prostych kafelkach), grafika na końcu
    - okolice dawnego getta (Plac Bohaterów Getta, mur na Lwowskiej) omijamy albo zostają spokojnym tłem, bez wrogów i żartów
- [x] **Monety i 1up** — 10 monet na poziom w trudnych miejscach (licznik w HUD), 2 życia na poziom: jedno na trasie, jedno ukryte; zebrane zostają zebrane po utracie życia
- [x] **Sekrety** — poziom 1: druga przepaść (87–96) wrzuca do jaskini z życiem, wraca się windą; poziom 2: krzak z jagodami w dżungli (7 podrapań = życie); poziom 3: rura pod ściekami w dziurze pod ruchomą płytą prowadzi do ukrytej komnaty
- [x] **Zapis postępu** — po każdym ukończonym poziomie (`user://save.cfg`: poziom, życia, znajdźki, czas); GRAJ → DALEJ / NOWA GRA; checkpointy nie są zapisywane; game over i koniec gry kasują zapis
- [x] **Głośność** — osobno muzyka i efekty (0–100 %, strzałki ←/→ albo Spacja), zapamiętana w `settings.cfg`
- [x] **Wibracje pada** — trafienie, utrata życia, game over, trafienia wrogów (drapanie, kłębek, skok na głowę), zabicie, pierd, dash, 1up, diament, długi upadek, surfowanie, koniec poziomu; OPCJE: WIBRACJE TAK/NIE (menu: strona DŹWIĘK, pauza zamiast JĘZYKA)
- [x] **Ekran końcowy** — czas gry, monety ze wszystkich poziomów, życia; ukryta nagroda „POKOJOWE PRZEJŚCIE”, gdy kot nie zabił żadnego wroga w całej grze (a na tablicy po poziomie „BEZ PRZEMOCY” za poziom bez zabitych)
- [ ] **13. Szlif grafiki** — klatki wspinaczki i drapania, pasek kocimiętki w HUD, lepsze tło, cząsteczki
- [ ] **14. Wydanie** — eksport HTML5, itch.io

## Gdzie co jest

- `scenes/player/cat.gd` — cała logika kota, parametry do strojenia w Inspectorze (węzeł `Cat`)
- `scenes/level/level_01.tscn` — poziom; maluj w `Ground` zakładką **Terrains** („Grass” / „Stone”), dekoracje pod `Decor`
- `scenes/level/level_01_old.tscn` — poprzednia wersja poziomu (kopia)
- `scenes/level/level_02.tscn` — poziom 2; `scenes/objects/surf_zone.tscn` (strefa surfowania), `bar.tscn` (leczenie)
- `scenes/hazards/` — przeszkody: kaktus/skała (`spiky.tscn`), rekin, ryba, kokos
- `scenes/objects/water.tscn` — woda; wstaw do poziomu i ustaw `width_tiles` / `depth_tiles` w Inspectorze
- `scenes/enemies/` — wrogowie: `enemy.gd` (baza) + folder na każdego (`dog/`, `rat/`, `crab/`, `crow/`, `wasp/`, `frog/`)
- `scripts/game.gd` — życia, komunikaty, przejścia między poziomami, klawisze, flagi DEV (`god_mode`, `fly_mode`)
- `scenes/ui/` — menu główne, pauza, menu DEV (`dev.gd`), HUD
- `assets/game/` — gotowa grafika używana w grze (podglądy w `assets/` zostają jako wzór stylu)
