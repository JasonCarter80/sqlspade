/* 2005,2008,2008R2 */

/*****************************************************************************************************
 * Script Information
 *----------------------------------------------------------------------------------------------------
 *		Author: Michael Wells
 *		  Date: 11/29/2010
 * Description: Run sp_configure to set the default configurations 
 *	   History: 11/29/2010 - Adapted to Auto-Install script
 *
 *****************************************************************************************************/

USE [master];

exec sp_configure 'show advanced options', 1;
RECONFIGURE;
exec sp_configure 'Agent', 1;
exec sp_configure 'Agent XPs', 1;
exec sp_configure 'remote admin connections', 1;
RECONFIGURE;