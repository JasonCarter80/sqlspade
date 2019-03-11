/* 2005,2008,2008R2,2012,2014,2016,2017 */

/*****************************************************************************************************
 * Script Information
 *----------------------------------------------------------------------------------------------------
 * Description: Rename & disable built-in sa account
 *****************************************************************************************************/

 /*rename sa*/
if exists
(
    select name
         , sid
    from sys.server_principals as sp
    where sid = 0x01
          and name = 'sa'
)
begin
    alter login [sa] with name = [usa];
end;
/*and disable the account*/
if exists
(
    select name
         , sid, *
    from sys.server_principals as sp
    where sid = 0x01 and sp.is_disabled=0          
)
begin
    alter login [usa] disable
end