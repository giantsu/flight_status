import processing.opengl.*;

import de.bezier.data.*;

import com.onformative.leap.LeapMotionP5;
import com.leapmotion.leap.Finger;
import com.leapmotion.leap.Hand;
import com.leapmotion.leap.Frame;
import com.leapmotion.leap.Gesture.State;
import com.leapmotion.leap.Gesture.Type;
import com.leapmotion.leap.SwipeGesture;
import com.leapmotion.leap.Vector;

import controlP5.*;

XlsReader reader;
LeapMotionP5 leap;
ControlP5 cp5;

PImage bg;
PImage texmap;

int sDetail = 35;  // Sphere detail setting
float rotationX = 0;
float rotationY = 0;
float velocityX = 0;
float velocityY = 0;
float globeRadius = 450;
float pushBack = 0;

float[] cx, cz, sphereX, sphereY, sphereZ;
float sinLUT[];
float cosLUT[];
float SINCOS_PRECISION = 0.5;
int SINCOS_LENGTH = int(360.0 / SINCOS_PRECISION);

int timer = 0;
int sec;

float sx = 40;

boolean bool = true;

int hour = hour();
int minute = minute();
int second = second();

int hour2 = hour() + 24;

PImage back;

int dpC = 0;
int crF = 0;

PVector swipePosBefore;
PVector swipePosAfter;

String flightNumber = "";

String text = "";

void setup() {
  //size(1024, 700, P3D);  
  size(displayWidth, displayHeight, OPENGL);
  //PFont font = loadFont("Meiryo-48.vlw");
  PFont font = createFont("メイリオ", 48, true);
  textFont(font);
  leap = new LeapMotionP5(this);
  colorMode(RGB, 256, 256, 256, 100);
  back = loadImage("space_3.jpg");
  texmap = loadImage("world32k.jpg");    
  reader = new XlsReader(this, "AirportDep(Converted).xls");
  initializeSphere(sDetail);
  cp5 = new ControlP5(this);
  cp5.addTextfield("flightNumber")
     .setPosition(width * 0.8,50)
     .setSize(200,40)
     .setFont(createFont("arial",20))
     .setAutoClear(false)
     ;
}

void draw() {    
  background(0);
  hint(DISABLE_DEPTH_MASK);
  image(back, 0, 0, width, height);
  hint(ENABLE_DEPTH_MASK);
  renderGlobe();
  clock();
  slideBar();
  timeSpeed();
  countFlight();
  leapMotion();
  textField();
//  stroke(255, 0, 0);
//  line(0, 0, 0, width, height, 0);
//  camera(width, height/2, width/2, width/2, height/2, 0, 0, 1, 0);
}

void renderGlobe() {
  pushMatrix();
  translate(width/2.0, height/2.0, pushBack);
  pushMatrix();
  noFill(); 
  stroke(255, 200);
  strokeWeight(2);
  smooth();
  popMatrix();
  lights();    
  pushMatrix();
  rotateX( radians(-rotationX) );  
  rotateY( radians(270 - rotationY) );
  fill(200);
  noStroke();
  textureMode(IMAGE);  
  texturedSphere(globeRadius, texmap);
  drawAirRoute();
  popMatrix();  
  popMatrix();
  rotationX += velocityX;
  rotationY += velocityY;
  velocityX *= 0.95;
  velocityY *= 0.95;

  // Implements mouse control (interaction will be inverse when sphere is  upside down)
  if (mousePressed) {
    if (bool == true) {
      velocityX += (mouseY-pmouseY) * 0.01;
      velocityY -= (mouseX-pmouseX) * 0.01;
    }
  }
}

void initializeSphere(int res)
{
  sinLUT = new float[SINCOS_LENGTH];
  cosLUT = new float[SINCOS_LENGTH];

  for (int i = 0; i < SINCOS_LENGTH; i++) {
    sinLUT[i] = (float) Math.sin(i * DEG_TO_RAD * SINCOS_PRECISION);
    cosLUT[i] = (float) Math.cos(i * DEG_TO_RAD * SINCOS_PRECISION);
  }

  float delta = (float)SINCOS_LENGTH/res;
  float[] cx = new float[res];
  float[] cz = new float[res];

  // Calc unit circle in XZ plane
  for (int i = 0; i < res; i++) {
    cx[i] = -cosLUT[(int) (i*delta) % SINCOS_LENGTH];
    cz[i] = sinLUT[(int) (i*delta) % SINCOS_LENGTH];
  }

  // Computing vertexlist vertexlist starts at south pole
  int vertCount = res * (res-1) + 2;
  int currVert = 0;

  // Re-init arrays to store vertices
  sphereX = new float[vertCount];
  sphereY = new float[vertCount];
  sphereZ = new float[vertCount];
  float angle_step = (SINCOS_LENGTH*0.5f)/res;
  float angle = angle_step;

  // Step along Y axis
  for (int i = 1; i < res; i++) {
    float curradius = sinLUT[(int) angle % SINCOS_LENGTH];
    float currY = -cosLUT[(int) angle % SINCOS_LENGTH];
    for (int j = 0; j < res; j++) {
      sphereX[currVert] = cx[j] * curradius;
      sphereY[currVert] = currY;
      sphereZ[currVert++] = cz[j] * curradius;
    }
    angle += angle_step;
  }
  sDetail = res;
}

// Generic routine to draw textured sphere
void texturedSphere(float r, PImage t) 
{
  int v1, v11, v2;
  r = (r + 240 ) * 0.33;
  beginShape(TRIANGLE_STRIP);
  texture(t);
  float iu=(float)(t.width-1)/(sDetail);
  float iv=(float)(t.height-1)/(sDetail);
  float u=0, v=iv;
  for (int i = 0; i < sDetail; i++) {
    vertex(0, -r, 0, u, 0);
    vertex(sphereX[i]*r, sphereY[i]*r, sphereZ[i]*r, u, v);
    u+=iu;
  }
  vertex(0, -r, 0, u, 0);
  vertex(sphereX[0]*r, sphereY[0]*r, sphereZ[0]*r, u, v);
  endShape();   

  // Middle rings
  int voff = 0;
  for (int i = 2; i < sDetail; i++) {
    v1=v11=voff;
    voff += sDetail;
    v2=voff;
    u=0;
    beginShape(TRIANGLE_STRIP);
    texture(t);
    for (int j = 0; j < sDetail; j++) {
      vertex(sphereX[v1]*r, sphereY[v1]*r, sphereZ[v1++]*r, u, v);
      vertex(sphereX[v2]*r, sphereY[v2]*r, sphereZ[v2++]*r, u, v+iv);
      u+=iu;
    }

    // Close each ring
    v1=v11;
    v2=voff;
    vertex(sphereX[v1]*r, sphereY[v1]*r, sphereZ[v1]*r, u, v);
    vertex(sphereX[v2]*r, sphereY[v2]*r, sphereZ[v2]*r, u, v+iv);
    endShape();
    v+=iv;
  }
  u=0;

  // Add the northern cap
  beginShape(TRIANGLE_STRIP);
  texture(t);
  for (int i = 0; i < sDetail; i++) {
    v2 = voff + i;
    vertex(sphereX[v2]*r, sphereY[v2]*r, sphereZ[v2]*r, u, v);
    vertex(0, r, 0, u, v+iv);    
    u+=iu;
  }
  vertex(sphereX[voff]*r, sphereY[voff]*r, sphereZ[voff]*r, u, v);
  endShape();
}

