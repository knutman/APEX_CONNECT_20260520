create or replace package PA_BNETZA is
  procedure updateChargingStations;
end;
/
create or replace package body PA_BNETZA is

  ----------------------------------------------------------------------------------------------------------------------
  procedure updateChargingStations is
    lSysdate    date := sysdate;
    lcUri       constant varchar2(200) := 'https://ladesaeulenregister.bnetza.de/els/service/public/v1/chargepoints';
    ----
    programUnit constant varchar2(200) := $$PLSQL_UNIT || '.updateChargingStations';
    function paras return varchar2 is begin
      return null;
    end;
  begin
    PA_LOG.TRACE(pMsg => 'start of ' || programUnit || '(' || paras() || ')', pProgramUnit => programUnit);
    
    APEX_WEB_SERVICE.set_request_headers(p_name_01 => 'Accept', p_value_01 => 'application/json');
    
    merge into cha_charging_station dst
      using ( select  res.CHA_CHARGING_STATION_ext_id, res.operator_companyname, res.operator_displayname, 
                      res.status_operational, res.station_type, res.location_description, res.street, res.house_no, 
                      res.address_addition, res.city, res.postal_code, res.district_independent_city, res.state, 
                      res.latitude, res.longitude, 
                      SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(res.longitude, res.latitude, NULL), NULL, NULL) geo, 
                      res.payment_systems, res.access_restriction, to_date(go_live_date, 'DD.MM.YYYY') go_live_date, 
                      res.opening_hours_specification, res.opening_days, res.max_electric_power_station, res.evses
                from json_table(
                       APEX_WEB_SERVICE.make_rest_request(p_url => lcUri, p_http_method => 'GET'),
                       '$.chargingStations[*]'
                       columns (
                         CHA_CHARGING_STATION_ext_id  number            path '$.id',
                         city                         varchar2          path '$.city',
                         district_independent_city    varchar2          path '$.district_independent_city',
                         postal_code                  varchar2          path '$.postal_code',
                         street                       varchar2          path '$.street',
                         house_no                     varchar2          path '$.house_no',
                         state                        varchar2          path '$.state',
                         address_addition             varchar2          path '$.address_addition',
                         location_description         varchar2          path '$.location_description',
                         station_type                 varchar2          path '$.type',
                         max_electric_power_station   number            path '$.max_electric_power_station',
                         go_live_date                 varchar2          path '$.go_live_date',
                         opening_hours_specification  varchar2          path '$.opening_hours_specification',
                         operator_companyname         varchar2          path '$.operator.companyName',
                         operator_displayname         varchar2          path '$.operator.displayName',
                         status_operational           varchar2          path '$.status.operational',
                         latitude                     number            path '$.coordinates.latitude',
                         longitude                    number            path '$.coordinates.longitude',
                         access_restriction           varchar2          path '$.access_restriction',
                         payment_systems              clob format json  path '$.payment_systems',
                         opening_days                 clob format json  path '$.opening_days',
                         evses                        clob format json  path '$.evses'
                       )
                     ) res
            ) src
      on (dst.cha_charging_station_ext_id = src.CHA_CHARGING_STATION_ext_id)
      when matched then update set
        --res.CHA_CHARGING_STATION_ext_id,
        dst.operator_companyname = src.operator_companyname,
        dst.operator_displayname = src.operator_displayname, 
        dst.status_operational = src.status_operational, 
        dst.station_type = src.station_type, 
        dst.location_description = src.location_description, 
        dst.street = src.street, 
        dst.house_no = src.house_no, 
        dst.address_addition = src.address_addition, 
        dst.city = src.city, 
        dst.postal_code = src.postal_code, 
        dst.district_independent_city = src.district_independent_city, 
        dst.state = src.state, 
        dst.latitude = src.latitude, 
        dst.longitude = src.longitude, 
        dst.geo = src.geo, 
        dst.payment_systems = src.payment_systems, 
        dst.access_restriction = src.access_restriction, 
        dst.go_live_date = src.go_live_date,
        dst.opening_hours_specification = src.opening_hours_specification, 
        dst.opening_days = src.opening_days, 
        dst.max_electric_power_station_in_kw = src.max_electric_power_station, 
        dst.evse = src.evses
      when not matched then insert set
        dst.CHA_CHARGING_STATION_ext_id = src.CHA_CHARGING_STATION_ext_id,
        dst.operator_companyname = src.operator_companyname,
        dst.operator_displayname = src.operator_displayname, 
        dst.status_operational = src.status_operational, 
        dst.station_type = src.station_type, 
        dst.location_description = src.location_description, 
        dst.street = src.street, 
        dst.house_no = src.house_no, 
        dst.address_addition = src.address_addition, 
        dst.city = src.city, 
        dst.postal_code = src.postal_code, 
        dst.district_independent_city = src.district_independent_city, 
        dst.state = src.state, 
        dst.latitude = src.latitude, 
        dst.longitude = src.longitude, 
        dst.geo = src.geo, 
        dst.payment_systems = src.payment_systems, 
        dst.access_restriction = src.access_restriction, 
        dst.go_live_date = src.go_live_date,
        dst.opening_hours_specification = src.opening_hours_specification, 
        dst.opening_days = src.opening_days, 
        dst.max_electric_power_station_in_kw = src.max_electric_power_station, 
        dst.evse = src.evses;
    
    PA_LOG.trace(pMsg => 'Merged ' || sql%rowcount || ' charging stations.', pProgramUnit => programUnit);
    delete from cha_charging_station ccs
      where nvl(ccs.updated_dt, ccs.created_dt) < lSysdate;
    PA_LOG.trace(pMsg => 'Deleted ' || sql%rowcount || ' old charging stations.', pProgramUnit => programUnit);
    PA_LOG.TRACE(pMsg => 'finished ' || programUnit || '(' || paras() || ')', pProgramUnit => programUnit);
  exception
    when others then
      PA_LOG.ERROR(pMsg => 'Error', pProgramUnit => programUnit || '(' || paras || ')');
      raise;
  end;
begin
  null;
end;
/
