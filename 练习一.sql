USE master;
GO
IF EXISTS(SELECT * FROM sys.procedures WHERE name='Proc_InitZyxtDB') DROP PROC Proc_InitZyxtDB;
GO

CREATE PROC Proc_InitZyxtDB
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
ALTER DATABASE zyxt SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE IF EXISTS zyxt;
CREATE DATABASE zyxt;
USE zyxt;

-- 成本主表
CREATE TABLE cost(
code CHAR(20) PRIMARY KEY,-- 费用编号/作业项目编号，主键
preunit CHAR(20),-- 预算单位（采油队代码）
wellcode CHAR(20),-- 井号（油水井编号）
premoney MONEY,-- 预算总金额
person CHAR(20),-- 预算编制人
predate DATE,-- 预算编制日期
startdate DATE,-- 工程开工日期
finish DATE,-- 工程完工日期
settleunit CHAR(20),-- 施工/结算单位
content CHAR(20),-- 作业内容/施工内容
mat1_code CHAR(20),mat1_num INT,mat1_price MONEY,mat1_sub MONEY,
mat2_code CHAR(20),mat2_num INT,mat2_price MONEY,mat2_sub MONEY,
mat3_code CHAR(20),mat3_num INT,mat3_price MONEY,mat3_sub MONEY,
mat4_code CHAR(20),mat4_num INT,mat4_price MONEY,mat4_sub MONEY,
matcost MONEY,-- 材料总成本
humancost MONEY,-- 人工成本
equipcost MONEY,-- 设备成本
othercost MONEY,-- 其他成本
settlecost MONEY,-- 结算总金额
settleperson CHAR(20),-- 结算经办人
settledate DATE,-- 结算日期
finalcost MONEY,-- 入账/终审金额
finalperson CHAR(20),-- 入账/终审人
finaldate DATE-- 入账/终审日期
)
GO
CREATE TABLE unit(
num CHAR(20) PRIMARY KEY,-- 单位代码，主键
name CHAR(20)-- 单位名称
)
CREATE TABLE well(
num CHAR(20) PRIMARY KEY,-- 井号，主键
type CHAR(20),-- 井别（油井/水井）
code CHAR(20)  -- 所属单位代码
)
CREATE TABLE construct_unit(
name CHAR(20) PRIMARY KEY-- 施工单位名称，主键
)
CREATE TABLE price(
code CHAR(20) PRIMARY KEY,-- 物资编码，主键
num CHAR(20),-- 物资名称/规格
name CHAR(20)-- 计量单位
)
COMMIT TRANSACTION;
PRINT '数据库与基础表初始化成功';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '建库建表失败，已回滚';
SELECT 错误号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
-- 执行初始化存储过程
EXEC Proc_InitZyxtDB;
USE zyxt;
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name='Proc_InsertBaseData') DROP PROC Proc_InsertBaseData;
GO

CREATE PROC Proc_InsertBaseData
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
-- 单位表
INSERT INTO unit 
VALUES 
('1122','采油厂'),('112201','采油一矿'),('112202','采油二矿'),
('112201001','采油一矿一队'),('112201002','采油一矿二队'),('112201003','采油一矿三队'),
('112202001','采油二矿一队'),('112202002','采油二矿二队');
-- 油水井
INSERT INTO well 
VALUES 
('y001','油井','112201001'),('y002','油井','112201001'),('y003','油井','112201002'),
('y004','油井','112201002'),('s001','油井','112201003'),('s002','水井','112202001'),
('s003','水井','112202001'),('y005','油井','112202002');
-- 施工单位
INSERT INTO construct_unit 
VALUES ('作业公司作业一队'),('作业公司作业二队'),('作业公司作业三队');
-- 物码
INSERT INTO price 
VALUES ('wm001','材料一','吨'),('wm002','材料二','米'),('wm003','材料三','桶'),('wm004','材料四','袋');
COMMIT TRANSACTION;
PRINT '基础数据插入完成';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '基础数据插入失败';
SELECT 错误号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_InsertBaseData;
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name='Proc_InsertCostData') DROP PROC Proc_InsertCostData;
GO