void drawAirRoute() {
  float r = globeRadius / 2;

  noFill();
  stroke(255, 0, 0);
  strokeWeight(5);
  
  /* ========== Airport Data ========== */

  // Narita International Airport
  float[] locate = new float[3];
  locate = changeCoordinate(35, 45, 50, "N", 140, 23, 30, "E");

  // London Heathrow Airport
  float[] locateL = new float[3];
  locateL = changeCoordinate(51, 28, 39, "N", 0, 27, 41, "W");

  // Sydney Airport
  float[] locateS = new float[3];
  locateS = changeCoordinate(33, 56, 46, "S", 151, 10, 38, "E");

  // São Paulo–Guarulhos International Airport
  float[] locateB = new float[3];
  locateB = changeCoordinate(23, 26, 8, "S", 46, 28, 23, "W");

  // Taiwan Taoyuan International Airport
  float[] locateT = new float[3];
  locateT = changeCoordinate(25, 4, 39, "N", 121, 13, 58, "E");

  // Chengdu Shuangliu International Airport
  float[] locateChengdu = new float[3];
  locateChengdu = changeCoordinate(30, 34, 42, "N", 103, 56, 49, "E");

  // Chongqing Jiangbei International Airport
  float[] locateChongqing = new float[3];
  locateChongqing = changeCoordinate(29, 43, 9, "N", 106, 38, 30, "E");

  // Incheon International Airport
  float[] locateIncheon = new float[3];
  locateIncheon = changeCoordinate(37, 27, 48, "N", 126, 26, 24, "E");

  // Ninoy Aquino International Airport
  float[] locateNinoy = new float[3];
  locateNinoy = changeCoordinate(14, 30, 31, "N", 121, 1, 10, "E");

  // Guangzhou Baiyun International Airport
  float[] locateGuangzhou = new float[3];
  locateGuangzhou = changeCoordinate(23, 23, 33, "N", 113, 17, 56, "E");

  // Guam International Airport
  float[] locateGuam = new float[3];
  locateGuam = changeCoordinate(13, 29, 2, "N", 144, 47, 50, "E");

  // Tansonnhat International Airport
  float[] locateTansonnhat = new float[3];
  locateTansonnhat = changeCoordinate(10, 49, 8, "N", 106, 39, 7, "E");

  // Hong Kong International Airport
  float[] locateHong = new float[3];
  locateHong = changeCoordinate(22, 18, 32, "N", 113, 54, 52, "E");

  // Dalian Zhoushuizi International Airport
  float[] locateDalian = new float[3];
  locateDalian = changeCoordinate(38, 57, 56, "N", 121, 32, 18, "E");

  // Shanghai Pudong International Airport
  float[] locateShanghai = new float[3];
  locateShanghai = changeCoordinate(38, 57, 56, "N", 121, 32, 18, "E");

  // Jeju International Airport
  float[] locateJeju = new float[3];
  locateJeju = changeCoordinate(33, 30, 41, "N", 126, 29, 35, "E");

  // Xiamen Gaoqi International Airport
  float[] locateXiamen = new float[3];
  locateXiamen = changeCoordinate(24, 32, 38, "N", 118, 7, 39, "E");

  // Noi Bai International Airport
  float[] locateNoi = new float[3];
  locateNoi = changeCoordinate(21, 13, 16, "N", 105, 48, 26, "E");

  // Shenyang Taoxian International Airport
  float[] locateShenyang = new float[3];
  locateShenyang = changeCoordinate(41, 38, 23, "N", 123, 29, 0, "E");

  // Hangzhou Xiaoshan International Airport
  float[] locateHangzhou = new float[3];
  locateHangzhou = changeCoordinate(30, 13, 46, "N", 120, 26, 4, "E");

  // Qingdao Liuting International Airport
  float[] locateQingdao = new float[3];
  locateQingdao = changeCoordinate(36, 15, 57, "N", 120, 22, 27, "E");

  // Saipan International Airport
  float[] locateSaipan = new float[3];
  locateSaipan = changeCoordinate(15, 7, 8, "N", 145, 43, 46, "E");

  // Zürich Airport
  float[] locateZurich = new float[3];
  locateZurich = changeCoordinate(47, 27, 53, "N", 8, 32, 57, "E");

  // Schiphol Airport
  float[] locateSchiphol = new float[3];
  locateSchiphol = changeCoordinate(52, 18, 31, "N", 4, 45, 50, "E");

  // Helsinki-Vantaa Airport
  float[] locateHelsinki = new float[3];
  locateHelsinki = changeCoordinate(60, 19, 2, "N", 24, 57, 48, "E");

  // Kuala Lumpur International Airport
  float[] locateKuala = new float[3];
  locateKuala = changeCoordinate(2, 44, 36, "N", 101, 41, 53, "E");

  // Beijing Capital International Airport
  float[] locateBeijing = new float[3];
  locateBeijing = changeCoordinate(40, 4, 48, "N", 116, 35, 5, "E");

  // Chicago O'Hare International Airport
  float[] locateChicago = new float[3];
  locateChicago = changeCoordinate(41, 58, 43, "N", 87, 54, 17, "W");

  // Jakarta International Soekarno-Hatta Airport
  float[] locateJakarta = new float[3];
  locateJakarta = changeCoordinate(6, 7, 32, "S", 106, 39, 21, "E");

  // Gimhae International Airport
  float[] locateGimhae = new float[3];
  locateGimhae = changeCoordinate(35, 10, 46.5, "N", 128, 56, 17, "E");

  // Suvarnabhumi International Airport
  float[] locateSuvarnabhumi = new float[3];
  locateSuvarnabhumi = changeCoordinate(13, 41, 33, "N", 100, 45, 0, "E");

  // Yangon International Airport
  float[] locateYangon = new float[3];
  locateYangon = changeCoordinate(16, 54, 26, "N", 96, 7, 59, "E");

  // Denpasar International Airport
  float[] locateDenpasar = new float[3];
  locateDenpasar = changeCoordinate(8, 44, 53, "S", 115, 10, 3, "E");

  // John F. Kennedy International Airport
  float[] locateJohn = new float[3];
  locateJohn = changeCoordinate(40, 38, 23, "N", 73, 46, 44, "W");

  // Flughafen Düsseldorf International
  float[] locateFlughafen = new float[3];
  locateFlughafen = changeCoordinate(51, 17, 22, "N", 6, 46, 22, "E");

  // Washington Dulles International Airport
  float[] locateWashington = new float[3];
  locateWashington = changeCoordinate(38, 56, 40, "N", 77, 27, 21, "W");

  // Singapore Changi Airport
  float[] locateSingapore = new float[3];
  locateSingapore = changeCoordinate(1, 21, 33, "N", 103, 59, 22, "E");

  // General Edward Lawrence Logan International Airport
  float[] locateGeneral = new float[3];
  locateGeneral = changeCoordinate(42, 21, 47, "N", 71, 0, 23, "W");

  // Vienna International Airport
  float[] locateVienna = new float[3];
  locateVienna = changeCoordinate(48, 6, 37, "N", 16, 34, 11, "E");

  // Indira Gandhi International Airport
  float[] locateIndira = new float[3];
  locateIndira = changeCoordinate(28, 33, 59, "N", 77, 6, 11, "E");

  // Dallas/Fort Worth International Airport
  float[] locateDallas = new float[3];
  locateDallas = changeCoordinate(32, 53, 49, "N", 97, 2, 17, "W");

  // Frankfurt Airport
  float[] locateFrankfurt = new float[3];
  locateFrankfurt = changeCoordinate(50, 2, 0, "N", 8, 34, 14, "E");

  // Copenhagen Airport
  float[] locateCopenhagen = new float[3];
  locateCopenhagen = changeCoordinate(55, 37, 43, "N", 12, 38, 49, "E");

  // Charles de Gaulle International Airport
  float[] locateCharles = new float[3];
  locateCharles = changeCoordinate(49, 0, 35, "N", 2, 32, 55, "E");

  // Atatürk International Airport
  float[] locateAtaturk = new float[3];
  locateAtaturk = changeCoordinate(40, 58, 36, "N", 26, 48, 52, "E");

  // Milan Malpensa International Airport
  float[] locateMilan = new float[3];
  locateMilan = changeCoordinate(45, 37, 48, "N", 8, 43, 23, "E");

  // Nouméa La Tontouta International Airport
  float[] locateNoumea = new float[3];
  locateNoumea = changeCoordinate(22, 0, 59, "S", 166, 12, 58, "E");

  // Kaohsiung International Airport
  float[] locateKaohsiung = new float[3];
  locateKaohsiung = changeCoordinate(22, 34, 38, "N", 120, 20, 33, "E");

  // Melbourne Airport
  float[] locateMelbourne = new float[3];
  locateMelbourne = changeCoordinate(37, 40, 24, "S", 144, 50, 36, "E");

  // Bandaranaike International Airport
  float[] locateBandaranaike = new float[3];
  locateBandaranaike = changeCoordinate(7, 10, 51, "N", 79, 53, 3, "E");

  // Vladivostok International Airport
  float[] locateVladivostok = new float[3];
  locateVladivostok = changeCoordinate(43, 23, 57, "N", 132, 9, 5, "E");

  // Mactan-Cebu International Airport
  float[] locateMactan = new float[3];
  locateMactan = changeCoordinate(10, 18, 27, "N", 123, 58, 45, "E");

  // Shenzhen Bao'an International Airport
  float[] locateShenzhen = new float[3];
  locateShenzhen = changeCoordinate(22, 38, 22, "N", 113, 48, 39, "E");

  // Detroit Metropolitan Wayne County Airport
  float[] locateDetroit = new float[3];
  locateDetroit = changeCoordinate(42, 12, 45, "N", 83, 21, 12, "W");

  // George Bush Intercontinental Airport
  float[] locateGeorge = new float[3];
  locateGeorge = changeCoordinate(29, 59, 4, "N", 95, 20, 29, "W");

  // Kota Kinabalu International Airport
  float[] locateKota = new float[3];
  locateKota = changeCoordinate(5, 56, 41, "N", 116, 3, 11, "E");

  // Mexico City International Airport
  float[] locateMexico = new float[3];
  locateMexico = changeCoordinate(19, 26, 10, "N", 99, 4, 19, "W");

  // San Francisco International Airport
  float[] locateSan = new float[3];
  locateSan = changeCoordinate(37, 37, 8, "N", 122, 22, 30, "W");

  // Los Angeles International Airport
  float[] locateLos = new float[3];
  locateLos = changeCoordinate(33, 56, 33, "N", 118, 24, 29, "W");

  // Seattle-Tacoma International Airport
  float[] locateSeattle = new float[3];
  locateSeattle = changeCoordinate(47, 26, 56, "N", 122, 18, 34, "W");

  // Minneapolis-Saint Paul International Airport
  float[] locateMinneapolis = new float[3];
  locateMinneapolis = changeCoordinate(44, 52, 55, "N", 93, 13, 18, "W");

  // Hartsfield-Jackson Atlanta International Airport
  float[] locateHartsfield = new float[3];
  locateHartsfield = changeCoordinate(33, 38, 12, "N", 84, 25, 41, "W");

  // Calgary International Airport
  float[] locateCalgary = new float[3];
  locateCalgary = changeCoordinate(51, 6, 50, "N", 114, 1, 13, "W");

  // Portland International Airport
  float[] locatePortland = new float[3];
  locatePortland = changeCoordinate(45, 35, 19, "N", 122, 35, 51, "W");

  // Macau International Airport
  float[] locateMacau = new float[3];
  locateMacau = changeCoordinate(22, 8, 58, "N", 113, 35, 29, "E");

  // Tahiti Faa'a International Airport
  float[] locateTahiti = new float[3];
  locateTahiti = changeCoordinate(17, 33, 24, "S", 149, 33, 42, "W");

  // Newark Liberty International Airport
  float[] locateNewark = new float[3];
  locateNewark = changeCoordinate(40, 41, 33, "N", 74, 10, 7, "W");

  // Denver International Airport
  float[] locateDenver = new float[3];
  locateDenver = changeCoordinate(39, 51, 42, "N", 104, 40, 23.5, "W");

  // Xi'an Xianyang International Airport
  float[] locateXi = new float[3];
  locateXi = changeCoordinate(34, 26, 50, "N", 108, 45, 6, "E");

  // Vancouver International Airport
  float[] locateVancouver = new float[3];
  locateVancouver = changeCoordinate(49, 11, 38, "N", 123, 11, 4, "W");

  // San Diego International Airport
  float[] locateSanD = new float[3];
  locateSanD = changeCoordinate(32, 44, 1, "N", 117, 11, 23, "W");

  // Norman Y. Mineta San José International Airport
  float[] locateNorman = new float[3];
  locateNorman = changeCoordinate(37, 21, 46, "N", 121, 55, 45, "W");

  // Toronto Pearson International Airport
  float[] locateToronto = new float[3];
  locateToronto = changeCoordinate(43, 40, 38, "N", 79, 37, 50, "W");

  // Palau International Airport
  float[] locatePalau = new float[3];
  locatePalau = changeCoordinate(7, 22, 2, "N", 134, 32, 39, "E");

  // Auckland International Airport
  float[] locateAuckland = new float[3];
  locateAuckland = changeCoordinate(37, 0, 29, "S", 174, 47, 30, "E");

  // Honolulu International Airport
  float[] locateHonolulu = new float[3];
  locateHonolulu = changeCoordinate(21, 19, 7, "N", 157, 55, 20, "W");

  // Gold Coast Airport
  float[] locateGold = new float[3];
  locateGold = changeCoordinate(28, 9, 52, "S", 153, 30, 17, "E");

  // Port Moresby Jacksons International Airport
  float[] locatePort = new float[3];
  locatePort = changeCoordinate(9, 26, 36, "S", 147, 13, 12, "E");

  // Cairns Airport
  float[] locateCairns = new float[3];
  locateCairns = changeCoordinate(16, 53, 12, "S", 145, 45, 18, "E");

  // Abu Dhabi International Airport
  float[] locateAbu = new float[3];
  locateAbu = changeCoordinate(24, 25, 58, "N", 54, 39, 4, "E");

  // Dubai International Airport
  float[] locateDubai = new float[3];
  locateDubai = changeCoordinate(25, 15, 10, "N", 55, 21, 52, "E");

  // Doha International Airport
  float[] locateDoha = new float[3];
  locateDoha = changeCoordinate(25, 15, 40, "N", 51, 33, 54, "E");

  // Fiumicino Airport
  float[] locateFiumicino = new float[3];
  locateFiumicino = changeCoordinate(25, 15, 40, "N", 51, 33, 54, "E");

  // Allama Airport
  float[] locateAllama = new float[3];
  locateAllama = changeCoordinate(31, 31, 17, "N", 74, 24, 12, "E");

  // Christchurch Airport
  float[] locateChristchurch = new float[3];
  locateChristchurch = changeCoordinate(43, 29, 22, "S", 172, 31, 56, "E");

  // Venezia Airport
  float[] locateVenezia = new float[3];
  locateVenezia = changeCoordinate(45, 30, 19, "N", 12, 21, 7, "E");

  // Chhatrapati Airport
  float[] locateChhatrapati = new float[3];
  locateChhatrapati = changeCoordinate(19, 5, 19, "N", 72, 52, 5, "E");

  // DonMueang Airport
  float[] locateDonMueang = new float[3];
  locateDonMueang = changeCoordinate(13, 54, 45, "N", 100, 36, 24, "E");

  // Sheremetyevo Airport
  float[] locateSheremetyevo = new float[3];
  locateSheremetyevo = changeCoordinate(55, 58, 22, "N", 37, 24, 53, "E");

  // Chinggis Airport
  float[] locateChinggis = new float[3];
  locateChinggis = changeCoordinate(47, 50, 35, "N", 106, 45, 59, "E");
  
  /* ========== End ========== */

  int dpCC = 0;
  int crFF = 0;
  text = "";
  reader.firstRow();
  for (int i = 0; i < reader.getLastRowNum() + 1; i++) {
    boolean bool = true;
    int[] dp = int(split(reader.getString(i, 0), ":"));
    float dpH = dp[0];
    int dpHd = int((str(dpH)).charAt(0));
    if (dpHd == 0) {
      dpH = float((str(dpH)).charAt(1));
    }
    float dpM = dp[1];
    int dpMd = int((str(dpM)).charAt(0));
    if (dpMd == 0) {
      dpM = float((str(dpH)).charAt(1));
    }
    //System.out.println(reader.getRowNum() + ", " + reader.getCellNum() + ", " + dpH + ":" + dpM);

    int[] nt = int(split(reader.getString(i, 1), ":"));
    float ntH = nt[0];
    int ntHd = int((str(ntH)).charAt(0));
    if (ntHd == 0) {
      ntH = float((str(ntH)).charAt(1));
    }
    float ntM = nt[1];
    int ntMd = int((str(ntM)).charAt(0));
    if (ntMd == 0) {
      ntM = float((str(ntM)).charAt(1));
    }
    //System.out.println(reader.getRowNum() + ", " + reader.getCellNum() + ", " + ntH + ":" + ntM);

    if (hour * 60 + minute > dpH * 60 + dpM) {
      dpCC++;
      dpC = dpCC;
    }

    if ((hour * 60 + minute > dpH * 60 + dpM && hour * 60 + minute < (dpH + ntH) * 60 + (dpM + ntM)) || (hour2 * 60 + minute > dpH * 60 + dpM && hour2 * 60 + minute < (dpH + ntH) * 60 + (dpM + ntM))) {
      crFF++;
      crF = crFF;
      float t = 1 - ((((dpH + ntH) * 60 + (dpM + ntM)) - (hour * 60 + minute)) / (ntH * 60 + ntM));
      if ((hour2 * 60 + minute > dpH * 60 + dpM && hour2 * 60 + minute < (dpH + ntH) * 60 + (dpM + ntM))) {
        t = 1 - ((((dpH + ntH) * 60 + (dpM + ntM)) - (hour2 * 60 + minute)) / (ntH * 60 + ntM));
      }
      float[] locateDestination = new float[3];
      String name = reader.getString(i, 2);
      String number = reader.getString(i, 3);
      //System.out.println(name);
      if (name.equals("台北")) {
        locateDestination[0] = locateT[0];
        locateDestination[1] = locateT[1];
        locateDestination[2] = locateT[2];
      } else if (name.equals("成都")) {
        locateDestination[0] = locateChengdu[0];
        locateDestination[1] = locateChengdu[1];
        locateDestination[2] = locateChengdu[2];
      } else if (name.equals("重慶")) {
        locateDestination[0] = locateChongqing[0];
        locateDestination[1] = locateChongqing[1];
        locateDestination[2] = locateChongqing[2];
      } else if (name.equals("ソウル")) {
        locateDestination[0] = locateIncheon[0];
        locateDestination[1] = locateIncheon[1];
        locateDestination[2] = locateIncheon[2];
      } else if (name.equals("マニラ")) {
        locateDestination[0] = locateNinoy[0];
        locateDestination[1] = locateNinoy[1];
        locateDestination[2] = locateNinoy[2];
      } else if (name.equals("広州")) {
        locateDestination[0] = locateGuangzhou[0];
        locateDestination[1] = locateGuangzhou[1];
        locateDestination[2] = locateGuangzhou[2];
      } else if (name.equals("グアム")) {
        locateDestination[0] = locateGuam[0];
        locateDestination[1] = locateGuam[1];
        locateDestination[2] = locateGuam[2];
      } else if (name.equals("ホーチミンシティ")) {
        locateDestination[0] = locateTansonnhat[0];
        locateDestination[1] = locateTansonnhat[1];
        locateDestination[2] = locateTansonnhat[2];
      } else if (name.equals("香港")) {
        locateDestination[0] = locateHong[0];
        locateDestination[1] = locateHong[1];
        locateDestination[2] = locateHong[2];
      } else if (name.equals("大連")) {
        locateDestination[0] = locateDalian[0];
        locateDestination[1] = locateDalian[1];
        locateDestination[2] = locateDalian[2];
      } else if (name.equals("上海")) {
        locateDestination[0] = locateShanghai[0];
        locateDestination[1] = locateShanghai[1];
        locateDestination[2] = locateShanghai[2];
      } else if (name.equals("済州")) {
        locateDestination[0] = locateJeju[0];
        locateDestination[1] = locateJeju[1];
        locateDestination[2] = locateJeju[2];
      } else if (name.equals("厦門")) {
        locateDestination[0] = locateXiamen[0];
        locateDestination[1] = locateXiamen[1];
        locateDestination[2] = locateXiamen[2];
      } else if (name.equals("ハノイ")) {
        locateDestination[0] = locateNoi[0];
        locateDestination[1] = locateNoi[1];
        locateDestination[2] = locateNoi[2];
      } else if (name.equals("瀋陽")) {
        locateDestination[0] = locateShenyang[0];
        locateDestination[1] = locateShenyang[1];
        locateDestination[2] = locateShenyang[2];
      } else if (name.equals("杭州")) {
        locateDestination[0] = locateHangzhou[0];
        locateDestination[1] = locateHangzhou[1];
        locateDestination[2] = locateHangzhou[2];
      } else if (name.equals("青島")) {
        locateDestination[0] = locateQingdao[0];
        locateDestination[1] = locateQingdao[1];
        locateDestination[2] = locateQingdao[2];
      } else if (name.equals("サイパン")) {
        locateDestination[0] = locateSaipan[0];
        locateDestination[1] = locateSaipan[1];
        locateDestination[2] = locateSaipan[2];
      } else if (name.equals("チューリッヒ")) {
        locateDestination[0] = locateZurich[0];
        locateDestination[1] = locateZurich[1];
        locateDestination[2] = locateZurich[2];
      } else if (name.equals("アムステルダム")) {
        locateDestination[0] = locateSchiphol[0];
        locateDestination[1] = locateSchiphol[1];
        locateDestination[2] = locateSchiphol[2];
      } else if (name.equals("ヘルシンキ")) {
        locateDestination[0] = locateHelsinki[0];
        locateDestination[1] = locateHelsinki[1];
        locateDestination[2] = locateHelsinki[2];
      } else if (name.equals("クアラルンプール")) {
        locateDestination[0] = locateKuala[0];
        locateDestination[1] = locateKuala[1];
        locateDestination[2] = locateKuala[2];
      } else if (name.equals("シカゴ")) {
        locateDestination[0] = locateChicago[0];
        locateDestination[1] = locateChicago[1];
        locateDestination[2] = locateChicago[2];
      } else if (name.equals("ジャカルタ")) {
        locateDestination[0] = locateJakarta[0];
        locateDestination[1] = locateJakarta[1];
        locateDestination[2] = locateJakarta[2];
      } else if (name.equals("ロンドン")) {
        locateDestination[0] = locateL[0];
        locateDestination[1] = locateL[1];
        locateDestination[2] = locateL[2];
      } else if (name.equals("釜山")) {
        locateDestination[0] = locateGimhae[0];
        locateDestination[1] = locateGimhae[1];
        locateDestination[2] = locateGimhae[2];
      } else if (name.equals("バンコク(スワンナプーム)")) {
        locateDestination[0] = locateSuvarnabhumi[0];
        locateDestination[1] = locateSuvarnabhumi[1];
        locateDestination[2] = locateSuvarnabhumi[2];
      } else if (name.equals("ヤンゴン")) {
        locateDestination[0] = locateYangon[0];
        locateDestination[1] = locateYangon[1];
        locateDestination[2] = locateYangon[2];
      } else if (name.equals("デンパサール")) {
        locateDestination[0] = locateDenpasar[0];
        locateDestination[1] = locateDenpasar[1];
        locateDestination[2] = locateDenpasar[2];
      } else if (name.equals("ニューヨーク")) {
        locateDestination[0] = locateJohn[0];
        locateDestination[1] = locateJohn[1];
        locateDestination[2] = locateJohn[2];
      } else if (name.equals("デュッセルドルフ")) {
        locateDestination[0] = locateFlughafen[0];
        locateDestination[1] = locateFlughafen[1];
        locateDestination[2] = locateFlughafen[2];
      } else if (name.equals("ワシントン DC")) {
        locateDestination[0] = locateWashington[0];
        locateDestination[1] = locateWashington[1];
        locateDestination[2] = locateWashington[2];
      } else if (name.equals("シンガポール")) {
        locateDestination[0] = locateSingapore[0];
        locateDestination[1] = locateSingapore[1];
        locateDestination[2] = locateSingapore[2];
      } else if (name.equals("ボストン")) {
        locateDestination[0] = locateGeneral[0];
        locateDestination[1] = locateGeneral[1];
        locateDestination[2] = locateGeneral[2];
      } else if (name.equals("ウィーン")) {
        locateDestination[0] = locateVienna[0];
        locateDestination[1] = locateVienna[1];
        locateDestination[2] = locateVienna[2];
      } else if (name.equals("デリー")) {
        locateDestination[0] = locateIndira[0];
        locateDestination[1] = locateIndira[1];
        locateDestination[2] = locateIndira[2];
      } else if (name.equals("ダラスフォートワース")) {
        locateDestination[0] = locateDallas[0];
        locateDestination[1] = locateDallas[1];
        locateDestination[2] = locateDallas[2];
      } else if (name.equals("フランクフルト")) {
        locateDestination[0] = locateFrankfurt[0];
        locateDestination[1] = locateFrankfurt[1];
        locateDestination[2] = locateFrankfurt[2];
      } else if (name.equals("コペンハーゲン")) {
        locateDestination[0] = locateCopenhagen[0];
        locateDestination[1] = locateCopenhagen[1];
        locateDestination[2] = locateCopenhagen[2];
      } else if (name.equals("パリ")) {
        locateDestination[0] = locateCharles[0];
        locateDestination[1] = locateCharles[1];
        locateDestination[2] = locateCharles[2];
      } else if (name.equals("イスタンブール")) {
        locateDestination[0] = locateAtaturk[0];
        locateDestination[1] = locateAtaturk[1];
        locateDestination[2] = locateAtaturk[2];
      } else if (name.equals("ミラノ")) {
        locateDestination[0] = locateMilan[0];
        locateDestination[1] = locateMilan[1];
        locateDestination[2] = locateMilan[2];
      } else if (name.equals("ヌーメア")) {
        locateDestination[0] = locateNoumea[0];
        locateDestination[1] = locateNoumea[1];
        locateDestination[2] = locateNoumea[2];
      } else if (name.equals("高雄")) {
        locateDestination[0] = locateKaohsiung[0];
        locateDestination[1] = locateKaohsiung[1];
        locateDestination[2] = locateKaohsiung[2];
      } else if (name.equals("メルボルン")) {
        locateDestination[0] = locateMelbourne[0];
        locateDestination[1] = locateMelbourne[1];
        locateDestination[2] = locateMelbourne[2];
      } else if (name.equals("ローマ")) {
        locateDestination[0] = locateFiumicino[0];
        locateDestination[1] = locateFiumicino[1];
        locateDestination[2] = locateFiumicino[2];
      } else if (name.equals("コロンボ")) {
        locateDestination[0] = locateBandaranaike[0];
        locateDestination[1] = locateBandaranaike[1];
        locateDestination[2] = locateBandaranaike[2];
      } else if (name.equals("ウラジオストク")) {
        locateDestination[0] = locateVladivostok[0];
        locateDestination[1] = locateVladivostok[1];
        locateDestination[2] = locateVladivostok[2];
      } else if (name.equals("セブ")) {
        locateDestination[0] = locateMactan[0];
        locateDestination[1] = locateMactan[1];
        locateDestination[2] = locateMactan[2];
      } else if (name.equals("シンセン")) {
        locateDestination[0] = locateShenzhen[0];
        locateDestination[1] = locateShenzhen[1];
        locateDestination[2] = locateShenzhen[2];
      } else if (name.equals("デトロイト")) {
        locateDestination[0] = locateDetroit[0];
        locateDestination[1] = locateDetroit[1];
        locateDestination[2] = locateDetroit[2];
      } else if (name.equals("ヒューストン")) {
        locateDestination[0] = locateGeorge[0];
        locateDestination[1] = locateGeorge[1];
        locateDestination[2] = locateGeorge[2];
      } else if (name.equals("コタキナバル")) {
        locateDestination[0] = locateKota[0];
        locateDestination[1] = locateKota[1];
        locateDestination[2] = locateKota[2];
      } else if (name.equals("メキシコシティ")) {
        locateDestination[0] = locateMexico[0];
        locateDestination[1] = locateMexico[1];
        locateDestination[2] = locateMexico[2];
      } else if (name.equals("サンフランシスコ")) {
        locateDestination[0] = locateSan[0];
        locateDestination[1] = locateSan[1];
        locateDestination[2] = locateSan[2];
      } else if (name.equals("ロスアンゼルス")) {
        locateDestination[0] = locateLos[0];
        locateDestination[1] = locateLos[1];
        locateDestination[2] = locateLos[2];
      } else if (name.equals("シアトル")) {
        locateDestination[0] = locateSeattle[0];
        locateDestination[1] = locateSeattle[1];
        locateDestination[2] = locateSeattle[2];
      } else if (name.equals("ミネアポリス")) {
        locateDestination[0] = locateMinneapolis[0];
        locateDestination[1] = locateMinneapolis[1];
        locateDestination[2] = locateMinneapolis[2];
      } else if (name.equals("アトランタ")) {
        locateDestination[0] = locateHartsfield[0];
        locateDestination[1] = locateHartsfield[1];
        locateDestination[2] = locateHartsfield[2];
      } else if (name.equals("カルガリー")) {
        locateDestination[0] = locateCalgary[0];
        locateDestination[1] = locateCalgary[1];
        locateDestination[2] = locateCalgary[2];
      } else if (name.equals("ポートランド")) {
        locateDestination[0] = locatePortland[0];
        locateDestination[1] = locatePortland[1];
        locateDestination[2] = locatePortland[2];
      } else if (name.equals("マカオ")) {
        locateDestination[0] = locateMacau[0];
        locateDestination[1] = locateMacau[1];
        locateDestination[2] = locateMacau[2];
      } else if (name.equals("パペーテ")) {
        locateDestination[0] = locateTahiti[0];
        locateDestination[1] = locateTahiti[1];
        locateDestination[2] = locateTahiti[2];
      } else if (name.equals("ニューアーク")) {
        locateDestination[0] = locateNewark[0];
        locateDestination[1] = locateNewark[1];
        locateDestination[2] = locateNewark[2];
      } else if (name.equals("デンバー")) {
        locateDestination[0] = locateDenver[0];
        locateDestination[1] = locateDenver[1];
        locateDestination[2] = locateDenver[2];
      } else if (name.equals("西安")) {
        locateDestination[0] = locateXi[0];
        locateDestination[1] = locateXi[1];
        locateDestination[2] = locateXi[2];
      } else if (name.equals("バンクーバー")) {
        locateDestination[0] = locateVancouver[0];
        locateDestination[1] = locateVancouver[1];
        locateDestination[2] = locateVancouver[2];
      } else if (name.equals("サンディエゴ")) {
        locateDestination[0] = locateSanD[0];
        locateDestination[1] = locateSanD[1];
        locateDestination[2] = locateSanD[2];
      } else if (name.equals("サンノゼ")) {
        locateDestination[0] = locateNorman[0];
        locateDestination[1] = locateNorman[1];
        locateDestination[2] = locateNorman[2];
      } else if (name.equals("トロント")) {
        locateDestination[0] = locateToronto[0];
        locateDestination[1] = locateToronto[1];
        locateDestination[2] = locateToronto[2];
      } else if (name.equals("コロール")) {
        locateDestination[0] = locatePalau[0];
        locateDestination[1] = locatePalau[1];
        locateDestination[2] = locatePalau[2];
      } else if (name.equals("オークランド")) {
        locateDestination[0] = locateAuckland[0];
        locateDestination[1] = locateAuckland[1];
        locateDestination[2] = locateAuckland[2];
      } else if (name.equals("ホノルル")) {
        locateDestination[0] = locateHonolulu[0];
        locateDestination[1] = locateHonolulu[1];
        locateDestination[2] = locateHonolulu[2];
      } else if (name.equals("シドニー")) {
        locateDestination[0] = locateS[0];
        locateDestination[1] = locateS[1];
        locateDestination[2] = locateS[2];
      } else if (name.equals("ゴールドコースト")) {
        locateDestination[0] = locateGold[0];
        locateDestination[1] = locateGold[1];
        locateDestination[2] = locateGold[2];
      } else if (name.equals("ポートモレスビー")) {
        locateDestination[0] = locatePort[0];
        locateDestination[1] = locatePort[1];
        locateDestination[2] = locatePort[2];
      } else if (name.equals("ケアンズ")) {
        locateDestination[0] = locateCairns[0];
        locateDestination[1] = locateCairns[1];
        locateDestination[2] = locateCairns[2];
      } else if (name.equals("アブダビ")) {
        locateDestination[0] = locateAbu[0];
        locateDestination[1] = locateAbu[1];
        locateDestination[2] = locateAbu[2];
      } else if (name.equals("ドバイ")) {
        locateDestination[0] = locateDubai[0];
        locateDestination[1] = locateDubai[1];
        locateDestination[2] = locateDubai[2];
      } else if (name.equals("ドーハ")) {
        locateDestination[0] = locateDoha[0];
        locateDestination[1] = locateDoha[1];
        locateDestination[2] = locateDoha[2];
      } else if (name.equals("北京")) {
        locateDestination[0] = locateBeijing[0];
        locateDestination[1] = locateBeijing[1];
        locateDestination[2] = locateBeijing[2];
      } else if (name.equals("ラホール")) {
        locateDestination[0] = locateAllama[0];
        locateDestination[1] = locateAllama[1];
        locateDestination[2] = locateAllama[2];
      } else if (name.equals("クライストチャーチ")) {
        locateDestination[0] = locateChristchurch[0];
        locateDestination[1] = locateChristchurch[1];
        locateDestination[2] = locateChristchurch[2];
      } else if (name.equals("ヴェネツィア")) {
        locateDestination[0] = locateVenezia[0];
        locateDestination[1] = locateVenezia[1];
        locateDestination[2] = locateVenezia[2];
      } else if (name.equals("ムンバイ")) {
        locateDestination[0] = locateChhatrapati[0];
        locateDestination[1] = locateChhatrapati[1];
        locateDestination[2] = locateChhatrapati[2];
      } else if (name.equals("バンコク(ドンムアン)")) {
        locateDestination[0] = locateDonMueang[0];
        locateDestination[1] = locateDonMueang[1];
        locateDestination[2] = locateDonMueang[2];
      } else if (name.equals("モスクワ")) {
        locateDestination[0] = locateSheremetyevo[0];
        locateDestination[1] = locateSheremetyevo[1];
        locateDestination[2] = locateSheremetyevo[2];
      } else if (name.equals("ウランバートル")) {
        locateDestination[0] = locateChinggis[0];
        locateDestination[1] = locateChinggis[1];
        locateDestination[2] = locateChinggis[2];
      } else {
        bool = false;
        System.out.println(name + "は登録されていない空港名です。");
      }
      if(bool = true){
        airRoute(locate[0], locate[2], locate[1], locateDestination[0], locateDestination[2], locateDestination[1], t, name, number);
      }
    }
  }
}

