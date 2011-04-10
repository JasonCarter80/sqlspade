/* 2005,2008,2008R2 */

/*****************************************************************************************************
 * Script Information
 *----------------------------------------------------------------------------------------------------
 *		Author: Michael Wells
 *		  Date: 11/29/2010
 * Description: Configure Database Mail and create a default profile 
 *	   History: 11/29/2010 - Adapted to Auto-Install script
 *
 *****************************************************************************************************/

USE [master];

-- Enable Database Mail for this instance
EXECUTE sp_configure 'show advanced', 1;
RECONFIGURE;
EXECUTE sp_configure 'Database Mail XPs',1;
RECONFIGURE;
EXECUTE sp_configure 'Agent XPs', 1;
RECONFIGURE;

declare @servername varchar(40), @email varchar(50)

select	@servername = 'SQLMAIL_' + convert(varchar, serverproperty('machinename'))

select @email = @servername + '@alfki.com'

-- Create a Database Mail account
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'Primary Account',
    @description = 'Account used by all mail profiles.',
    @email_address = @email,
    @replyto_address = 'IT-DBA@alfki.com',
    @display_name = @servername,
    @mailserver_name = 'mailrelay.alfki.com';
 
-- Create a Database Mail profile
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = @servername,
    @description = 'Default public profile for all users';
 
-- Add the account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = @servername,
    @account_name = 'Primary Account',
    @sequence_number = 1;
 
-- Grant access to the profile to all msdb database users
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = @servername,
    @principal_name = 'public',
    @is_default = 1;

--EXECUTE msdb.dbo.sysmail_configure_sp
--    'LoggingLevel', '1' ;