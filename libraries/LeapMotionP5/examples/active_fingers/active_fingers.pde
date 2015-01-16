import com.onformative.leap.LeapMotionP5;
import com.leapmotion.leap.Finger;

LeapMotionP5 leap;

public void setup() {
  size(displayWidth, displayHeight, OPENGL);
  leap = new LeapMotionP5(this);
  textSize(17);
}

public void draw() {
  background(0);
  //background(255);
  fill(255);
  String text = "";
  for (Finger finger : leap.getFingerList ()) {
    PVector fingerPos = leap.getTip(finger);
    text += "fingerPos: " + fingerPos + "\n";
    //ellipse(fingerPos.x, fingerPos.y, 10, 10);
    
    float x = fingerPos.x;
    float y = fingerPos.y;
    float z = fingerPos.z;
    pushMatrix();
    translate(x, y, z);
    sphere(5);
    popMatrix();
  }
  text(leap.getFingerList() + " " + leap.getFingerList().size() + "\n" + text, 30, 30);
}

public void stop() {
  leap.stop();
}

