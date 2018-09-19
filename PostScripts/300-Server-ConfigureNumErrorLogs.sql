/* 2005,2008,2008R2,2012,2014,2016,2017 */

/*****************************************************************************************************
 * Script Information
 *----------------------------------------------------------------------------------------------------
 * Description: Set the number of error logs to cycle
 *****************************************************************************************************/
 
USE [master];

EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 30;