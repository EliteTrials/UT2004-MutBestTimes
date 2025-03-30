# Best Times

Transforms the infamous Assault game mode of **Unreal Tournament 2004** into a highly competitive speed running mode.

## Features

### Leaderboards

#### Top Players - All Time

![image](https://github.com/user-attachments/assets/fc612979-a43b-40f7-a2d3-c23222cd658c)

#### Top Map Records

![image](https://github.com/user-attachments/assets/8758bbb1-ecf5-4a77-a223-57464131e167)

#### Top Player Records

![image](https://github.com/user-attachments/assets/aa5c3fab-1323-4e2e-ae6a-cb18f2abf341)

### Ghost playback

All time record runs are recorded for all players, and can be re-played at any time by any player that chooses to, any top record's ghost playback will also be running 24/7.
Additionally, players also choose to race against any ghost, either through the GUI or by typing '!ghost 1' where 1 is the placement of the record.

### Leveling

![image](https://github.com/user-attachments/assets/4e123579-5b7e-4e66-bdbb-c4283fc1ade0)

Players can earn experience by completing objectives, setting new records, or by eliminating monsters.
Achieving levels will earn the player in-game currency depicted with '$', this currency can then be used to buy items from the in-game store, such as cosmetics or utilities.

### Store

![image](https://github.com/user-attachments/assets/21b78168-1814-4f36-983b-a2ad19eaacee)

### Inventory

![image](https://github.com/user-attachments/assets/d3f7acf3-f088-4bcc-a322-a23b1cf4af71)

### Achievements

![image](https://github.com/user-attachments/assets/e3db4766-1c6f-4357-bce8-a0fbc2db9b47)

### Scoreboard

![image](https://github.com/user-attachments/assets/eeec4b4f-0c06-436d-9eba-1203e82a8fac)

### Voting Menu

![image](https://github.com/user-attachments/assets/563b710d-053c-4681-acb3-0ffe39df9ef0)

### Regular Trials

* Regular Trials is the given name for the classic trial maps that arose from community made maps for the `Assault` game type, such as the first two maps ***AS-SkillTrials*** and ***AS-TempleOfTrials***.
* Players must complete all the objectives to end the game, team work may be required, but is usually the best option to achieve the fastest time.
* The map name must have more than one objective and must be prefixed either with `AS-` or `RTR-`

### Solo Trials

* Solo Trials is the given name for quick and short maps that are by design optimized for speed running, but designed for a single player.
* Players must complete one objective to complete the map, however this does not end the game, allowing anyone to repeatedly try to achieve the fastest time.
* The map name must be prefixed with either `AS-Solo-` or `STR-` and must have only one objective; otherwise the map fallbacks to regular trials.

#### Supreme

A solo map is allowed to have more than one objective, when this is the case, the ***Supreme*** is activated, and each objective will be treated as a separate level.

* Players can pick any level at any time for as long as the player has unlocked that level, a level can be unlocked by completing the previous level first.
* Each level has its own top fastest time and set of 'ghosts', additionally a series of 'solo' maps can be converted to supreme and remain backwards compatible, meaning BestTimes will keep the records and ghosts cross-leveled.

### Group Trials

Powered by [TrialGroup](https://github.com/EliotVU/UT2004-TrialGroup)

* Group Trials is the given name for maps that are designed with team work in mind, much like regular trials, but instead with player-defined groups that can run through the map independently.
* Players must complete all the tasks in order to complete the final (and only) objective; the maps usually have specialized gameplay elements that are optimized for team-work.
* The map name must be prefixed with either `AS-Group-` or `GTR-`, or have a GroupManager actor in the map.
* Upon achieving a best time, all members of the group are rewarded the same completion time; each group run-through is recorded and can be played back as ghosts.

### Bunny Trials

* Bunny Trials is the given name for Capture the Flag maps designed for UT99's `BunnyTrack` and is automatically activated if the current game mode is a derivative of `CTFGame`
* Players must capture a copy of the flag and return it to their base to complete a run. This mode can be played by two teams, competing for victory.

### Invasion Extension

* The mutator can used as an extension for the `Invasion` game type, and is automatically activated if the current game mode is a derivative of `Invasion`
* The store, inventory, leveling, and achievements system will remain functioning.
* Players can complete achievements, eliminate monsters to gain experience and earn 'currency' to buy items from the store.

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

* [Marco](https://github.com/Marco888) a.k.a **.:..:** for developing the original `bTimesMute` circa 2005; single-top-time per RTR map, a message showdown leaderboard of players with the most accumulated points (5 points for top record), and the ghost prototype.
* [elmuerte](https://github.com/elmuerte) for the [LibHTTP4.u](https://github.com/elmuerte/UE2-LibHTTP) package.
