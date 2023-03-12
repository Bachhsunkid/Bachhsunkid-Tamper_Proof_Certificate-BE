﻿--
-- Script was generated by Devart dbForge Studio 2020 for MySQL, Version 9.0.338.0
-- Product home page: http://www.devart.com/dbforge/mysql/studio
-- Script date 3/12/2023 11:42:39 AM
-- Server version: 8.0.26
-- Client version: 4.1
--

-- 
-- Disable foreign keys
-- 
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;

-- 
-- Set SQL mode
-- 
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- 
-- Set character set the client will use to send SQL statements to the server
--
SET NAMES 'utf8';

--
-- Set default database
--
USE `nckh.blockchain.team4`;

--
-- Drop procedure `proc_certificate_DeleteMultiple`
--
DROP PROCEDURE IF EXISTS proc_certificate_DeleteMultiple;

--
-- Drop procedure `proc_user_delete`
--
DROP PROCEDURE IF EXISTS proc_user_delete;

--
-- Drop procedure `proc_user_insert`
--
DROP PROCEDURE IF EXISTS proc_user_insert;

--
-- Drop procedure `proc_certificate_delete`
--
DROP PROCEDURE IF EXISTS proc_certificate_delete;

--
-- Drop procedure `proc_certificate_GetPagingIssued`
--
DROP PROCEDURE IF EXISTS proc_certificate_GetPagingIssued;

--
-- Drop procedure `proc_certificate_GetPagingReceived`
--
DROP PROCEDURE IF EXISTS proc_certificate_GetPagingReceived;

--
-- Drop procedure `proc_certificate_insert`
--
DROP PROCEDURE IF EXISTS proc_certificate_insert;

--
-- Drop procedure `proc_certificate_send`
--
DROP PROCEDURE IF EXISTS proc_certificate_send;

--
-- Drop procedure `proc_certificate_sign`
--
DROP PROCEDURE IF EXISTS proc_certificate_sign;

--
-- Drop procedure `proc_dashbroad_GetInfor`
--
DROP PROCEDURE IF EXISTS proc_dashbroad_GetInfor;

--
-- Drop table `certificate`
--
DROP TABLE IF EXISTS certificate;

--
-- Drop procedure `proc_contact_accept`
--
DROP PROCEDURE IF EXISTS proc_contact_accept;

--
-- Drop procedure `proc_contact_delete`
--
DROP PROCEDURE IF EXISTS proc_contact_delete;

--
-- Drop procedure `proc_contact_GetPaging`
--
DROP PROCEDURE IF EXISTS proc_contact_GetPaging;

--
-- Drop procedure `proc_contact_insert`
--
DROP PROCEDURE IF EXISTS proc_contact_insert;

--
-- Drop table `contact`
--
DROP TABLE IF EXISTS contact;

--
-- Drop table `user`
--
DROP TABLE IF EXISTS user;

--
-- Set default database
--
USE `nckh.blockchain.team4`;

--
-- Create table `user`
--
CREATE TABLE user (
  PolicyID varchar(255) NOT NULL DEFAULT '' COMMENT 'Khóa chính là PolicyID',
  UserCode mediumint UNSIGNED NOT NULL COMMENT 'Mã code, để hiển thị lên trang web',
  UserName varchar(255) DEFAULT NULL COMMENT 'Tên tổ chức',
  Logo text DEFAULT NULL,
  CreatedDate datetime DEFAULT NULL COMMENT 'Ngày tạo tài khoản',
  IsDeleted tinyint DEFAULT NULL COMMENT 'Bị xóa hay chưa (0-chưa xóa; 1-đã xóa)',
  PRIMARY KEY (PolicyID)
)
ENGINE = INNODB,
AVG_ROW_LENGTH = 2730,
CHARACTER SET utf8mb4,
COLLATE utf8mb4_general_ci;

--
-- Create index `UserCode` on table `user`
--
ALTER TABLE user
ADD UNIQUE INDEX UserCode (UserCode);

