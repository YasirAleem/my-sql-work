with data as(
SELECT  * FROM (   
                SELECT   id,item_name, sku, confirmationDate,category, sum(quantity) as quantity, ROW_NUMBER() OVER (PARTITION BY id ORDER BY confirmationDate DESC) as rank
                FROM     {{snippet: Commercials - All Query (Categories)}} as mt
                where app_status in ('confirmed', 'delivered') 
                GROUP BY 1, 2,3,4,5
                )a 
WHERE rank <= 30 AND item_name NOT LIKE ('Delist%')  

),sale30days as (
SELECT  id,item_name, sku, SUM(quantity) "30_Days_Sale", MIN(confirmationDate) AS min_date, MAX(confirmationDate) AS max_date FROM data 
WHERE rank <= 30 AND item_name NOT LIKE ('Delist%') 
GROUP BY 1,2,3      

),sale15days as (
SELECT  id,item_name, sku, SUM(quantity) "15_Days_Sale", MIN(confirmationDate) AS min_date, MAX(confirmationDate) AS max_date FROM data
WHERE rank <= 15 AND item_name NOT LIKE ('Delist%') 
GROUP BY 1,2,3  

),sale7days as (
SELECT  id,item_name, sku, SUM(quantity) "7_Days_Sale", MIN(confirmationDate) AS min_date, MAX(confirmationDate) AS max_date FROM data
WHERE rank <= 7 AND item_name NOT LIKE ('Delist%') 
GROUP BY 1,2,3  

),gm5 as            (select p.id, left(p.name, length(p.name)-7) name, p.sku                      from product p left join "productCategory" pc on pc."productId" = p.id where "categoryId" in (17)  and position(' 500 gm' in p.name) > 0 or p.name like ('Cheeni%')  and p.name not like 'HUB%'
and p.name not like 'Lal Masoor%' and p.name not like 'Moong Daal%' and p.name not like 'Kala Chana%' and p.name not like 'Daal Channa%' and p.name not like 'Basian%'and p.name not like 'Bake Parlor%'

),kg1 as            (select p.id,left(p.name, length(p.name)-5) name, p.sku                       from product p where p.name not like ('Delist %%') and position(' 1 kg' in p.name) > 0  and p.name not like 'HUB%'
and p.name not like 'Lal Masoor%' and p.name not like 'Moong Daal%' and p.name not like 'Kala Chana%' and p.name not like 'Daal Channa%' and p.name not like 'Basian%' and p.name not like 'Bake Parlor%'

),parentskutable as (select kg1.name pname, kg1.sku psku,kg1.id pid, gm5.name name, gm5.id id     from kg1     left join gm5 on gm5.name = kg1.name where gm5.sku is not null 
),cd as             (select * from "productCategory" pc left join product p on pc."productId" = p.id where "categoryId" in (67) and pc."deletedAt" is null and (p.name  like ('%250 ml%') or p.name  like ('%345 ml%') or p.name  like ('%350 ml%') or p.name  like ('%300 ml%') or p.name  like ('%330 ml%') or p.name  like ('%500 ml%') or p.name  like ('%355 ml%') or p.name  like ('%200 ml%') or p.name  like ('%1 Litre%')) and p.name not like ('Delist%') and p.name not like 'HUB%'
),doodh as          ( select * from "productCategory" pc left join product p on pc."productId" = p.id where "categoryId" in (14) and pc."deletedAt" is null and p.name not like 'HUB%'

-- ) select * from parentskutable
),producttable as (
select case when p.id in (parentskutable.id) then parentskutable.psku 
            -- when p.name like ('Cheeni%') then 'ANCH0020'
            -- when p.name like ('Bajra %') then 'ANBJ0126' 
            when p.id in (cd."productId") then p.sku
            when p.id in (doodh."productId") then p.sku
            else split_part(p.sku, '-', 1) end as parentsku,
cast(case   when (position(' 500 gm' in p.name) > 0 and (position('Daal' in p.name) > 0 or  position('Chana' in p.name) > 0 or position('Lobiya' in p.name) > 0 or position('Channa' in p.name) > 0 or position('Baisan' in p.name) > 0 or position('Daliya' in p.name) > 0 or position('Masoor' in p.name) > 0) 
            and p.name not like 'Lal Masoor%' and p.name not like 'Moong Daal%' and p.name not like 'Kala Chana%' and p.name not like 'Daal Channa%' and p.name not like 'Basian%' and p.name not like 'Bake Parlor%'
            ) then '0.5' 
            when position('-' in p.sku) > 0 then reverse(split_part(reverse(p.sku), '-', 1)) 
            when p.name like ('Cheeni %') then split_part(p.name, ' ', 2)
            when p.name like ('Bajra %') then split_part(p.name, ' ', 2)
            else '1' end as float) packsize,
            i."purchasePrice" buying_price,
            g."discountedPrice" selling_price,
            p.*
from product p
left join (select * from product where name like ('%500 gm') and name not like 'HUB%') pp on pp.id = p.id
left join parentskutable on parentskutable.id = p.id
left join cd on cd."productId" = p.id
left join doodh on doodh."productId" = p.id
left join "inventory" i on i."productId" = p.id
left join "groupRange" g on g."productId" = p.id
where p.name not like ('Delist%') and  p.name not like ('Cheeni 3kg %%') and  p.name not like ('Flash%%') and p.name not like 'HUB%'
-- and p.name like '%Daal%'
--  and  p.name like ('Nestle Everyday Instant Tea Mix (Kashmiri Chai) Sachet 18 gm (1x2)%')

) 

