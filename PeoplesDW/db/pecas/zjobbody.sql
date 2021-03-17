create or replace package body zjob as
--
-- $Id$
--
----------------------------------------------------------------------
--
-- run_pecas - run the pecas interface job
--
----------------------------------------------------------------------
PROCEDURE run_pecas
IS
BEGIN
    zpecas.process_input;
END run_pecas;

END zjob;
/
exit;
