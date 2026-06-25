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