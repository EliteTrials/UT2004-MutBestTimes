class BTFlagResemblance extends Actor
	notplaceable;
	
var MutBestTimes BT;
var CTFFlag ResemblantFlag;

var class<CTFFlag> TeamFlagClasses[2];

event Touch( Actor other )
{
	local Pawn pawn;
	local CTFFlag flag;
	local PlayerController PC;
	local PlayerReplicationInfo PRI;
	
	pawn = Pawn(other);
	if( pawn == none )
		return;
		
	PRI = pawn .PlayerReplicationInfo;
	if( PRI == none )
		return;
		
	PC = PlayerController(pawn.Controller);
	if( PC == none )
		return;
		
	Level.Game.Broadcast( self, "Flag touched!" );
	
	flag = HasFlag( pawn.PlayerReplicationInfo );
	if( flag != none )
	{
		if( flag.TeamNum == ResemblantFlag.TeamNum )
		{
			return;
		}
		Level.Game.Broadcast( self, "Taking flag..." @ flag );
		
		// Take the flag
		Level.GRI.FlagState[flag.TeamNum] = FLAG_Home;
		flag.ClearHolder();
		flag.BroadcastLocalizedMessage( flag.MessageClass, 3, none, none, flag.Team );
		
		MutBestTimes(Owner).BunnyScored( PC, flag );
		
		flag.Destroy();
	}
	else if( pawn.GetTeamNum() != ResemblantFlag.TeamNum )
	{
		Level.Game.Broadcast( self, "Giving flag..." );
		// Give a flag
		ResembleFlag( PC, ResemblantFlag ); 
	}
}

final function ResembleFlag( PlayerController PC, CTFFlag flag )
{
	local CTFFlag newFlag;
	
	newFlag = Spawn( TeamFlagClasses[flag.TeamNum], flag.HomeBase,, flag.Location, flag.Rotation );
	newFlag.Team = flag.Team;
	newFlag.TeamNum = flag.TeamNum;
	newFlag.HomeBase = flag.HomeBase;
	newFlag.SetHolder( PC );
	newFlag.HomeBase.bHidden = true;
	Level.GRI.FlagState[flag.TeamNum] = FLAG_Home;
}

final function CTFFlag HasFlag( PlayerReplicationInfo PRI )
{
	return CTFFlag(PRI.HasFlag);
}

defaultproperties
{
	TeamFlagClasses[0]=class'BTBunny_FlagRed'
	TeamFlagClasses[1]=class'BTBunny_FlagBlue'
	
	bStatic=false
	bHidden=true
	bCollideActors=true
}