--
-- Create table `contact`
--
CREATE TABLE contact (
  ContactID char(36) NOT NULL DEFAULT '' COMMENT 'Khóa chính, có kiểu GUID',
  ContactCode mediumint UNSIGNED NOT NULL COMMENT 'mã hiện thị trên website, có kiểu là số',
  IssuedID varchar(255) NOT NULL DEFAULT '' COMMENT 'Khóa ngoại, liên kết với bảng user(PolicyID)',
  ReceivedID varchar(255) NOT NULL DEFAULT '' COMMENT 'Khóa ngoại, liên kết với bảng user(PolicyID)',
  ContactStatus tinyint DEFAULT NULL COMMENT 'Trạng thái kết nối (0-pending, 1-connected)',
  CreatedDate datetime DEFAULT NULL COMMENT 'Ngày tạo',
  IsDeleted tinyint NOT NULL COMMENT 'xóa hay chưa (0-hiện/1-ẩn)',
  PRIMARY KEY (ContactID)
)
ENGINE = INNODB,
AVG_ROW_LENGTH = 3276,
CHARACTER SET utf8mb4,
COLLATE utf8mb4_general_ci,
COMMENT = 'Bảng liên hệ';

--
-- Create index `ContactCode` on table `contact`
--
ALTER TABLE contact
ADD UNIQUE INDEX ContactCode (ContactCode);

--
-- Create foreign key
--
ALTER TABLE contact
ADD CONSTRAINT FK_contact_IssuedID FOREIGN KEY (IssuedID)
REFERENCES user (PolicyID);

--
-- Create foreign key
--
ALTER TABLE contact
ADD CONSTRAINT FK_contact_ReceivedID FOREIGN KEY (ReceivedID)
REFERENCES user (PolicyID);

DELIMITER $$

--
-- Create procedure `proc_contact_insert`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_contact_insert (IN v_IssuedID varchar(255), IN v_ReceivedID varchar(255))
COMMENT 'Thêm mới một liên lạc'
BEGIN
  -- Lấy giá trị lớn nhất của user code
  DECLARE CODE mediumint;
  SELECT
    MAX(ContactCode) INTO CODE
  FROM contact;

  -- Check if the contact already exists
  IF (SELECT
        COUNT(*)
      FROM contact c
      WHERE c.IssuedID = v_IssuedID
      AND c.ReceivedID = v_ReceivedID) > 0 THEN
    -- Contact already exists, do nothing
    SELECT
      '';
  ELSE
    -- Nếu table xxx chưa có data sẽ mặc định CODE = 100000
    IF CODE IS NULL THEN
      SET CODE = 100000;
    ELSE
      SET CODE = CODE + 1;
    END IF;

    -- Thực hiện insert
    INSERT INTO contact
      VALUES (UUID(), CODE, v_IssuedID, v_ReceivedID, 0,  -- ContactStatus (Pending)
      NOW(), 0);
  END IF;
END
$$

--
-- Create procedure `proc_contact_GetPaging`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_contact_GetPaging (IN v_UserID varchar(255),
IN v_PageSize int,
IN v_PageNumber int,
IN v_UserName varchar(255),
IN v_ContactStatus tinyint)
BEGIN
  DECLARE offset_page int;
  DECLARE no_results_error CONDITION FOR SQLSTATE '02000';

  -- v_PageSize and  v_PageNumber must be > 0
  IF v_PageSize <= 0 THEN
    SELECT
      'Invalid Page Size: Page Size must be greater than zero';
    SIGNAL no_results_error;
  END IF;

  IF v_PageNumber <= 0 THEN
    SELECT
      'Invalid Page Number: Page Number must be greater than zero';
    SIGNAL no_results_error;
  END IF;

  -- Offset_page is record number want to get
  SET offset_page = (v_PageNumber - 1) * v_PageSize;

  SELECT
    c.ContactID,
    c.ContactCode,
    u.UserName,
    c.CreatedDate,
    c.ContactStatus
  FROM user u
    JOIN contact c
      ON u.PolicyID = c.IssuedID
  -- Check conditions
  WHERE (c.IssuedID = v_UserID
  OR c.ReceivedID = v_UserID)
  AND (u.UserName LIKE CONCAT('%', v_UserName, '%')
  OR v_UserName IS NULL)
  AND (c.ContactStatus = v_ContactStatus
  OR v_ContactStatus IS NULL)
  AND c.IsDeleted = 0

  -- Default sort by CreatedDate
  ORDER BY c.CreatedDate ASC
  LIMIT v_PageSize
  OFFSET offset_page;

