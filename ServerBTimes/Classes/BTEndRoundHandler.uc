class BTEndRoundHandler extends Info;

event PostBeginPlay()
{
    super.PostBeginPlay();

    Tag = 'EndRound';
}

event Trigger( Actor other, Pawn eventInstigator )
{
    MutBestTimes(Owner).NotifyGameEnd( other, eventInstigator );
}
