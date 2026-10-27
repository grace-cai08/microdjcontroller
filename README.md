# micro(dj)controller

## Preview

![](/media/preview.gif)

## Required components

* ESP32/LilyGo TTGO T-Display
* Breadboard
* Button x2
* Potentiometer
* Joystick
* LED
* 220Ω resistor
* 5 female/male wires
* jumper wires

## Project Structure

```
.
├── README.md
├── controller              #main program and custom fonts/tracks used in program
│   ├── controller.pde
│   └── data
│       ├── Redaction35-Regular.otf
│       ├── Redaction50-Bold.otf
│       ├── goozette.otf
│       ├── track1.mp3
│       ├── track2.mp3
│       └── track3.mp3
├── input-wiring
│   └── input-wiring.ino    #ESP32 program
└── media                   #media used in README               
    ├── module-2-fritzing_bb.png
    └── preview.gif

```

## System Diagram

![](/media/module-2-fritzing_bb.png)

### ESP32 Pin connections

In case the digits on the diagram are difficult to read, below is a list of each component and the ESP32 pin it is connected to in order for the program to run.

|Component|ESP32 Pin|
|---|---|
|Joystick VRx|39|
|Joystick VRy|32|
|Joystick SW|33|
|Potentiometer|36|
|Button 1|2|
|Button 2|25|
|LED (via resistor)|15|


## Recreation
These instructions assume that the user already has the Arduino IDE installed, Processing installed, and the required hardware components.

1. Clone this repository by either clicking the download icon or with the url: ```https://github.com/grace-cai08/microdjcontroller.git```

2. Assemble the components. (See the Fritzing diagram)

3. Run `input-wiring.ino`, open the serial montior and make sure that you can see input streams from all components. Close the monitor afterwards.

4. Run `controller.pde`, ensure that the port number (for the ESP32) and baud rate is correct.

5. The program is supposed to run at full screen, press `Esc` to exit. Happy mixing!

## Mixing functions

Below is a quick summary of what each component function is programmed to do:

- Clicking on the joystick switches between track selection mode and mixing mode.
- In track selection mode:
    - Joystick x tilt: allows you to navigate the tracklist.
    - Joystick SW/button: once a track has been selected, clicking the joystick button again loads the selected track and switches you back to mixing mode.
- In mixing mode:
    - Button 1: plays/pauses the current track.
    - Joystick x tilt: speeds up/slows down the current track.
    - Joystick y tilt: scrubs back and forth through the track.
    - Potentiometer: applies a general color effect filter, with the left end sounding 'muffled' and the right end sounding 'sharp'.
    - Button 2:
        - first press sets loop start point.
        - second press sets loop end point and begins the loop immediately.
        - third press exits out of the loop.
    - LED light: lit when track is playing, blinking when track is looping.

*note: Due to layout restrictions I decided to 'attach' the joystick to my breadboard at a 90° rotation in order for the wires not to overlap with other components on the board. So although it appears that I'm tilting the joystick y as I'm moving it vertically, I am actually moving the joystick x value. Sorry for the confusion!