END
$$

--
-- Create procedure `proc_contact_delete`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_contact_delete (IN v_ContactID varchar(255))
COMMENT 'Xóa '
BEGIN
  UPDATE contact c
  SET c.IsDelete = 1
  WHERE c.ContactID = v_ContactID;
END
$$

--
-- Create procedure `proc_contact_accept`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_contact_accept (IN v_ContactID char(36))
BEGIN
  UPDATE contact c
  SET c.ContactStatus = 1
  WHERE c.ContactID = v_ContactID;
END
$$

DELIMITER ;

--
-- Create table `certificate`
--
CREATE TABLE certificate (
  CertificateID char(36) NOT NULL DEFAULT '' COMMENT 'Khóa ngoại, liên kết với bảng user(PolicyID)',
  IssuedID varchar(255) NOT NULL DEFAULT '' COMMENT 'Khóa ngoại, liên kết với bảng user(PolicyID)',
  ReceivedID varchar(255) NOT NULL DEFAULT '' COMMENT 'Khóa ngoại, liên kết với bảng user(PolicyID)',
  CertificateCode mediumint NOT NULL COMMENT 'Mã code, để hiển thị lên trang web',
  CertificateType varchar(255) NOT NULL COMMENT 'Kiểu bằng cấp (0-Education Certificate)',
  CertificateName varchar(255) NOT NULL DEFAULT '' COMMENT 'Tên bằng cấp (Bằng kỹ sư, bằng cử nhân)',
  ReceivedAddressWallet varchar(255) DEFAULT NULL COMMENT 'Dia chi vi nguoi nhan',
  ReceivedName varchar(255) DEFAULT NULL COMMENT 'Tên người nhận bằng',
  ReceivedDoB date DEFAULT NULL COMMENT 'Ngày sinh người nhận bằng',
  YearOfGraduation smallint DEFAULT NULL,
  Classification varchar(50) NOT NULL DEFAULT '' COMMENT 'Loại bằng cấp',
  ModeOfStudy varchar(255) DEFAULT NULL COMMENT 'Hình thức đào tạo (0-Chính quy tập trung, 1-Tại chức)',
  CertificateStatus tinyint DEFAULT NULL COMMENT 'Trạng thái của bằng cấp (0-Draft/1-Signed/2-Sent)',
  CreatedDate datetime DEFAULT NULL,
  IsSigned tinyint DEFAULT 0 COMMENT 'Được kí hay chưa (0-chưa kí; 1-đã kí)',
  SignedDate datetime DEFAULT NULL COMMENT 'Ngày kí',
  IsSend tinyint NOT NULL COMMENT 'Gửi bằng hay chưa (0-Chưa gửi/1-Đã gửi)',
  SentDate datetime DEFAULT NULL COMMENT 'Ngày tháng xuất/nhận bằng',
  IsDeleted tinyint DEFAULT NULL,
  PRIMARY KEY (CertificateID)
)
ENGINE = INNODB,
AVG_ROW_LENGTH = 3276,
CHARACTER SET utf8mb4,
COLLATE utf8mb4_general_ci;

--
-- Create index `FK_certificate_IssuedDID2` on table `certificate`
--
ALTER TABLE certificate
ADD INDEX FK_certificate_IssuedDID2 (IssuedID);

--
-- Create foreign key
--
ALTER TABLE certificate
ADD CONSTRAINT FK_certificate_IssuedID FOREIGN KEY (IssuedID)
REFERENCES user (PolicyID);

