/*�B�J�@�G�Х��N�H�USELECT���G�ƻs�X��(�ХѤW�ӤU�̧ǽƻs)�A�@�w�n���������d�ߥX��(�@�w�������G)*/
/*�B�J�G�G��2������SQL�y�k �j�MNVARCHAR(5000)�令NVARCHAR(Max) �]��NVARCHAR�u����4000*/
/*�B�J�T�G�A�̧ǰ���A���i��ʶ���*/
/*�Ƶ�:��2�Ӫ�SQL�y�k�P��Ʋ��h�A�]���ݭn��\�h�ɶ�����A�Э@�ߵ���SQL���槹��*/


/* 1. ����SQL �M��PK */
USE DG
SELECT 'ALTER TABLE ' + TABLE_NAME + ' DROP CONSTRAINT ' + CONSTRAINT_NAME + '' FROM (
SELECT DISTINCT CONSTRAINT_NAME, TABLE_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE OBJECTPROPERTY(OBJECT_ID(constraint_name), 'IsPrimaryKey') = 1
AND LEFT(table_name, 2) = 'TB') AS A

/* 2. ����SQL �M���D�O������*/
USE XX_DataBase
SELECT ' DROP INDEX ' + Index_Name + ' ON ' + Table_Name + '' 
FROM (SELECT DISTINCT SC.name AS Schema_Name, 
                      O.name AS Table_Name, 
				      I.name AS Index_Name, 
				      I.type_desc AS Index_Type
       FROM sys.indexes I
      INNER JOIN sys.objects O ON I.object_id = O.object_id
      INNER JOIN sys.schemas SC ON O.schema_id = SC.schema_id
	  WHERE I.name IS NOT NULL AND O.type = 'U' AND I.type_desc = 'NONCLUSTERED' AND is_unique = '0'
	  ) AS A

/* 3. ����SQL �վ� varchar TO nvarchar ����������s�|�]����Ʋ��h�ݭn��\�h�ɶ� */
USE XX_DataBase
SELECT DISTINCT 'ALTER TABLE ' + TABLE_NAME + ' ALTER COLUMN [' + COLUMN_NAME + '] NVARCHAR(' + CONVERT(VARCHAR(50),CHARACTER_MAXIMUM_LENGTH) + 
                ') ' + CASE WHEN IS_NULLABLE = 'NO' THEN 'NOT NULL' ELSE 'NULL' END
FROM INFORMATION_SCHEMA.COLUMNS
WHERE Data_type = 'varchar' AND LEFT(TABLE_NAME, 2) = 'TB'

/* 4. ����SQL �إ߫D�O������ */
USE XX_DataBase
SELECT 'CREATE NONCLUSTERED INDEX ' + Index_Name + ' ON ' + Table_Name + ' (' + SUBSTRING(column_name, 1, LEN(column_name) - 1) + ')' + result_column_name + ''
FROM(
     SELECT DISTINCT D.Index_Name, D.Table_Name, column_name,
                     CASE WHEN D.includ_column_name <> '' THEN ' INCLUDE (' + SUBSTRING(includ_column_name, 1, LEN(includ_column_name) - 1) + ')'
     				      ELSE '' END result_column_name
       FROM(
            SELECT DISTINCT C.Index_Name, C.Table_Name, 
                            column_name = (SELECT CAST(column_name AS NVARCHAR) + ' ASC, ' 
                                             FROM(SELECT DISTINCT A2.name AS Table_Name, 
                                                                  A1.name AS Index_Name, 
                                                                  A1.type_desc AS Index_Type,
                                                                  A4.index_id, 
                                                                  CASE WHEN A4.is_included_column = 0 THEN A3.name ELSE '' END column_name,
                                                  				  CASE WHEN A4.is_included_column = 0 THEN A4.index_column_id ELSE 0 END index_column_id
                                                  FROM sys.indexes A1
                                                  INNER JOIN sys.objects A2 ON A1.object_id = A2.object_id
                                                  INNER JOIN sys.columns A3 ON A3.object_id = A1.object_id
                                                  INNER JOIN sys.index_columns A4 ON A4.object_id = A1.object_id AND A4.index_id = A1.index_id AND A4.column_id = A3.column_id
                                                  WHERE A1.name IS NOT NULL AND A2.type = 'U' AND A1.type_desc = 'NONCLUSTERED' AND is_unique = '0' AND A4.is_included_column = 0
                                      	          )A
                                           WHERE A.Index_Name = C.Index_Name AND A.Table_Name = C.Table_Name AND A.column_name <> ''
                                           ORDER BY A.Index_Name, A.index_column_id
										   FOR XML PATH('')
                                           ),
                            includ_column_name = STUFF((SELECT CAST(includ_column_name AS NVARCHAR) + ', ' 
                                                          FROM(SELECT DISTINCT B2.name AS Table_Name, 
                                            	  	    		               B1.name AS Index_Name, 
                                            	  	    		               B1.type_desc AS Index_Type,
                                            	  	    		               B4.index_id,  
                                            	  	    	                   CASE WHEN B4.is_included_column = 1 THEN B3.name ELSE '' END includ_column_name,
																			   CASE WHEN B4.is_included_column = 1 THEN B4.index_column_id ELSE 0 END index_column_id
                                                                 FROM sys.indexes B1
                                                               INNER JOIN sys.objects B2 ON B1.object_id = B2.object_id
                                                               INNER JOIN sys.columns B3 ON B3.object_id = B1.object_id
                                                               INNER JOIN sys.index_columns B4 ON B4.object_id = B1.object_id AND B4.index_id = B1.index_id AND B4.column_id = B3.column_id
                                                               WHERE B1.name IS NOT NULL AND B2.type = 'U' AND B1.type_desc = 'NONCLUSTERED' AND is_unique = '0' AND B4.is_included_column = 1
                                      	                       )B
                                                        WHERE B.Index_Name = C.Index_Name AND B.Table_Name = C.Table_Name AND B.includ_column_name IS NOT NULL
                                                        ORDER BY B.Index_Name, B.index_column_id
														FOR XML PATH('')
                                                        ), 1, 0, '')
            FROM(SELECT DISTINCT C2.name AS Table_Name, 
            				     C1.name AS Index_Name, 
            				     C1.type_desc AS Index_Type
                  FROM sys.indexes C1
                 INNER JOIN sys.objects C2 ON C1.object_id = C2.object_id
                 WHERE C1.name IS NOT NULL AND C2.type = 'U' AND C1.type_desc = 'NONCLUSTERED' AND is_unique = '0'
                 ) C
            ) D
)E

/* 5. ����SQL �إ� PK */
USE XX_DataBase
SELECT 'ALTER TABLE ' + TABLE_NAME + ' ADD CONSTRAINT PK_' + TABLE_NAME + ' PRIMARY KEY (' + SUBSTRING(Datelist, 1, LEN(Datelist) - 1) + ')'
FROM(
SELECT DISTINCT CONSTRAINT_NAME, TABLE_NAME, Datelist =
(
	SELECT CAST(COLUMN_NAME AS NVARCHAR) + ',' 
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
	WHERE CONSTRAINT_NAME = T0.CONSTRAINT_NAME AND LEFT(table_name, 2) = 'TB'	
	ORDER BY CONSTRAINT_NAME, ORDINAL_POSITION
	FOR XML PATH('')
)
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE T0) AS A 
WHERE ISNULL(Datelist, '') <> ''


