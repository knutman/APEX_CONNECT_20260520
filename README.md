# APEX_CONNECT_20260520

Begleitcode zum gleichnamigen Vortrag: Import des öffentlichen Ladesäulenregisters der Bundesnetzagentur in eine Oracle-26ai-Datenbank, anschließend visualisiert in einer APEX-Anwendung. Der Code ist als Demo gedacht und bewusst minimal gehalten.

## Welche Oracle-Features die Demo zeigt

- **SQL Domains** mit `annotations(...)` — sowohl für wiederverwendbare Audit-Spalten als auch für fachliche Enums.
- **Tabellen- und Spalten-Annotations** für ein selbstbeschreibendes Schema.
- **`SDO_GEOMETRY`** mit Spatial-Index für die Standortdaten.
- **JSON-Spalten** und `JSON_TABLE` zur Aufbereitung der REST-Antwort.
- **`APEX_WEB_SERVICE.make_rest_request`** direkt im `MERGE` über `JSON_TABLE` konsumiert — ohne Staging-Tabelle.
- **Autonomes Logging-Paket** (`pragma autonomous_transaction`).

## Inhalt

```
Datenbank/
├── SYSTEM/
│   ├── Role connect1.sql       -- Rollendefinition CONNECT1
│   └── User CHASTA.sql         -- Schema-User inkl. Quotas
└── CHASTA/
    ├── Table LOG_TAB.sql                  -- Logging-Tabelle inkl. Domain
    ├── Table CHA_CHARGING_STATION.sql     -- Faktentabelle inkl. Domains, Spatial-Index, Trigger
    ├── PA_LOG.pck                         -- Logging-API (autonome Transaktionen)
    └── PA_BNETZA.pck                      -- REST-Loader (BNetzA → Oracle)
```

## Installation

Reihenfolge ist wichtig — die späteren Skripte hängen von Domains und Tabellen aus den früheren ab.

1. **Als SYS / SYSTEM ausführen:**
   - `Datenbank/SYSTEM/Role connect1.sql`
   - `Datenbank/SYSTEM/User CHASTA.sql` — das Passwort steht als Platzhalter (`myPassword`) im Skript und ist vor produktiver Nutzung anzupassen.

2. **Als `CHASTA` verbinden und ausführen:**
   - `Datenbank/CHASTA/Table LOG_TAB.sql`
   - `Datenbank/CHASTA/Table CHA_CHARGING_STATION.sql`
   - `Datenbank/CHASTA/PA_LOG.pck`
   - `Datenbank/CHASTA/PA_BNETZA.pck`

Die Datenbank benötigt zusätzlich eine **Network ACL** für den BNetzA-Endpoint  
`https://ladesaeulenregister.bnetza.de/els/service/public/v1/chargepoints`,  
sodass `CHASTA` ausgehend auf diesen Host zugreifen kann.

## Loader ausführen

```sql
begin PA_BNETZA.updateChargingStations; end;
/
```

Der Aufruf holt den aktuellen Stand vom BNetzA-Endpoint, mergt ihn in `CHA_CHARGING_STATION` und löscht Zeilen, die im aktuellen Feed nicht mehr enthalten sind (erkannt anhand `nvl(updated_dt, created_dt) < sysdate`). Log-Einträge sind anschließend in `LOG_TAB`:

```sql
select * from LOG_TAB order by cur_time desc;
```

## Datenquelle

Öffentliches Ladesäulenregister der Bundesnetzagentur:  
<https://www.bundesnetzagentur.de/DE/Fachthemen/ElektrizitaetundGas/E-Mobilitaet/start.html>