--
-- Create foreign key
--
ALTER TABLE certificate
ADD CONSTRAINT FK_certificate_ReceivedID FOREIGN KEY (ReceivedID)
REFERENCES user (PolicyID);

DELIMITER $$

--
-- Create procedure `proc_dashbroad_GetInfor`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_dashbroad_GetInfor (IN v_UserID nvarchar(255),
OUT v_Pending int,
OUT v_Connected int,
OUT v_Draft int,
OUT v_Signed int,
OUT v_Sent int,
OUT v_Received int)
BEGIN
  SELECT
    IFNULL(COUNT(c.ContactID), 0) INTO v_Pending
  FROM contact c
  WHERE (c.IssuedID = v_UserID
  OR c.ReceivedID = v_UserID)
  AND c.ContactStatus = 0;

  SELECT
    IFNULL(COUNT(c.ContactID), 0) INTO v_Connected
  FROM contact c
  WHERE (c.IssuedID = v_UserID
  OR c.ReceivedID = v_UserID)
  AND c.ContactStatus = 1;

  SELECT
    IFNULL(COUNT(c.IssuedID), 0) INTO v_Draft
  FROM certificate c
  WHERE (c.IssuedID = v_UserID)
  AND c.CertificateStatus = 0;

  SELECT
    IFNULL(COUNT(c.IssuedID), 0) INTO v_Signed
  FROM certificate c
  WHERE c.IssuedID = v_UserID
  AND c.CertificateStatus = 1;

  SELECT
    IFNULL(COUNT(c.IssuedID), 0) INTO v_Sent
  FROM certificate c
  WHERE c.IssuedID = v_UserID
  AND c.CertificateStatus = 2;

  SELECT
    IFNULL(COUNT(c.ReceivedID), 0) INTO v_Received
  FROM certificate c
  WHERE c.ReceivedID = v_UserID
  AND c.CertificateStatus = 2;
END
$$

--
-- Create procedure `proc_certificate_sign`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_certificate_sign (IN v_CertificateID char(36))
BEGIN
  UPDATE certificate c
  SET c.CertificateStatus = 1,
      c.IsSigned = 1,
      c.SignedDate = NOW()
  WHERE c.CertificateID = v_CertificateID;
END
$$

--
-- Create procedure `proc_certificate_send`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_certificate_send (IN v_CertificateID char(36))
BEGIN
  UPDATE certificate c
  SET c.CertificateStatus = 2,
      c.IsSend = 1,
      c.SentDate = NOW()
  WHERE c.CertificateID = v_CertificateID;
END
$$

--
-- Create procedure `proc_certificate_insert`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_certificate_insert (IN v_IssuedID varchar(255), IN v_ReceivedID varchar(255), IN v_CertificateName varchar(255), IN v_ReceivedAddressWallet varchar(255), IN v_ReceivedName varchar(255), IN v_ReceivedDoB date, IN v_Classification varchar(50), IN v_ModeOfStudy varchar(255))
BEGIN
  -- Lấy giá trị lớn nhất của user code
  DECLARE CODE mediumint;
  SELECT
    MAX(certificatecode) INTO CODE
  FROM certificate;

  -- Nếu table xxx chưa có data sẽ mặc định CODE = 100000
  IF CODE IS NULL THEN
    SET CODE = 100000;
  ELSE
    SET CODE = CODE + 1;
  END IF;

  INSERT INTO certificate
    VALUES (UUID(), v_IssuedID, v_ReceivedID, CODE, 'Education Certificate', v_CertificateName, v_ReceivedAddressWallet, v_ReceivedName, v_ReceivedDoB, YEAR(CURDATE()), v_Classification, v_ModeOfStudy, 0, -- CertificateStatus: Draft
    NOW(), -- CreatedDate: NOW
    0, -- IsSigned: Chua ki
    NULL, -- SignedDate: NULL
    0, -- IsSent: Chua gui
    NULL, -- SentDate: NULL
    0); -- IsDeleted: Chua xoa

  -- Them contact voi nguoi gui bang
  CALL proc_contact_insert(v_IssuedID, v_ReceivedID);
