import oscP5.*;
import netP5.*;
import ddf.minim.*;
import gab.opencv.*;
import processing.video.*;
import processing.sound.*;
import java.awt.Rectangle;
import java.awt.event.KeyEvent;

OscP5 osc;
NetAddress netAddr;
Capture camera;
OpenCV opencv;
Rectangle[] faces;
Minim minim;
AudioInput in;
float volumeIn, rotationX = -0.5, wheel_value = 0, zoom = 0, calibrated_mouseX = 0, calibrated_mouseY = 0;
int save_count=0, offsetX = 0, offsetY = 0, clickX=0, clickY=0, dragX=50, dragY=50, x = 0, y = 0, line_count=101, circle_count=101, circle_count_d=101, rect_count=0, rect_count_realtime=0, beat_count_realtime=0;
boolean draw = false, line = false, bezier = false, point = false, arc = false, triangle = false, rect = false, quad = false, ellipse = false, text = false, noise = false, camera_sampling = false, clear = false, face_calibration = false;
boolean press_1 = false, press_2 = false, press_3 = false, press_4 = false, press_5 = false, press_6 = false, press_7 = false, press_8 = false, press_space = false;
char draw_mode = ' ';

void DetectFace() {

  if (camera.available()) camera.read();
  opencv = new OpenCV(this, camera);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  faces = opencv.detect();
}

void setup() {

  size(1920, 1080, P3D);
  background(244, 244, 233);
  colorMode(RGB, 255);

  minim = new Minim(this);
  in = minim.getLineIn(Minim.MONO, 512);

  //Send Note On
  netAddr = new NetAddress("127.0.0.1", 57120);
  osc = new OscP5(this, 7000);
  osc.send(new OscMessage("/noteon"), netAddr);
}

void draw() {

  if (face_calibration && faces.length == 1) {
    thread("DetectFace");
    zoom = 100000 * (faces[0].height - faces[0].y) / height;
  } else {
    zoom = 0;
  }
  
  //Get & Convert Mic Amplitude
  volumeIn = map(in.left.level(), 0, 0.5, 0, 100 + 10 * abs(wheel_value) + zoom);

  //Draw Primitives
  colorMode(HSB, 2);
  stroke(map(in.left.level(), 0, 0.5, 0, 2), 2, 2, map(in.left.level(), 0, 0.5, 0, 2));
  translate(width/2, height/2, 0);
  calibrated_mouseX = mouseX - width / 2;
  calibrated_mouseY = mouseY - height / 2;
  if (draw) {
    if (line) {
      line(clickX+random(-volumeIn, volumeIn), clickY+random(-volumeIn, volumeIn), calibrated_mouseX+random(-volumeIn, volumeIn), calibrated_mouseY+random(-volumeIn, volumeIn));
    } else if (point) {
      for (int noise_count=0; noise_count<volumeIn+100; ++noise_count) {
        point(calibrated_mouseX+random(-volumeIn, volumeIn), calibrated_mouseY+random(-volumeIn, volumeIn));
      }
    } else if (arc) {
      noFill();
      arc(calibrated_mouseX, calibrated_mouseY, 50+random(-volumeIn, volumeIn), 50+random(-volumeIn, volumeIn), 0, HALF_PI);
      arc(calibrated_mouseX, calibrated_mouseY, 50+random(-volumeIn, volumeIn), 50+random(-volumeIn, volumeIn), HALF_PI, PI);
      arc(calibrated_mouseX, calibrated_mouseY, 50+random(-volumeIn, volumeIn), 50+random(-volumeIn, volumeIn), PI, PI+HALF_PI);
      arc(calibrated_mouseX, calibrated_mouseY, 50+random(-volumeIn, volumeIn), 50+random(-volumeIn, volumeIn), PI+HALF_PI, TWO_PI);
    } else if (bezier) {
      noFill();
      beginShape();
      vertex(clickX, clickY);
      bezierVertex(clickX + (calibrated_mouseX - clickX) / 3 + random(-volumeIn, volumeIn), clickY + (calibrated_mouseY - clickY) / 3 + random(-volumeIn, volumeIn), clickX + (calibrated_mouseX - clickX) * 2 / 3 + random(-volumeIn, volumeIn), clickY + (calibrated_mouseY - clickY) * 2 / 3 + random(-volumeIn, volumeIn), calibrated_mouseX, calibrated_mouseY);
      endShape();
    } else if (triangle) {
      fill(map(in.left.level(), 0, 0.5, 0, 2), 2, 2, map(in.left.level(), 0, 0.5, 0, 1));
      triangle(calibrated_mouseX+random(-volumeIn, volumeIn)-28, calibrated_mouseY+random(-volumeIn, volumeIn)+16.165807537, calibrated_mouseX+random(-volumeIn, volumeIn), calibrated_mouseY+random(-volumeIn, volumeIn)-32.331615074, calibrated_mouseX+random(-volumeIn, volumeIn)+28, calibrated_mouseY+random(-volumeIn, volumeIn)+16.165807537);
    } else if (rect) {
      fill(map(in.left.level(), 0, 0.5, 0, 2), 2, 2, map(in.left.level(), 0, 0.5, 0, 1));
      rectMode(CENTER);
      rect(calibrated_mouseX, calibrated_mouseY, 55+random(-volumeIn, volumeIn), 55+random(-volumeIn, volumeIn));
    } else if (quad) {
      fill(map(in.left.level(), 0, 0.5, 0, 2), 2, 2, map(in.left.level(), 0, 0.5, 0, 1));
      quad(calibrated_mouseX, calibrated_mouseY, calibrated_mouseX+random(-volumeIn, volumeIn), calibrated_mouseY+random(-volumeIn, volumeIn), calibrated_mouseX+random(-volumeIn, volumeIn), calibrated_mouseY+random(-volumeIn, volumeIn), calibrated_mouseX+random(-volumeIn, volumeIn), calibrated_mouseY+random(-volumeIn, volumeIn));
    } else if (ellipse) {
      fill(map(in.left.level(), 0, 0.5, 0, 2), 2, 2, map(in.left.level(), 0, 0.5, 0, 1));
      ellipseMode(CENTER);
      ellipse(calibrated_mouseX, calibrated_mouseY, 55+random(-volumeIn, volumeIn), 55+random(-volumeIn, volumeIn));
    } else if (noise) {
      fill(map(in.left.level(), 0, 0.5, 0, 2), 2, 2, map(in.left.level(), 0, 0.5, 0, 1));
      for (int noise_count=0; noise_count<volumeIn; ++noise_count) {
        point(random(- width / 2, width / 2), random(- height / 2, height / 2));
      }
    } else if (camera_sampling) {
      camera.loadPixels();
      for(int y = 0; y < 240; ++y) {
        for(int x = 0; x < 320; ++x) {
          stroke(camera.pixels[y * 320 + x],map(in.left.level(), 0, 0.5, 0, 1));
          point(calibrated_mouseX + 40*x/320.0-20+random(-volumeIn, volumeIn), calibrated_mouseY + 30*y/240.0-15+random(-volumeIn, volumeIn));
        }
      }
    } else if (clear) {
      colorMode(RGB, 255);
      background(244, 244, 233);
    }
  }
  rotationX += wheel_value;

  //Send Mic Amplitude
  OscMessage msg = new OscMessage("/amp");
  msg.add(in.left.level());
  osc.send(msg, netAddr);
}

