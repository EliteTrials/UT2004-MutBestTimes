class SpinnySkel extends SpinnyWeap;

function Tick(float Delta)
{
    // Removed spinning.
    CurrentTime += Delta/Level.TimeDilation;

    // If desired, play some random animations
    if(bPlayRandomAnims && CurrentTime >= NextAnimTime)
    {
        PlayNextAnim();
    }
}