END
$$

--
-- Create procedure `proc_certificate_GetPagingReceived`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_certificate_GetPagingReceived (IN v_ReceivedID varchar(255),
IN v_PageSize int,
IN v_PageNumber int,
IN v_CertificateType varchar(255),
IN v_UserName varchar(255),
IN v_ReceivedDate int)
BEGIN
  DECLARE offset_page int;
  DECLARE no_results_error CONDITION FOR SQLSTATE '02000';

  -- v_PageSize and  v_PageNumber must be > 0
  IF v_PageSize <= 0 THEN
    SELECT
      'Invalid Page Size: Page Size must be greater than zero';
    SIGNAL no_results_error;
  END IF;

  IF v_PageNumber <= 0 THEN
    SELECT
      'Invalid Page Number: Page Number must be greater than zero';
    SIGNAL no_results_error;
  END IF;

  -- Offset_page is record number want to get
  SET offset_page = (v_PageNumber - 1) * v_PageSize;

  SELECT
    c.CertificateID,
    c.CertificateCode,
    c.CertificateType,
    u.UserName AS `IssuerName`,
    c.ReceivedName,
    c.CertificateName,
    c.YearOfGraduation,
    c.Classification,
    c.ModeOfStudy,
    c.SentDate AS `ReceivedDate`
  FROM certificate c
    JOIN user u
      ON c.IssuedID = u.PolicyID
  -- Check conditions
  WHERE c.ReceivedID = v_ReceivedID
  AND (u.UserName LIKE CONCAT('%', v_UserName, '%')
  OR v_UserName IS NULL)
  AND (c.CertificateType = v_CertificateType
  OR v_CertificateType IS NULL)
  AND c.IsSend = 1
  AND c.IsDeleted = 0

  -- Default sort by SentDate = ReceivedDate
  ORDER BY IF(v_ReceivedDate = 0, c.SentDate, NULL) ASC,
  IF(v_ReceivedDate = 1, c.SentDate, NULL) DESC,
  IF(v_ReceivedDate NOT IN (0, 1), c.SentDate, NULL) ASC

  LIMIT v_PageSize
  OFFSET offset_page;
END
$$

--
-- Create procedure `proc_certificate_GetPagingIssued`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_certificate_GetPagingIssued (IN v_IssuerID varchar(255),
IN v_PageSize int,
IN v_PageNumber int,
IN v_CertType varchar(100),
IN v_ReceivedName varchar(255),
IN v_SignDate int, -- 0 la tu gan den xa, 1 la tu da den gan
IN v_ContactStatus tinyint,
IN v_CertStatus tinyint)
BEGIN
  DECLARE offset_page int;
  DECLARE no_results_error CONDITION FOR SQLSTATE '02000';

  -- v_PageSize and  v_PageNumber must be > 0
  IF v_PageSize <= 0 THEN
    SELECT
      'Invalid Page Size: Page Size must be greater than zero';
    SIGNAL no_results_error;
  END IF;

  IF v_PageNumber <= 0 THEN
    SELECT
      'Invalid Page Number: Page Number must be greater than zero';
    SIGNAL no_results_error;
  END IF;

  -- Offset_page is record number want to get
  SET offset_page = (v_PageNumber - 1) * v_PageSize;

  SELECT
    c1.ContactID,
    c.CertificateID,
    c.ReceivedAddressWallet,
    c.CertificateCode,
    c.CertificateType,
    c.ReceivedName,
    c.SignedDate,
    c1.ContactStatus,
    c.CertificateStatus

  FROM certificate c
    JOIN user u
      ON c.ReceivedID = u.PolicyID
    JOIN contact c1
      ON u.PolicyID = c1.ReceivedID

  -- Check conditions
  WHERE c.IssuedID = v_IssuerID
  AND (c.ReceivedName LIKE CONCAT('%', v_ReceivedName, '%')
  OR v_ReceivedName IS NULL)
  AND (c.CertificateType = v_CertType
  OR v_CertType IS NULL)
  AND (c1.ContactStatus = v_ContactStatus
  OR v_ContactStatus IS NULL)
  AND (c.CertificateStatus = v_CertStatus
  OR v_CertStatus IS NULL)
  AND c.IsDeleted = 0

  -- Default sort by CreatedDate
  ORDER BY IF(v_SignDate = 0, c.SignedDate, NULL) ASC,
  IF(v_SignDate = 1, c.SignedDate, NULL) DESC,
  IF(v_SignDate NOT IN (0, 1), c.CreatedDate, NULL) ASC

  LIMIT v_PageSize
  OFFSET offset_page;

