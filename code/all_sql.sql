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
-- ===== 练习二.sql =====

USE zyxt;
GO
IF EXISTS(SELECT * FROM sys.procedures WHERE name='Proc_CreateDropIndex') DROP PROC Proc_CreateDropIndex;
GO
-- 存储过程：创建/删除索引CREATE PROC Proc_CreateDropIndex @operate VARCHAR(10)
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
IF @operate='create'
BEGIN
CREATE INDEX index1 ON cost (predate);
CREATE INDEX index2 ON cost (startdate);
CREATE INDEX index3 ON cost (settledate);
PRINT '索引创建成功';
END
IF @operate='drop'
BEGIN
DROP INDEX index1 ON cost;
DROP INDEX index2 ON cost;
DROP INDEX index3 ON cost;
PRINT '索引删除成功';
END
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '索引操作失败';
SELECT 错误号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
-- 创建索引
EXEC Proc_CreateDropIndex 'create';
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name='Proc_QueryAllTask') DROP PROC Proc_QueryAllTask;
GO
-- 存储过程：封装实验全部16条查询
CREATE PROC Proc_QueryAllTask
AS
BEGIN
--1采油一矿二队预算
SELECT '1.一矿二队预算项目' AS 查询结果,* FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND predate BETWEEN '2018-05-01' AND '2018-05-28';
--2已结算
SELECT '2.一矿二队结算项目' AS 查询结果,* FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND settledate BETWEEN '2018-05-01' AND '2018-05-28';
--3材料明细
SELECT '3.材料消耗明细' AS 查询结果,code,mat1_code,mat1_sub,mat2_code,mat2_sub,mat3_code,mat3_sub,mat4_code,mat4_sub FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND settledate BETWEEN '2018-05-01' AND '2018-05-28';
--4已入账
SELECT '4.已入账项目' AS 查询结果,* FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND finaldate BETWEEN '2018-05-01' AND '2018-05-28';
--5总预算
SELECT '5.一矿二队总预算' AS 查询结果,SUM(premoney) 总预算 FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队')
AND predate BETWEEN '2018-05-01' AND '2018-05-28';
--6总结算
SELECT '6.一矿二队总结算' AS 查询结果,SUM(settlecost) 总结算 FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND settledate BETWEEN '2018-05-01' AND '2018-05-28';
--7总入账
SELECT '7.一矿二队总入账' AS 查询结果,SUM(finalcost) 总入账 FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND finaldate BETWEEN '2018-05-01' AND '2018-05-28';
--8采油一矿总入账
SELECT '8.采油一矿总入账' AS 查询结果,SUM(finalcost) 一矿总入账 FROM cost 
WHERE preunit LIKE '112201%' 
AND finaldate BETWEEN '2018-05-01' AND '2018-05-28';
--9入账人员
SELECT '9.入账操作人员' AS 查询结果,DISTINCT finalperson FROM cost;
--10已结算未入账
SELECT '10.已结算未入账' AS 查询结果,* FROM cost 
WHERE settledate BETWEEN '2018-05-01' AND '2018-05-28' AND finalcost IS NULL;
--11按入账降序
SELECT '11.一矿二队按入账降序' AS 查询结果,* FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
ORDER BY finalcost DESC;
--12各施工单位结算汇总
SELECT '12.各施工单位结算汇总' AS 查询结果,settleunit,SUM(settlecost) 单位总结算 FROM cost GROUP BY settleunit;
--13材料三超2000
SELECT '13.材料三消耗超2000项目' AS 查询结果,code,mat3_code,mat3_sub FROM cost WHERE mat3_sub > 2000;
--14作业二队
SELECT '14.作业二队项目' AS 查询结果,* FROM cost WHERE settleunit = '作业公司作业二队';
--15一队+二队UNION
SELECT '15.一二队合并项目' AS 查询结果,* FROM cost WHERE settleunit = '作业公司作业二队' 
UNION SELECT * FROM cost WHERE settleunit = '作业公司作业一队';
--16一矿施工队伍
SELECT '16.采油一矿施工单位' AS 查询结果,DISTINCT settleunit FROM cost WHERE preunit LIKE '112201%';
END
GO
EXEC Proc_QueryAllTask;
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name='Proc_SumTableOper') DROP PROC Proc_SumTableOper;
GO
-- 存储过程：创建汇总表、插入、修改删除事务
CREATE PROC Proc_SumTableOper
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
--3(1)建表
CREATE TABLE sumofmoney(
 constructunit CHAR(100) NOT NULL,
 yearmonth CHAR(100),
 amount MONEY
);
--3(2)子查询插入
INSERT INTO sumofmoney (constructunit, yearmonth, amount)
SELECT settleunit, CONVERT(VARCHAR(7),settledate,120), SUM(settlecost)
FROM cost GROUP BY settleunit, CONVERT(VARCHAR(7),settledate,120);
--3(3)更新结算人
UPDATE cost SET settleperson = '李兵'
WHERE wellcode IN (SELECT num FROM well WHERE type = '油井') AND preunit LIKE '112201%';
--3(4)删除一矿项目
DELETE FROM cost WHERE preunit IN (SELECT num FROM unit WHERE name LIKE '采油一矿%');
ROLLBACK TRANSACTION;
PRINT '汇总表操作执行完成，已回滚更新删除';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '汇总表操作失败';
SELECT 错误号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_SumTableOper;
-- 删除索引
EXEC Proc_CreateDropIndex 'drop';
GO
-- ===== 练习3.sql =====

