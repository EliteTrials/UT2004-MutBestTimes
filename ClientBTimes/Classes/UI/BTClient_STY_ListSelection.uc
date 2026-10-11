class BTClient_STY_ListSelection extends STY2ListSelection;

event Initialize()
{
    super(GUIStyles).Initialize();
}

defaultproperties
{
	KeyName="BTListSelection"

    BorderOffsets(0)=5
    BorderOffsets(1)=5
    BorderOffsets(2)=5
    BorderOffsets(3)=5

    Images(0)=Texture'BTScoreBoardBG'
    Images(1)=Texture'BTScoreBoardBG'
    Images(2)=Texture'BTScoreBoardBG'
    Images(3)=Texture'BTScoreBoardBG'
    Images(4)=Texture'BTScoreBoardBG'

	ImgColors(0)=(B=34,G=34,R=34,A=230)
    ImgColors(1)=(B=51,G=51,R=51,A=242)
    ImgColors(2)=(B=51,G=51,R=51,A=236)
    ImgColors(3)=(B=51,G=51,R=51,A=236)
    ImgColors(4)=(B=0,G=10,R=10,A=248)

    FontColors(0)=(R=255,G=255,B=255,A=255)
    FontColors(1)=(R=255,G=255,B=255,A=255)
    FontColors(2)=(R=255,G=255,B=255,A=255)
    FontColors(3)=(R=255,G=255,B=255,A=255)
    FontColors(4)=(R=100,G=100,B=100,A=200)
}