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