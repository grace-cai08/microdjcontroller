const int JOY_X  = 39;
const int JOY_Y  = 32;
const int JOY_SW = 33;
const int POT    = 36;
const int BTN1   = 2;
const int BTN2   = 25;
const int LED    = 15;
char ledMode = '0';

void setup() {
  Serial.begin(115200);
  pinMode(JOY_SW, INPUT_PULLUP);
  pinMode(BTN1, INPUT_PULLUP);
  pinMode(BTN2, INPUT_PULLUP);
  pinMode(LED, OUTPUT);
}

//read in voltages from each input source and send back to laptop as an array
//array format: [joy_x, joy_y, joy_sw, red button/btn1, black button/btn2, potentiometer]
void loop() {

  //led light programming
  if (Serial.available() > 0) {
    char c = Serial.read(); //state sent by processing
    if (c == '0' || c == '1' || c == '2') ledMode = c;
  }

  if (ledMode == '0') digitalWrite(LED, LOW);
  if (ledMode == '1') digitalWrite(LED, HIGH);
  if (ledMode == '2') {
    digitalWrite(LED, millis()/250 % 2); //claude generated
  }

  Serial.print(analogRead(JOY_X));                    Serial.print(',');
  Serial.print(analogRead(JOY_Y));                    Serial.print(',');
  Serial.print(digitalRead(JOY_SW) == LOW ? 1 : 0);   Serial.print(',');
  Serial.print(digitalRead(BTN1) == LOW ? 1 : 0);     Serial.print(',');
  Serial.print(digitalRead(BTN2) == LOW ? 1 : 0);     Serial.print(',');
  Serial.println(analogRead(POT));
  delay(20);
}