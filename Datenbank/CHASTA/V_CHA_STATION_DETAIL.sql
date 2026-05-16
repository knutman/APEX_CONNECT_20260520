create or replace view V_CHA_STATION_DETAIL as
select  ccs.cha_charging_station_id,
        ccs.cha_charging_station_ext_id,
        coalesce(ccs.operator_displayname, ccs.operator_companyname,
                 'Unbekannter Betreiber')                                       as operator_name,
        case when ccs.operator_displayname is not null
              and ccs.operator_companyname is not null
              and upper(ccs.operator_displayname) <> upper(ccs.operator_companyname)
             then ccs.operator_companyname
        end                                                                    as operator_secondary,
        ccs.status_operational,
        case ccs.status_operational
          when 'In Betrieb' then 'cha-popup__badge--ok'
          when 'In Wartung' then 'cha-popup__badge--warn'
          else                   'cha-popup__badge--unknown'
        end                                                                    as status_class,
        ccs.station_type,
        ccs.location_description,
        trim(ccs.street || ' ' || ccs.house_no)                                as street_line,
        ccs.address_addition,
        trim(ccs.postal_code || ' ' || ccs.city)                               as city_line,
        nullif(trim(ccs.district_independent_city || ', ' || ccs.state),
               ', ')                                                           as region_line,
        ccs.latitude,
        ccs.longitude,
        nvl(ccs.access_restriction, '—')                                       as access_restriction,
        nvl(to_char(ccs.go_live_date, 'DD.MM.YYYY'), '—')                      as go_live_date_fmt,
        nvl(ccs.opening_hours_specification, '—')                              as opening_hours_specification,
        nvl(to_char(ccs.max_electric_power_station_in_kw,
                    'FM999G990D0', 'NLS_NUMERIC_CHARACTERS=,.'),
            '—') || ' kW'                                                      as power_fmt,
        nvl(( select listagg(ps.value, ' · ') within group (order by ps.value)
                from json_table(ccs.payment_systems, '$[*]'
                       columns (value varchar2(100) path '$')) ps
            ), '—')                                                            as payment_systems_fmt,
        nvl(( select listagg(g.label, ' · ') within group (order by g.label)
                from ( select case when count(*) > 1 then count(*) || '× ' end
                                || c.connector_type
                                || ' / '
                                || to_char(c.power, 'FM999G990D0',
                                           'NLS_NUMERIC_CHARACTERS=,.')
                                || ' kW'                                       as label
                         from json_table(ccs.evse, '$[*]'
                                columns (
                                  nested path '$.connectors[*]' columns (
                                    connector_type varchar2(60) path '$.connector_type',
                                    power          number       path '$.max_electric_power_connector'
                                  )
                                )) c
                        where c.connector_type is not null
                        group by c.connector_type, c.power
                     ) g
            ), '—')                                                            as evse_fmt,
        to_char(coalesce(ccs.updated_dt, ccs.created_dt),
                'DD.MM.YYYY HH24:MI')                                          as stand_fmt
  from  cha_charging_station ccs;
