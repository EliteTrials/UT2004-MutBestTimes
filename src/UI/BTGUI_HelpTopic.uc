class BTGUI_HelpTopic extends Object;

// var() editconst name Id;
var() editconst string Caption;
var() editconstarray array<string> Contents;
var() const string Separator;
var protected string Content;

// Expected to be identical to the Caption of another HelpTopic.
var() editconst string ParentCaption;

delegate bool IsRelevant();
delegate string ParseVariable( string varContext, string varName );

final static function string ExMakeColorCode( Color NewColor )
{
	// Text colours use 1 as 0.
	if(NewColor.R == 0)
		NewColor.R = 1;
	else if(NewColor.R == 10)
		NewColor.R = 11;
	else if(NewColor.R == 127)
		NewColor.R = 128;

	if(NewColor.G == 0)
		NewColor.G = 1;
	else if(NewColor.G == 10)
		NewColor.G = 11;
	else if(NewColor.G == 127)
		NewColor.G = 128;

	if(NewColor.B == 0)
		NewColor.B = 1;
	else if(NewColor.B == 10)
		NewColor.B = 11;
	else if(NewColor.B == 127)
		NewColor.B = 128;

	return Chr(0x1B)$Chr(NewColor.R)$Chr(NewColor.G)$Chr(NewColor.B);
}

final function string CompileContent( string str )
{
	local int i,j,k;
	local string S,F;
	local Color C;

	while( true )
	{
		i = InStr(str,"{");
		if( i == -1 )
			return F$str;
		F = F$Left(str,i);
		S = Mid(str,i+1);
		j = InStr(S,"}");
		if( j == -1 )
			str = S;
		else
		{
			str = Mid(S,j+1);
			S = Left(S,j);
			k = Asc(Locs(S));
			if( (k >= Asc("a") && k <= Asc("z")) )
			{
				i = InStr(S,".");
				if( i != -1 )
				{
					F = F$ParseVariable( Left(S,i), Mid(Left(S,j),i+1) );
				}
			}
			else
			{
				C.R = 0;
				C.G = 0;
				C.B = 0;
				i = InStr(S,",");
				if( i == -1 )
					C.R = byte(S);
				else
				{
					C.R = byte(Left(S,i));
					S = Mid(S,i+1);
					i = InStr(S,",");
					if( i == -1 )
						C.G = byte(S);
					else
					{
						C.G = byte(Left(S,i));
						C.B = byte(Mid(S,i+1));
					}
				}
				F = F$ExMakeColorCode(C);
			}
		}
	}
}

final function Compile()
{
	local int i;
	local string str;

    str = Contents[0];
    for( i = 1; i < Contents.Length; ++ i )
    {
    	str $= Separator$Contents[i];
    }
	Content = CompileContent( str );
}

final function string GetContent()
{
	if( Content == "" )
		Compile();

	return Content;
}

defaultproperties
{
	Separator="|"
}