USE [RetailDW_Dev];
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[UpdateWatermark]
    @TableSchema      VARCHAR(50),
    @TableName        VARCHAR(100),
    @WatermarkColumn  VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @MaxValue BIGINT;

    -- Get the latest watermark value dynamically
    SET @SQL =
        N'SELECT @MaxVal = MAX(' + QUOTENAME(@WatermarkColumn) + N')
          FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName);

    EXEC sys.sp_executesql
        @SQL,
        N'@MaxVal BIGINT OUTPUT',
        @MaxVal = @MaxValue OUTPUT;

    -- Handle empty source table
    SET @MaxValue = ISNULL(@MaxValue, 0);

    -- Update existing watermark row
    IF EXISTS
    (
        SELECT 1
        FROM dbo.ADF_Watermark_Table
        WHERE TableSchema = @TableSchema
          AND TableName = @TableName
    )
    BEGIN
        UPDATE dbo.ADF_Watermark_Table
        SET WatermarkColumn = @WatermarkColumn,
            LastLoadValue = @MaxValue
        WHERE TableSchema = @TableSchema
          AND TableName = @TableName;
    END
    ELSE
    BEGIN
        -- Insert metadata if the table is not already registered
        INSERT INTO dbo.ADF_Watermark_Table
        (
            TableSchema,
            TableName,
            WatermarkColumn,
            LastLoadValue
        )
        VALUES
        (
            @TableSchema,
            @TableName,
            @WatermarkColumn,
            @MaxValue
        );
    END
END;
GO
