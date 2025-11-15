/********************************************************************************************
    PROJECT: Nashville Housing Data Cleaning
    DATABASE: PortfolioProject
    TABLE: nashvile_realestate

    DESCRIPTION:
    ---------------------------------------------------------
    This SQL script performs a complete data cleaning process 
    for the Nashville Housing dataset. The main objectives are:
        1. Standardize date formats.
        2. Populate missing property addresses.
        3. Split combined address fields into multiple columns.
        4. Standardize categorical data values (e.g., 'Y' → 'Yes').
        5. Add new, clean columns to the dataset.
        6. Identify and handle duplicate records.
        7. Drop unused or redundant columns after cleaning.

    AUTHOR: [Your Name]
    DATE EXECUTED: [Insert Date]
********************************************************************************************/

-- ======================================================
-- 1. View all records in the table
-- ======================================================
SELECT *
FROM PortfolioProject..nashvile_realestate
ORDER BY 1;


-- ======================================================
-- 2. Standardize Date Format
--    Convert 'SaleDate' from text to proper DATE type
-- ======================================================
SELECT 
    SaleDate, 
    CONVERT(date, SaleDate) AS StandardizedDate
FROM PortfolioProject..nashvile_realestate;


-- ======================================================
-- 3. Populate NULL PropertyAddress values
--    Fill in missing addresses based on matching ParcelID
-- ======================================================
SELECT 
    a.ParcelId, 
    a.PropertyAddress, 
    b.ParcelId, 
    b.PropertyAddress, 
    ISNULL(a.PropertyAddress, b.PropertyAddress) AS PopulatedAddress
FROM PortfolioProject..nashvile_realestate a
JOIN PortfolioProject..nashvile_realestate b
    ON a.ParcelId = b.ParcelId
   AND a.UniqueId <> b.UniqueId
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..nashvile_realestate a
JOIN PortfolioProject..nashvile_realestate b
    ON a.ParcelId = b.ParcelId
   AND a.UniqueId <> b.UniqueId
WHERE a.PropertyAddress IS NULL;


-- ======================================================
-- 4. Split PropertyAddress into 'Address' and 'City'
-- ======================================================
SELECT 
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..nashvile_realestate;


-- ======================================================
-- 5. Split OwnerAddress into 'Address', 'City', and 'State'
-- ======================================================
SELECT 
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Owner_Address,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS Owner_City,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS Owner_State
FROM PortfolioProject..nashvile_realestate;


-- ======================================================
-- 6. Standardize 'SoldAsVacant' values
--    Convert 'Y'/'N' to 'Yes'/'No'
-- ======================================================
SELECT 
    SoldAsVacant,
    CASE 
        WHEN SoldAsVacant = 'y' THEN 'Yes'
        WHEN SoldAsVacant = 'n' THEN 'No'
        ELSE SoldAsVacant
    END AS UpdatedSoldAsVacant
FROM PortfolioProject..nashvile_realestate;

UPDATE PortfolioProject..nashvile_realestate
SET SoldAsVacant = CASE 
                       WHEN SoldAsVacant = 'y' THEN 'Yes'
                       WHEN SoldAsVacant = 'n' THEN 'No'
                       ELSE SoldAsVacant
                   END;


-- ======================================================
-- 7. Add new columns for cleaned data
-- ======================================================
ALTER TABLE PortfolioProject..nashvile_realestate
ADD Sale_Date DATE;

ALTER TABLE PortfolioProject..nashvile_realestate
ADD 
    Property_Address NVARCHAR(255),
    Property_City NVARCHAR(255),
    Owner_Address NVARCHAR(255),
    Owner_City NVARCHAR(255),
    Owner_State NVARCHAR(255);


-- ======================================================
-- 8. Populate new columns with transformed data
-- ======================================================
UPDATE PortfolioProject..nashvile_realestate
SET 
    Sale_Date = CONVERT(date, SaleDate),
    Property_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    Property_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)),
    Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    Owner_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    Owner_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


-- ======================================================
-- 9. Identify duplicate records
-- ======================================================
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelId,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM PortfolioProject..nashvile_realestate
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;


-- ======================================================
-- 10. Drop unused columns after transformation
-- ======================================================
SELECT *
FROM PortfolioProject..nashvile_realestate;

ALTER TABLE PortfolioProject..nashvile_realestate 
DROP COLUMN 
    OwnerAddress, 
    TaxDistrict, 
    PropertyAddress, 
    SaleDate;
