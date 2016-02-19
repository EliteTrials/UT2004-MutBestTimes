class BTGUI_HelpTopic extends Object;

// var() editconst name Id;
var() editconst string Caption;
var() array<string> Contents;

// Expected to be identical to the Caption of another HelpTopic.
var() editconst string ParentCaption;

delegate bool IsRelevant();

defaultproperties
{
}