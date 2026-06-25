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
-- ===== 练习2.sql =====

USE zyxt;
GO
IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_CreateDropIndex) DROP PROC Proc_CreateDropIndex;
GO
CREATE PROC Proc_CreateDropIndex @oper VARCHAR(10)
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
IF @oper='create'
BEGIN
CREATE INDEX index1 ON cost (predate);
CREATE INDEX index2 ON cost (startdate);
CREATE INDEX index3 ON cost (settledate);
PRINT '索引创建成功';
END
IF @oper='drop'
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
SELECT 错误编号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_CreateDropIndex 'create';
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_QueryAllTask) DROP PROC Proc_QueryAllTask;
GO
CREATE PROC Proc_QueryAllTask
AS
BEGIN
--1.采油一矿二队预算
SELECT '1.采油一矿二队预算项目' AS 结果,* FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND predate BETWEEN '2018-05-01' AND '2018-05-28';

--2.已结算项目
SELECT '2.采油一矿二队已结算项目' AS 结果,* FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND settledate BETWEEN '2018-05-01' AND '2018-05-28';

--3.材料明细（直接读取cost内置材料外键关联字段）
SELECT '3.材料消耗明细' AS 结果,code,mat1_code,mat1_sub,mat2_code,mat2_sub,mat3_code,mat3_sub,mat4_code,mat4_sub
FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND settledate BETWEEN '2018-05-01' AND '2018-05-28';

--4.已入账项目
SELECT '4.已入账项目' AS 结果,* FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND finaldate BETWEEN '2018-05-01' AND '2018-05-28';

--5.总预算
SELECT '5.一矿二队总预算' AS 结果,SUM(premoney) AS 总预算 FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队')
AND predate BETWEEN '2018-05-01' AND '2018-05-28';

--6.总结算
SELECT '6.一矿二队总结算' AS 结果,SUM(settlecost) AS 总结算 FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND settledate BETWEEN '2018-05-01' AND '2018-05-28';

--7.总入账
SELECT '7.一矿二队总入账' AS 结果,SUM(finalcost) AS 总入账 FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
AND finaldate BETWEEN '2018-05-01' AND '2018-05-28';

--8.采油一矿总入账
SELECT '8.采油一矿总入账' AS 结果,SUM(finalcost) AS 一矿总入账 FROM cost 
WHERE preunit LIKE '112201%' 
AND finaldate BETWEEN '2018-05-01' AND '2018-05-28';

--9.入账人员
SELECT '9.入账操作人员' AS 结果,DISTINCT finalperson FROM cost;

--10.已结算未入账
SELECT '10.已结算未入账项目' AS 结果,* FROM cost 
WHERE settledate BETWEEN '2018-05-01' AND '2018-05-28' AND finalcost IS NULL;

--11.按入账降序
SELECT '11.一矿二队按入账金额降序' AS 结果,* FROM cost 
WHERE preunit IN (SELECT num FROM unit WHERE name = '采油一矿二队') 
ORDER BY finalcost DESC;

--12.各施工单位结算汇总
SELECT '12.各施工单位结算汇总' AS 结果,settleunit,SUM(settlecost) AS 单位总结算 
FROM cost GROUP BY settleunit;

--13.材料三消耗超2000
SELECT '13.材料三消耗超2000项目' AS 结果,code,mat3_code,mat3_sub FROM cost WHERE mat3_sub > 2000;

--14.作业二队项目
SELECT '14.作业公司作业二队项目' AS 结果,* FROM cost WHERE settleunit = '作业公司作业二队';

--15.一队+二队 UNION
SELECT '15.一二队合并项目' AS 结果,* FROM cost WHERE settleunit = '作业公司作业二队' 
UNION 
SELECT * FROM cost WHERE settleunit = '作业公司作业一队';

