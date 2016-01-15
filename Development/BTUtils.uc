//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTUtils extends Object;

const MeterUnits = 128;

final static function bool IsInServerPackages( string packageName, out int index )
{
    local int j;

    j = Class'GameEngine'.default.ServerPackages.Length;
    for( index = 0; index < j; ++ index )
    {
        if( Class'GameEngine'.default.ServerPackages[index] ~= packageName )
        {
            return true;
        }
    }
    return false;
}

final static function int FahrenheitToCelsius( int f )
{
    return (5f / 9f) * (f - 32);
}

final static function float UUnitToMeters( float UUnit )
{
    return UUnit / MeterUnits;
}

final static function string DecimalToBinary( int decimal )
{
    local string binary;
    local int c;

    c = 1;
    do
    {
        binary = Eval( ((decimal & c) == c), "1", "0" ) $ binary;
        c *= 2;
    } until( c > decimal || c == 2147483648 /* 32th bit */);
    return binary;
}

final static function MutBestTimes GetBT( Actor level )
{
    local Mutator m;

    for( m = level.Game.BaseMutator; m != none; m = m.NextMutator )
    {
        if( MutBestTimes(m) != none )
        {
            return MutBestTimes(m);
        }
    }
    return none;
}












