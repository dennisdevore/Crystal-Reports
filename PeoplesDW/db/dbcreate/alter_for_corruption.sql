/*
*  This is a script Burleson ran when an instance was corrupt (hence no
*  export could be performed).  The alter doesn't fix the corruption, but
*  it does allow an export of the data to be created.
*/
alter system set EVENTS '10231 trace name context forever, level 10';