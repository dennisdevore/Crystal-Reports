create or replace TRIGGER "D2KTMS"."TMS_AU" 

before update of pu_appt,mbid
on tms
for each row
declare

begin
    begin
    update alps.orderhdr
       set shipdate = :new.pu_appt,
           transapptdate = :new.pu_appt,
           hdrpassthruchar01 = to_char(:new.mbid),
           lastuser = 'TMS',
           lastupdate = sysdate
     where orderid = :new.orderid
       and shipid = :new.shipid;
    exception when others then
      null;
    end;
end;
/