# That Nameless Game Specification

This document describes the specification of That Nameless Game (名もなきあの遊び).

<br>
<br>

# Table of Contents

- [App Overview](#app-overview)
  - [Overview of "That Game"](#overview-of-that-game)
  - [App Concept Images](#app-concept-images)
  - [Rule Summary for This App](#rule-summary-for-this-app)

- [Rule Details](#rule-details)

- [CPU Details](#cpu-details)

- [App Screen Details](#app-screen-details)
  - [Screen Transition Diagram](#screen-transition-diagram)
  - [Throughout the Game](#throughout-the-game)
    - [First-Launch Settings](#first-launch-settings)
    - [When the App Is Terminated Mid-Session (Task Killed)](#when-the-app-is-terminated-mid-session-task-killed)
    - [When the App Is Sent to the Background (Task Not Killed)](#when-the-app-is-sent-to-the-background-task-not-killed)

  - [Home Screen](#home-screen)
    - [Home Screen Details](#home-screen-details)

  - [Play Screen](#play-screen)
    - [Play Screen Transition Diagram](#play-screen-transition-diagram)
    - [Play Screen Overall Details](#play-screen-overall-details)
    - [Theme Colors for Each Mode](#theme-colors-for-each-mode)
    - [Play Screen Details / Start Screen](#play-screen-details--start-screen)
    - [Play Screen Details / During Play](#play-screen-details--during-play)
    - [Play Screen Details / Result Screen](#play-screen-details--result-screen)

  - [Settings Screen](#settings-screen)
    - [Settings Screen Overview](#settings-screen-overview)
    - [Settings Screen Details](#settings-screen-details)

  - [Rules Screen](#rules-screen)
    - [Rules Screen Overview](#rules-screen-overview)
    - [Rules Screen Details](#rules-screen-details)

<br>
<br>

# App Overview
A game app that takes **"that game"** — the one everyone probably played as a kid, regardless of generation — and powers it up.

<br>

## Overview of "That Game"

<img src="images/rules_2hands.png" width="400">

<br>

## App Concept Images
- Icon

  <img src="images/icon_preview.png" width="150">

- Home screen

  <img src="images/top_screen_image_jp.png" width="400">

- Play screen

  <img src="images/play_screen_image_2play_pink_jp.png" width="400">

<br>

## Rule Summary for This App

<img src="images/rules_2_jp.png" width="300">

<img src="images/rules_3_jp.gif" width="300">

<img src="images/rules_4_jp.gif" width="300">

<img src="images/rules_5_jp.gif" width="300">

<img src="images/rules_6_jp.gif" width="300">

<img src="images/rules_7_jp.png" width="300">

<img src="images/rules_8_jp.png" width="300">


<br>
<br>

# Rule Details

1. At the start
  - Hands
    - The number of fingers on each hand is chosen at random from the combinations below (the order of the 3 hands inside each `[]`, and the order of the two `[]` sets, are each shuffled randomly).
    - Combinations that would allow a hand to be eliminated on the very first move — i.e., combinations where a hand sums to 5 with one of the opponent's hands — are not used.
    ```
    {[1,1,1], [1,1,1]}
    {[1,1,1], [1,1,2]}
    {[1,1,1], [1,1,3]}
    {[1,1,1], [1,2,2]}
    {[1,1,1], [1,2,3]}
    {[1,1,1], [1,3,3]}
    {[1,1,1], [2,2,2]}
    {[1,1,1], [2,2,3]}
    {[1,1,1], [2,3,3]}
    {[1,1,1], [3,3,3]}
    {[1,1,2], [1,1,2]}
    {[1,1,2], [1,2,2]}
    {[1,1,2], [2,2,2]}
    {[1,1,3], [1,1,3]}
    {[1,1,3], [1,3,3]}
    {[1,1,3], [3,3,3]}
    {[1,1,4], [2,2,2]}
    {[1,1,4], [2,2,3]}
    {[1,1,4], [2,3,3]}
    {[1,1,4], [3,3,3]}
    {[1,2,2], [1,2,2]}
    {[1,2,2], [2,2,2]}
    {[1,2,4], [2,2,2]}
    {[1,3,3], [1,3,3]}
    {[1,3,3], [3,3,3]}
    {[1,3,4], [3,3,3]}
    {[1,4,4], [2,2,2]}
    {[1,4,4], [2,2,3]}
    {[1,4,4], [2,3,3]}
    {[1,4,4], [3,3,3]}
    {[2,2,2], [2,2,2]}
    {[2,2,2], [2,2,4]}
    {[2,2,2], [2,4,4]}
    {[2,2,2], [4,4,4]}
    {[2,2,3], [4,4,4]}
    {[2,2,4], [2,2,4]}
    {[2,2,4], [2,4,4]}
    {[2,2,4], [4,4,4]}
    {[2,3,3], [4,4,4]}
    {[2,3,4], [4,4,4]}
    {[2,4,4], [2,4,4]}
    {[2,4,4], [4,4,4]}
    {[3,3,3], [3,3,3]}
    {[3,3,3], [3,3,4]}
    {[3,3,3], [3,4,4]}
    {[3,3,3], [4,4,4]}
    {[3,3,4], [3,3,4]}
    {[3,3,4], [3,4,4]}
    {[3,3,4], [4,4,4]}
    {[3,4,4], [3,4,4]}
    {[3,4,4], [4,4,4]}
    {[4,4,4], [4,4,4]}
    ```

  - Time limit (subject to change based on playtesting)
    - 2-player mode: selected from "**5, 10, 15, 20, 30, 45, 60, 無制限/Unlimited**" on the Settings screen. The default is **15** seconds.
    - 1-player Easy mode: **30** seconds
    - 1-player Normal mode: **15** seconds
    - 1-player Hard mode: **5** seconds

  - Which player goes first is decided at random.

2. The player whose turn it is chooses "which of their own hands" to tap "which of the opponent's hands" with, then presses "けってい (OK)".
  - If the player fails to choose hands within the time limit, that player loses.
  - Once a hand reaches 0, that hand can no longer be used.


3. For the chosen hands, the number of fingers on the attacker's hand is added to the number of fingers on the opponent's hand. (If a hand reaches exactly 5 fingers, that hand becomes unusable from then on. If the total would be 6 or more, the hand's finger count becomes the remainder of that total divided by 5.)

4. Steps 2 and 3 are repeated with players alternating turns. A player loses when all of their hands become unusable.

5. If the same state* appears again, creating a loop, the player with the **smaller** total number of remaining fingers wins. If the totals are equal, the game is a draw.

- \* "The same state" means:
The **finger counts of every hand of both players**, together with **whose turn** it currently is, match a state that has occurred before.
Note that for the 3 hands belonging to the same player, their **on-screen positions are also distinguished** when making this judgment.

<br>
<br>

# CPU Details
The CPUs for the three 1-player modes have the following strength levels. Note that the time limit is displayed during the CPU's turn as well.
- Easy mode:
  - If there is a move that reduces a hand's finger count to 0 and eliminates it, the CPU plays that move with a 95% probability.
  - Within the 30-second time limit, the CPU performs the sequence "select each hand → press OK" over a span of 4–10 seconds.
    - The timing of selecting each hand and pressing OK is also randomized.
    - Each action is separated by an interval of at least 1 second.
    - The CPU never re-selects a hand between selecting hands and pressing OK.
- Normal mode:
  - Based on a full game-tree search, the CPU should feel like it can read about 3–4 moves ahead.
  - Within the 15-second time limit, the CPU performs the sequence "select each hand → press OK" over a span of 3–8 seconds.
    - The timing of selecting each hand and pressing OK is also randomized.
    - Each action is separated by an interval of at least 0.5 seconds.
    - Between selecting hands and pressing OK, the CPU re-selects a hand with a 15% probability (re-selection may occur at most once per turn).
- Hard mode:
  - We want this CPU to be nearly unbeatable, including the win/loss determination after loops.
    - However, a human who has memorized all the patterns should still be able to win.
  - Within the 5-second time limit, the CPU performs the sequence "select each hand → press OK" over a span of 1–4 seconds.
    - The timing of selecting each hand and pressing OK is also randomized.
    - Each action is separated by an interval of at least 0.25 seconds.
    - Between selecting hands and pressing OK, the CPU re-selects a hand with a 15% probability (re-selection may occur at most once per turn).

Detailed internal design will be documented in the detailed design document. The full game-tree search should preferably be done in Python.

<br>
<br>

# App Screen Details
## Screen Transition Diagram
The app consists of four main screens. Each screen is described in detail below.
- Home screen
- Play screen
- Settings screen
- Rules screen

<img src="images/screen_transition_diagram.png" width="1500">

<br>

## Throughout the Game
- The screen is always fixed in landscape orientation; rotation based on device orientation is never allowed.
- The screen is fixed at a **16:9** aspect ratio regardless of device size or aspect ratio. Margins are filled with black as shown below. (The photos are only meant to illustrate the black fill; the actual screens differ.)

  <img src="images/aspect_example_1.png" width="200">
  <img src="images/aspect_example_2.png" width="200">

- Two versions of all in-app text are provided: Japanese and English.

- The BGM throughout the app is [Grandpa (グランパ)](https://dova-s.jp/bgm/detail/108) (file name here: `bgm.mp3`), played on loop.
  It can be turned ON/OFF from the Settings screen (described later).

- All sound effects are from [Sound Effect Lab (効果音ラボ)](https://soundeffect-lab.info/). The following are used.
  They can be turned ON/OFF from the Settings screen (described later).
  - "決定ボタンを押す2 (Press Confirm Button 2)" (used as `tap_button.mp3`)
  - "決定ボタンを押す9 (Press Confirm Button 9)" (used as `tap_hand.mp3`)
  - "決定ボタンを押す21 (Press Confirm Button 21)" (used as `win.mp3`)
  - "決定ボタンを押す31 (Press Confirm Button 31)" (used as `tap_ok.mp3`)
  - "決定ボタンを押す52 (Press Confirm Button 52)" (used as `countdown.mp3`)
  - "エアーホーン (Air Horn)" (used as `start.mp3`)
  - "和太鼓でドドン (Taiko Drum Do-don)" (used as `draw.mp3`)
  - "目が点になる (Dumbfounded)" (used as `lose.mp3`)

- The language setting, BGM and sound effect ON/OFF settings, the 2-player time limit, and the presence of ☆ marks on the home screen* are all retained even after the app is closed.


### First-Launch Settings
- Screen on first launch<br>
  The **Home screen** is displayed on launch.

- Language setting<br>
  If the **device's language setting** is Japanese, the app uses Japanese; for any other language, it uses English.
  This language setting is applied starting from the Home screen shown at launch.

- BGM and sound effect ON/OFF<br>
  Both default to **ON** and apply from launch.

- 2-player time limit<br>
  The default is **15** seconds.

- Presence of ☆ marks on the home screen<br>
  All ☆ marks are initially **absent**.


### When the App Is Terminated Mid-Session (Task Killed)
- On the next launch, the previously saved settings (language, BGM, sound effects, 2-player time limit, ☆ mark states) are carried over, and the **Home screen** is displayed first regardless of which screen was showing when the task was killed.

- If the task is killed during gameplay<br>
  A 2-player game is simply aborted; in all three 1-player modes, the game counts as a loss for the player.<br>
  In this case, if the 2-player mode had not yet reached a state that would earn a ☆, no new ☆ is **awarded**.


### When the App Is Sent to the Background (Task Not Killed)
- The moment the app goes to the background, **BGM is paused and sound effects are disabled**.
- When returning to the app, BGM resumes and sound effects are re-enabled if the respective settings are ON.
#### 1-player modes
- If the app goes to the background during the player's turn:
  - When returning to the app, the time elapsed in the background is applied to the current player's time limit.
  - If applying the elapsed time exceeds the time limit, the player loses by timeout and the game moves to the result screen.
- If the app goes to the background during the CPU's turn:
  - When returning to the app, the time elapsed in the background is NOT applied to the CPU's time limit.
  - After returning to the app, the CPU's turn is processed.
  - The CPU never loses by timeout due to time elapsed in the background.
#### 2-player mode
  - When returning to the app, the time elapsed in the background is applied to the current player's time limit.
  - If applying the elapsed time exceeds the time limit, the player loses by timeout and the game moves to the result screen.


\* About the ☆ marks on the home screen<br>
In 2-player mode, playing **at least one game through to a win/loss or draw** earns a ☆;
in 1-player Easy/Normal/Hard, **beating the CPU at least once** earns a ☆. The ☆ mark appears at the bottom right of the corresponding mode's button on the home screen.

<img src="images/top_screen_image_jp.png" width="300">

↓ After playing one 2-player game and beating the CPU once in 1-player Easy:

<img src="images/top_screen_image_jp_2.png" width="300">

<br>

## Home Screen
### Home Screen Details
#### [Japanese version]

<img src="images/top_image_jp_with_comments.png" width="400">

#### [English version]

<img src="images/top_image_en_with_comments.png" width="400">

#### [Object Descriptions]
##### ➀ Background
- Function: none
- Asset: `background_rainbow.png`
- Notes: fixed at 16:9

##### ➁ Main logo
- Function: none
- Assets:
  - Japanese version: `title_logo_jp.png`
  - English version: `title_logo_en.png`

##### ➂ Rules button
- Function: **Transitions to the Rules screen.** The switch is instantaneous (no motion). If sound effects are ON, a sound effect is played.
- Assets:
  - Japanese version: `rules_jp.png`
  - English version: `rules_en.png`
  - Sound effect: `tap_button.mp3` (shared by the Japanese and English versions; hereafter, all sound effects are shared by both versions.)

##### ➃ Settings button
- Function: **Transitions to the Settings screen.** The switch is instantaneous (no motion). If sound effects are ON, a sound effect is played.
- Assets:
  - `settings.png` (shared by the Japanese and English versions)
  - Sound effect: `tap_button.mp3`

##### ➄ 2-player button
- Function: **Transitions to the 2-player play screen.** The transition uses a rightward slide motion. If sound effects are ON, a sound effect is played.
- Assets:
  - Japanese version: `play_2_jp.png`
  - English version: `play_2_en.png`
  - Sound effect: `tap_button.mp3`

##### ➅ 1-player Easy button
- Function: **Transitions to the 1-player Easy play screen.** The transition uses a rightward slide motion. If sound effects are ON, a sound effect is played.
- Assets:
  - Japanese version: `play_1_easy_jp.png`
  - English version: `play_1_easy_en.png`
  - Sound effect: `tap_button.mp3`

##### ➆ 1-player Normal button
- Function: **Transitions to the 1-player Normal play screen.** The transition uses a rightward slide motion. If sound effects are ON, a sound effect is played.
- Assets:
  - Japanese version: `play_1_normal_jp.png`
  - English version: `play_1_normal_en.png`
  - Sound effect: `tap_button.mp3`

##### ➇ 1-player Hard button
- Function: **Transitions to the 1-player Hard play screen.** The transition uses a rightward slide motion. If sound effects are ON, a sound effect is played.
- Assets:
  - Japanese version: `play_1_hard_jp.png`
  - English version: `play_1_hard_en.png`
  - Sound effect: `tap_button.mp3`

##### ➈ ☆ icon
- Function: Displays the clear status of each play mode.
- Display conditions:
  - 2-player: displayed permanently once a game has been played through to a result at least once.
  - 1-player 3 modes: displayed permanently once the corresponding CPU has been beaten at least once.
- Assets:
  - `star.png` (shared by the Japanese and English versions)

#### Notes
- From launch onward, BGM plays on loop (only if the BGM setting is ON).

<br>

## Play Screen
### Play Screen Transition Diagram

<img src="images/screen_transition_diagram_play_screen.png" width="800">

### Play Screen Overall Details
#### 2-player mode
##### [Japanese version]

<img src="images/play_screen_image_2play_pink_jp_with_comments.png" width="300">
<img src="images/play_screen_image_2play_purple_jp_with_comments.png" width="300">

##### [English version]

<img src="images/play_screen_image_2play_pink_en_with_comments.png" width="300">
<img src="images/play_screen_image_2play_purple_en_with_comments.png" width="300">

#### 1-player Easy mode
##### [Japanese version]

<img src="images/play_screen_image_1playeasy_player_jp_with_comments.png" width="300">
<img src="images/play_screen_image_1playeasy_cpu_jp_with_comments.png" width="300">

##### [English version]

<img src="images/play_screen_image_1playeasy_player_en_with_comments.png" width="300">
<img src="images/play_screen_image_1playeasy_cpu_en_with_comments.png" width="300">

#### 1-player Normal mode
##### [Japanese version]

<img src="images/play_screen_image_1playnormal_player_jp_with_comments.png" width="300">
<img src="images/play_screen_image_1playnormal_cpu_jp_with_comments.png" width="300">

##### [English version]

<img src="images/play_screen_image_1playnormal_player_en_with_comments.png" width="300">
<img src="images/play_screen_image_1playnormal_cpu_en_with_comments.png" width="300">

#### 1-player Hard mode
##### [Japanese version]

<img src="images/play_screen_image_1playhard_player_jp_with_comments.png" width="300">
<img src="images/play_screen_image_1playhard_cpu_jp_with_comments.png" width="300">

##### [English version]

<img src="images/play_screen_image_1playhard_player_en_with_comments.png" width="300">
<img src="images/play_screen_image_1playhard_cpu_en_with_comments.png" width="300">


#### [Object Descriptions]
##### ➀ Background
- Function: The background switches on each turn to make it visually clear whose turn it is.
- Asset: `background_{color code of each theme color}.png`
- Notes: fixed at 16:9

##### ➁ Finger buttons
- Function: described in detail later in "Play Screen Details / During Play"
- Assets:
  - Normal state:
    - 1 finger: `hand_1.png`
    - 2 fingers: `hand_2.png`
    - 3 fingers: `hand_3.png`
    - 4 fingers: `hand_4.png`
  - Selected state:
    - 1 finger: `hand_1_selected.png`
    - 2 fingers: `hand_2_selected.png`
    - 3 fingers: `hand_3_selected.png`
    - 4 fingers: `hand_4_selected.png`
  - Unusable state:
    - 0 fingers: `hand_0.png`
  - Note: in the Dart code, for the normal, selected, and unusable states alike, **each hand's outline is tinted with its theme color's color code**, as shown in the concept images.
  - Sound effect: `tap_hand.mp3` (shared by the Japanese and English versions)

##### ➂ Turn indicator
- Function: Displays whose turn it currently is (**no tap function**).
- Assets:
  - 2-player mode:
    - Japanese version: "あなたのターン (`your_turn_jp.png`)" is displayed **only on the side of the player whose turn it is**.
    - English version: "Your turn (`your_turn_en.png`)" is displayed only on the side of the player whose turn it is.
  - 1-player 3 modes:
    - Japanese version: "あなたのターン (`your_turn_jp.png`)" / "CPUのターン (`cpu_turn_jp.png`)" is displayed **only on the player's side**.
    - English version: "Your turn (`your_turn_en.png`)" / "CPU turn (`cpu_turn_en.png`)" is displayed only on the player's side.

##### ➃ OK button
- Function: **Confirms the action** with the selected hands (described in detail later in "Play Screen Details / During Play").
  - 2-player mode / player's turn in 1-player modes: initially `#CCCCCC` (gray). Once hands are selected and the conditions for pressing the button are met, it changes to the respective **theme color** and becomes pressable.
  - CPU's turn in 1-player modes: **the button is not displayed**.
- Assets:
  - No PNG is prepared. **Reproduced in Dart code.**
        (Preparing PNGs per color would increase the number of PNGs.)
  - Sound effect: `tap_ok.mp3` (shared by the Japanese and English versions)
- Notes:
  - Pressed after selecting one of your own hands and one of the opponent's hands.
  - Must be pressed within the time limit.
  - The action cannot be confirmed if the selection is incomplete.

##### ➄ Time limit display
- Function: Displays the remaining time (**no tap function**).
  - 2-player mode: selected from "5, 10, 15, 20, 30, 45, 60, Unlimited" on the Settings screen. The default is 15 seconds. (**When "Unlimited" is selected, the label itself is not displayed.**)
  - 1-player Easy mode: 30 seconds
  - 1-player Normal mode: 15 seconds
  - 1-player Hard mode: 5 seconds
  - All of the above are subject to change based on playtesting.
- Assets: No PNG is prepared. **Reproduced as text in Dart code.**
- Notes:
  - Counts down each turn.
  - Failing to complete the action within the time limit results in a loss.
  - Positioned at the bottom right of the screen.

##### ➅ Home screen button
- Function: Returns to the Home screen after confirmation via a pop-up (described in detail later in "Play Screen Details / During Play"). If sound effects are ON, a tap sound (sound effect) is played.
- Assets: No PNG is prepared. Reproduced in Dart code.
        (Preparing PNGs per color would increase the number of PNGs.)
  - Sound effect: `tap_button.mp3` (shared by the Japanese and English versions)


#### Notes
- BGM plays on loop (only if the BGM setting is ON). Note that BGM is interrupted on the start screen and the result screen (details in `Play Screen Details` below).

### Theme Colors for Each Mode
- 2-player
  - Near-side player: `#F59DBC` (pink)
  - Far-side player: `#C297C8` (purple)
- 1-player (Easy)
  - Player: `#F2D087` (yellow)
  - CPU: `#CCCCCC` (gray)
- 1-player (Normal)
  - Player: `#8BCD7D` (green)
  - CPU: `#CCCCCC` (gray)
- 1-player (Hard)
  - Player: `#81BFE0` (blue)
  - CPU: `#CCCCCC` (gray)

### Play Screen Details / Start Screen
The start screen is a pre-game countdown presentation displayed immediately after selecting a play mode and transitioning to the play screen.

#### <2-player>

<img src="images/start_3_2play_jp.png" width="300">

<img src="images/start_2_2play_jp.png" width="300">

<img src="images/start_1_2play_jp.png" width="300">

<img src="images/start_start_2play_jp.png" width="300">

#### <1-player, 3 modes>

<img src="images/start_3_1play_jp.png" width="300">

<img src="images/start_2_1play_jp.png" width="300">

<img src="images/start_1_1play_jp.png" width="300">

<img src="images/start_start_1play_jp.png" width="300">

#### Appearance
- The **hand counts and all labels in the background are the same as at the moment of the game start** (the background labels use the currently set language; details in "Hands and Labels at the Moment of Start" below).
- On top of that, a **`#000000` (70% opacity)** overlay is spread across the entire screen.
- On top of that, the countdown characters ("**3 (`start_3.png`)**", "**2 (`start_2.png`)**", "**1 (`start_1.png`)**", "**Start! (`start_start.png`)**") are displayed.
  - Displayed **both top and bottom in 2-player mode**, and **only at the bottom in the three 1-player modes** (the top label in 2-player mode is flipped upside down).

#### Screen transitions
- The four screens "3, 2, 1, Start!" are each displayed for **1 second** in order.
- During this time, **all buttons on the screen are disabled**.
- If the BGM setting is ON, **BGM is stopped** during the pre-play motion. BGM resumes immediately after the start.
- If sound effects are ON, `countdown.mp3` is played simultaneously with each of the "3, 2, 1" screen switches, and `start.mp3` simultaneously with "Start!".


#### Hands and Labels at the Moment of Start
##### <2-player>
- When the near side (pink) goes first:

  <img src="images/start_backimage_2play_pink_jp.png" width="300">
  <img src="images/start_backimage_2play_pink_en.png" width="300">

- When the far side (purple) goes first:

  <img src="images/start_backimage_2play_purple_jp.png" width="300">
  <img src="images/start_backimage_2play_purple_en.png" width="300">

##### <1-player, 3 modes>
- When the player goes first:

  <img src="images/start_backimage_1play_you_jp.png" width="300">
  <img src="images/start_backimage_1play_you_en.png" width="300">

- When the CPU goes first:

  <img src="images/start_backimage_1play_cpu_jp.png" width="300">
  <img src="images/start_backimage_1play_cpu_en.png" width="300">


##### [Object Descriptions]
**None of the objects can be tapped while the start screen is showing.**
###### ➀ Background

###### ➁ Finger buttons
The starting finger counts follow the Rule Details. In summary: each hand has a random count of 1–4 fingers, excluding patterns where a hand could be eliminated on the first move.

###### ➂ OK button
Japanese/English versions differ. At the moment of start, all are **`#CCCCCC` (gray)**.
Note: **when the game starts on the CPU's turn, the button itself is not displayed.**

###### ➃ Turn indicator label
In accordance with the Rule Details:
- 2-player mode: "あなたのターン (Your turn)" is displayed on the side of the applicable player.
- 1-player 3 modes: either "あなたのターン (Your turn)" or "CPUのターン (CPU turn)" is displayed.

###### ➄ Countdown label
A label showing the remaining time at start — i.e., the same time as each mode's time limit — is displayed.
```
- 2-player mode: selected from "5, 10, 15, 20, 30, 45, 60, 無制限/Unlimited" on the Settings screen. Default is 15 seconds. (**When "Unlimited" is selected, the label itself is not displayed.**)
- 1-player Easy mode: 30 seconds
- 1-player Normal mode: 15 seconds
- 1-player Hard mode: 5 seconds
```

###### ➅ Return-to-home button


### Play Screen Details / During Play
#### 2-player

<img src="images/play_image.gif" width="400">

#### 1-player

<img src="images/play_image_2.gif" width="400">

#### Specification
##### 2-player mode / player's turn in 1-player modes

1. ➄ The timer starts.
2. Select one hand each from **➁ "your own hands" and "the opponent's hands" (3 hands each)**.
    - A selection can be **changed** after being made. Only one hand from each set of 3 can be selected at a time; if one is already selected, tapping another switches the selection to the new hand.
    - Each time a hand is tapped, **`tap_hand.mp3` is played** (only if sound effects are ON in Settings).
    - Once one hand from each side has been selected, the **➃ "けってい (OK)" button changes from gray to the respective theme color**.
3. Press **➃ "けってい" ("OK" in the English version)**.
    - The "けってい (OK)" button **disappears the instant it is pressed**.
    - After that, a hand-tapping motion plays (about 0.8 seconds).
      - Just before the motion ends (at the moment of the tap), **`tap_ok.mp3` is played** (only if sound effects are ON in Settings).
      - During this motion, the attacking hand moves directly in **front** of the hand being tapped and strikes it.
      - **The time limit is paused** during this motion.
4. The turn switches to the other player. **Failing to complete steps 2 and 3 within the time limit results in a loss for that player.**

##### CPU's turn in 1-player modes
The player does nothing. Also, **the "OK button" is not displayed** during the CPU's turn.

##### Determining the winner
Repeating the above:
- All of a player's hands become unusable: that player loses.
- The hands enter a loop (the same state appears again): the player with the smaller total number of remaining fingers wins.
- The UI is explained later ("Play Screen Details / Result Screen").

#### Confirmation Dialog Before Returning to the Home Screen
##### [Japanese version]
<img src="images/pop_image_jp.png" width="400">

##### [English version]
<img src="images/pop_image_en.png" width="400">

##### [Object Descriptions]
###### ➀ Pop-up background
- Function: none
- Asset: planned to be reproduced in Dart code. (If a PNG is used: `pop_frame.png`)
- Notes: this pop-up is intended to hide the finger counts, so it should be at least large enough to cover all fingers.

###### ➁ Confirmation label
- Function: none
- Asset: planned to be reproduced in Dart code. (If PNGs are used: `pop_text_jp.png` / `pop_text_en.png`)

###### ➂ Yes button
- Function: Returns to the Home screen.
  - No motion.
  - If sound effects are ON, a tap sound is played.
- Asset: planned to be reproduced in Dart code. (If PNGs are used: `pop_yes_jp.png` / `pop_yes_en.png`)
  - Sound effect: `tap_button.mp3`

###### ➃ No button
- Function: Returns to the in-progress play screen.
  - No motion.
  - If sound effects are ON, a tap sound is played.
- Asset: planned to be reproduced in Dart code. (If PNGs are used: `pop_no_jp.png` / `pop_no_en.png`)
  - Sound effect: `tap_button.mp3`

##### [Specification]
- When the home screen button is pressed on the play screen and the confirmation dialog appears:
  - Motions and the time limit label freeze mid-state and become untouchable.
  - BGM is stopped for the time being (this may change based on on-device testing).
- After returning to the play screen via "No":
  - 2-player mode / player's turn in 1-player modes:
    - If it was during the post-OK motion:
      - The motion resumes (time is paused during the motion).
      - BGM resumes.
    - If it was before pressing OK:
      - **The time spent interrupted is applied to the timer.** If the time limit expired during the interruption, the result screen is shown immediately after resuming.
      - If the time limit has not expired, BGM resumes. If it has expired, BGM resumes after the result sound effect (described later in "Play Screen Details / Result Screen").
  - CPU's turn in 1-player modes:
    - If it was during the post-OK motion:
      - The motion resumes (time is paused during the motion).
      - BGM resumes.
    - If it was before pressing OK:
      - **The time spent interrupted is NOT applied to the timer.** Play resumes as-is.
      - BGM resumes.
- When returning to the Home screen via "Yes":
  - **Even if the time limit expired during the interruption and a result was decided internally, if the player returns home without resuming, no new ☆ is added to the home screen.**


### Play Screen Details / Result Screen
#### When the result is decided by all 3 hands reaching 0
##### 2-player mode
- When the near side (pink) wins:

    <img src="images/judge_image_2_win_jp.png" width="300">
    <img src="images/judge_image_2_win_en.png" width="300">

- When the far side (purple) wins:

    <img src="images/judge_image_2_lose_jp.png" width="300">
    <img src="images/judge_image_2_lose_en.png" width="300">

##### 1-player, 3 modes
- When the player wins:

    <img src="images/judge_image_1_win_jp.png" width="300">
    <img src="images/judge_image_1_win_en.png" width="300">

- When the player loses:

    <img src="images/judge_image_1_lose_jp.png" width="300">
    <img src="images/judge_image_1_lose_en.png" width="300">


#### When the result is decided by a loop
##### 2-player mode
- When the near side (pink) wins:

    <img src="images/judge_image_2_loop_win_jp.png" width="300">
    <img src="images/judge_image_2_loop_win_en.png" width="300">

- When the far side (purple) wins:

    <img src="images/judge_image_2_loop_lose_jp.png" width="300">
    <img src="images/judge_image_2_loop_lose_en.png" width="300">

- When it is a draw:

    <img src="images/judge_image_2_loop_draw_jp.png" width="300">
    <img src="images/judge_image_2_loop_draw_en.png" width="300">

##### 1-player, 3 modes
- When the player wins:

    <img src="images/judge_image_1_loop_win_jp.png" width="300">
    <img src="images/judge_image_1_loop_win_en.png" width="300">

- When the player loses:

    <img src="images/judge_image_1_loop_lose_jp.png" width="300">
    <img src="images/judge_image_1_loop_lose_en.png" width="300">

- When it is a draw:

    <img src="images/judge_image_1_loop_draw_jp.png" width="300">
    <img src="images/judge_image_1_loop_draw_en.png" width="300">

#### [Object Descriptions]
Objects behind `➀ Background` (hands, etc.) remain in the state they were in when the result was decided.

##### ➀ Background
- Function: none
- Asset: No PNG is prepared. **`#000000` (70% opacity)** spread across the entire screen. Reproduced in Dart code.

##### ➁ Return-to-home button
- Function: Returns to the Home screen with a leftward slide motion and a tap sound. **If a new ☆ is to be added to the home screen, it is applied.**
- Assets:
    - Japanese version: `return_to_home_jp.png`
    - English version: `return_to_home_en.png`
    - Sound effect: `tap_button.mp3` (if sound effects are ON)

##### ➂ Play-again button
- Function: Starts the game again from the start screen. No motion. A tap sound is played.
- Assets:
    - Japanese version: `play_again_jp.png`
    - English version: `play_again_en.png`
    - Sound effect: `tap_button.mp3` (if sound effects are ON)

##### ➃ Result label
- Function: Clearly indicates the result. When the result was decided by a loop, that fact is also indicated (**no tap function**). In the three 1-player modes, it is displayed only on the player's (near) side.
- Assets:
  - When the result was decided by all 3 hands reaching 0 / by the time limit:
    - Win: `win_jp.png` (Japanese version) / `win_en.png` (English version)
    - Lose: `lose_jp.png` (Japanese version) / `lose_en.png` (English version)
  - When the result was decided by a loop:
    - Win: `win_loop_jp.png` (Japanese version) / `win_loop_en.png` (English version)
    - Lose: `lose_loop_jp.png` (Japanese version) / `lose_loop_en.png` (English version)
    - Draw: `draw_loop_jp.png` (Japanese version) / `draw_loop_en.png` (English version)

#### [BGM and Sound Effects]
- If sound effects are ON:
  - 2-player mode:
    - When a winner is decided: `win.mp3` is played regardless of which player wins.
    - When it is a draw: `draw.mp3` is played.
  - 1-player 3 modes:
    - When the player wins: `win.mp3` is played.
    - When the player loses: `lose.mp3` is played.
    - When it is a draw: `draw.mp3` is played.
- If the BGM setting is ON, **BGM is stopped while the sound effect is playing**, and resumes after the sound effect ends.

<br>
<br>

## Settings Screen
### Settings Screen Overview
The Settings screen is where the "2-player time limit", "sound effects ON/OFF", "BGM ON/OFF", and "language" are configured.

### Settings Screen Details
#### [Japanese version]

<img src="images/settings_image_jp_with_comments.png" width="400">

#### [English version]

<img src="images/settings_image_en_with_comments.png" width="400">

#### [Object Descriptions]
##### ➀ Background
- Function: none
- Asset: `background_settings.png`
- Notes: fixed at 16:9

##### ➁, ➂, ➄, ➆, ➈ Various labels
- Function: none
- Assets: No PNG is prepared. Reproduced in Dart code.

##### ➃ Time limit selection button
- Function: Selects the time limit for 2-player mode. No button tap sound or motion.
- Assets: No PNG is prepared. **Reproduced in Dart code.**
        (Preparing PNGs per color would increase the number of PNGs.)
        (Adjusting the width for "無制限/Unlimited" etc. may be difficult, so as a last resort this may be reproduced by swapping in PNGs.)

##### ➅, ➇ ON/OFF toggle buttons
- Function: ➅ toggles sound effects ON/OFF; ➇ toggles BGM ON/OFF. No button tap sound or motion.
- Assets: No PNG is prepared. **Reproduced in Dart code.**
        (Reproduction by swapping in PNGs is also acceptable; to be adjusted while writing the code.)

##### ➉ Language selection button
- Function: Switches the language between Japanese and English. No button tap sound or motion.
- Assets: No PNG is prepared. **Reproduced in Dart code.**
        (Reproduction by swapping in PNGs is also acceptable; to be adjusted while writing the code.)

##### ⑪ Return-to-home button
- Function: Transitions to the Home screen. No motion. If the sound effect setting is ON, a button tap sound (sound effect) is played.
- Assets:
  - `settings_home.png` (shared by the Japanese and English versions)
  - Sound effect: `tap_button.mp3`

<br>
<br>

## Rules Screen
### Rules Screen Overview
This screen explains the rules.
- Both the Japanese and English versions consist of 8 pages.
- Pages are navigated by tapping the arrow marks or by swiping left/right.

### Rules Screen Details
#### [Japanese version]

<img src="images/rules_image_1_jp.png" width="300">
<img src="images/rules_image_2_jp.png" width="300">
<img src="images/rules_image_3_jp.png" width="300">
<img src="images/rules_image_4_jp.png" width="300">
<img src="images/rules_image_5_jp.png" width="300">
<img src="images/rules_image_6_jp.png" width="300">
<img src="images/rules_image_7_jp.png" width="300">
<img src="images/rules_image_8_jp.png" width="300">

#### [English version]

<img src="images/rules_image_1_en.png" width="300">
<img src="images/rules_image_2_en.png" width="300">
<img src="images/rules_image_3_en.png" width="300">
<img src="images/rules_image_4_en.png" width="300">
<img src="images/rules_image_5_en.png" width="300">
<img src="images/rules_image_6_en.png" width="300">
<img src="images/rules_image_7_en.png" width="300">
<img src="images/rules_image_8_en.png" width="300">

#### [Object Descriptions]
##### ➀ Background
- Function: none
- Assets:
  - Japanese version:
    - Page 1: `rules_1_jp.png`
    - Page 2: `rules_2_jp.png`
    - Page 3: `rules_3_jp.gif`
    - Page 4: `rules_4_jp.gif`
    - Page 5: `rules_5_jp.gif`
    - Page 6: `rules_6_jp.gif`
    - Page 7: `rules_7_jp.png`
    - Page 8: `rules_8_jp.png`
  - English version:
    - Page 1: `rules_1_en.png`
    - Page 2: `rules_2_en.png`
    - Page 3: `rules_3_en.gif`
    - Page 4: `rules_4_en.gif`
    - Page 5: `rules_5_en.gif`
    - Page 6: `rules_6_en.gif`
    - Page 7: `rules_7_en.png`
    - Page 8: `rules_8_en.png`
- Notes: fixed at 16:9. GIFs in particular are heavy, so **if the app performs poorly, the plan will switch to reproducing each page in Dart code**.

##### ➁ Previous-page button
- Function:
  - Tap to go back to the previous page.
  - **Swiping right also goes back.**
  - Uses a leftward slide motion.
  - **Page 1 does not have this button.**
  - No tap/swipe sound.
- Asset: `back_page.png` (shared by the Japanese and English versions)

##### ➂ Next-page button
- Function:
  - Tap to advance to the next page.
  - **Swiping left also advances to the next page.**
  - Uses a rightward slide motion.
  - **Page 8 does not have this button.**
  - No tap/swipe sound.
- Asset: `next_page.png` (shared by the Japanese and English versions)

##### ➃ Return-to-home button
- Function: Transitions to the Home screen. No motion. If the sound effect setting is ON, a button tap sound (sound effect) is played.
- Assets:
  - `settings_home.png` (shared by the Japanese and English versions)
  - Sound effect: `tap_button.mp3`