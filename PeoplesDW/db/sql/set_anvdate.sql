set serveroutput on
declare
errmsg varchar2(400);
action varchar2(400);
errno  integer;
warnno  integer;
rc integer;

cnt integer;

CURSOR C_LD(in_loadno number)
IS
  SELECT rcvddate
    FROM loads
   WHERE loadno = in_loadno;
LD C_LD%rowtype;

l_anvdate date;

begin

    dbms_output.enable(1000000);


    loop
        cnt := 0;
        for cp in (select rowid, lpid, loadno, creationdate
                     from plate
                    where type = 'PA'
                      and anvdate is null)
        loop

            if nvl(cp.loadno,0) = 0 then
                l_anvdate := trunc(nvl(cp.creationdate,sysdate));
            else
                LD := null;
                OPEN C_LD(cp.loadno);
                FETCH C_LD into LD;
                CLOSE C_LD;
                l_anvdate := trunc(nvl(LD.rcvddate,
                                       nvl(cp.creationdate,sysdate)));
        
            end if;

            update plate
               set anvdate = l_anvdate
             where rowid = cp.rowid;
            
            cnt := cnt + 1;
            
            exit when cnt > 1000;
        end loop;

        commit;

        exit when cnt = 0;
    end loop;
end;

/
