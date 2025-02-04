﻿	GO
USE QLBH
GO

-- I. Ngôn ngữ định nghĩa dữ liệu (Data Definition Language):
-- 11.	Ngày mua hàng (NGHD) của một khách hàng thành viên sẽ lớn hơn hoặc bằng ngày khách hàng đó đăng ký thành viên (NGDK).
-- Trigger kiểm tra ngày mua hàng (NGHD) phải lớn hơn hoặc bằng ngày đăng ký thành viên (NGDK)
CREATE TRIGGER trg_CheckNGHD_NGDK
ON HOADON
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra điều kiện: NGHD >= NGDK
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN KHACHHANG k ON i.MAKH = k.MAKH
        WHERE i.NGHD < k.NGDK
    )
    BEGIN
        -- Nếu điều kiện không thỏa mãn, trả lỗi
        RAISERROR ('Ngày mua hàng (NGHD) phải lớn hơn hoặc bằng ngày đăng ký thành viên (NGDK)', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO


-- 12.	Ngày bán hàng (NGHD) của một nhân viên phải lớn hơn hoặc bằng ngày nhân viên đó vào làm.
CREATE TRIGGER TRG_HD_NV ON HOADON FOR INSERT
AS
BEGIN
	DECLARE @NGHD SMALLDATETIME, @NGVL SMALLDATETIME, @MANV CHAR(4)
	SELECT @NGHD = NGHD, @MANV = MANV FROM INSERTED
	SELECT	@NGVL = NGVL FROM NHANVIEN WHERE MANV = @MANV

	IF (@NGHD >= @NGVL)
		PRINT N'Thêm mới một hóa đơn thành công.'
	ELSE
	BEGIN
		PRINT N'Lỗi: Ngày bán hàng của một nhân viên phải lớn hơn hoặc bằng ngày nhân viên đó vào làm.'
		ROLLBACK TRANSACTION
	END
END
GO

-- 13.	Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn.
CREATE TRIGGER TRG_HD_CTHD ON HOADON FOR INSERT
AS
BEGIN
	DECLARE @SOHD INT, @COUNT_SOHD INT
	SELECT @SOHD = SOHD FROM INSERTED
	SELECT @COUNT_SOHD = COUNT(SOHD) FROM CTHD WHERE SOHD = @SOHD

	IF (@COUNT_SOHD >= 1)
		PRINT N'Thêm mới một hóa đơn thành công.'
	ELSE
	BEGIN
		PRINT N'Lỗi: Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn.'
		ROLLBACK TRANSACTION
	END
END
GO

-- 14.	Trị giá của một hóa đơn là tổng thành tiền (số lượng*đơn giá) của các chi tiết thuộc hóa đơn đó.
CREATE TRIGGER TRG_CTHD ON CTHD FOR INSERT, DELETE
AS
BEGIN
	DECLARE @SOHD INT, @TONGGIATRI INT

	SELECT @TONGGIATRI = SUM(SL * GIA), @SOHD = SOHD 
	FROM INSERTED INNER JOIN SANPHAM
	ON INSERTED.MASP = SANPHAM.MASP
	GROUP BY SOHD

	UPDATE HOADON
	SET TRIGIA += @TONGGIATRI
	WHERE SOHD = @SOHD
END
GO 

CREATE TRIGGER TR_DEL_CTHD ON CTHD FOR DELETE
AS
BEGIN
	DECLARE @SOHD INT, @GIATRI INT

	SELECT @SOHD = SOHD, @GIATRI = SL * GIA 
	FROM DELETED INNER JOIN SANPHAM 
	ON SANPHAM.MASP = DELETED.MASP

	UPDATE HOADON
	SET TRIGIA -= @GIATRI
	WHERE SOHD = @SOHD
END
GO