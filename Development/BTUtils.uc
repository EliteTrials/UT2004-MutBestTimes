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

final function StringToArray( string s, out array<string> a )
{
    local int i;

    a.Length = Len( s );
    if( a.Length == 1 )
    {
        a[0] = s;
        return;
    }

    for( i = 0; i < a.Length; ++ i )
    {
        a[i] = Mid( Left( s, i + 1), i );
    }
}

final static function MutBestTimes GetBT( LevelInfo world )
{
    local Mutator m;

    for( m = world.Game.BaseMutator; m != none; m = m.NextMutator )
    {
        if( MutBestTimes(m) != none )
        {
            return MutBestTimes(m);
        }
    }
    return none;
}












