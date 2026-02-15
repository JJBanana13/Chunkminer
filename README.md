# ChunkMine - ATM10 Mining Dimension

Basierend auf [Mastermine](https://github.com/merlinlikethewizard/Mastermine) von merlinlikethewizard.
Umgeschrieben fuer **16 Turtles** die gemeinsam einen **Chunk** in der Mining Dimension abbauen.

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

Keine Kollisionen, da jede Turtle ihren eigenen Bereich hat.
Funktioniert auch mit weniger als 16 Turtles - freie Quadranten werden einfach spaeter abgebaut.

## Installation

### Voraussetzungen

- **CC: Tweaked** (HTTP muss aktiviert sein)
- **Advanced Peripherals** (optional, fuer Chunky Turtles)
- Physische Aufstellung wie beim [Original Mastermine](https://www.youtube.com/watch?v=2DTP1LXuiCg)

### 1. Installer herunterladen

Am **Hub-Computer** (Advanced Computer neben Disk Drive mit Floppy):

```
wget https://raw.githubusercontent.com/JJBanana13/Chunkminer/main/install.lua install.lua
install.lua disk
```

### 2. Config anpassen

```
edit disk/hub_files/config.lua
```

Aendere mindestens:
```lua
mine_entrance = {x = DEIN_X, y = DEIN_Y, z = DEIN_Z}
```

Das Y ist 1 Block **ueber** dem Boden (gleiche Hoehe wie der Disk Drive).

Optional anpassen:
```lua
mine_y_top = 64       -- Oberste Schicht
mine_y_bottom = 5     -- Unterste Schicht (ueber Bedrock)
use_chunky_turtles = false  -- true wenn du Chunk Loader Turtles nutzt
```

### 3. Hub starten

```
disk/hub.lua
```

### 4. Turtles registrieren

Jede Mining Turtle neben den Disk Drive stellen, dann in der Turtle:

```
disk/turtle.lua <HUB_ID>
```

Die Hub-ID steht auf dem Hub-Computer (oder `id` eingeben).
Das fuer alle 16 Turtles wiederholen.

### 5. Mining starten

Am Hub-Computer:

```
on
```

## Update

Um auf die neueste Version zu updaten:

```
wget https://raw.githubusercontent.com/JJBanana13/Chunkminer/main/install.lua install.lua
install.lua disk
```

**Achtung:** Das ueberschreibt auch die `config.lua`! Sichere deine Koordinaten vorher oder passe sie danach neu an.

## Befehle

| Befehl | Beschreibung |
|--------|-------------|
| `on` / `go` | Mining starten |
| `off` / `stop` | Mining stoppen |
| `status` | Chunk-Fortschritt + Quadrant-Zuweisung anzeigen |
| `return <#>` | Turtle zurueckholen (`*` fuer alle) |
| `halt <#>` | Turtle anhalten (`*` fuer alle) |
| `reboot <#>` | Turtle neustarten |
| `reset <#>` | Turtle-Status zuruecksetzen |
| `clear <#>` | Turtle-Aufgaben loeschen |
| `hubshutdown` | Hub herunterfahren |
| `hubreboot` | Hub neustarten |

## Wie es funktioniert

1. Hub waehlt einen Chunk (Spirale vom Eingang ausgehend)
2. Alle Turtles bekommen je einen **4x4 Quadranten** im selben Chunk
3. Jede Turtle faehrt zu ihrem Quadranten und grabt Schicht fuer Schicht
4. Serpentinen-Muster (Zickzack), grabt aktuelles Level + darueber
5. Wertlose Bloecke (Stein, Erde etc.) werden automatisch weggeworfen
6. Bei vollem Inventar oder niedrigem Fuel → zurueck zur Basis
7. Items abladen, tanken, zurueck zum Quadranten weitermachen
8. Wenn alle Quadranten fertig → naechster Chunk

## Item-Filter

In der Config kannst du einstellen welche Bloecke weggeworfen werden:

```lua
skip_blocks = {
    ['minecraft:stone'] = true,
    ['minecraft:cobblestone'] = true,
    ['minecraft:dirt'] = true,
    ['minecraft:gravel'] = true,
    ['minecraft:deepslate'] = true,
    -- Weitere Bloecke hier hinzufuegen
}

filter_items = true  -- false = alles behalten
```

## Troubleshooting

- **wget geht nicht:** In `config/computercraft-server.toml` pruefen ob HTTP aktiviert ist
- **Turtles bewegen sich nicht:** GPS pruefen, `gps locate` muss funktionieren
- **Turtles finden nicht nach Hause:** Control Room Area in der Config vergroessern
- **Falscher Chunk wird abgebaut:** `mine_entrance` Koordinaten pruefen

## Benoetigte Mods

- [CC: Tweaked](https://www.curseforge.com/minecraft/mc-mods/cc-tweaked)
- [Advanced Peripherals](https://www.curseforge.com/minecraft/mc-mods/advanced-peripherals) (optional)

## Credits

Basiert auf [Mastermine](https://github.com/merlinlikethewizard/Mastermine) von [merlinlikethewizard](https://github.com/merlinlikethewizard).

## Lizenz

MIT
