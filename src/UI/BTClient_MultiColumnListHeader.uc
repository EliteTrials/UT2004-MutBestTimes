class BTClient_MultiColumnListHeader extends GUIMultiColumnListHeader;

/** Draws all header columns of @MyList. */
function bool InternalOnDraw( Canvas C )
{
	local int i;
	local float x, y, xl, yl;
	local eMenuState MState;
	local float isNotLast;

	x = ActualLeft();
	y = ActualTop();
	yl = ActualHeight();
	for( i = 0; i < MyList.ColumnWidths.Length; ++ i )
	{
		isNotLast = float(i != MyList.ColumnWidths.Length-1);
		if( MyList.SortColumn == i )
		{
			MState = MSAT_Focused;
		}
		else
		{
			MState = MSAT_Blurry;
		}
		xl = MyList.ColumnWidths[i] - 4*isNotLast;
		Style.Draw( C, MState, x, y, xl, yl );
		Style.DrawText( C, MState, x + 2, y, xl - 4, yl, TXTA_Left, MyList.ColumnHeadings[i], FontScale );
		x += MyList.ColumnWidths[i];
	}
	return true;
}

defaultproperties
{
	StyleName="BTSectionHeaderTop"
	OnDraw=InternalOnDraw
	FontScale=FNS_Medium
}