set serveroutput on
declare
errmsg varchar2(400);
action varchar2(400);
errno  integer;
warnno  integer;
rc integer;

ix integer;

l_offset integer;

err_flag BOOLEAN;

CURSOR C_DEF(in_name varchar2)
IS
SELECT *
  FROM impexp_definitions
 WHERE upper(name) = upper(in_name);

DEF impexp_definitions%rowtype;

CURSOR C_LINE(in_definc number, in_line varchar2)
IS
SELECT *
  FROM impexp_lines
 WHERE definc = in_definc
   AND upper(linealias) = upper(in_line);

LINE impexp_lines%rowtype;

CURSOR C_CHUNK(in_definc number, in_lineinc number, in_desc varchar2)
IS
SELECT *
  FROM impexp_chunks
 WHERE definc = in_definc
   AND lineinc = in_lineinc
   AND upper(description) = upper(in_desc);

CHK impexp_chunks%rowtype;

procedure find_chunk(in_name varchar2, in_line varchar2, in_chunk varchar2)
IS
BEGIN

-- Locate Def/line/chunk for delimiteroffset
    CHK := null;
    DEF := null;
    LINE := null;

    OPEN C_DEF(in_name);
    FETCH C_DEF into DEF;
    CLOSE C_DEF;
 
    if DEF.definc is null then
        err_flag := TRUE;
        errmsg := 'Invalid export name';
        return;
    end if;

    OPEN C_LINE(DEF.definc, in_line);
    FETCH C_LINE into LINE;
    CLOSE C_LINE;

    if LINE.lineinc is null then
        err_flag := TRUE;
        errmsg := 'Invalid line ID';
        return;
    end if;

    OPEN C_CHUNK(DEF.definc, LINE.lineinc, in_chunk);
    FETCH C_CHUNK into CHK;
    CLOSE C_CHUNK;

    if CHK.lineinc is null then
        err_flag := TRUE;
        errmsg := 'Invalid Chunk';
        return;
    end if;

END;

PROCEDURE adjust_offsets(CHK impexp_chunks%rowtype)
IS
BEGIN
-- Fix the offsets for the proc stuff
    l_offset := 0;

    for crec in (select *
                   from impexp_chunks
                  where definc = CHK.definc
                    and lineinc = CHK.lineinc
                  order by chunkinc)
    loop
        if nvl(crec.chunktype,0) not in (1,4,6) then
            update impexp_chunks
               set offset = l_offset
             where definc = CHK.definc
               and lineinc = CHK.lineinc
               and chunkinc = crec.chunkinc;

            l_offset := l_offset + nvl(crec.length,0);
        end if;
    end loop;

END;



begin

    dbms_output.enable(1000000);

    err_flag := FALSE;


-- Clone the current version of Format Defintion Export
    ix := 1;
    loop
        DEF := null;
        OPEN C_DEF('Format Definition Export Clone '||to_char(ix));
        FETCH C_DEF into DEF;
        CLOSE C_DEF;
        exit when DEF.definc is null;
        ix := ix + 1;
    end loop;

    zimp.clone_format('Format Definition Export',
        'Format Definition Export Clone '||to_char(ix),
        0,'ZTEST',errno,errmsg);

    if errno != 0 then
        err_flag := TRUE;
        errmsg := 'Clone Export:'||errmsg;
        goto end_of_the_world;
    end if;

-- Clone the current version of Format Defintion Import
    ix := 1;
    loop
        DEF := null;
        OPEN C_DEF('Format Definition Import Clone '||to_char(ix));
        FETCH C_DEF into DEF;
        CLOSE C_DEF;
        exit when DEF.definc is null;
        ix := ix + 1;
    end loop;

    zimp.clone_format('Format Definition Import',
        'Format Definition Import Clone '||to_char(ix),
        0,'ZTEST',errno,errmsg);

    if errno != 0 then
        err_flag := TRUE;
        errmsg := 'Clone Import:'||errmsg;
        goto end_of_the_world;
    end if;

-- Locate Def/line/chunk for delimiteroffset
    find_chunk('Format Definition Export', 'Line Format','delimiteroffset');
    if CHK.lineinc is null then
        err_flag := TRUE;
        errmsg := 'Find delimiteroffset:'||errmsg;
        goto end_of_the_world;
    end if;



    update impexp_chunks
       set mappings = '-999'
     where definc = CHK.definc
       and lineinc = CHK.lineinc
       and chunkinc = CHK.chunkinc;

-- Locate Def/line/chunk for paramname
    find_chunk('Format Definition Export', 'Chunk Format','paramname');
    if CHK.lineinc is null then
        err_flag := TRUE;
        errmsg := 'Find ExChunk paramname:'||errmsg;
        goto end_of_the_world;
    end if;


    update impexp_chunks
       set length = 35
     where definc = CHK.definc
       and lineinc = CHK.lineinc
       and chunkinc = CHK.chunkinc;

-- Locate Def/line/chunk for defvalue
    find_chunk('Format Definition Export', 'Chunk Format','defvalue');
    if CHK.lineinc is null then
        err_flag := TRUE;
        errmsg := 'Find ExChunk defvalue:'||errmsg;
        goto end_of_the_world;
    end if;


    update impexp_chunks
       set length = 255
     where definc = CHK.definc
       and lineinc = CHK.lineinc
       and chunkinc = CHK.chunkinc;


-- Fix the offsets for the proc stuff
    adjust_offsets(CHK);

-- Locate Def/line/chunk for paramname
    find_chunk('Format Definition Export', 'Proc Format','paramname');
    if CHK.lineinc is null then
        err_flag := TRUE;
        errmsg := 'Find ExProc paramname:'||errmsg;
        goto end_of_the_world;
    end if;


    update impexp_chunks
       set length = 35
     where definc = CHK.definc
       and lineinc = CHK.lineinc
       and chunkinc = CHK.chunkinc;



-- Fix the offsets for the proc stuff
    adjust_offsets(CHK);

-- Imports

-- Locate Def/line/chunk for paramname
    find_chunk('Format Definition Import', 'Chunk Format','paramname');
    if CHK.lineinc is null then
        err_flag := TRUE;
        errmsg := 'Find ImChunk paramname:'||errmsg;
        goto end_of_the_world;
    end if;


    update impexp_chunks
       set length = 35
     where definc = CHK.definc
       and lineinc = CHK.lineinc
       and chunkinc = CHK.chunkinc;

-- Locate Def/line/chunk for defvalue
    find_chunk('Format Definition Import', 'Chunk Format','defvalue');
    if CHK.lineinc is null then
        err_flag := TRUE;
        errmsg := 'Find ImChunk defvalue:'||errmsg;
        goto end_of_the_world;
    end if;


    update impexp_chunks
       set length = 255
     where definc = CHK.definc
       and lineinc = CHK.lineinc
       and chunkinc = CHK.chunkinc;


-- Fix the offsets for the proc stuff
    adjust_offsets(CHK);

-- Locate Def/line/chunk for paramname
    find_chunk('Format Definition Import', 'Proc Format','paramname');
    if CHK.lineinc is null then
        err_flag := TRUE;
        errmsg := 'Find ImProc paramname:'||errmsg;
        goto end_of_the_world;
    end if;


    update impexp_chunks
       set length = 35
     where definc = CHK.definc
       and lineinc = CHK.lineinc
       and chunkinc = CHK.chunkinc;

-- Fix the offsets for the proc stuff
    adjust_offsets(CHK);

<<end_of_the_world>>
    if err_flag then
        rollback;
        zut.prt('Failed:'||errmsg);
    else
        commit;
        zut.prt('Success!');
    end if;


end;

/

-- rollback;


