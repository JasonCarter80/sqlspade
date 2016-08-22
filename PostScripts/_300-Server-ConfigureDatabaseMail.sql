/* 2005,2008,2008R2,2012,2014,2016 */

/*****************************************************************************************************
 * Auto-Install Script Template
 *----------------------------------------------------------------------------------------------------
 *
 * Instructions:
 * The top line of this document must contain a commented comma seperated list of the versions of SQL 
 * that this script applies to.  Example: "/* 2000,2005,2008,2008R2 */"
 * 
 * This script template is only suitable for statements that are to be executed as part of the 
 * auto-install process and must run only against the server instance being installed.
 *
 * The script must terminate each statement using the ";" operator and the keyword 
 * "GO" must be enclosed in square brackets [].
 *
 * This template does not support scripts that need to be called with parameters.  If your script 
 * requires parameters please use the PowerShell Script template.
 *
 * Scripts must be named using the following pattern:
 * level-level name-script name
 *
 * level: The numeric level of the script.  This controls the order in which scripts are applied to
 *		  ensure that dependancies are not broken.  See Level list for the possible values.
 *
 * level name: The friendly name of the level.  This is meant to makes the scripts more easily
 *			   identifiable.  See Level list for the possible values.
 *
 * script name: The friendly name of the script.  This should be short, but detailed enought to tell
 *				what the script will accomplish.
 *
 * Example: "300-Server-AddExtendedProperty.sql" - Server level script that adds the DBA Extended
 *			property to the master and model databases
 *
 * Level List:
 * ---------------
 * 300 - Server - Scripts that create/alter/drop server level objects and settings
 * 400 - Database - Scripts that create/alter/drop databases and settings
 * 500 - Table - Scripts that create/alter/drop tables, schemas, users, roles
 * 600 - View - Scripts that create/alter/drop views, indexes, or other objects with table dependancies
 * 700 - Procedure - Scripts that create/alter/drop objects with table/view dependancies
 * 800 - Agent - Scripts that create/alter/drop agent jobs, job steps, job schedules, notifications, etc
 * 900 - Management - Scripts that are used for management operations
 *****************************************************************************************************/

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