/* 2005,2008,2008R2,2012,2014,2016,2017 */
/*****************************************************************************************************
 * Script Information
 *----------------------------------------------------------------------------------------------------
 *		Author: Jason Carter
 *		  Date: 11/07/2016
 * Description: Resize Default Databases 
 *	   History: 08/15/2016 - Adapted to Auto-Install script
 *
 *****************************************************************************************************/

USE [master];


---- Adjust Default Database Options
IF NOT EXISTS(select * from sys.master_files where name='master' and size>=8192)
BEGIN
	ALTER DATABASE [master] MODIFY FILE (NAME = master, SIZE = 64MB, FILEGROWTH = 64MB)
	PRINT 'Master Database Sizes Set (Initial/Growth):  64MB / 64MB'
END

IF NOT EXISTS(select * from sys.master_files where name='mastlog' and size>=2048)
BEGIN	
	ALTER DATABASE [master] MODIFY FILE (NAME = mastlog, SIZE = 16MB, FILEGROWTH = 16MB)
	PRINT 'Master Database Log Sizes Set (Initial/Growth):  16MB / 16MB'
END

IF NOT EXISTS(Select * from sys.databases where name = N'model' and recovery_model=3)
BEGIN
	ALTER DATABASE [Model] SET RECOVERY SIMPLE
	PRINT 'Model Database Set to SIMPLE RECOVERY MODE'
END

IF NOT EXISTS(select * from sys.master_files where name='modeldev' and size>=16384)
BEGIN	
	ALTER DATABASE [Model] MODIFY FILE (NAME = 'modeldev', SIZE = 128MB, FILEGROWTH = 64MB)
	PRINT 'Model Database Sizes Set (Initial/Growth):  128MB / 64MB'
END

IF NOT EXISTS(select * from sys.master_files where name='modellog' and size>=4096)
BEGIN
	ALTER DATABASE [Model] MODIFY FILE (NAME = 'modellog', SIZE = 32MB, FILEGROWTH = 32MB)
	PRINT '[Model] Database Log Sizes Set (Initial/Growth):  32MB / 32MB'
END

IF NOT EXISTS(select * from sys.master_files where name='MSDBData' and size>=32768)
BEGIN
	ALTER DATABASE [MSDB] MODIFY FILE (NAME = 'MSDBData', SIZE = 256MB, FILEGROWTH = 64MB)
	PRINT '[MSDB] Database Sizes Set (Initial/Growth):  256MB / 64MB'
END

IF NOT EXISTS(select * from sys.master_files where name='MSDBLog' and size>=4096)
BEGIN
	ALTER DATABASE [MSDB] MODIFY FILE (NAME = 'MSDBLog', SIZE = 32MB, FILEGROWTH = 32MB)
	PRINT '[MSDB] Database Log Sizes Set (Initial/Growth):  32MB / 32MB'
END