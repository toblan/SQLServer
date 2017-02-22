with lagerbestand as
(	select il.[Item No_], sum(il.Quantity) as Menge
	From [urban_NAV600_SL].[dbo].[Urban-Brand GmbH$Item Ledger Entry] as il with (NOLOCK)
	Group by il.[Item No_]),
maxpostSales as
(   select il.[Item No_], max(il.[Posting Date]) as MaxDate
	From [urban_NAV600_SL].[dbo].[Urban-Brand GmbH$Item Ledger Entry] as il with (NOLOCK)
	Where [Entry Type] = 1 and [Source No_] NOT IN ('D1364500','D1164626','D1563736','D1113531','D1434457') 
	Group by il.[Item No_]), 
maxpostPurch as
(	select il.[Item No_], min(il.[Posting Date]) as MaxDate
	From [urban_NAV600_SL].[dbo].[Urban-Brand GmbH$Item Ledger Entry] as il with (NOLOCK)
	Where [Entry Type] = 0 and [Source No_] NOT IN ('70311','70611','70833')
	Group by il.[Item No_])

select  il.[No_], best.Menge, 
(isnull(maxpostSales.MaxDate,maxpostPurch.MaxDate) )as relDate,
datediff(day,isnull(maxpostSales.MaxDate,maxpostPurch.MaxDate), GETDATE()) as DateDiffrelDate, 
it.[Unit Cost] * best.Menge as Lagerwert, 
it.[Attribute 2]
From [urban_NAV600_SL].[dbo].[Urban-Brand GmbH$Item] as il with (NOLOCK)
Left Join [urban_NAV600_SL].[dbo].[Urban-Brand GmbH$Item] as it (NOLOCK) on il.[No_] = it.No_
Left Join  lagerbestand as best on best.[Item No_] = il.[No_]
Left Join maxpostSales on maxpostSales.[Item No_] = il.[No_]
left Join maxpostPurch on maxpostPurch.[Item No_] = il.No_

Where  best.Menge <> 0 and datediff(day,isnull(maxpostSales.MaxDate,maxpostPurch.MaxDate), GETDATE()) > 270