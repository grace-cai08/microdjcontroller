import ddf.minim.*;
import ddf.minim.ugens.*;
import processing.serial.*;

//input vars
Serial port;
int joyX, joyY, joySW, btn1, btn2, pot; //inputs

//minim vars
Minim minim;
AudioOutput out; //laptop speakers
FilePlayer player; //plays mp3 file
TickRate rateControl; //playback speed
MoogFilter moog;
Delay delay;

//value vars
float tempo = 1.0;
int prevBtn1 = 0;
int prevBtn2 = 0;
int joystickCenter = 1860;
int deadband = 300; //ignore accidental nudges to joystick
int pot_max = 4095;
int pot_mid = 2048;
int loopState = 0; //0 = no loop, 1 = begin set, 2 = looping
int loopBegin;
int loopEnd;
int ledState = -1;
int lastLoopPress = 0;

//browse vars
String[] files = {"track1.mp3", "track2.mp3", "track3.mp3"};
String[] titles = {"Daft Punk - Doin' It Right",
                   "SOPHIE - NOTHING MORE TO SAY (Remix)",
                   "Underworld - Born Slippy (Nuxx)"};
float[] bpms = {89, 127, 140};
int selected = 0; //highlighted track
int loaded = 0; //currently in the player
boolean joyXReady = true; //true is joy x val is centered (for browsing)
int prevJoySW = 0;
boolean browseMode = false;

//display vars
int margin = 40;
int listX, listW; //tracklist panel
int deckW; //w of left panel
int barX, barY, barW, barH; //progress bar
int boxX, boxY, boxW, boxH; //waveform rect
PFont titleFont;
PFont headerFont;
PFont bodySerif;
PFont bodySans;
int headerH = 100;
int contentY; //everything below header


void setup() {
  
  fullScreen();
  
  contentY = headerH + margin;
  
  listX = width * 3/4;
  listW = width / 4 - margin;
  deckW = listX - 2 * margin;
  
  barX = margin; barY = contentY + 140; barW = deckW; barH = 40;
  
  boxX = margin;
  boxY = barY + barH + 40;
  boxW = deckW;
  boxH = height - boxY - margin;
  
  minim = new Minim(this);
  out = minim.getLineOut();
  moog = new MoogFilter(20000, 0.3);
  delay = new Delay(0.4, 0.0, true, true);
  
  player = new FilePlayer(minim.loadFileStream("track1.mp3"));
  
  rateControl = new TickRate(1.0);
  rateControl.setInterpolation (true);
  
  //AUDIO CHAIN
  player.patch(rateControl).patch(moog).patch(delay).patch(out);
  
  printArray(Serial.list());
  String portName = Serial.list()[13];
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n');
  
  //fonts for display
  titleFont = createFont("goozette.otf", 36);
  headerFont = createFont("Redaction50-Bold.otf", 20);
  bodySerif = createFont("Redaction35-Regular.otf", 18);
  bodySans = createFont("SansSerif", 18);
}

void serialEvent(Serial p) {
  String line = p.readStringUntil('\n'); //data received from serial port
  if (line == null) return;

  int[] v = int(split(trim(line), ','));
  if (v.length == 6) {
    joyX = v[0];  joyY = v[1];  joySW = v[2]; //assign values from serial port array to inst vars (see arduino comments)
    btn1 = v[3];  btn2 = v[4];  pot  = v[5];
  }
}

//display
void draw() {  
  input();
  background(0);
  drawPlayScreen();
  drawTrackList();
  updateLED();

}