CREATE PROC Proc_InsertCostData
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
INSERT INTO cost 
VALUES
('zy2018001','112201001','y001',10000.00,'张三','2018-05-01','2018-05-04','2018-05-25','作业公司作业一队','堵漏',
'wm001',200,10,2000.00,'wm002',200,10,2000.00,'wm003',200,10,2000.00,'wm004',100,10,1000.00,
7000.00,2500.00,1000.00,1400.00,11900.00,'李四','2018-05-26',11900.00,'王五','2018-05-28'),
('zy2018002','112201002','y003',11000.00,'张三','2018-05-01','2018-05-04','2018-05-23','作业公司作业二队','检泵',
'wm001',200,10,2000.00,'wm002',200,10,2000.00,'wm003',200,10,2000.00,NULL,0,0,0,
6000.00,1500.00,1000.00,2400.00,10900.00,'李四','2018-05-26',10900.00,'王五','2018-05-28'),
('zy2018003','112201002','s001',10500.00,'张三','2018-05-01','2018-05-06','2018-05-23','作业公司作业二队','调剖',
'wm001',200,10,2000.00,'wm002',200,10,2000.00,'wm003',250,10,2500.00,NULL,0,0,0,
6500.00,2000.00,500.00,1400.00,10400.00,'李四','2018-05-26',10400.00,'王五','2018-05-28'),
('zy2018004','112202001','s002',12000.00,'张三','2018-05-01','2018-05-04','2018-05-24','作业公司作业三队','解堵',
'wm001',200,10,2000.00,'wm002',200,10,2000.00,NULL,0,0,0,'wm004',200,10,2000.00,
6000.00,2000.00,1000.00,1600.00,10600.00,'李四','2018-05-26',10600.00,'王五','2018-05-28');

INSERT INTO cost (code,preunit,wellcode,premoney,person,predate,startdate,finish,settleunit,content,
mat1_code,mat1_num,mat1_price,mat1_sub,mat2_code,mat2_num,mat2_price,mat2_sub,mat3_code,mat3_num,mat3_price,mat3_sub,mat4_code,mat4_num,mat4_price,mat4_sub,
matcost,humancost,equipcost,othercost,settlecost,settleperson,settledate)
VALUES
('zy2018005','112202002','y005',12000.00,'张三','2018-05-01','2018-05-04','2018-05-28','作业公司作业三队','防砂',
'wm001',200,10,2000.00,'wm002',200,10,2000.00,NULL,0,0,0,'wm004',300,10,3000.00,
7000.00,1000.00,2000.00,1300.00,11300.00,'李四','2018-06-01');
COMMIT TRANSACTION;
PRINT '作业项目数据插入完成';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '作业数据插入失败';
SELECT 错误号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_InsertCostData;
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name='Proc_UpdateDelTest') DROP PROC Proc_UpdateDelTest;
GO

CREATE PROC Proc_UpdateDelTest
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
-- (1)zy2018004人工费、结算金额+200
UPDATE cost SET settlecost=settlecost+200,humancost=humancost+200 WHERE code='zy2018004';
SELECT '修改后zy2018004' AS 提示,code,humancost,settlecost FROM cost WHERE code='zy2018004';
-- (2)删除已结算未入账
DELETE FROM cost WHERE settledate IS NOT NULL AND finalcost IS NULL;
SELECT '删除后全部数据' AS 提示,* FROM cost;
-- 手动回滚，模拟撤销
ROLLBACK TRANSACTION;
SELECT '回滚后数据' AS 提示,* FROM cost;
PRINT '操作已执行并回滚，数据恢复';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '更新删除操作出错';
SELECT 错误号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_UpdateDelTest;
GO