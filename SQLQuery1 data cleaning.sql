select *
from PortfolioProject..nashvile_realestate
order by 1

--standardize date format
select saledate, convert(date,saledate)
from PortfolioProject..nashvile_realestate 


--populate the  null address 

select a.parcelId, a.propertyAddress, b.parcelId, b.propertyAddress, ISNULL (a.propertyAddress, b.propertyAddress)
from PortfolioProject..nashvile_realestate a
join PortfolioProject..nashvile_realestate b
ON a.parcelid = b.parcelid
    AND a.uniqueid <> b.uniqueid
where a.propertyAddress is null

update a
Set PropertyAddress = ISNULL (a.propertyAddress, b.propertyAddress)
from PortfolioProject..nashvile_realestate a
join PortfolioProject..nashvile_realestate b
ON a.parcelid = b.parcelid
    AND a.uniqueid <> b.uniqueid
where a.propertyAddress is null

--beaking property address into individual columns 

select 
substring(propertyAddress, 1, charindex(',', propertyAddress)-1) as Address,
substring(propertyAddress, charindex(',', propertyAddress)+1, len(propertyAddress)) as City
from PortfolioProject..nashvile_realestate


select 
parsename(replace(OwnerAddress, ',', '.'), 3),
parsename(replace(OwnerAddress, ',', '.'), 2),
parsename(replace(OwnerAddress, ',', '.'), 1)
from PortfolioProject..nashvile_realestate 


--change y to yes and n to no 

select SoldAsVacant,
case when soldasvacant = 'y' then 'Yes'
     when soldasvacant = 'n' then 'No'
	 else soldasvacant
	 end
from PortfolioProject..nashvile_realestate 

Update PortfolioProject..nashvile_realestate
Set soldasvacant = case when soldasvacant = 'y' then 'Yes'
     when soldasvacant = 'n' then 'No'
	 else soldasvacant
	 end

--Alter table

Alter table PortfolioProject..nashvile_realestate
Add sale_Date date;

ALTER TABLE PortfolioProject..nashvile_realestate
ADD 
    Property_Address NVARCHAR(255),
    Property_City NVARCHAR(255),
    Owner_Address NVARCHAR(255),
    Owner_City NVARCHAR(255),
    Owner_State NVARCHAR(255);


UPDATE PortfolioProject..nashvile_realestate
SET 
    Sale_Date = CONVERT(date, saledate),
    Property_Address = SUBSTRING(propertyAddress, 1, CHARINDEX(',', propertyAddress) - 1),
    Property_City = SUBSTRING(propertyAddress, CHARINDEX(',', propertyAddress) + 1, LEN(propertyAddress)),
    Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    Owner_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    Owner_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


--Remove Duplicate

with RowNumCTE as (
select*,
     Row_Number() over (
	 partition by parcelId,
	              propertyAddress,
				  salePrice,
				  saleDate,
				  legalReference
				  order by 
				    uniqueID
					) row_num
from PortfolioProject..nashvile_realestate 
)

select*
from RowNumCTE
where roe_num > 1
order by propertyAddress


--delete unused columns

Select *
from PortfolioProject..nashvile_realestate 

Alter table PortfolioProject..nashvile_realestate 
Drop column owneraddress, taxdistrict, propertyaddress, saledate