USE zyxt;
GO
IF EXISTS(SELECT * FROM sys.procedures WHERE name='Proc_SumTableAlterDrop') DROP PROC Proc_SumTableAlterDrop;
GO
-- 存储过程：sumofmoney修改、清空、删除
CREATE PROC Proc_SumTableAlterDrop
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
ALTER TABLE sumofmoney ADD 备注 CHAR(100);
ALTER TABLE sumofmoney ADD PRIMARY KEY(constructunit);
INSERT INTO sumofmoney (constructunit, yearmonth, amount)
SELECT settleunit, CONVERT(VARCHAR(7),settledate,120), SUM(settlecost)
FROM cost GROUP BY settleunit, CONVERT(VARCHAR(7),settledate,120);
TRUNCATE TABLE sumofmoney;
DROP TABLE sumofmoney;
COMMIT TRANSACTION;
PRINT 'sumofmoney表修改删除完成';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT 'sumofmoney操作失败';
SELECT 错误号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name='Proc_AddAllConstraint') DROP PROC Proc_AddAllConstraint;
GO
-- 存储过程：批量添加实体、参照、用户自定义完整性（事务）
CREATE PROC Proc_AddAllConstraint
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
-- 主键
ALTER TABLE cost ADD PRIMARY KEY(code);
ALTER TABLE unit ADD PRIMARY KEY(num);
ALTER TABLE construct_unit ADD PRIMARY KEY(name);
ALTER TABLE price ADD PRIMARY KEY(code);
ALTER TABLE well ADD PRIMARY KEY(num);
-- 外键
ALTER TABLE cost ADD CONSTRAINT fk_preunit FOREIGN KEY(preunit) REFERENCES unit(num);
ALTER TABLE cost ADD CONSTRAINT fk_well FOREIGN KEY(wellcode) REFERENCES well(num);
ALTER TABLE cost ADD CONSTRAINT fk_settleunit FOREIGN KEY(settleunit) REFERENCES construct_unit(name);
-- 自定义约束
ALTER TABLE unit ADD CONSTRAINT ck_unit_name CHECK(name IS NOT NULL),ADD UNIQUE(name);
ALTER TABLE well ADD CONSTRAINT ck_well_unit CHECK(code IS NOT NULL),ADD CONSTRAINT ck_well_type CHECK(type IN('油井','水井'));
ALTER TABLE price ADD CONSTRAINT ck_spec CHECK(num IS NOT NULL),ADD CONSTRAINT ck_unit CHECK(name IS NOT NULL),ADD UNIQUE(num);
ALTER TABLE cost ADD CONSTRAINT ck_mat1_num CHECK(mat1_num IS NOT NULL),ADD CONSTRAINT ck_mat1_price CHECK(mat1_price IS NOT NULL);
ALTER TABLE cost ADD CONSTRAINT ck_mat2_num CHECK(mat2_num IS NOT NULL),ADD CONSTRAINT ck_mat2_price CHECK(mat2_price IS NOT NULL);
ALTER TABLE cost ADD CONSTRAINT ck_mat3_num CHECK(mat3_num IS NOT NULL),ADD CONSTRAINT ck_mat3_price CHECK(mat3_price IS NOT NULL);
ALTER TABLE cost ADD CONSTRAINT ck_mat4_num CHECK(mat4_num IS NOT NULL),ADD CONSTRAINT ck_mat4_price CHECK(mat4_price IS NOT NULL);
ALTER TABLE cost ADD CONSTRAINT ck_predate CHECK(predate IS NOT NULL);
COMMIT TRANSACTION;
PRINT '所有完整性约束添加成功';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '添加约束失败';
SELECT 错误号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_AddAllConstraint;
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name='Proc_ViewOper') DROP PROC Proc_ViewOper;
GO
-- 存储过程：创建视图、视图查询、视图插入回滚
CREATE PROC Proc_ViewOper
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
-- 创建项目材料视图
CREATE VIEW job_material_view AS
SELECT code,preunit,wellcode,premoney,person,predate,startdate,finish,settleunit,content,
mat1_code,mat1_num,mat1_price,mat1_sub,mat2_code,mat2_num,mat2_price,mat2_sub,
mat3_code,mat3_num,mat3_price,mat3_sub,mat4_code,mat4_num,mat4_price,mat4_sub,
matcost,humancost,equipcost,othercost,settlecost,settleperson,settledate,finalcost,finalperson,finaldate
FROM cost;
-- 视图查询
SELECT '视图查询1-预算超万' AS res,* FROM job_material_view WHERE premoney > 10000;
SELECT '视图查询2-5月预算' AS res,* FROM job_material_view WHERE predate BETWEEN '2018-05-01' AND '2018-05-31';
-- 预算视图
CREATE VIEW job_budget_status_view AS
SELECT code, preunit, wellcode, premoney, person, predate, startdate, finish, settleunit, content,
matcost, humancost, equipcost, othercost, settlecost, finalcost FROM cost;
-- 视图插入测试
INSERT INTO job_budget_status_view (code, preunit, wellcode, premoney, person, predate)
VALUES ('zy2018008','112202002',10000,'张三','2018-07-02');
SELECT '插入后cost' AS res,* FROM cost WHERE code='zy2018008';
ROLLBACK TRANSACTION;
SELECT '回滚后cost' AS res,* FROM cost WHERE code='zy2018008';
PRINT '视图操作完成，插入已回滚';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '视图操作失败';
SELECT 错误号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_ViewOper;
GO
-- ===== 练习4.sql =====

