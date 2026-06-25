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