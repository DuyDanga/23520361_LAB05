USE QLGV
GO

-- I. Ngôn ngữ định nghĩa dữ liệu (Data Definition Language):
-- 9.	Lớp trưởng của một lớp phải là học viên của lớp đó.
CREATE TRIGGER trg_ins_udt_LopTruong ON LOP
FOR INSERT, UPDATE
AS
BEGIN
 IF NOT EXISTS (SELECT * FROM INSERTED I, HOCVIEN HV
 WHERE I.TRGLOP = HV.MAHV AND I.MALOP = HV.MALOP)
 BEGIN
 PRINT 'Error: Lop truong cua mot lop phai la hoc vien cua lop do'
 ROLLBACK TRANSACTION
 END
END  
GO

CREATE TRIGGER trg_del_HOCVIEN ON HOCVIEN
FOR DELETE
AS
BEGIN
 IF EXISTS (SELECT * FROM DELETED D, INSERTED I, LOP L 
 WHERE D.MAHV = L.TRGLOP AND D.MALOP = L.MALOP)
 BEGIN
 PRINT 'Error: Hoc vien hien tai dang la truong lop'
 ROLLBACK TRANSACTION
 END
END
GO

-- 10.	Trưởng khoa phải là giáo viên thuộc khoa và có học vị “TS” hoặc “PTS”.

--- Sửa quan hệ GIAOVIEN
GO
CREATE TRIGGER TRG_UPDATE_GIAOVIEN ON GIAOVIEN
FOR UPDATE
AS
BEGIN
 IF(SELECT COUNT(*)
 FROM inserted I , KHOA K
 WHERE K.TRGKHOA=I.MAGV AND I.MAKHOA=K.MAKHOA)=0
 BEGIN
 PRINT 'ERROR'
 ROLLBACK TRANSACTION
 END
 ELSE
 BEGIN
 PRINT'THANH CONG'
 END 
END
--- Xóa GIAOVIEN
GO
CREATE TRIGGER TRG10_DELETE_GIAOVIEN ON GIAOVIEN
FOR DELETE
AS
BEGIN
 DECLARE @MAGV CHAR(4), @TRGKHOA CHAR(4), @MAKHOA VARCHAR(4)
 SELECT @MAGV = MAGV, @MAKHOA=MAKHOA
 FROM DELETED
 SELECT @TRGKHOA=TRGKHOA
 FROM KHOA
 WHERE MAKHOA=@MAKHOA
 IF(@MAGV = @TRGKHOA)
 BEGIN 
 PRINT ' Khong duoc xoa'
 ROLLBACK TRANSACTION
 END
 ELSE
 BEGIN
 PRINT 'Xoa thanh cong!'
 END
END;
GO

-- 15.	Học viên chỉ được thi một môn học nào đó khi lớp của học viên đã học xong môn học này.

-- 16.	Mỗi học kỳ của một năm học, một lớp chỉ được học tối đa 3 môn.
GO
CREATE TRIGGER TRG16_INSERT_GIANGDAY ON GIANGDAY
FOR INSERT ,UPDATE
AS
BEGIN
      IF(SELECT COUNT(*)
      FROM inserted I , GIANGDAY GD
      WHERE I.MALOP=GD.MALOP AND I.HOCKY=GD.HOCKY)>3
      BEGIN
            PRINT 'ERROR'
            ROLLBACK TRANSACTION
      END
      ELSE
            BEGIN
            PRINT 'THANHCONG'
      END
END;
GO

-- 17.	Sỉ số của một lớp bằng với số lượng học viên thuộc lớp đó.
--- Sửa, THÊM sỉ số  GO
CREATE TRIGGER TRG17_INSERT_LOP ON LOP
FOR INSERT, UPDATE
AS
BEGIN
      DECLARE @SISO TINYINT, @DEMHOCVIEN TINYINT, @MALOP CHAR(3)
      SELECT @SISO = SISO, @MALOP = MALOP
      FROM INSERTED I
      SELECT @DEMHOCVIEN = COUNT(MAHV)
      FROM HOCVIEN
      WHERE MALOP =@MALOP
      IF(@SISO<>@DEMHOCVIEN)
      BEGIN
            PRINT 'Khong cho sua si so'
            ROLLBACK TRANSACTION
      END
      ELSE
      BEGIN
            PRINT 'Sua si so thanh cong'
      END
END;
GO

/* 18.	Trong quan hệ DIEUKIEN giá trị của thuộc tính MAMH và MAMH_TRUOC trong cùng một bộ 
không được giống nhau (“A”,”A”) và cũng không tồn tại hai bộ (“A”,”B”) và (“B”,”A”). */

-- 19.	Các giáo viên có cùng học vị, học hàm, hệ số lương thì mức lương bằng nhau.

GO
CREATE TRIGGER TRG19_INSERTED_GIAOVIEN ON GIAOVIEN
FOR INSERT , UPDATE
AS
BEGIN
      IF(SELECT COUNT (*)
      FROM inserted I , GIAOVIEN GV
      WHERE I.HOCHAM=GV.HOCHAM AND I.HOCVI=GV.HOCVI AND I.HESO=GV.HESO AND I.MUCLUONG!=GV.MUCLUONG)>0
      BEGIN
            PRINT 'ERROR'
            ROLLBACK TRAN
      END
      ELSE
      BEGIN
            PRINT 'THANHCONG'
      END
END;
GO
-- 20.	Học viên chỉ được thi lại (lần thi >1) khi điểm của lần thi trước đó dưới 5.
GO
CREATE TRIGGER TRG20_INSERT_KQT ON KETQUATHI
FOR INSERT
AS
BEGIN
      DECLARE @LANTHI TINYINT, @MAHV CHAR(5), @DIEM NUMERIC(4,2)
      SELECT @LANTHI = KETQUATHI.LANTHI +1, @MAHV = I.MAHV, @DIEM = KETQUATHI.DIEM
      FROM INSERTED I JOIN KETQUATHI ON I.MAHV =KETQUATHI.MAHV
      WHERE I.MAMH = KETQUATHI.MAMH
      IF(@DIEM>5)
      BEGIN
            PRINT 'Khong duoc thi lan nua!'
            ROLLBACK TRANSACTION
      END
      ELSE
      BEGIN
            PRINT 'Them lan thi thanh cong!'
      END
END;
GO
-- 21.	Ngày thi của lần thi sau phải lớn hơn ngày thi của lần thi trước (cùng học viên, cùng môn học).
GO
CREATE TRIGGER TRG21_INSERT_KQT ON KETQUATHI
FOR INSERT , UPDATE
AS
BEGIN
      IF(SELECT COUNT(*)
      FROM INSERTED I , KETQUATHI K
      WHERE I.LANTHI> K.LANTHI AND I.MAHV=K.MAHV AND I.MAMH=I.MAMH AND I.NGTHI>K.NGTHI)=0
      BEGIN
            PRINT 'ERROR'
            ROLLBACK TRAN
      END
      ELSE
      BEGIN
            PRINT 'THANHCONG'
      END
END;
GO
--22. Khi phân công giảng dạy một môn học, phải xét đến thứ tự trước sau giữa các môn học (sau khi học xong những môn học phải học trước mới được học những môn liền sau).
--23. Giáo viên chỉ được phân công dạy những môn thuộc khoa giáo viên đó phụ trách.