USE zyxt;
GO
--1.事务插入存储过程
IF EXISTS(SELECT  FROM sys.procedures WHERE name='Proc_TransInsertCost') DROP PROC Proc_TransInsertCost;
GO
CREATE PROC Proc_TransInsertCost
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
insert into cost values('zy2018006','112202002','y005',
10000,'张三','2018-07-01','2018-07-04','2018-07-25','作业公司作业一队','堵漏',
'wm001',200,10,2000,'wm002',200,10,2000,'wm003',200,10,2000,'wm004',100,10,1000,
7000,2500,1000,1400,11900,'李四','2018-07-26',11900,'王五','2018-07-28');
COMMIT TRANSACTION;
PRINT '事务插入成功';
END TRY
BEGIN CATCH
IF @@TRANCOUNT0 ROLLBACK TRANSACTION;
PRINT '事务插入失败回滚';
SELECT 错误编号 = ERROR_NUMBER(),错误描述 = ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_TransInsertCost;
GO

--2.游标封装存储过程
IF EXISTS(SELECT  FROM sys.procedures WHERE name='Proc_CursorQueryCost') DROP PROC Proc_CursorQueryCost;
GO
CREATE PROC Proc_CursorQueryCost
AS
BEGIN
DECLARE 
    @code CHAR(20),@preunit CHAR(20),@wellcode CHAR(20),@premoney MONEY,@person CHAR(20),@predate DATE,
    @startdate DATE,@finish DATE,@settleunit CHAR(20),@content CHAR(20),
    @mat1_code CHAR(20),@mat1_num INT,@mat1_price MONEY,@mat1_sub MONEY,
    @mat2_code CHAR(20),@mat2_num INT,@mat2_price MONEY,@mat2_sub MONEY,
    @mat3_code CHAR(20),@mat3_num INT,@mat3_price MONEY,@mat3_sub MONEY,
    @mat4_code CHAR(20),@mat4_num INT,@mat4_price MONEY,@mat4_sub MONEY,
    @matcost MONEY,@humancost MONEY,@equipcost MONEY,@othercost MONEY,
    @settlecost MONEY,@settleperson CHAR(20),@settledate DATE,@finalcost MONEY,@finalperson CHAR(20),@finaldate DATE
