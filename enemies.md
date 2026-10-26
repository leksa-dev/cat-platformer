# Cat Platformer — dokumentacja przeciwników

Platformówka 2D z pomarańczowym kotem. Wrogowie mają różne sposoby poruszania się i ataki, żeby wymuszać różne strategie.

**Styl:** pixel art, ten sam co kot.
**Skala gry:** kafelek 16 px, kot ok. 13 px wysokości, ekran 320×180. Arkusz `assets/enemies.png` ma klatki ok. 48 px; w grze wrogowie mają 11–15 px wysokości (zeskalowani jak kot).
**Uwaga:** liczby to wartości startowe do testów i balansu. Wszystkie są `@export`, więc stroi się je w Inspectorze.

---

# Zasady walki

## Kot: pasek HP i życia
- Kot ma **pasek HP: 6 punktów** (pod serduszkami w HUD).
- **Serduszka to życia (3).** Gdy HP spadnie do 0 → traci życie i poziom startuje od nowa z pełnym HP.
- **Upadek w przepaść** zabiera od razu życie (jak dotąd).
- Po trafieniu kot **odskakuje** i przez **1 s jest nietykalny** (miga).

## Obrażenia zadawane kotu
| Źródło | Obrażenia |
|---|---:|
| Atak wroga (ugryzienie, dziób, język, żądło) | 2 |
| Dotyk ciała wroga | 1 (+ odrzut) |

## Obrażenia zadawane przez kota
| Atak | Obrażenia | Uwagi |
|---|---:|---|
| Drapanie | 1 za machnięcie | wróg po trafieniu jest nietykalny 0,4 s, więc seria nie zabija od razu |
| Pierd | 2 | + ogłuszenie wroga na 1 s |
| Skok na głowę | 3 | tylko **szczur i żabol**; kot odbija się w górę |

## Wspólne zasady AI
- **Wykrywanie:** każdy wróg ma zasięg wykrywania; samo pojawienie się kota na ekranie nie uruchamia ataku.
- **Przygotowanie ataku:** każdy atak ma czytelną fazę przygotowania — gracz widzi zamiar i może zareagować.
- **Aktywna faza:** obrażenia atakiem zadaje tylko aktywna faza (osobny hitbox), nie każda klatka animacji.
- **Cooldown:** po ataku wróg chwilę nie atakuje — czas na kontratak albo ucieczkę.
- **HP, trafienie, śmierć:** każdy wróg ma HP, animację `hurt` z krótkim odrzutem i `death`; po śmierci nie zadaje obrażeń.

## Interakcje z mechanikami kota
- **Pies nie wspina się ani nie pływa:** kot ucieka na drzewo, pies szczeka pod nim. Pies zawraca przy krawędzi i wodzie.
- **Wrona** poluje także na kota wiszącego na drzewie / pnączu.
- **Żabol** siedzi przy wodzie i pływa w basenie.
- **Osa** krąży przy kwiatach.

## Kolizje w Godot
- **Collision shape** — fizyka ze światem (warstwa 1).
- **Hurtbox** — ciało wroga na warstwie 4; w nie trafiają pazury i pierd kota.
- **Hitbox** — obszar ataku wroga, sprawdzany tylko w aktywnej fazie (np. pysk psa, język żabola sięgający poza ciało).
- Kot i wrogowie przez siebie przenikają (bez pchania); dotyk liczy się jako obrażenia.

---

# Przeciwnicy

## 1. 🐶 Pies — Dog
**Rola:** podstawowy wróg naziemny · **Trudność:** łatwa · **Środowisko:** trawa, leśne ścieżki

**Zachowanie:** patroluje w lewo i prawo, zawraca przy krawędzi, ścianie i wodzie. Po wykryciu kota goni go (wolniej niż kot biega). Jeśli kot jest wyżej (np. na drzewie) — staje pod nim i szczeka. Przed ugryzieniem zatrzymuje się na chwilę.

**Atak: gryzienie** — przygotowanie, szybkie ugryzienie przed sobą (hitbox tylko w tej fazie), cooldown, powrót do pościgu/patrolu.

| Parametr | Wartość |
|---|---:|
| HP | 3 |
| Prędkość patrolu / pościgu | 40 / 75 px/s |
| Zasięg wykrywania | 80 px |
| Zasięg ataku | 14 px |
| Ugryzienie | 1 (wyjątek: słabsze niż inne ataki) |
| Przygotowanie / cooldown | 0,25 s / 1,2 s |

**Animacje:** `idle`, `run`, `attack`, `hurt`, `death`.

## 2. 🐦 Wrona — Crow
**Rola:** wróg powietrzny atakujący z góry · **Trudność:** średnia · **Środowisko:** lasy, otwarte przestrzenie

