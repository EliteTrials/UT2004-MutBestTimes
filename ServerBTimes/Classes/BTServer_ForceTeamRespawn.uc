//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_ForceTeamRespawn Extends Triggers
    NotPlaceable;

Event Trigger( Actor Other, Pawn EventInstigator )
{
    local Controller    C;
    local Pawn          OldPawn;

    if ( Role < Role_Authority || !Level.Game.IsA('ASGameInfo') )
        return;

    for ( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if ( (C.PlayerReplicationInfo != None) && !C.PlayerReplicationInfo.bOnlySpectator )
        {
            if( C.Pawn.IsA('BTClient_Ghost') )
                continue;

            if( Vehicle(C.Pawn) != None )
                Vehicle(C.Pawn).KDriverLeave( true );

            if ( C.Pawn != None )
            {
                if( C.Pawn.Weapon == None )
                {
                    OldPawn = C.Pawn;
                    C.UnPossess();
                    OldPawn.Destroy();
                    C.Pawn = None;
                    Level.Game.RestartPlayer( C );
                }
                else
                {
                    // Restore pawn.
                    if( C.Pawn.Health < C.Pawn.HealthMax )
                        C.Pawn.Health = C.Pawn.HealthMax;
                }
            }
            ASGameInfo(Level.Game).RespawnPlayer( C, false );
        }
     }
}

DefaultProperties
{
    bStatic=False
    bNoDelete=False
    bCollideActors=False
}
