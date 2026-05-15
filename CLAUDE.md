# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Hinweis zur Sprache

Der Autor und das Zielpublikum sind deutschsprachig. Antworten, Erklärungen und Commit-Messages bitte auf Deutsch verfassen. Bezeichner, Kommentare und Enum-Literale im Code mischen bewusst Deutsch und Englisch (z. B. `InBetrieb`, `Normalladeeinrichtung`) — diese Mischung beibehalten und nicht als vermeintliche „Bereinigung" vereinheitlichen.

## Projektkontext

Begleitmaterial zu einem DOAG-Vortrag (Deutsche ORACLE-Anwendergruppe). Die Codebasis ist eine kleine Oracle-23ai-Demo, die das öffentliche Ladesäulenregister der Bundesnetzagentur in ein Oracle-Schema importiert und anschließend per Spatial- und JSON-Queries auswertet. Der Code dient der Veranschaulichung im Vortrag, nicht dem produktiven Einsatz — die Beispiele sind auf die Folien zugeschnitten, nicht auf Robustheit.

## Aufbau

- `Datenbank/SYSTEM/` — Setup mit SYSDBA-Rechten: legt die Rolle `CONNECT1` und den Schema-User `CHASTA` an. **Einmalig** als SYS/SYSTEM ausführen, bevor irgendetwas anderes läuft.
- `Datenbank/CHASTA/` — wird als Schema-Eigentümer `CHASTA` ausgeführt:
  - `Table LOG_TAB.sql` — Logging-Tabelle (hängt vom in derselben Datei definierten Domain `LOG_LEVEL_ENUM` ab).
  - `Table CHA_CHARGING_STATION.sql` — zentrale Faktentabelle; definiert wiederverwendbare Audit-Domains (`created_time_d`, `updated_time_d`, `updated_counter_d`, `deleted_time_d`) sowie die fachlichen Enums.
  - `PA_LOG.pck` — Logging-API (autonome Transaktionen; `trace`/`warning`/`error` sind jeweils für `varchar2` und `clob` überladen).
  - `PA_BNETZA.pck` — `updateChargingStations` führt einen MERGE des BNetzA-REST-Feeds in `CHA_CHARGING_STATION` aus und löscht anschließend Zeilen, deren `nvl(updated_dt, created_dt) < lSysdate` ist (also Zeilen, die der aktuelle Feed nicht angefasst hat — so wird „upstream entfernt" erkannt).

Installationsreihenfolge: `SYSTEM/Role connect1.sql` → `SYSTEM/User CHASTA.sql` → als CHASTA verbinden → `Table LOG_TAB.sql` → `Table CHA_CHARGING_STATION.sql` → `PA_LOG.pck` → `PA_BNETZA.pck`.

## Welche Oracle-Features die Demo zeigt

Diese 23ai-Features tragen die Demo — der Vortrag existiert, um sie zu zeigen. Bitte nicht zugunsten älterer Äquivalente wegrefaktorieren:

- **SQL Domains** (`create domain ... as ...`) mit `annotations(...)` für Metadaten wie Beschreibung und Sichtbarkeit. Verwendet sowohl für Audit-Spalten als auch für fachliche Enums (`CHA_OPERATIONAL_STATUS_ENUM`, `CHA_TYPE_OF_CHARGING_STATION_ENUM`, `CHA_OPENING_HOURS_ENUM`, `LOG_LEVEL_ENUM`).
- **Annotations auf Tabellen und Spalten** für ein selbstbeschreibendes Schema (`Description`, `Visibility 'ui_Hidden'`, `system_generated`).
- **`SDO_GEOMETRY`-Spalte** (`geo`) mit SRID 4326, befüllt aus Längen- und Breitengrad, registriert in `user_sdo_geom_metadata` und mit `mdsys.spatial_index_v2` indiziert. Das Muster `delete from user_sdo_geom_metadata` + `insert` in `Table CHA_CHARGING_STATION.sql:101-105` ist Voraussetzung dafür, dass der Spatial-Index angelegt werden kann.
- **`json`-Spalten** (`payment_systems`, `opening_days`, `evse`), die per `JSON_TABLE` aus einer REST-Antwort befüllt werden.
- **`APEX_WEB_SERVICE.make_rest_request`**, direkt im `MERGE` über `JSON_TABLE` konsumiert. Keine Staging-Tabelle.

## Konventionen

- Audit-Spalten werden ausschließlich über die geteilten Domains deklariert (`created_dt domain created_time_d` etc.). Der Trigger `tbu_CHA_CHARGING_STATION` (BEFORE UPDATE, FOR EACH ROW) pflegt `updated_dt` und inkrementiert `updated_counter`.
- PL/SQL-Pakete tragen das Präfix `PA_` (Package). In jeder Prozedur: `programUnit := $$PLSQL_UNIT || '.<procName>'` setzen, eine lokale Funktion `paras()` mit der Parametersignatur definieren, Ein- und Austritt per `PA_LOG.trace` loggen und im `when others`-Block nach `PA_LOG.error` re-raisen. Beim Hinzufügen neuer Prozeduren genauso vorgehen.
- Die Prozeduren in `PA_LOG` verwenden `pragma autonomous_transaction`, damit Log-Einträge ein Rollback im Aufrufer überleben. Das Pragma nicht entfernen.
- Quelldateinamen enthalten Leerzeichen (`Table CHA_CHARGING_STATION.sql`) — Pfade in Shell-Kommandos quoten. `.pck`-Dateien sind das kombinierte Spec+Body-Format von PL/SQL Developer und werden mit `/` abgeschlossen.

## Loader ausführen

`PA_BNETZA.updateChargingStations` wird in einer SQL-Session als `CHASTA` aufgerufen:

```sql
begin PA_BNETZA.updateChargingStations; end;
/
```

Die Prozedur ruft den Live-Endpoint der BNetzA auf (`https://ladesaeulenregister.bnetza.de/els/service/public/v1/chargepoints`). Die Datenbank braucht dafür Netzwerk-Egress sowie eine ACL, die `CHASTA` Zugriff auf diesen Host gewährt. Ergebnisse lassen sich in `LOG_TAB` per `order by cur_time desc` einsehen.
