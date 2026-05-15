create user CHASTA
  default tablespace users
  temporary tablespace TEMP
  profile DEFAULT
  identified by "myPassword";

--grant execute on C##CLOUD$SERVICE.DBMS_CLOUD$PDBCS_250919_0 to CHASTA;
grant connect1 to CHASTA;
grant select_catalog_role to CHASTA;
alter user CHASTA
  quota unlimited on users;
grant connect to chasta;