DECLARE cost_cursor CURSOR FOR
SELECT code,preunit,wellcode,premoney,person,predate,startdate,finish,settleunit,content,
mat1_code,mat1_num,mat1_price,mat1_sub,mat2_code,mat2_num,mat2_price,mat2_sub,
mat3_code,mat3_num,mat3_price,mat3_sub,mat4_code,mat4_num,mat4_price,mat4_sub,
matcost,humancost,equipcost,othercost,settlecost,settleperson,settledate,finalcost,finalperson,finaldate FROM cost
OPEN cost_cursor
PRINT '单据号 预算单位 井号 预算金额 预算人 预算日期 开工日期 完工日期 施工单位 施工内容 材料费 人工费 设备费 其它费用 结算金额 结算人 结算日期 入账金额 入账人 入账日期'
FETCH NEXT FROM cost_cursor INTO 
@code,@preunit,@wellcode,@premoney,@person,@predate,@startdate,@finish,@settleunit,@content,
@mat1_code,@mat1_num,@mat1_price,@mat1_sub,@mat2_code,@mat2_num,@mat2_price,@mat2_sub,
@mat3_code,@mat3_num,@mat3_price,@mat3_sub,@mat4_code,@mat4_num,@mat4_price,@mat4_sub,
@matcost,@humancost,@equipcost,@othercost,@settlecost,@settleperson,@settledate,@finalcost,@finalperson,@finaldate
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT RTRIM(@code)+' '+RTRIM(@preunit)+' '+RTRIM(@wellcode)+' '+CAST(@premoney AS VARCHAR)+' '+RTRIM(@person)+' '+CONVERT(VARCHAR,@predate)+' '+CONVERT(VARCHAR,@startdate)+' '+CONVERT(VARCHAR,@finish)+' '+RTRIM(@settleunit)+' '+RTRIM(@content)+' '+CAST(@matcost AS VARCHAR)+' '+CAST(@humancost AS VARCHAR)+' '+CAST(@equipcost AS VARCHAR)+' '+CAST(@othercost AS VARCHAR)+' '+CAST(@settlecost AS VARCHAR)+' '+RTRIM(@settleperson)+' '+CONVERT(VARCHAR,@settledate)+' '+CAST(@finalcost AS VARCHAR)+' '+RTRIM(@finalperson)+' '+CONVERT(VARCHAR,@finaldate)
    FETCH NEXT FROM cost_cursor INTO 
@code,@preunit,@wellcode,@premoney,@person,@predate,@startdate,@finish,@settleunit,@content,
@mat1_code,@mat1_num,@mat1_price,@mat1_sub,@mat2_code,@mat2_num,@mat2_price,@mat2_sub,
@mat3_code,@mat3_num,@mat3_price,@mat3_sub,@mat4_code,@mat4_num,@mat4_price,@mat4_sub,
@matcost,@humancost,@equipcost,@othercost,@settlecost,@settleperson,@settledate,@finalcost,@finalperson,@finaldate
END
CLOSE cost_cursor
DEALLOCATE cost_cursor
END
GO
EXEC Proc_CursorQueryCost;
GO

--3.成本统计存储过程
IF EXISTS(SELECT  FROM sys.procedures WHERE name='Proc_Cost_Stat') DROP PROC Proc_Cost_Stat;
GO
CREATE PROC Proc_Cost_Stat
    @UnitCode CHAR(20),@StartDate DATE,@EndDate DATE
AS
BEGIN
SET NOCOUNT ON;
DECLARE @UnitName CHAR(20),@TotalPre MONEY=0,@TotalSettle MONEY=0,@TotalFinal MONEY=0,@NoSettle MONEY=0,@NoFinal MONEY=0
SELECT @UnitName = name FROM unit WHERE num = @UnitCode
SELECT
    @TotalPre = ISNULL(SUM(premoney),0),
    @TotalSettle = ISNULL(SUM(settlecost),0),
    @TotalFinal = ISNULL(SUM(ISNULL(finalcost),0))
