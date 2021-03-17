--
-- $Id$
--
create or replace type rategrouptype as object
(
    custid      varchar2(10),
    rategroup   varchar2(10),

    ORDER MEMBER FUNCTION 
        cmp_rgt(in_rgt IN rategrouptype) RETURN INTEGER,

    PRAGMA RESTRICT_REFERENCES (cmp_rgt, WNDS, WNPS, RNPS, RNDS)
);
/

create or replace type body rategrouptype as 
ORDER MEMBER FUNCTION 
cmp_rgt(in_rgt IN rategrouptype)
RETURN INTEGER
IS
BEGIN
    if custid is null then
        return -1;
    end if;
    if in_rgt.custid is null then
        return 1;
    end if;

    if custid < in_rgt.custid then
        return -1;
    elsif custid > in_rgt.custid then
        return 1;
    end if;

    if rategroup is null then
        return -1;
    end if;
    if in_rgt.rategroup is null then
        return 1;
    end if;

    if rategroup < in_rgt.rategroup then
        return -1;
    elsif rategroup > in_rgt.rategroup then 
        return 1;
    end if;

    return 0;

END cmp_rgt;
END;
/
exit;