**Zachowanie:** lata nad ziemią, ustawia się nad kotem, nurkuje, potem wraca na wysokość. Celuje w pozycję kota **z początku nurkowania** (nie koryguje lotu) — da się uskoczyć.

| Parametr | Wartość |
|---|---:|
| HP | 2 |
| Prędkość lotu / nurkowania | 50 / 160 px/s |
| Zasięg wykrywania | 100 px |
| Przygotowanie / cooldown | 0,45 s / 1,8 s |

**Animacje:** `idle`, `fly`, `dive`, `recover`, `hurt`, `death`.

## 3. 🐭 Szczur — Rat
**Rola:** szybki wróg naziemny · **Trudność:** średnia · **Środowisko:** ciasne przejścia, okolice przeszkód

**Zachowanie:** patroluje mały obszar, po zauważeniu kota robi krótki skok z gryzieniem, po nieudanym ataku odskakuje. **Można na niego skoczyć.** Skok ma ograniczony zasięg — przewagą jest szybkość, nie przeskakiwanie ekranu.

| Parametr | Wartość |
|---|---:|
| HP | 2 |
| Prędkość biegu | 80 px/s |
| Maks. odległość skoku | 40 px |
| Przygotowanie / cooldown | 0,2 s / 1,4 s |

**Animacje:** `idle`, `run`, `jump`, `attack`, `hurt`, `death`.

## 4. 🐸 Żabol — Frog
**Rola:** kontrola przestrzeni na średnim dystansie · **Trudność:** średnia · **Środowisko:** woda, basen, szersze platformy

**Zachowanie:** porusza się skokami, po lądowaniu chwilę stoi. Co jakiś czas strzela językiem w stronę kota (stoi wtedy w miejscu). Język ma osobny hitbox sięgający poza ciało. Pływa. **Można na niego skoczyć.**

| Parametr | Wartość |
|---|---:|
| HP | 3 |
| Skok: odległość / wysokość | 48 / 30 px |
| Zasięg języka | 48 px |
| Przygotowanie / cooldown | 0,5 s / 2 s |

**Animacje:** `idle`, `jump`, `tongue`, `land`, `hurt`, `death`.

## 5. 🐝 Osa — Wasp
**Rola:** szybki wróg powietrzny · **Trudność:** średnia–trudna · **Środowisko:** okolice kwiatów, otwarte przestrzenie

**Zachowanie:** lata, lekko falując, zbliża się do kota na mały dystans i szybko kłuje. Po ataku odsuwa się. W przeciwieństwie do wrony — krótki, szybki atak zamiast długiego nurkowania.

| Parametr | Wartość |
|---|---:|
| HP | 1 |
| Prędkość lotu / ataku | 60 / 140 px/s |
| Zasięg wykrywania | 80 px |
| Przygotowanie / cooldown | 0,3 s / 1,3 s |

**Animacje:** `idle`, `fly`, `approach`, `sting`, `hurt`, `death`.

---

# Porównanie

| Cecha | 🐶 Pies | 🐦 Wrona | 🐭 Szczur | 🐸 Żabol | 🐝 Osa |
|---|---|---|---|---|---|
| Typ | naziemny | powietrzny | naziemny | naziemny/woda | powietrzny |
| Ruch | bieg | lot | bieg, skok | skoki, pływanie | lot |
| Atak | gryzienie | nurkowanie | skok z gryzieniem | język | żądło |
| HP | 3 | 2 | 2 | 3 | 1 |
| Skok na głowę | nie | nie | **tak** | **tak** | nie |
| Główna trudność | pościg | atak z góry | nagły skok | zasięg języka | szybkie ukłucie |

---

# Struktura plików

```text
scenes/enemies/
├── enemy.gd            # wspólna baza: HP, trafienia, odrzut, śmierć, dotyk, skok na głowę, animacje
├── dog/   dog.tscn, dog.gd
├── crow/  crow.tscn, crow.gd
├── rat/   rat.tscn, rat.gd
├── frog/  frog.tscn, frog.gd
└── wasp/  wasp.tscn, wasp.gd
assets/game/enemies/
├── dog.png, crow.png, rat.png, frog.png, wasp.png   # paski klatek wycięte z assets/enemies.png
└── frames.json                                      # rozmiar klatki i zakresy animacji
```

# Kolejność implementacji
1. **Pies** + pasek HP kota — ustala wspólną bazę `enemy.gd`.
2. **Szczur** — skok w ataku, skok na głowę.
3. **Wrona** — pierwsza logika powietrzna.
4. **Osa** — szybki lot.
5. **Żabol** — skoki, pływanie, wydłużany hitbox języka.

# Rozmieszczenie w poziomie 1
- Pies na plaży przy dwóch drzewach (ucieczka na drzewo) i drugi przy drzewie za szybem.
- Żabol w basenie, wrona nad kamiennymi platformami, osa przy kwiatach / stole, szczur pod stołem.
