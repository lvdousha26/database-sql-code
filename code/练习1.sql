USE master;
GO
IF EXISTS(SELECT * FROM sys.procedures WHERE Proc_InitZyxtDB) DROP PROC Proc_InitZyxtDB;
GO
--存储过程：初始化库、基础表
CREATE PROC Proc_InitZyxtDB
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
ALTER DATABASE zyxt SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE IF EXISTS zyxt;
CREATE DATABASE zyxt;
USE zyxt;

--1.单位表
CREATE TABLE unit(
num CHAR(20) PRIMARY KEY,-- 单位代码，主键
name CHAR(20) NOT NULL UNIQUE-- 单位名称
);

--2.油水井表
CREATE TABLE well(
num CHAR(20) PRIMARY KEY,-- 井号，主键
type CHAR(20) CHECK(type IN('油井','水井')),-- 井别
unit_code CHAR(20) NOT NULL-- 所属单位代码，外键预留
);

--3.施工单位表
CREATE TABLE construct_unit(
name CHAR(20) PRIMARY KEY-- 施工单位名称，主键
);

--4.物码表
CREATE TABLE price(
code CHAR(20) PRIMARY KEY,-- 物资编码，主键
spec CHAR(20) NOT NULL UNIQUE,-- 物资名称/规格
unit_name CHAR(20) NOT NULL-- 计量单位
);

--5.成本主表
CREATE TABLE cost(
code CHAR(20) PRIMARY KEY,-- 费用编号/作业项目编号，主键
preunit CHAR(20) NOT NULL,-- 预算单位（采油队代码）
wellcode CHAR(20) NOT NULL,-- 井号（油水井编号）
premoney MONEY,-- 预算总金额
person CHAR(20),-- 预算编制人
predate DATE NOT NULL,-- 预算编制日期
startdate DATE,-- 工程开工日期
finish DATE,-- 工程完工日期
settleunit CHAR(20) NOT NULL,-- 施工/结算单位
content CHAR(20),-- 作业内容/施工内容

--内嵌4套材料字段，对应物码表
mat1_code CHAR(20),mat1_num INT CHECK(mat1_num >= 0),mat1_price MONEY CHECK(mat1_price >= 0),mat1_sub MONEY,
mat2_code CHAR(20),mat2_num INT CHECK(mat2_num >= 0),mat2_price MONEY CHECK(mat2_price >= 0),mat2_sub MONEY,
mat3_code CHAR(20),mat3_num INT CHECK(mat3_num >= 0),mat3_price MONEY CHECK(mat3_price >= 0),mat3_sub MONEY,
mat4_code CHAR(20),mat4_num INT CHECK(mat4_num >= 0),mat4_price MONEY CHECK(mat4_price >= 0),mat4_sub MONEY,

matcost MONEY CHECK(matcost >= 0),-- 材料总成本
humancost MONEY CHECK(humancost >= 0),-- 人工成本
equipcost MONEY CHECK(equipcost >= 0),-- 设备成本
othercost MONEY CHECK(othercost >= 0),-- 其他成本
settlecost MONEY CHECK(settlecost >= 0),-- 结算总金额
settleperson CHAR(20),-- 结算经办人
settledate DATE,-- 结算日期
finalcost MONEY NULL CHECK(finalcost >= 0),-- 入账/终审金额
finalperson CHAR(20) NULL,-- 入账/终审人
finaldate DATE NULL-- 入账/终审日期
);

COMMIT TRANSACTION;
PRINT '数据库与基础表创建完成，主键已设置';
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
PRINT '建库建表失败，事务回滚';
SELECT 错误编号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_InitZyxtDB;
USE zyxt;
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_AddAllFK) DROP PROC Proc_AddAllFK;
GO

CREATE PROC Proc_AddAllFK
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
--1.well 关联 unit 单位表
ALTER TABLE well
ADD CONSTRAINT fk_well_unit
FOREIGN KEY(unit_code) REFERENCES unit(num)
ON DELETE CASCADE  --删除单位，同步删除下属油水井
ON UPDATE CASCADE; --单位代码修改同步更新

