SELECT TOP (1000) [UniqueID] -- This is what gets run automatically when right clicking the table in the Object Viewer, and clicking "Select Top 1000"
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[Acreage]
      ,[TaxDistrict]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
  FROM [master].[dbo].[NashvilleHousing]

-- Convert Date Column from "month day, year" to "yyyy-mm-dd"

SELECT SaleDate from [NashvilleHousing]

UPDATE [NashvilleHousing]
SET SaleDate = CONVERT(Date, SaleDate)

-- Effectively Removing the Null Values from Property Addresses 
-- (if they have the same Parcel ID as an entry with a Property Address, use that Property Address)

SELECT *
FROM [NashvilleHousing]
-- WHERE PropertyAddress is null
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [NashvilleHousing] a
JOIN [NashvilleHousing] b 
    on a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [NashvilleHousing] a
JOIN [NashvilleHousing] b
    on a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

--Split Property Addresses into separate columns (Address, City) THESE BLOCKS MUST BE RUN ONE AT A TIME

SELECT PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2),
PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1)
FROM [NashvilleHousing]
-- WHERE PropertyAddress is null

ALTER TABLE [dbo].[NashvilleHousing]
ADD PropertySplitAddress NVARCHAR(255)

UPDATE [dbo].[NashvilleHousing]
SET PropertySplitAddress = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2)

ALTER TABLE [dbo].[NashvilleHousing]
ADD PropertySplitCity NVARCHAR(255)

UPDATE [dbo].[NashvilleHousing]
SET PropertySplitCity = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1)

--Same for Owner Address (Address, City, State)

ALTER TABLE [dbo].[NashvilleHousing]
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE [dbo].[NashvilleHousing]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE [dbo].[NashvilleHousing]
ADD OwnerSplitCity NVARCHAR(255)

UPDATE [dbo].[NashvilleHousing]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE [dbo].[NashvilleHousing]
ADD OwnerSplitState NVARCHAR(255)

UPDATE [dbo].[NashvilleHousing]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--Change sold as vacent "Y/N"s to "Yes/No"s

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM [dbo].[NashvilleHousing]
GROUP BY SoldAsVacant

SELECT SoldAsVacant,
    CASE WHEN SoldAsVacant='Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM [NashvilleHousing]

UPDATE [NashvilleHousing]
SET SoldAsVacant = CASE WHEN SoldAsVacant='Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END

--


--REMOVING DUPLICATES


WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference
    ORDER BY
    UniqueID
    ) row_num

FROM [NashvilleHousing]
)
-- The above code selects all of the rows deemed to be duplicates, the below line deletes all of them (must run both at same time for it to work).

DELETE  --after running this, this can be changed to SELECT *, run again, and then no entries are returned. This confirms that the duplicate rows have been deleted.
FROM RowNumCTE
WHERE row_num > 1

--REMOVING UNUSED COLUMNS (some columns such as OwnerAddress and TaxDistrict look relatively unusable)
ALTER TABLE [NashvilleHousing]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress --Property Address was also redundant



