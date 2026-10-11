class BTStaticUtils extends Object;

final static function Color MakeColor( optional byte r, optional byte g, optional byte b, optional byte a )
{
    local Color c;

    c.r = r;
    c.g = g;
    c.b = b;
    c.a = a;
    return c;
}

final static function Color Lighten( Color c, float pct )
{
    pct = 1.0 + pct/100.0f;
    return MakeColor( c.R*pct, c.G*pct, c.B*pct, c.A );
}

final static function Color Darken( Color c, float pct )
{
    pct = 1.0 - pct/100.0f;
    return MakeColor( c.R*pct, c.G*pct, c.B*pct, c.A );
}