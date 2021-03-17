set serveroutput on
declare

errmsg varchar2(400);

cnt integer;
cnt_done integer;
cnt_loop integer;

last_wave number;


begin

    dbms_output.enable(1000000);

    cnt := 0;
    cnt_done := 0;
    last_wave := 0;


    loop
    
        cnt_loop := 0;
        for crec in (select distinct wave
                       from orderhdr
                      where ordertype = 'W'
                        and orderstatus in ('6','X')
                        and wave is not null
                        and wave > last_wave
                        order by wave)
        loop
            cnt := cnt + 1;
            cnt_loop := cnt_loop + 1;

            zkit.complete_kit_wave(crec.wave,'KITWVCHK',errmsg);
        
            if errmsg = 'OKAY' then
                cnt_done := cnt_done + 1;
            end if;

            last_wave := crec.wave;

            exit when cnt_loop >= 100;
        end loop;

        commit;
        zut.prt('Checked:'||cnt||'/'||cnt_loop);

        exit when cnt_loop < 100;

    end loop;

    zut.prt('Waves checked:'||cnt||' waves completed:'||cnt_done);
    rollback;

end;

/



