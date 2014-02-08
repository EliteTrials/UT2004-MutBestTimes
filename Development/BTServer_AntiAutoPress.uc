//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_AntiAutoPress Extends Actor;

var float LastUseTime;
var int Uses;

// Don't notify mutators, no need and happens too much because players die so often
Event PreBeginPlay();

Event PostBeginPlay()
{
    SetTimer( 1.0f, True );
}

Event UsedBy( Pawn user )
{
    if( user != None )
    {
        //xPawn(user).ClientMessage( "Usedby!" );

        if( Level.TimeSeconds-LastUseTime > 1.0 )
        {
            LastUseTime = Level.TimeSeconds;
            Uses = 0;
        }
        ++ Uses;

        if( Uses > 20 )
        {
            //xPawn(user).ClientMessage( "AutoPress Detected!" );
            user.bCanUse = False;   // till suicide
            Destroy();
            return;
        }
    }
}

Event Tick( float delta )
{
    if( Owner == None )
    {
        Destroy();
        return;
    }
    SetLocation( Owner.Location );
}

DefaultProperties
{
    bHidden=True
    CollisionRadius=+00040.000000
    CollisionHeight=+00040.000000
    bCollideActors=True
}