float[] changeCoordinate(float phiA, float phiM, float phiS, String NS, float ramdaA, float ramdaM, float ramdaS, String EW) {
  float r = globeRadius / 2;
  float[] decimal = new float[2];
  float[] xyz = new float[3];

  decimal = changeSexagesimal(phiA, phiM, phiS, NS, ramdaA, ramdaM, ramdaS, EW);

  xyz[0] = r * cos(decimal[0] * PI / 180) * cos(decimal[1] * PI / 180);
  xyz[1] = -(r * cos(decimal[0] * PI / 180) * sin(decimal[1] * PI / 180));
  xyz[2] = -(r * sin(decimal[0] * PI / 180));

  if (NS == "S" && EW == "W") {
    xyz[1] = -xyz[1];
  }

  for (int i = 0; i < 3; i++) {
    //xyz[i] = xyz[i] * 1.0085;
  }

  return xyz;
}

float[] changeSexagesimal(float phiA, float phiM, float phiS, String NS, float ramdaA, float ramdaM, float ramdaS, String EW) {
  float[] decimal = new float[2];

  decimal[0] = phiA + (phiM / 60) + (phiS / 3600);
  decimal[1] = ramdaA + (ramdaM / 60) + (ramdaS / 3600);

  if (NS == "S") {
    decimal[0] = -decimal[0];
  } else if (EW == "W") {
    decimal[1] = -decimal[1];
  }

  return decimal;
}