--16.采油一矿施工队伍
SELECT '16.采油一矿所有施工单位' AS 结果,DISTINCT settleunit FROM cost WHERE preunit LIKE '112201%';
END
GO
EXEC Proc_QueryAllTask;
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_SumTableOper) DROP PROC Proc_SumTableOper;
GO
CREATE PROC Proc_SumTableOper
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
CREATE TABLE sumofmoney(
 constructunit CHAR(100) NOT NULL,
 yearmonth CHAR(100),
 amount MONEY
);
INSERT INTO sumofmoney (constructunit, yearmonth, amount)
SELECT settleunit, CONVERT(VARCHAR(7),settledate,120), SUM(settlecost)
FROM cost GROUP BY settleunit, CONVERT(VARCHAR(7),settledate,120);
UPDATE cost SET settleperson = '李兵'
WHERE wellcode IN (SELECT num FROM well WHERE type = '油井') AND preunit LIKE '112201%';
DELETE FROM cost WHERE preunit IN (SELECT num FROM unit WHERE name LIKE '采油一矿%');
ROLLBACK TRANSACTION;
PRINT '汇总表操作完成，更新删除已回滚';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '汇总表操作失败';
SELECT 错误编号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_SumTableOper;
EXEC Proc_CreateDropIndex 'drop';
GO
-- ===== 练习3.sql =====

USE zyxt;
GO
IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_SumTableAlterDrop) DROP PROC Proc_SumTableAlterDrop;
GO
CREATE PROC Proc_SumTableAlterDrop
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
ALTER TABLE sumof ADD 备注 CHAR(100);
ALTER TABLE sumofmoney ADD PRIMARY KEY(constructunit);
INSERT INTO sumofmoney (constructunit, yearmonth, amount)
SELECT settleunit, CONVERT(VARCHAR(7),settledate,120), SUM(settlecost)
FROM cost GROUP BY settleunit, CONVERT(VARCHAR(7),settledate,120);
TRUNCATE TABLE sumofmoney;
DROP TABLE sumofmoney;
COMMIT TRANSACTION;
PRINT 'sumofmoney修改删除完成';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT 'sumofmoney操作失败';
SELECT 错误编号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_ViewOper) DROP PROC Proc_ViewOper;
GO
CREATE PROC Proc_ViewOper
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
CREATE VIEW job_material_view AS
SELECT code,preunit,wellcode,premoney,person,predate,startdate,finish,settleunit,content,
mat1_code,mat1_num,mat1_price,mat1_sub,mat2_code,mat2_num,mat2_price,mat2_sub,
mat3_code,mat3_num,mat3_price,mat3_sub,mat4_code,mat4_num,mat4_price,mat4_sub,
matcost,humancost,equipcost,othercost,settlecost,settleperson,settledate,finalcost,finalperson,finaldate
FROM cost;

SELECT '视图查询1' AS res,* FROM job_material_view WHERE premoney > 10000;
SELECT '视图查询2' AS res,* FROM job_material_view WHERE predate BETWEEN '2018-05-01' AND '2018-05-31';

CREATE VIEW job_budget_status_view AS
SELECT code, preunit, wellcode, premoney, person, predate, startdate, finish, settleunit, content,
matcost, humancost, equipcost, othercost, settlecost, finalcost
FROM cost;

INSERT INTO job_budget_status_view (code, preunit, wellcode, premoney, person, predate)
VALUES ('zy2018008','112202002','y005',10000,'张三','2018-07-02');
SELECT '插入后' AS res,* FROM cost WHERE code='zy2018008';
ROLLBACK TRANSACTION;
SELECT '回滚后' AS res,* FROM cost WHERE code='zy2018008';
PRINT '视图操作完成';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '视图操作失败';
SELECT 错误编号=ERROR_NUMBER(),错误信息=ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_ViewOper;
GO
-- ===== 练习4.sql =====

USE zyxt;
GO
--1.事务插入存储过程
IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_TransInsertCost) DROP PROC Proc_TransInsertCost;
GO
CREATE PROC Proc_TransInsertCost
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
INSERT INTO cost values('zy2018006','112202002','y005',
10000,'张三','2018-07-01','2018-07-04','2018-07-25','作业公司作业一队','堵漏',
'wm001',200,10,2000,'wm002',200,10,2000,'wm003',200,10,2000,'wm004',100,10,1000,
7000,2500,1000,1400,11900,'李四','2018-07-26',11900,'王五','2018-07-28');
COMMIT TRANSACTION;
PRINT '事务插入成功';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '事务插入失败回滚';
SELECT 错误编号 = ERROR_NUMBER(),错误描述 = ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_TransInsertCost;
GO