-- select * from producttable

,mastertable as (
select p.id,p.name,p.sku,
case when parentsku not in (select sku from product where  name not like ('%500 gm') and name not like ('Flash%%') and name not like 'HUB%' and name not like 'Delist%') then p.sku else parentsku end as parentsku,
-- parentsku,
p.packsize, p.status,buying_price/p.packsize bp, selling_price/p.packsize sp,
SUM(t."30_Days_Sale")   last_30days_sale, SUM(f."15_Days_Sale")   last_15days_sale,SUM(s."7_Days_Sale")  last_7days_sale,
(SUM(t."30_Days_Sale") * packsize ) total_last_30days_sale, (SUM(f."15_Days_Sale") * packsize ) total_last_15days_sale,(SUM(s."7_Days_Sale") * packsize ) total_last_7days_sale
from producttable p
left join sale30days t on t.id = p.id
left join sale15days f on f.id = p.id
left join sale7days s on s.id = p.id
group by 1,2,3,4,5,6,7,8)
--  select * from mastertable 

,categorytable as (
select c.name as category, m.* from mastertable m
left join "productCategory" pc on pc."productId" = m.id
left join category c on c.id = pc."categoryId"
where c.id in (4,5,6,7,8,14,16,17,18,20,23,29,58,61,67,103,113,153,158,187,210) and pc."deletedAt" is null 
order by 1,3)
-- select * from categorytable 


,salestable as (
select 
s.category, --p.name, 
-- case when category like 'Dairy%' then s.name else p.name end as name,
p.name,
p.sku,
s.parentsku,bp, sp,sum(total_last_30days_sale) last_30days_units_sold, sum(total_last_15days_sale)last_15days_units_sold, sum(total_last_7days_sale)last_7days_units_sold
from   categorytable s 
left join product p   on p.sku = s.parentsku where p.name not like ('Delist%') and p.name not like 'HUB%'
-- where s.category like ('Dairy%')
group by 1,2,3,4,5,6
)
-- select * from salestable --where category is not null


,finaltable as (
select distinct category, 
case when category like ('Mashr%') or category like ('Dairy%') or category like ('Snack%') then split_part(name, ' (', 1) else min(name) end as name,
case when category like ('Dairy%') or category like ('Snack%') then split_part(parentsku, '-', 1) 
     when category like ('Mashr%') and parentsku like ('%%-2') then concat(split_part(parentsku, '-', 1) ,'-12')
     when name like ('Fuzetea%') then split_part(parentsku, '-', 1) 
    --  parentsku like 'CDSR0133-2' then 'CDSR0133-12'
else parentsku end as parentsku,
avg(bp) bp,
MIN(sp) sp,
sum(last_30days_units_sold) last_30days_units_sold , sum(last_15days_units_sold) last_15days_units_sold,sum(last_7days_units_sold) last_7days_units_sold
from salestable
group by 1,3,name)
-- select * from finaltable

select category, 
case when name like '%% (1x%%' then split_part(name, ' (1x', 1) else name end as name, 
case when category like ('Mashr%') then split_part(parentsku, '-', 1) 
     when parentsku like '%%-%%' then split_part(parentsku, '-', 1) 
else parentsku end as parentsku, 

sum(last_30days_units_sold) last_30days_units_sold , sum(last_15days_units_sold) last_15days_units_sold,sum(last_7days_units_sold) last_7days_units_sold, 
avg(bp) bp,min(sp) sp
from finaltable 
where parentsku not in (
'Mezan_Tea_Ultra_Rich_Pouch_950g_x_6_+_Olper_1.5_ltr_free',		
'Brite_Maximum_Power_500gm',		
'Hilal_Cooking_Oil_1_Litre_(Buy_12_Cartons,_Get_1_Carton_Free)',		
'Shahtaj_Cooking_Oil_1Ltr',
'Lifebuoy_Herbal_Soap_133gm'		
)
and name not like ('Bundle%') and name not like 'HUB%'
-- and name like ('Fuzetea Lemon Flavor 250 ml%')
group by 1,2,3