void airRoute(float lx1, float ly1, float lz1, float lx2, float ly2, float lz2, float t, String name, String number) {
  float cx, cy, cz, cx1, cy1, cz1, cx2, cy2, cz2;
  cx = (lx1 + lx2) / 2;
  cy = (ly1 + ly2) / 2;
  cz = (lz1 + lz2) / 2;
  if (sqrt((cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 4) {
    while (sqrt ( (cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 2) {
      cx *= 1.01;
      cy *= 1.01;
      cz *= 1.01;
    }
    cx *= 1.5;
    cy *= 1.5;
    cz *= 1.5;
  } else if (sqrt((cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 3) {
    while (sqrt ( (cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 2) {
      cx *= 1.01;
      cy *= 1.01;
      cz *= 1.01;
    }
    cx *= 1.25;
    cy *= 1.25;
    cz *= 1.25;
  } else if (sqrt((cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 2) {
    while (sqrt ( (cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 2) {
      cx *= 1.01;
      cy *= 1.01;
      cz *= 1.01;
    }
    cx *= 1.05;
    cy *= 1.05;
    cz *= 1.05;
  }
  cx1 = (lx1 + cx) / 2;
  cy1 = (ly1 + cy) / 2;
  cz1 = (lz1 + cz) / 2;
  cx2 = (cx + lx2) / 2;
  cy2 = (cy + ly2) / 2;
  cz2 = (cz + lz2) / 2;
  if (sqrt((cx1 * cx1) + (cy1 * cy1) + (cz1 * cz1)) < sqrt((cx * cx) + (cy * cy) + (cz * cz)) * 1.25) {
    while (sqrt ( (cx1 * cx1) + (cy1 * cy1) + (cz1 * cz1)) < sqrt((cx * cx) + (cy * cy) + (cz * cz)) * 1.25) {
      cx1 *= 1.01;
      cy1 *= 1.01;
      cz1 *= 1.01;
      cx2 *= 1.01;
      cy2 *= 1.01;
      cz2 *= 1.01;
    }
  }
  //stroke(22, 233, 159, 40);
  //line(0.0, 0.0, 0.0, cx, cy, cz);
  //line(0.0, 0.0, 0.0, cx1, cy1, cz1);
  //line(0.0, 0.0, 0.0, cx2, cy2, cz2);
  
//  stroke(255, 0, 0);
//  line(0, 0, 0, 300, 0, 0);
//  line(0, 0, 0, 0, 300, 0);
//  line(0, 0, 0, 0, 0, 300);

  //  if (YN == "Y") { // over day yes or no
  //    ar = ar + 24 * 60;
  //  }
  //  float nt = (float)(ar - (dp - td)); //neccesaryTime = arriveTime - (departureTime - timeDifference)
  //  nt = nt * 60; // minute to second
  //  // System.out.println("nt = " + nt);
  
  text += name + ", " + number + "\n";

  strokeWeight(3);
  if (t > 0.9) {
    stroke(255, 0, 38, 30);
  } else {
    stroke(15, 60, 241, 30);
  }
  bezier(lx1, ly1, lz1, cx1, cy1, cz1, cx2, cy2, cz2, lx2, ly2, lz2);
  float x = bezierPoint(lx1, cx1, cx2, lx2, t);
  float y = bezierPoint(ly1, cy1, cy2, ly2, t);
  float z = bezierPoint(lz1, cz1, cz2, lz2, t);
  //System.out.println(number + ": " + x + ", " + y + ", " + z + ", " + t);
  pushMatrix();
  translate(x, y, z);
  
  /* ===== billboard ===== */
  pushMatrix();
  PMatrix3D builboardMat = (PMatrix3D)g.getMatrix();
  builboardMat.m00 = builboardMat.m11 = builboardMat.m22 = 1;
  builboardMat.m01 = builboardMat.m02 = 
  builboardMat.m10 = builboardMat.m12 = 
  builboardMat.m20 = builboardMat.m21 = 0;
  resetMatrix();  
  applyMatrix(builboardMat);
  textAlign(CENTER);
  textSize(10);
  /*
  float mouseXMat = mouseX;
  float mouseYMat = mouseY;
  float worldX = modelX(x, y, z);
  float worldY = modelY(x, y, z);
  float worldZ = modelZ(x, y, z);
  float X = screenX(worldX, worldY, worldZ);
  float Y = screenY(worldX, worldY, worldZ);
  float Z = screenZ(worldX, worldY, worldZ);
  text = "";
  text += "mouseXMat: " + mouseXMat + "\n";
  text += "mouseYMat: " + mouseYMat + "\n";
  text += "x: " + x + "\n";
  text += "y: " + y + "\n";
  text += "z: " + z + "\n";
  text += "worldX: " + worldX + "\n";
  text += "worldY: " + worldY + "\n";
  text += "worldZ: " + worldZ + "\n";
  text += "X: " + X + "\n";
  text += "Y: " + Y + "\n";
  text += "Z: " + Z + "\n";
  System.out.println("mouseXMat: " + mouseXMat + ", mouseYMat: " + mouseYMat + "\nX: " + X + ", Y : " + Y + ", Z: " + Z);
  if (mouseXMat < X+10 && mouseXMat > X-10 && mouseYMat < Y+10 && mouseYMat > Y-10) {
    text("Airport", 0, -5, 0);
    println("Airport");
  }
  */
  if (number.equals(flightNumber)){
    fill(255, 0, 0, 100);
    stroke(255, 0, 0, 100);
    text(name, 0, -5, 0);
    text(number, 0, 12, 0);
    noFill();
  }
  else {
    stroke(241, 196, 15, 50);
  }
  popMatrix();
  /* ===== End ===== */
  
  sphere(3);
  
  popMatrix();
}

void clock() {
  second += sec;
  if (second >= 60) {
    minute++;
    second = 0;
  }
  if (minute >= 60) {
    hour++;
    hour2++;
    minute = 0;
  }
  if (hour >= 24) {
    hour = 0;
    hour2 = 24;
  }

  int h = hour;
  int m = minute;
  int s = second;
  String t = h + ":" + nf(m, 2) + ":" + nf(s, 2);

  textSize(80);
  textAlign(CENTER);
  fill(241, 196, 15);
  text(t, displayWidth * 0.8, displayHeight * 0.9);
}

void timeSpeed() {
  float time = map(sx, 40, 290, 1, 3600);
  timer += (int)time;
  sec = timer / 60;
  if (sec > 0) {
    timer = 0;
  }
  //System.out.println(timer + ", " + sec);
  textSize(20);
  fill(52, 153, 211);
  text((int)time + "speed", 360, 674);
}

void slideBar() {
  noFill();
  stroke(192, 192, 192);
  strokeWeight(3);
  rectMode(CORNER);
  rect(40, 660, 250, 16);
  noStroke();
  fill(255, 255, 255);
  rectMode(CENTER);
  rect(sx, 668, 16, 32);
  rectMode(CORNER);
  rect(40, 660, sx - 40, 16);
}

void countFlight() {
  textSize(25);
  fill(255);
  textAlign(RIGHT);
  text("total flight: ", 200, 60);
  text("current flight: ", 200, 95);
  textAlign(LEFT);
  text(dpC, 200, 60);
  text(crF, 200, 95);
}

void textField(){
  textSize(5);
  text(text, width*0.8, 120);
}

void leapMotion() {
  leapFinger();
  leapHand();
}

void leapFinger() {
  for (Finger finger : leap.getFingerList ()) {
    PVector fingerPos = leap.getTip(finger);
    float x = fingerPos.x;
    float y = fingerPos.y;
    float z = fingerPos.z;
    pushMatrix();
    translate(x, y, z);
    sphere(5);
    popMatrix();
  }

  if (leap.getFingerList ().size() == 1) {
    Finger currentFinger = leap.getFinger(0);
    Frame lastFrame = leap.getLastFrame();
    for (Finger finger : leap.getFingerList (lastFrame)) {
      PVector lastFingerPos = leap.getTip(finger);
      float x = lastFingerPos.x;
      float y = lastFingerPos.y;
      velocityX += (leap.getTip(currentFinger).y - y) * 0.1;
      velocityY -= (leap.getTip(currentFinger).x - x) * 0.1;
    }
  } else if (leap.getFingerList().size() == 2) {
    Finger currentFinger = leap.getFinger(0);
    Frame lastFrame = leap.getLastFrame();
    for (Finger finger : leap.getFingerList (lastFrame)) {
      PVector lastFingerPos = leap.getTip(finger);
      float x = lastFingerPos.x;
      if (sx >= 40 && sx <= 290) {
        if (sx != 290 && leap.getTip(currentFinger).x - x > 0) {
          sx+=10;
        } else if (sx != 40 && leap.getTip(currentFinger).x - x < 0) {
          sx-=10;
        }
      }
      break;
    }
  } else if (leap.getFingerList().size() == 5) {
    velocityX *= 0.7;
    velocityY *= 0.7;
  }
}

void leapHand() {
  for (Hand hand : leap.getHandList ()) {
    PVector handPos = leap.getPosition(hand);
    float x = handPos.x;
    float y = handPos.y;
    float z = handPos.z;
    pushMatrix();
    translate(x, y, z);
    sphere(5);
    popMatrix();
  }

  Hand rightHand;
  Hand leftHand;
  if (leap.getHandList().size() == 2 && leap.getFingerList().size() == 10) {
    rightHand = leap.getHand(0);
    leftHand = leap.getHand(1);
    if (leap.getPosition(rightHand).x - leap.getPosition(leftHand).x < 0) {
      rightHand = leap.getHand(1);
      leftHand = leap.getHand(0);
    }

    Frame lastFrame = leap.getLastFrame();
    Hand lastRightHand = null;
    Hand lastLeftHand = null;
    for (Hand hand : leap.getHandList (lastFrame)) {
      PVector lastHandPos = leap.getPosition(hand);
      float x = lastHandPos.x;
      if (abs(leap.getPosition(rightHand).x - x) < 50) {
        lastRightHand = hand;
      } else if (abs(leap.getPosition(leftHand).x - x) < 50) {
        lastLeftHand = hand;
      }
    }

    if (leap.getRoll(rightHand) < -30 && leap.getRoll(rightHand) > -100 && leap.getRoll(leftHand) > 30 && leap.getRoll(leftHand) < 100) {
      if (leap.getPosition(rightHand).x - leap.getPosition(lastRightHand).x > 0 && leap.getPosition(leftHand).x - leap.getPosition(lastLeftHand).x < 0) {
        pushBack += 10;
      }
      if (leap.getPosition(rightHand).x - leap.getPosition(lastRightHand).x < 0 && leap.getPosition(leftHand).x - leap.getPosition(lastLeftHand).x > 0) {
        pushBack -= 10;
      }
    }
  } else if (leap.getHandList().size() == 1 && leap.getFingerList().size() == 5) {
    Frame lastFrame = leap.getLastFrame();
    Hand hand = leap.getHand(0);

    float rotationXAxis = hand.rotationAngle(lastFrame, Vector.xAxis());
    float rotationYAxis = hand.rotationAngle(lastFrame, Vector.yAxis());

    //    velocityX += rotationXAxis * 50;
    //    velocityY -= rotationYAxis * 50;
  }
}

void mousePressed() {
  float x = mouseX;
  float y = mouseY;
  if (x > 32 && x < 298 && y > 652 && y < 684) {
    bool = false;
  }
}

void mouseDragged() {
  float x = mouseX;
  float y = mouseY;
  if (bool == false) {
    if (x >= 40 && x <= 290) {
      sx = x;
    } else if (x < 40) {
      sx = 40;
    } else if (x > 290) {
      sx = 290;
    }
  }
}

void mouseReleased() {
  bool = true;
}

void keyPressed() {
  if (key == '+') {
    pushBack += 10;
  } else if (key == '-') {
    pushBack -= 10;
  }
}

void controlEvent(ControlEvent theEvent) {
  if(theEvent.isAssignableFrom(Textfield.class)) {
    flightNumber = theEvent.getStringValue();
    println("controlEvent: accessing a string from controller '"
            +theEvent.getName()+"': "
            +theEvent.getStringValue()
            );
  }
}

public void stop() {
  leap.stop();
}
