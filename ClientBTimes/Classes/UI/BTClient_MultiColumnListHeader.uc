class BTClient_MultiColumnListHeader extends GUIMultiColumnListHeader;

var() array<Material> HeadingIcons;

/** Draws all header columns of @MyList. */
function bool InternalOnDraw( Canvas C )
{
	local int i;
	local float x, y, xl, yl, iconXL, textYL;
	local eMenuState MState;
	local float isNotLast;
	local byte lastStyle;

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
		if( i < HeadingIcons.Length && HeadingIcons[i] != none )
		{
			Style.TextSize( C, MState, "T", iconXL, textYL, FontScale );
	        iconXL = HeadingIcons[i].MaterialUSize()/HeadingIcons[i].MaterialVSize()*textYL;
	        C.SetPos( x + xl - iconXL - 2/**cellspacing*/, y + yl*0.5 - textYL*0.5 );
	        C.DrawColor = class'HUD'.default.WhiteColor;
	        lastStyle = C.Style;
            C.Style = 1;
	        C.DrawTile( HeadingIcons[i], iconXL, textYL, 0, 0, HeadingIcons[i].MaterialUSize(), HeadingIcons[i].MaterialVSize() );
	        C.Style = lastStyle;
		}
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