--2.cost 预算单位关联 unit
ALTER TABLE cost
ADD CONSTRAINT fk_cost_preunit
FOREIGN KEY(preunit) REFERENCES unit(num)
ON DELETE RESTRICT --有作业不能删除对应单位
ON UPDATE CASCADE;

--3.cost 井号关联 well
ALTER TABLE cost
ADD CONSTRAINT fk_cost_well
FOREIGN KEY(wellcode) REFERENCES well(num)
ON DELETE RESTRICT
ON UPDATE CASCADE;

--4.cost 施工单位关联 construct_unit
ALTER TABLE cost
ADD CONSTRAINT fk_cost_construct
FOREIGN KEY(settleunit) REFERENCES construct_unit(name)
ON DELETE RESTRICT
ON UPDATE CASCADE;

--5.4套材料编码分别关联物码表price
ALTER TABLE cost
ADD CONSTRAINT fk_mat1_code FOREIGN KEY(mat1_code) REFERENCES price(code)
ON DELETE SET NULL,
CONSTRAINT fk_mat2_code FOREIGN KEY(mat2_code) REFERENCES price(code)
ON DELETE SET NULL,
CONSTRAINT fk_mat3_code FOREIGN KEY(mat3_code) REFERENCES price(code)
ON DELETE SET NULL,
CONSTRAINT fk_mat4_code FOREIGN KEY(mat4_code) REFERENCES price(code)
ON DELETE SET NULL;

COMMIT TRANSACTION;
PRINT '全部外键约束添加成功！';
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
PRINT '外键创建失败，事务回滚';
SELECT 错误编号=ERROR_NUMBER(),错误信息();
END CATCH
END
GO
--执行批量外键创建
EXEC Proc_AddAllFK;
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_InsertBaseData) DROP PROC Proc_InsertBaseData;
GO
--插入基础数据
CREATE PROC Proc_InsertBaseData
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
--单位
INSERT INTO unit 
VALUES 
('1122','采油厂'),
('112201','采油一矿'),
('112202','采油二矿'),
('112201001','采油一矿一队'),
('112201002','采油一矿二队'),
('112201003','采油一矿三队'),
('112202001','采油二矿一队'),
('112202002','采油二矿二队');

--油水井
INSERT INTO well 
VALUES 
('y001','油井','112201001'),
('y002','油井','112201001'),
('y003','油井','112201002'),
('y004','油井','112201002'),
('s001','油井','112201003'),
('s002','水井','112202001'),
('s003','水井','112202001'),
('y005','油井','112202002');

--施工单位
INSERT INTO construct_unit 
VALUES 
('作业公司作业一队'),
('作业公司作业二队'),
('作业公司作业三队');

--物码表
INSERT INTO price 
VALUES 
('wm001','材料一','吨'),
('wm002','材料二','米'),
('wm003','材料三','桶'),
('wm004','材料四','袋');

COMMIT TRANSACTION;
PRINT '基础数据插入完成，外键校验通过';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '基础数据插入失败';
SELECT 错误编号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_InsertBaseData;
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_InsertCostData) DROP PROC Proc_InsertCostData;
GO
--插入5条作业
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
PRINT '作业项目数据插入完成，外键校验通过';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '作业数据插入失败';
SELECT 错误编号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_InsertCostData;
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_UpdateDelTest) DROP PROC Proc_UpdateDelTest;
GO
--更新删除演示+事务回滚
CREATE PROC Proc_UpdateDelTest
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
UPDATE cost SET settlecost=settlecost+200,humancost=humancost+200 WHERE code='zy2018004';
SELECT '修改后记录' AS 结果,code,humancost,settlecost FROM cost WHERE code='zy2018004';
DELETE FROM cost WHERE settledate IS NOT NULL AND finalcost IS NULL;
SELECT '删除全部数据' AS 结果,* FROM cost;
ROLLBACK TRANSACTION;
SELECT '回滚恢复数据' AS 结果,* FROM cost;
PRINT '操作执行并回滚';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '更新删除操作异常';
SELECT 错误编号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_UpdateDelTest;
GO