void input() {
  
  if (joySW == 1 && prevJoySW == 0) { //toggle browsemode when joystick is clicked
    if(!browseMode) {
      browseMode = true;
      selected= loaded;
    } else {
       if (selected != loaded) loadTrack(selected);
       browseMode = false;
    }
  }
  
  prevJoySW = joySW;
  
  if (browseMode) {
    browse();
  } else {
    
    //joystick X: tempo
    if (joyX > joystickCenter + deadband) setTempo(tempo + .005);
    if (joyX < joystickCenter - deadband) setTempo(tempo - .005);
    
    //joystick Y: scrubbing
    if (joyY > joystickCenter + deadband) player.skip(150);
    if (joyY < joystickCenter - deadband) player.skip(-150);
    
     //black button/btn2 - set loop points
    if (btn2 == 1 && prevBtn2 == 0 && millis() - lastLoopPress > 250) {
    loopTrack(loopState);
    lastLoopPress = millis();
    }
  }
  
  prevBtn2 = btn2;
  
  //red button/btn1 - play/pause track
  if (btn1 == 1 && prevBtn1 == 0) togglePlay();
  prevBtn1 = btn1;
  
  //potentiometer: color effects
  applyCFX(pot);

}

//play pause music
void togglePlay() {
  if (player.isPlaying()) {player.pause();}
  else player.play();
}

//set tempo (adapted from tickRateExample)
void setTempo(float t) {
  tempo = constrain(t, .5, 1.5);
  rateControl.value.setLastValue(tempo); //send new tempo to audio engine
}

//cfx (adapted from moogFilterExample)
void applyCFX(int v) {
    
  int noFilterBoundary = 150; //at pot_mid +-150 do not add any filter
  float freq;
  float rez;
  
  if (v < pot_mid - noFilterBoundary) {
    moog.type = MoogFilter.Type.LP;
    freq = map(v, 0, (pot_mid - noFilterBoundary), 200, 20000);
    rez = map(v, 0, (pot_mid - noFilterBoundary), 0.7, 0); 
  } else if (v > pot_mid + noFilterBoundary) {
    moog.type = MoogFilter.Type.HP;
    freq = map(v, (pot_mid + noFilterBoundary), pot_max, 20, 4000);
    rez = map(v, (pot_mid + noFilterBoundary), pot_max, 0, 0.7);
  } else {
    moog.type = MoogFilter.Type.LP;
    freq = 20000;
    rez = 0;
  }
  
  float del = map(v, 0, pot_max, 0.1, 0);
  
  moog.frequency.setLastValue(freq);
  moog.resonance.setLastValue(rez);
  delay.delAmp.setLastValue(del);
  
}

//track looping (adapted from setLoopPoints)
void loopTrack(int status) {
  if (status == 0) {
    loopBegin = player.position();
    loopState = 1;
  }
  else if (status == 1) {
    loopEnd = player.position();
    loopState = 2;
    player.setLoopPoints(loopBegin, loopEnd);
    player.loop();
  }
  else {
    player.setLoopPoints(0, player.length());
    player.play();
    loopState = 0;
  }
}

//send looping/playing state information to esp32 to turn on led light
void updateLED() {
  int newState;
  if (!player.isPlaying()) newState = 0;
  else if (loopState == 2) newState = 2;
  else newState = 1;
  
  if (newState != ledState) {
    port.write(str(newState));
    ledState = newState;
  }
}

void browse() {
  if (joyXReady && joyX > joystickCenter + deadband) {
    selected--;
    joyXReady = false;
  }
  else if (joyXReady && joyX < joystickCenter - deadband) {
    selected++;
    joyXReady = false;
  }
  
  if (abs(joyX - joystickCenter) < deadband) joyXReady = true; //returned to center
  selected = constrain(selected, 0, files.length - 1);
}

void loadTrack(int i) {
  player.pause();
  player.unpatch(rateControl); //disconnect track from patch strema
  player.close();
  player = new FilePlayer(minim.loadFileStream(files[i]));
  player.patch(rateControl);
  loaded = i;
  loopState = 0;
  setTempo(1.0); //revert tempo back to normal
}





// display functions --------------------------------------------------------------

