-- ORDS für den Benutzer freischalten
begin
  ords.enable_schema(
    p_enabled             => true,
    p_schema              => 'CHASTA',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'chasta',
    p_auto_rest_auth      => false);
  commit;
end;
/

-- Modul "cha" anlegen + Tile- und Detail-Endpoint definieren.
-- Voraussetzung: ORDS.ENABLE_SCHEMA wurde fuer CHASTA bereits ausgefuehrt.
-- Resultierende URLs (relativ zur ORDS-Basis):
--   GET /ords/chasta/cha/tiles/{z}/{x}/{y}    -> Vector-Tile (MVT)
--   GET /ords/chasta/cha/stations/{id}        -> JSON mit Detaildaten

begin
  -- Modul (idempotent: erst loeschen, dann neu anlegen)
  begin
    ords.delete_module(p_module_name => 'cha');
  exception when others then null;
  end;

  ords.define_module(
    p_module_name    => 'cha',
    p_base_path      => 'cha/',
    p_items_per_page => 0);

  ----------------------------------------------------------------------------
  -- Tile-Endpoint
  ----------------------------------------------------------------------------
  ords.define_template(
    p_module_name => 'cha',
    p_pattern     => 'tiles/:z/:x/:y');

  ords.define_handler(
    p_module_name    => 'cha',
    p_pattern        => 'tiles/:z/:x/:y',
    p_method         => 'GET',
    p_source_type    => ords.source_type_plsql,
    p_source         => q'[
      declare
        l_tile blob;
      begin
        l_tile := PA_TILES.get_tile(
          p_zoom => to_number(:z),
          p_x    => to_number(:x),
          p_y    => to_number(:y));
        owa_util.mime_header('application/vnd.mapbox-vector-tile', false);
        htp.p('Cache-Control: public, max-age=3600');
        htp.p('Access-Control-Allow-Origin: *');
        owa_util.http_header_close;
        wpg_docload.download_file(l_tile);
      end;
    ]');

  ----------------------------------------------------------------------------
  -- Detail-Endpoint (JSON)
  ----------------------------------------------------------------------------
  ords.define_template(
    p_module_name => 'cha',
    p_pattern     => 'stations/:id');

  ords.define_handler(
    p_module_name => 'cha',
    p_pattern     => 'stations/:id',
    p_method      => 'GET',
    p_source_type => ords.source_type_collection_feed,
    p_source      => 'select * from v_cha_station_detail
                        where cha_charging_station_id = :id');

  commit;
end;
/