FROM cost
WHERE LEFT(preunit,LEN(@UnitCode)) = @UnitCode AND predate BETWEEN @StartDate AND @EndDate
SET @NoSettle = @TotalPre - @TotalSettle;
SET @NoFinal = @TotalSettle - @TotalFinal;
PRINT ''+RTRIM(@UnitName)+'单位'+CONVERT(VARCHAR,@StartDate)+'时间---'+CONVERT(VARCHAR,@EndDate)+'成本运行情况'
PRINT '预算金额      结算金额      入账金额      未结算金额      未入账金额'
PRINT CONVERT(VARCHAR,@TotalPre)+'    '+CONVERT(VARCHAR,@TotalSettle)+'    '+CONVERT(VARCHAR,@TotalFinal)+'    '+CONVERT(VARCHAR,@NoSettle)+'    '+CONVERT(VARCHAR,@NoFinal)
END
GO
-- 三层单位分别执行
BEGIN TRANSACTION
EXEC Proc_Cost_Stat '1122','2018-05-01','2018-05-31';
EXEC Proc_Cost_Stat '112201','2018-05-01','2018-05-31';
EXEC Proc_Cost_Stat '112202002','2018-05-01','2018-05-31';
COMMIT TRANSACTION;
GO

--4.触发器创建+测试存储过程
IF EXISTS(SELECT  FROM sys.procedures WHERE name='Proc_CreateTriggerTest') DROP PROC Proc_CreateTriggerTest;
GO
CREATE PROC Proc_CreateTriggerTest
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
-- 插入自动计算结算金额触发器
IF EXISTS(SELECT  FROM sys.triggers WHERE name='trg_cost_insert_settlecost') DROP TRIGGER trg_cost_insert_settlecost;
CREATE TRIGGER trg_cost_insert_settlecost ON cost AFTER INSERT
AS BEGIN UPDATE cost SET settlecost = matcost + humancost + equipcost + othercost WHERE code IN (SELECT code FROM inserted); END
-- 修改自动更新结算金额触发器
IF EXISTS(SELECT  FROM sys.triggers WHERE name='trg_cost_update_settlecost') DROP TRIGGER trg_cost_update_settlecost;
CREATE TRIGGER trg_cost_update_settlecost ON cost AFTER UPDATE
AS BEGIN IF UPDATE(matcost) OR UPDATE(humancost) OR UPDATE(equipcost) OR UPDATE(othercost) UPDATE cost SET settlecost = matcost + humancost + equipcost + othercost WHERE code IN (SELECT code FROM inserted); END
-- 触发器测试
INSERT INTO cost(code,preunit,wellcode,premoney,person,predate,startdate,finish,settleunit,content,
mat1_code,mat1_num,mat1_price,mat1_sub,mat2_code,mat2_num,mat2_price,mat2_sub,mat3_code,mat3_num,mat3_price,mat3_sub,mat4_code,mat4_num,mat4_price,mat4_sub,
matcost,humancost,equipcost,othercost,settleperson,settledate,finalcost,finalperson,finaldate)
VALUES('zy2018006','112202002','y006',10000,'张三','2018-07-01','2018-07-04','2018-07-25','作业公司作业一队','堵漏',
'wm001',200,10,2000,'wm002',200,10,2000,'wm003',200,10,2000,'wm004',100,10,1000,
7000,2500,1000,1400,'李四','2018-07-26',11900,'王五','2018-07-28');
SELECT '插入后结算金额' AS t,code, matcost,humancost,equipcost,othercost,settlecost FROM cost WHERE code='zy2018006';
UPDATE cost SET matcost = 8000 WHERE code='zy2018006';
SELECT '修改材料费后结算金额' AS t,code, matcost,humancost,equipcost,othercost,settlecost FROM cost WHERE code='zy2018006';
DELETE FROM cost WHERE code='zy2018006';
COMMIT TRANSACTION;
PRINT '触发器创建与测试完成';
END TRY
BEGIN CATCH
IF @@TRANCOUNT0 ROLLBACK TRANSACTION;
PRINT '触发器操作失败';
SELECT 错误编号 = ERROR_NUMBER(),错误描述 = ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_CreateTriggerTest;
GO