class BTServer_AchievementListener extends Info;

function Trigger( Actor other, Pawn eventInstigator )
{
	MutBestTimes(Owner).OnMapAchievementTrigger( tag, eventInstigator );
}

defaultproperties
{

}