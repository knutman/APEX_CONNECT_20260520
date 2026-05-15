create or replace package PA_LOG is

  cDefaultProgramUnit constant varchar2(20) := 'anonymous block';
  
  procedure trace(pMsg varchar2, pProgramUnit varchar2 default cDefaultProgramUnit);
  procedure warning(pMsg varchar2, pProgramUnit varchar2 default cDefaultProgramUnit);
  procedure error(pMsg varchar2, pProgramUnit varchar2 default cDefaultProgramUnit);
  
  procedure trace(pMsg clob, pProgramUnit varchar2 default cDefaultProgramUnit);
  procedure warning(pMsg clob, pProgramUnit varchar2 default cDefaultProgramUnit);
  procedure error(pMsg clob, pProgramUnit varchar2 default cDefaultProgramUnit);
 
end;
/
create or replace package body PA_LOG is

  ----------------------------------------------------------------------------------------------------------------------
  procedure writeMessage(pMsg in varchar2, pMsgType in varchar2, pProgramUnit varchar2) is
    lMsg  log_tab.msg%type;
  begin
    DBMS_OUTPUT.put_line(substr(pMsg, 1, 4000));
    if pMsgType = 'error' THEN 
        DBMS_OUTPUT.put_line('-------FORMAT_ERROR_STACK--'); 
        DBMS_OUTPUT.put_line(DBMS_UTILITY.format_error_stack); 
        lMsg := substr(pMsg || CHR(13) || CHR(10) || DBMS_UTILITY.format_error_stack, 1, 32767);
        insert into LOG_TAB (MSG, LOG_LEVEL, PROGRAM_UNIT, SID, SESSIONID)
          values (lMsg, 
                  pMsgType, 
                  pProgramUnit,
                  sys_context('USERENV', 'SID'),
                  sys_context('USERENV', 'SESSIONID'));
    elsif pMsgType in ('warning', 'info', 'trace') THEN
      lMsg := substr(pMsg, 1, 32767);
      insert into LOG_TAB (MSG, LOG_LEVEL, PROGRAM_UNIT, SID, SESSIONID)
        values (lMsg, 
                pMsgType, 
                pProgramUnit,
                sys_context('USERENV', 'SID'),
                sys_context('USERENV', 'SESSIONID'));
    end if;
    commit; -- autonomous transaction!    
  end;

  ----------------------------------------------------------------------------------------------------------------------
  procedure error(pMsg varchar2, pProgramUnit varchar2 default cDefaultProgramUnit) is
    pragma autonomous_transaction;
  begin
    writeMessage(pMsg, 'error', pProgramUnit);
  end;
  
  ----------------------------------------------------------------------------------------------------------------------
  procedure error(pMsg clob, pProgramUnit varchar2 default cDefaultProgramUnit) is
    pragma autonomous_transaction;
  begin
    writeMessage(dbms_lob.substr(lob_loc => pMsg, amount => 30000, offset => 1), 'error', pProgramUnit);
  end;
  
  ----------------------------------------------------------------------------------------------------------------------
  procedure warning(pMsg varchar2, pProgramUnit varchar2 default cDefaultProgramUnit) is
    pragma autonomous_transaction;
  begin
    writeMessage(pMsg, 'warning', pProgramUnit);
  end;
  
  ----------------------------------------------------------------------------------------------------------------------
  procedure warning(pMsg clob, pProgramUnit varchar2 default cDefaultProgramUnit) is
    pragma autonomous_transaction;
  begin
    writeMessage(dbms_lob.substr(lob_loc => pMsg, amount => 30000, offset => 1), 'warning', pProgramUnit);
  end;
   
  ----------------------------------------------------------------------------------------------------------------------
  procedure trace(pMsg varchar2, pProgramUnit varchar2 default cDefaultProgramUnit) is
    pragma autonomous_transaction;
  begin
    writeMessage(pMsg, 'trace', pProgramUnit);
  end; 
  
  ----------------------------------------------------------------------------------------------------------------------
  procedure trace(pMsg clob, pProgramUnit varchar2 default cDefaultProgramUnit) is
    pragma autonomous_transaction;
  begin
    writeMessage(dbms_lob.substr(lob_loc => pMsg, amount => 30000, offset => 1), 'trace', pProgramUnit);
  end; 
begin
  null;
end;
/