END
$$

--
-- Create procedure `proc_certificate_delete`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_certificate_delete (IN v_CertificateID char(36))
BEGIN
  UPDATE certificate c
  SET c.IsDeleted = 1
  WHERE c.CertificateID = v_CertificateID;
END
$$

--
-- Create procedure `proc_user_insert`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_user_insert (IN v_PolicyID varchar(255),
IN v_UserName varchar(255),
IN v_Logo varchar(255))
COMMENT 'Procedure thêm mới 1 nguoi dung'
BEGIN
  -- Lấy giá trị lớn nhất của user code
  DECLARE CODE mediumint;
  SELECT
    MAX(UserCode) INTO CODE
  FROM user;

  -- Nếu table xxx chưa có data sẽ mặc định CODE = 100000
  IF CODE IS NULL THEN
    SET CODE = 100000;
  ELSE
    SET CODE = CODE + 1;
  END IF;

  INSERT INTO user
    VALUES (v_PolicyID, CODE, v_UserName, v_Logo, NOW(), 0);
END
$$

--
-- Create procedure `proc_user_delete`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_user_delete (IN v_PolicyID varchar(255))
COMMENT 'Xóa 1 người dùng'
BEGIN
  UPDATE user u
  SET u.IsDeleted = 1
  WHERE u.PolicyID = v_PolicyID;
END
$$