//adapted from drawWaveformAndLevel example code
void drawWave() {
  
  noFill();
  stroke(80);
  rect(boxX, boxY, boxW, boxH);
  
  float leftMid = boxY + boxH / 4.0;
  float rightMid = boxY + 3 * boxH / 4.0;
  float amp = boxH / 4.0;
  
  stroke(255, 15, 240);
  for (int i = 0; i < out.bufferSize()-1; i++) {
    float x1 = map( i, 0, out.bufferSize(), boxX, boxX + boxW);
    float x2 = map( i+1, 0, out.bufferSize(), boxX, boxX + boxW);
    line( x1, leftMid + out.left.get(i)*amp, x2, leftMid + out.left.get(i+1)*amp );
    line( x1, rightMid + out.right.get(i)*amp, x2, rightMid + out.right.get(i+1)*amp );
  }
}

void drawPositionLine() {
  float posx = map(player.position(), 0, player.length(), barX, barX + barW); //current position in song
  stroke(0, 200, 0);
  line(posx, barY, posx, barY + barH);
}

void statusText() {
  
  textFont(headerFont);
  fill(150);
  textSize(14);
  text("NOW PLAYING: ", margin, contentY + 15);
  
  fill(255);
  textFont(headerFont);
  textSize(40);
  text(titles[loaded], margin, contentY + 60);
  
  String info = nf(bpms[loaded] * tempo, 1, 1) + " BPM";
  info += "    |    " + (player.isPlaying() ? "Playing" : "Paused");
  if (loopState == 1) info += "   |   LOOP START SET";
  if (loopState == 2) info += "   |   LOOPING";
  
  fill(180);
  textSize(18);
  textFont(bodySans);
  text(info, margin, contentY + 100);
}

void drawProgressBar () {
  float progress = player.position() / (float) player.length();
  noFill();
  stroke(255);
  rect(barX, barY, barW, barH);
  noStroke();
  fill(255, 15, 240);
  rect(barX, barY, barW*progress, barH);
}

void drawLoopPoints() {
  if (loopState >= 1) {
    float beginX = map(loopBegin, 0, player.length(), barX, barX + barW);
    stroke(255, 200, 0);
    line(beginX, barY, beginX, barY + barH);
  }
  if (loopState == 2) {
    float endX = map(loopEnd, 0, player.length(), barX, barX + barW);
    stroke(255, 200, 0);
    line(endX, barY, endX, barY + barH);
  }
}

void drawPlayScreen() {
  drawHeader();
  statusText();
  drawProgressBar();
  drawLoopPoints();
  drawPositionLine();
  drawWave();
}

void drawHeader() {
  
  textFont(titleFont);
  textSize(40);
  fill(255, 15, 240);
  textAlign(CENTER, CENTER);
  text("micro(dj)controller", width / 2, margin / 2 + headerH / 2);
  textAlign(LEFT, BASELINE);
  
}

/* GENERATED BY CLAUDE, midly edited by me */
void drawTrackList() {
  // panel border: pink while browsing, grey otherwise
  noFill();
  if (browseMode) stroke(255, 15, 240);
  else stroke(80);
  strokeWeight(2);
  rect(listX, contentY, listW, height - contentY - margin);
  strokeWeight(1);

  fill(255);
  textSize(20);
  textFont(headerFont);
  text("tracklist ", listX + 20, contentY + 40);

  int rowH = 60;   // height of each row
  for (int i = 0; i < titles.length; i++) {
    float y = contentY + 70 + i * rowH;   // top of this row

    // highlight the selected row, only while browsing
    if (browseMode && i == selected) {
      noStroke();
      fill(255, 15, 240, 80);   // see-through pink
      rect(listX, y, listW, rowH);
    }

    // title: pink with ▶ if it's the loaded track
    if (i == loaded) fill(255, 15, 240);
    else fill(255);
    textFont(bodySans);
    textSize(14);
    text((i == loaded ? "▶ " : "") + titles[i], listX + 20, y + 25);

    // BPM underneath, in grey
    fill(150);
    textSize(14);
    textFont(bodySans);
    text(nf(bpms[i], 1, 0) + " BPM", listX + 20, y + 47);
  }

  // hint at the bottom
  fill(120);
  textSize(14);
  textFont(bodySerif);
  text(browseMode ? "tilt joystick to scroll | click to load" : "click joystick to browse",
       listX + 20, height - margin - 20);
}
