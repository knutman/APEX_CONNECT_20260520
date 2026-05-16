create or replace package PA_TILES is
  function get_tile(p_zoom in number, p_x in number, p_y in number) return blob;
end;
/
create or replace package body PA_TILES is

  ----------------------------------------------------------------------------------------------------------------------
  function get_tile(p_zoom in number, p_x in number, p_y in number) return blob is
    l_tile      blob;
    programUnit constant varchar2(200) := $$PLSQL_UNIT || '.get_tile';
    function paras return varchar2 is begin
      return 'z=' || p_zoom || ', x=' || p_x || ', y=' || p_y;
    end;
  begin
    PA_LOG.trace(pMsg => 'start of ' || programUnit || '(' || paras() || ')', pProgramUnit => programUnit);

    l_tile := MDSYS.SDO_UTIL.GET_VECTORTILE(
      table_name    => 'CHA_CHARGING_STATION',
      geom_col_name => 'GEO',
      tile_x        => p_x,
      tile_y        => p_y,
      tile_zoom     => p_zoom,
      att_col_names => MDSYS.SDO_STRING_ARRAY(
                         'CHA_CHARGING_STATION_ID',
                         'STATION_TYPE',
                         'OPERATOR_DISPLAYNAME'),
      layer_name    => 'charging_stations',
      google_ts     => true
    );

    PA_LOG.trace(pMsg => 'finished ' || programUnit || '(' || paras() || ')', pProgramUnit => programUnit);
    return l_tile;
  exception
    when others then
      PA_LOG.error(pMsg => 'Error', pProgramUnit => programUnit || '(' || paras() || ')');
      raise;
  end;

begin
  null;
end;
/
