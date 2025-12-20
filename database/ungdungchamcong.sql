CREATE DATABASE ChamCongQR1;
GO
USE ChamCongQR1;
GO
----------------------------------------
-- 1. NhanVien
----------------------------------------
CREATE TABLE NhanVien (
    NhanVienId       VARCHAR(36) PRIMARY KEY,
    HoTen            NVARCHAR(150) NOT NULL,
    SoDienThoai      VARCHAR(20),
    Email            NVARCHAR(150),
    GioiTinh         NVARCHAR(10),
    NgaySinh         DATE,
    NgayVaoLam       DATE,
    TrangThai        BIT DEFAULT 1,
    NgayTao          DATETIME DEFAULT GETDATE()
);

----------------------------------------
-- 2. CaLam
----------------------------------------
CREATE TABLE CaLam (
    CaLamId INT IDENTITY(1,1) PRIMARY KEY,
    TenCa NVARCHAR(100),
    GioBatDau TIME NOT NULL,
    GioKetThuc TIME NOT NULL,
    ThoiGianNghi INT DEFAULT 0,
    NgayTao DATETIME DEFAULT GETDATE()
);

----------------------------------------
-- 3. PhanCa
----------------------------------------
CREATE TABLE PhanCa (
    PhanCaId INT IDENTITY(1,1) PRIMARY KEY,
    NhanVienId VARCHAR(36) NOT NULL,
    CaLamId INT NOT NULL,
    NgayApDung DATE NOT NULL,
    GiaoBang NVARCHAR(100),
    NgayTao DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_PhanCa_NhanVien FOREIGN KEY (NhanVienId)
        REFERENCES NhanVien(NhanVienId),

    CONSTRAINT FK_PhanCa_CaLam FOREIGN KEY (CaLamId)
        REFERENCES CaLam(CaLamId),

    CONSTRAINT UQ_PhanCa UNIQUE (NhanVienId, CaLamId, NgayApDung)
);

----------------------------------------
-- 4. LogQuetQR
----------------------------------------
CREATE TABLE LogQuetQR (
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    NhanVienId VARCHAR(36) NULL,
    ThoiGianQuet DATETIME NOT NULL,
    LoaiQuet NVARCHAR(20) NOT NULL,
    DataQR NVARCHAR(MAX),
    KetQua NVARCHAR(100),
    DeviceId NVARCHAR(100),
    DeviceIp VARCHAR(45),
    NgayTao DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (NhanVienId) REFERENCES NhanVien(NhanVienId)
);

----------------------------------------
-- 5. ViTriQuet
----------------------------------------
CREATE TABLE ViTriQuet (
    ViTriId INT IDENTITY(1,1) PRIMARY KEY,
    LogId INT NOT NULL,
    ThoiGian DATETIME NOT NULL,
    KinhDo DECIMAL(10,7) NOT NULL,
    ViDo DECIMAL(10,7) NOT NULL,
    DoCao DECIMAL(8,2),
    DoChinhXac DECIMAL(8,2),
    NguonGPS NVARCHAR(50),

    FOREIGN KEY (LogId) REFERENCES LogQuetQR(LogId)
);

----------------------------------------
-- 6. ChamCong
----------------------------------------
CREATE TABLE ChamCong (
    ChamCongId INT IDENTITY(1,1) PRIMARY KEY,
    NhanVienId VARCHAR(36) NOT NULL,
    CaLamId INT NOT NULL,
    NgayLamViec DATE NOT NULL,
    GioVao DATETIME NULL,
    GioRa DATETIME NULL,
    SoGioLam DECIMAL(5,2),
    DiMuon BIT DEFAULT 0,
    VeSom BIT DEFAULT 0,
    VangMat BIT DEFAULT 0,
    NgayTao DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (NhanVienId) REFERENCES NhanVien(NhanVienId),
    FOREIGN KEY (CaLamId) REFERENCES CaLam(CaLamId),

    CONSTRAINT UQ_ChamCong UNIQUE (NhanVienId, CaLamId, NgayLamViec)
);

----------------------------------------
-- 7. BangLuong
----------------------------------------
CREATE TABLE BangLuong (
    BangLuongId INT IDENTITY(1,1) PRIMARY KEY,
    NhanVienId VARCHAR(36) NOT NULL,
    Thang TINYINT NOT NULL,
    Nam SMALLINT NOT NULL,
    SoNgayCong DECIMAL(5,2),
    TongGioLam DECIMAL(7,2),
    SoLanDiMuon INT DEFAULT 0,
    TienLuong DECIMAL(12,2),
    GhiChu NVARCHAR(500),
    NgayPhat DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (NhanVienId) REFERENCES NhanVien(NhanVienId),
    CONSTRAINT UQ_BangLuong UNIQUE (NhanVienId, Thang, Nam)
);

----------------------------------------
-- 8. LogHeThong
----------------------------------------
CREATE TABLE LogHeThong (
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    ThucHienBoi VARCHAR(36),
    HanhDong NVARCHAR(200),
    BangMuc NVARCHAR(100),
    BanGhiId NVARCHAR(100),
    ThoiGian DATETIME DEFAULT GETDATE(),
    DiaChiIp VARCHAR(45),
    ChiTiet NVARCHAR(MAX),
    FOREIGN KEY (ThucHienBoi) REFERENCES NhanVien(NhanVienId)
);
ALTER TABLE NhanVien
ADD VaiTro NVARCHAR(20) DEFAULT 'NhanVien';
ALTER TABLE NhanVien
ADD MatKhau NVARCHAR(256) NOT NULL;