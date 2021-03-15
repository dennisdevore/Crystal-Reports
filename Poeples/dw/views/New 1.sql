   SELECT c.abbrev                              AS revtype,
          c.descr                               AS revtypedescr,
          d.abbrev                              AS revsubtype,
          d.descr                               AS revsubtypedescr,
          invoice,
          facility,
          custid,
          invdate,
          activity,
          billedqty,
          billedamt,
          revenuegroup,
          zdtc.firstOfMonth (invdate)           AS firstofmonth,
          zdtc.firstOfWeekSunToSat (invdate)    AS firstOfWeek,
          1                                     AS truelink
     FROM aprbldinvdtlview     a,
          activity             b,
          revenuereportgroups  c,
          invoicetypes         d
    WHERE     a.activity = b.code
          AND invtype = 'A'
          AND invtype = d.code
          AND b.revenuegroup(+) = c.code
--          AND b.revenuegroup IN (SELECT code
--                                   FROM revenurptbackoutview
--                                  WHERE invtype = 'A')
                                  and invoice = 3818386
