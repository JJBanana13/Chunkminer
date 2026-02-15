# ChunkMine - ATM10 Mining Dimension

Basierend auf [Mastermine](https://github.com/merlinlikethewizard/Mastermine).
Umgeschrieben fuer **16 Turtles** die gemeinsam einen **Chunk** abbauen.

## Konzept

Ein 16x16 Chunk wird in **16 Quadranten** a 4x4 Bloecke aufgeteilt.
Jede Turtle bekommt einen Quadranten und grabt ihn komplett von oben nach unten durch.

```
  Chunk 16x16 Aufteilung:

   +----+----+----+----+
   | T1 | T2 | T3 | T4 |   z+0..3
   +----+----+----+----+
   | T5 | T6 | T7 | T8 |   z+4..7
   +----+----+----+----+
   | T9 |T10 |T11 |T12 |   z+8..11
   +----+----+----+----+
   |T13 |T14 |T15 |T16 |   z+12..15
   +----+----+----+----+
    x+0  x+4  x+8  x+12
```

## Wie es funktioniert

1. Hub waehlt einen Chunk (Spirale vom Eingang ausgehend)
2. **Alle 16 Turtles** bekommen je einen **4x4 Quadranten** im selben Chunk
3. Jede Turtle faehrt zu ihrem Quadranten und grabt ihn von `mine_y_top` bis `mine_y_bottom`
4. Serpentinen-Muster pro Schicht (4x4 Zickzack), grabt dabei oben + vorne
5. Wertlose Bloecke (Stein, Erde etc.) werden weggeworfen
6. Bei vollem Inventar oder niedrigem Fuel → zurueck zur Basis
7. Items abladen, tanken, zurueck zum Quadranten weitermachen
8. Wenn alle 16 Quadranten fertig → naechster Chunk

**16 Turtles = 16x schneller** als eine einzelne. Keine Kollisionen, da jede ihren eigenen 4x4 Bereich hat.

## Setup

Physische Aufstellung identisch zum [Original Mastermine](https://www.youtube.com/watch?v=2DTP1LXuiCg).
Du brauchst 16 Mining Turtles (+ optional 16 Chunky Turtles).

### Config anpassen (`hub_files/config.lua`)

```lua
-- Deine Koordinaten
mine_entrance = {x = 104, y = 76, z = 215}

-- Mining Dimension Y-Bereich
mine_y_top = 64
mine_y_bottom = 5

-- Chunky Turtles?
use_chunky_turtles = false
```

### Item-Filter

Bloecke in `skip_blocks` werden automatisch weggeworfen:
```lua
skip_blocks = {
    ['minecraft:stone'] = true,
    ['minecraft:cobblestone'] = true,
    ['minecraft:dirt'] = true,
    -- ...
}
```

## Befehle

- `on` / `go` - Mining starten
- `off` / `stop` - Mining stoppen
- `status` - Zeigt Chunk-Fortschritt + Quadrant-Zuweisung aller Turtles
- `return <#>` / `return *` - Turtle(s) zurueckholen
- `halt <#>` / `halt *` - Turtle(s) anhalten
- `reboot <#>` - Turtle neustarten
- `hubshutdown` / `hubreboot` - Hub steuern

## Weniger als 16 Turtles?

Funktioniert auch mit weniger! Jede Turtle bekommt einfach einen freien Quadranten.
Mit 4 Turtles dauert ein Chunk halt 4x laenger als mit 16.
Mehr als 16 bringt nichts, da es nur 16 Quadranten pro Chunk gibt.

## Benoetigte Mods

- **CC: Tweaked**
- **Advanced Peripherals** (optional, fuer Chunky Turtles)

## Lizenz

MIT (wie Original Mastermine)