void mousePressed() {
  clickX = mouseX - width / 2;
  clickY = mouseY - height / 2;
  if (draw) {
    draw = false;
    cursor(ARROW);
  } else {
    draw = true;
    cursor(CROSS);
  }
}

void keyPressed() {
  wheel_value = 0;
  if (keyCode == 107) {
    if (face_calibration) {
      camera.stop();
      face_calibration = false;
    } else {
      camera = new Capture(this, 320, 240, 30);
      camera.start();
      opencv = new OpenCV(this, 640, 480);
      if (camera.available()) camera.read();
      opencv = new OpenCV(this, camera);
      opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
      faces = opencv.detect();
      face_calibration = true;
    }
    return;
  }
  line = false;
  bezier = false;
  point = false;
  arc = false;
  triangle = false;
  rect = false;
  quad = false;
  ellipse = false;
  text = false;
  noise = false;
  camera_sampling = false;
  clear = false;
  if (camera != null && face_calibration == false && keyCode != 106) {
    camera.stop();
  }
  if (keyCode == 32) {
    save("./save/" + save_count + ".png");
    ++save_count;
  } else if (keyCode == 97) {
    point = true;
  } else if (keyCode == 98) {
    line = true;
  } else if (keyCode == 99) {
    bezier = true;
  } else if (keyCode == 100) {
    arc = true;
  } else if (keyCode == 101) {
    ellipse = true;
  } else if (keyCode == 102) {
    triangle = true;
  } else if (keyCode == 103) {
    rect = true;
  } else if (keyCode == 104) {
    quad = true;
  } else if (keyCode == 105) {
        noise = true;
  } else if (keyCode == 106) {
    camera = new Capture(this, 320, 240, 30);
    camera.start();
    if (camera.available()) camera.read();
    camera_sampling = true;
  } else if (keyCode == 108) {
    clear = true;
  }
}

void mouseWheel(MouseEvent event) {
  wheel_value += event.getCount();
}

void stop(){
  in.close();
  minim.stop();
  super.stop();
}