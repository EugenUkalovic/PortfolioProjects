--Rows = 56477
select *
from Projects.dbo.NashvilleHousing
order by [UniqueID ]

select PropertyAddress, SaleDate, SalePrice
from Projects.dbo.NashvilleHousing
where PropertyAddress is null


/**************************************************************************************************************************************************************************************/

--------- Standardise Date Format -------------------------

--Using Convert

Select SaleDate, CONVERT(date,SaleDate)
from Projects.dbo.NashvilleHousing

-- Using Cast (*preferred) --

Select CAST(saledate as date) as saledate
from Projects.dbo.NashvilleHousing

-- Update date format in the database --

ALTER TABLE  NashvilleHousing
Add SaleDateConverted Date;

Update Projects.dbo.NashvilleHousing
SET SaleDateConverted = CAST(SaleDate as date)

/**************************************************************************************************************************************************************************************/

-----------------------------------------------------      Populate NULLs in Address column      ----------------------------------------------------------------------
													  -- try with a temp table   
-- Check the Property Address NULLs
-- 29 rows

Select [UniqueID ], ParcelID, PropertyAddress
from Projects.dbo.NashvilleHousing
where PropertyAddress is null

---------- Method 1 ----------

-- 1. Join table to itself

Select a.ParcelID, a.PropertyAddress, b.ParcelID, ISNULL(a.PropertyAddress, b.PropertyAddress)
		from Projects.dbo.NashvilleHousing a
left join Projects.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

--2. Update the table
	-- Run this table then run the table above to check

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from Projects.dbo.NashvilleHousing a
left join Projects.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

---------------------------------------------------------------------------------------------------------------

-- ANother way of getting the same result as above

Select a.[UniqueID ] , a.ParcelID, a.PropertyAddress, b.[UniqueID ], b.ParcelID, b.PropertyAddress
		from Projects.dbo.NashvilleHousing a
left join (select [UniqueID ], ParcelID, PropertyAddress
		from
		Projects.dbo.NashvilleHousing) b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


---------- Method 2 ----------

-- This method does not alter the original table in the database

-- 1. Create CTE table, and row numbers partitioned by ParcelID. This table will then be joined to the Nashville housing table.


With CTE_PropAddress as
(Select ParcelID, PropertyAddress,
	ROW_NUMBER() OVER (
	Partition by ParcelID
	Order By ParcelID) row_num
from Projects.dbo.NashvilleHousing
--where PropertyAddress is not NULL
)

-- Check the number of rows (should be < the original data)

--select *
--from CTE_PropAddress
--where row_num = 1

-- 2. Create table with the CTE table joined
--    (Highlight the CTE and the code below to run)

Select t1.[UniqueID ], t1.ParcelID, t1.PropertyAddress, T2.ParcelID, T2.PropertyAddress
From Projects.dbo.NashvilleHousing T1
Left Join CTE_PropAddress T2 on
			T1.ParcelID = t2.ParcelID
Where T2.row_num = 1
		--AND t1.PropertyAddress is null

---------------------------------------------------------------------------------------------------------------

-- Breaking out address into individual columns (Address, City, State)

-- 1. Look at the Property address column 

Select PropertyAddress
From Projects.dbo.NashvilleHousing

-- 2. Remove the last string after the comma
      -- a. Write out the query to check if it works
Select
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address  --------> The reason to include the -1 is so the output does not include the comma.
	, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) as AddressCity --------> The charindex is where we want it to start. The reason to include the +1 is so the output does not include the comma.
From Projects.dbo.NashvilleHousing

     -- b. Alter the table with the above query.

Alter TABLE Projects.dbo.NashvilleHousing
Add PropertySplitAddress Nvarchar (255);

Update Projects.dbo.NashvilleHousing
SET PropertySplitAddress =  SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


Alter TABLE NashvilleHousing
Add PropertySplitCity Nvarchar (255);

Update Projects.dbo.NashvilleHousing
SET PropertySplitCity =  SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN (PropertyAddress))


-- Part 2 - Breaking out owner address using PARSENAME. This is easier than substring

-- 1. Look at the Owner address column 

Select OwnerAddress
From Projects.dbo.NashvilleHousing

-- 2. Split out the Owner address using Pasrsename (used when strings are delimited)
Select
PARSENAME(REPLACE(OwnerAddress, ',','.'),3) -----> Parse recognises only '.' so will need to replace comma with '.' Also parse start from, right to left
,PARSENAME(REPLACE(OwnerAddress, ',','.'),2)
,PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
From Projects.dbo.NashvilleHousing


     -- b. Alter the table with the above query.

Alter TABLE Projects.dbo.NashvilleHousing
Add OwnerSplitAddress Nvarchar (255);

Update Projects.dbo.NashvilleHousing
SET OwnerSplitAddress =  PARSENAME(REPLACE(OwnerAddress, ',','.'),3)


Alter TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar (255);

Update Projects.dbo.NashvilleHousing
SETOwnerSplitCity =  PARSENAME(REPLACE(OwnerAddress, ',','.'),2)

Alter TABLE NashvilleHousing
Add OwnerSplitState Nvarchar (255);

Update Projects.dbo.NashvilleHousing
SETOwnerSplitState =  PARSENAME(REPLACE(OwnerAddress, ',','.'),2)

-- Part 3. Change Y and N to Yes and No in "Sold as Vacant" field

-- 1. Check all the cells contents

select Distinct(SoldAsVacant), count(SoldAsVacant)
From Projects.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2

-- 2. Change Y & N to 'Yes & 'No' using case statement

Select SoldAsVacant
, CASE when SoldAsVacant = 'Y' then 'Yes'
	   when SoldAsVacant = 'N' then 'No'
	   ELSE SoldAsVacant
	   End 
From Projects.dbo.NashvilleHousing
--where SoldAsVacant = 'Y'               -----> Check it worked

-- 3. Update Database table
UPDATE Projects.dbo.NashvilleHousing
	SET SoldAsVacant = 
	   CASE when SoldAsVacant = 'Y' then 'Yes'
	   when SoldAsVacant = 'N' then 'No'
	   ELSE SoldAsVacant
	   End 

-- Part 4. Remove Duplicates

Select *
From Projects.dbo.NashvilleHousing


WITH RowNumCTE AS (
Select*,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				 ) row_num

From Projects.dbo.NashvilleHousing
)

select *
from 
RowNumCTE


-- Delete the duplicates

DELETE
From RowNumCTE
Where row_num > 1


-- Check that no more duplicates exist

Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress


-- Part 5. Delete Unused columns

Select *
From Projects.dbo.NashvilleHousing

ALTER TABLE Projects.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PopertyAddress, SaleDate

-- **Complete the ETL part of this project** (Snapshot in projects folder) --
