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