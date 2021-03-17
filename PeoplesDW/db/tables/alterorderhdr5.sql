--
-- $Id$
--
alter table orderhdr
add
(
staffhrs number(10,4),
QTY2SORT                                  NUMBER(7),
WEIGHT2SORT                               NUMBER(10,4),
CUBE2SORT                                 NUMBER(10,4),
AMT2SORT                                  NUMBER(10,2),
QTY2PACK                                  NUMBER(7),
WEIGHT2PACK                               NUMBER(10,4),
CUBE2PACK                                 NUMBER(10,4),
AMT2PACK                                  NUMBER(10,2),
QTY2CHECK                                 NUMBER(7),
WEIGHT2CHECK                              NUMBER(10,4),
CUBE2CHECK                                NUMBER(10,4),
AMT2CHECK                                 NUMBER(10,2)
);
exit;