--2.游标存储过程
IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_CursorQueryCost) DROP PROC Proc_CursorQueryCost;
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
matcost,humancost,equipcost,othercost,settlecost,settleperson,settledate,finalcost,finalperson,finaldate
FROM cost

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

--3.统计存储过程
IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_Cost_Stat) DROP PROC Proc_Cost_Stat;
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
PRINT '***'+RTRIM(@UnitName)+'单位'+CONVERT(VARCHAR,@StartDate)+'时间---'+CONVERT(VARCHAR,@EndDate)+'成本运行情况'
PRINT '预算金额      结算金额      入账金额      未结算金额      未入账金额'
PRINT CONVERT(VARCHAR,@TotalPre)+'    '+CONVERT(VARCHAR,@TotalSettle)+'    '+CONVERT(VARCHAR,@TotalFinal)+'    '+CONVERT(VARCHAR,@NoSettle)+'    '+CONVERT(VARCHAR,@NoFinal)
END
GO
BEGIN TRANSACTION
EXEC Proc_Cost_Stat '1122','2018-05-01','2018-05-31';
EXEC Proc_Cost_Stat '112201','2018-05-01','2018-05-31';
EXEC Proc_Cost_Stat '112202002','2018-05-01','2018-05-31';
COMMIT TRANSACTION;
GO

--4.触发器存储过程
IF EXISTS(SELECT * FROM sys.procedures WHERE name=Proc_CreateTriggerTest) DROP PROC Proc_CreateTriggerTest;
GO
CREATE PROC Proc_CreateTriggerTest
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION;
IF EXISTS(SELECT * FROM sys.triggers WHERE name=trg_cost_insert_settlecost) DROP TRIGGER trg_cost_insert_settlecost;
CREATE TRIGGER trg_cost_insert_settlecost ON cost AFTER INSERT
AS BEGIN UPDATE cost SET settlecost = matcost + humancost + equipcost + othercost WHERE code IN (SELECT code FROM inserted); END

IF EXISTS(SELECT * FROM sys.triggers WHERE name=trg_cost_update_settlecost) DROP TRIGGER trg_cost_update_settlecost;
CREATE TRIGGER trg_cost_update_settlecost ON cost AFTER UPDATE
AS BEGIN IF UPDATE(matcost) OR UPDATE(humancost) OR UPDATE(equipcost) OR UPDATE(othercost) UPDATE cost SET settlecost = matcost + humancost + equipcost + othercost WHERE code IN (SELECT code FROM inserted); END

--触发器测试数据
INSERT INTO cost(code,preunit,wellcode,premoney,person,predate,startdate,finish,settleunit,content,
mat1_code,mat1_num,mat1_price,mat1_sub,mat2_code,mat2_num,mat2_price,mat2_sub,mat3_code,mat3_num,mat3_price,mat3_sub,mat4_code,mat4_num,mat4_price,mat4_sub,
matcost,humancost,equipcost,othercost,settleperson,settledate,finalcost,finalperson,finaldate)
VALUES('zy2018006','112202002','y006',10000,'张三','2018-07-01','2018-07-04','2018-07-25','作业公司作业一队','堵漏',
'wm001',200,10,2000,'wm002',200,10,2000,'wm003',200,10,2000,'wm004',100,10,1000,
7000,2500,1000,1400,'李四','2018-07-26',11900,'王五','2018-07-28');

SELECT '插入结算金额' AS t,code, matcost,humancost,equipcost,othercost,settlecost FROM cost WHERE code='zy2018006';
UPDATE cost SET matcost = 8000 WHERE code='zy2018006';
SELECT '修改后结算金额' AS t,code, matcost,humancost,equipcost,othercost,settlecost FROM cost WHERE code='zy2018006';
DELETE FROM cost WHERE code='zy2018006';
COMMIT TRANSACTION;
PRINT '触发器创建与测试完成';
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
PRINT '触发器操作失败';
SELECT 错误编号 = ERROR_NUMBER(),错误描述 = ERROR_MESSAGE();
END CATCH
END
GO
EXEC Proc_CreateTriggerTest;
GO