--
-- Create procedure `proc_certificate_DeleteMultiple`
--
CREATE DEFINER = 'root'@'localhost'
PROCEDURE proc_certificate_DeleteMultiple (IN v_CertificateIDs text)
BEGIN
  SET @v_CertificateIDs = REPLACE(v_CertificateIDs, ',', ''',''');

  SET @Query = CONCAT('UPDATE certificate SET isDeleted = 1 WHERE CertificateID IN (''', @v_CertificateIDs, ''');');

  PREPARE deleteQueryStatement FROM @Query;
  EXECUTE deleteQueryStatement;

  DEALLOCATE PREPARE deleteQueryStatement;
END
$$

DELIMITER ;

-- 
-- Dumping data for table user
--
INSERT INTO user VALUES
('146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 100000, 'University of Transport and Communications', 'UTC.jpg', '2023-03-10 12:08:12', 0),
('bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e25', 100002, 'Trinh Xuan Bach', 'student+Code.jpg', '2023-03-10 12:08:12', 0),
('bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e26', 100003, 'Le Duc An', 'student+Code.jpg', '2023-03-10 12:08:12', 0),
('bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e27', 100004, 'Le Duc Binh', 'student+Code.jpg', '2023-03-10 12:08:12', 0),
('bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e28', 100005, 'Le Thi Mai', 'student+Code.jpg', '2023-03-10 12:08:12', 0),
('bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e29', 100006, 'He he he', 'kakaka', '2023-03-10 15:11:13', 0),
('d9312da562da182b02322fd8acb536f37eb9d29fba7c49dc17255527', 100001, 'Tran Huy Hiep', 'student+Code.jpg', '2023-03-10 12:08:12', 0);

-- 
-- Dumping data for table contact
--
INSERT INTO contact VALUES
('94b35923-c08e-11ed-8713-54e1ad6c2368', 100000, '146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 'd9312da562da182b02322fd8acb536f37eb9d29fba7c49dc17255527', 1, '2023-03-12 11:30:13', 0),
('94b897ba-c08e-11ed-8713-54e1ad6c2368', 100001, '146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 'bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e25', 1, '2023-03-12 11:30:13', 0),
('94bc47ac-c08e-11ed-8713-54e1ad6c2368', 100002, '146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 'bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e26', 1, '2023-03-12 11:30:13', 0),
('94bf20ee-c08e-11ed-8713-54e1ad6c2368', 100003, '146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 'bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e27', 0, '2023-03-12 11:30:13', 0),
('94c260e0-c08e-11ed-8713-54e1ad6c2368', 100004, '146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 'bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e28', 0, '2023-03-12 11:30:13', 0);

-- 
-- Dumping data for table certificate
--
INSERT INTO certificate VALUES
('94b0652e-c08e-11ed-8713-54e1ad6c2368', '146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 'd9312da562da182b02322fd8acb536f37eb9d29fba7c49dc17255527', 100000, 'Education Certificate', 'The Degree Of Engineer', 'addr_test1qq68a8hxmz6x295epvy5tluak0z3z9uxfk0yqsepnragz33ka2gm6amddyamqjt2agngj8s8vhzhf5hm6jsgmw5umvuqx9u8hh', 'Tran Huy Hiep', '2023-03-12', 2023, 'Good', 'Full-time', 2, '2023-03-12 11:30:13', 1, '2023-03-12 11:31:42', 1, '2023-03-12 11:31:42', 0),
('94b76a3b-c08e-11ed-8713-54e1ad6c2368', '146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 'bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e25', 100001, 'Education Certificate', 'The Degree Of Engineer', 'addr_test1qqhhtnqp0jwgtfryrpql5se9f9q0cctzcmk5x70slddwcf3x66wapyaagku48pfgu6njmsm98ml9kcu3xr2uffyhl8cq4h3zdr', 'Trinh Xuan Bach', '2023-03-12', 2023, 'Good', 'Full-time', 1, '2023-03-12 11:30:13', 1, '2023-03-12 11:31:42', 0, NULL, 0),
('94ba7696-c08e-11ed-8713-54e1ad6c2368', '146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 'bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e26', 100002, 'Education Certificate', 'The Degree Of Engineer', 'addr_test1qqhhtnqp0jwgtfryrpql5se9f9q0cctzcmk5x70slddwcf3x66wapyaagku48pfgu6njmsm98ml9kcu3xr2uffyhl8cq4h3zdt', 'Le Duc An', '2000-09-04', 2023, 'Excellent', 'Part-time', 0, '2023-03-12 11:30:13', 0, NULL, 0, NULL, 0),
('94bdae59-c08e-11ed-8713-54e1ad6c2368', '146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 'bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e27', 100003, 'Education Certificate', 'The Degree Of Bachelor', 'addr_test1qqhhtnqp0jwgtfryrpql5se9f9q0cctzcmk5x70slddwcf3x66wapyaagku48pfgu6njmsm98ml9kcu3xr2uffyhl8cq4h3zdy', 'Le Duc Binh', '1999-10-04', 2023, 'Excellent', 'Full-time', 0, '2023-03-12 11:30:13', 0, NULL, 0, NULL, 0),
('94c0b022-c08e-11ed-8713-54e1ad6c2368', '146d28b014f87920fa81c3b91007606d03ce0376c365befb5a3df1f7', 'bf1f5570841b4ee812dc49e6111ba402813d19b3e1f8ec1e94ca9e28', 100004, 'Education Certificate', 'The Degree Of Bachelor', 'addr_test1qqhhtnqp0jwgtfryrpql5se9f9q0cctzcmk5x70slddwcf3x66wapyaagku48pfgu6njmsm98ml9kcu3xr2uffyhl8cq4h3zdu', 'Le Thi Mai', '1999-11-04', 2023, 'Good', 'Part-time', 0, '2023-03-12 11:30:13', 0, NULL, 0, NULL, 0);

-- 
-- Restore previous SQL mode
-- 
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;

-- 
-- Enable foreign keys
-- 
/*!40014 SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS */;