# Best Times

Transforms the infamous Assault game mode of **Unreal Tournament 2004** into a highly competitive speed running mode.

## Pre-Requisites

The following packages are necessary to run MutBestTimes:
- TrialGroup.u (https://github.com/EliotVU/UT2004-TrialGroup)

## Usage

1. Install by copying the `ClientBTimesV#.u`, `ServerBTimes.u` and `ServerBTimes.ucl` files to your `/UT2004Root/System/` directory.
2. Launch UT2004 -> Instant Action, and look for `MutBestTimes` in the mutators page.
3. For server admins, you enable the mutator by appending `?Mutator=ServerBTimes.MutBestTimes` to the commandline.

## Build

1. Clone the repository to your `/UT2004Root/`, make sure that the directory name is `MutBestTimes` e.g. it shoud look like `/UT2004Root/MutBestTimes/ClientBTimes/`
2. Run `/MutBestTimes/Scripts/Install-dev.bat` at least once.
3. Run `/MutBestTimes/ClientBTimes/make.bat` and `/MutBestTimes/ServerBTimes/make.bat` in that order, and repeat whenever you make any changes.
4. Launch `/MutBestTimes/Scripts/Play.bat` to launch a quick-test.

## Credits

* [Marco](https://github.com/Marco888) a.k.a **.:..:** for developing the original `bTimesMute` circa 2005; single-top-time per RTR map, a leaderboard of most accumulated points (5 points for top record), and the ghost prototype.
* [elmuerte](https://github.com/elmuerte) for the [LibHTTP4.u](https://github.com/elmuerte/UE2-LibHTTP) package.
