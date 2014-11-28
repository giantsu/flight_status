import de.bezier.data.*;

XlsReader reader;

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

void setup() {
  size(1024, 700, P3D);  
  colorMode(RGB, 256, 256, 256, 100);
  back = loadImage("space_3.jpg");
  texmap = loadImage("world32k.jpg");    
  reader = new XlsReader(this, "Narita_International_Airport_flightall(departure)_2a.xls");
  initializeSphere(sDetail);
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

  // Narita International Airport
  float[] locate = new float[3];

  locate = changeCoordinate(35, 45, 50, "N", 140, 23, 30, "E");
  //line(0.0, 0.0, 0.0, locate[0], locate[2], locate[1]);

  // London Heathrow Airport
  float[] locateL = new float[3];

  locateL = changeCoordinate(51, 28, 39, "N", 0, 27, 41, "W");
  //line(0.0, 0.0, 0.0, locateL[0], locateL[2], locateL[1]);

  // Sydney Airport
  float[] locateS = new float[3];

  locateS = changeCoordinate(33, 56, 46, "S", 151, 10, 38, "E");
  //line(0.0, 0.0, 0.0, locateS[0], locateS[2], locateS[1]);

  // São Paulo–Guarulhos International Airport
  float[] locateB = new float[3];

  locateB = changeCoordinate(23, 26, 8, "S", 46, 28, 23, "W");
  //line(0.0, 0.0, 0.0, locateB[0], locateB[2], locateB[1]);

  // Taiwan Taoyuan International Airport
  float[] locateT = new float[3];

  locateT = changeCoordinate(25, 4, 39, "N", 121, 13, 58, "E");
  //line(0.0, 0.0, 0.0, locateT[0], locateT[2], locateT[1]);

  // Chengdu Shuangliu International Airport
  float[] locateChengdu = new float[3];

  locateChengdu = changeCoordinate(30, 34, 42, "N", 103, 56, 49, "E");
  //line(0.0, 0.0, 0.0, locateChengdu[0], locateChengdu[2], locateChengdu[1]);

  // Chongqing Jiangbei International Airport
  float[] locateChongqing = new float[3];

  locateChongqing = changeCoordinate(29, 43, 9, "N", 106, 38, 30, "E");
  //line(0.0, 0.0, 0.0, locateChongqing[0], locateChongqing[2], locateChongqing[1]);

  // Incheon International Airport
  float[] locateIncheon = new float[3];

  locateIncheon = changeCoordinate(37, 27, 48, "N", 126, 26, 24, "E");
  //line(0.0, 0.0, 0.0, locateIncheon[0], locateIncheon[2], locateIncheon[1]);

  // Ninoy Aquino International Airport
  float[] locateNinoy = new float[3];

  locateNinoy = changeCoordinate(14, 30, 31, "N", 121, 1, 10, "E");
  //line(0.0, 0.0, 0.0, locateNinoy[0], locateNinoy[2], locateNinoy[1]);

  // Guangzhou Baiyun International Airport
  float[] locateGuangzhou = new float[3];

  locateGuangzhou = changeCoordinate(23, 23, 33, "N", 113, 17, 56, "E");
  //line(0.0, 0.0, 0.0, locateGuangzhou[0], locateGuangzhou[2], locateGuangzhou[1]);

  // Guam International Airport
  float[] locateGuam = new float[3];

  locateGuam = changeCoordinate(13, 29, 2, "N", 144, 47, 50, "E");
  //line(0.0, 0.0, 0.0, locateGuam[0], locateGuam[2], locateGuam[1]);

  // Tansonnhat International Airport
  float[] locateTansonnhat = new float[3];

  locateTansonnhat = changeCoordinate(10, 49, 8, "N", 106, 39, 7, "E");
  //line(0.0, 0.0, 0.0, locateTansonnhat[0], locateTansonnhat[2], locateTansonnhat[1]);

  // Hong Kong International Airport
  float[] locateHong = new float[3];

  locateHong = changeCoordinate(22, 18, 32, "N", 113, 54, 52, "E");
  //line(0.0, 0.0, 0.0, locateHong[0], locateHong[2], locateHong[1]);

  // Dalian Zhoushuizi International Airport
  float[] locateDalian = new float[3];

  locateDalian = changeCoordinate(38, 57, 56, "N", 121, 32, 18, "E");
  //line(0.0, 0.0, 0.0, locateDalian[0], locateDalian[2], locateDalian[1]);

  // Shanghai Pudong International Airport
  float[] locateShanghai = new float[3];

  locateShanghai = changeCoordinate(38, 57, 56, "N", 121, 32, 18, "E");
  //line(0.0, 0.0, 0.0, locateShanghai[0], locateShanghai[2], locateShanghai[1]);

  // Jeju International Airport
  float[] locateJeju = new float[3];

  locateJeju = changeCoordinate(33, 30, 41, "N", 126, 29, 35, "E");
  //line(0.0, 0.0, 0.0, locateJeju[0], locateJeju[2], locateJeju[1]);

  // Xiamen Gaoqi International Airport
  float[] locateXiamen = new float[3];

  locateXiamen = changeCoordinate(24, 32, 38, "N", 118, 7, 39, "E");
  //line(0.0, 0.0, 0.0, locateXiamen[0], locateXiamen[2], locateXiamen[1]);

  // Noi Bai International Airport
  float[] locateNoi = new float[3];

  locateNoi = changeCoordinate(21, 13, 16, "N", 105, 48, 26, "E");
  //line(0.0, 0.0, 0.0, locateNoi[0], locateNoi[2], locateNoi[1]);

  // Shenyang Taoxian International Airport
  float[] locateShenyang = new float[3];

  locateShenyang = changeCoordinate(41, 38, 23, "N", 123, 29, 0, "E");
  //line(0.0, 0.0, 0.0, locateShenyang[0], locateShenyang[2], locateShenyang[1]);

  // Hangzhou Xiaoshan International Airport
  float[] locateHangzhou = new float[3];

  locateHangzhou = changeCoordinate(30, 13, 46, "N", 120, 26, 4, "E");
  //line(0.0, 0.0, 0.0, locateHangzhou[0], locateHangzhou[2], locateHangzhou[1]);

  // Qingdao Liuting International Airport
  float[] locateQingdao = new float[3];

  locateQingdao = changeCoordinate(36, 15, 57, "N", 120, 22, 27, "E");
  //line(0.0, 0.0, 0.0, locateQingdao[0], locateQingdao[2], locateQingdao[1]);

  // Saipan International Airport
  float[] locateSaipan = new float[3];

  locateSaipan = changeCoordinate(15, 7, 8, "N", 145, 43, 46, "E");
  //line(0.0, 0.0, 0.0, locateSaipan[0], locateSaipan[2], locateSaipan[1]);

  // Zürich Airport
  float[] locateZurich = new float[3];

  locateZurich = changeCoordinate(47, 27, 53, "N", 8, 32, 57, "E");
  //line(0.0, 0.0, 0.0, locateZurich[0], locateZurich[2], locateZurich[1]);

  // Schiphol Airport
  float[] locateSchiphol = new float[3];

  locateSchiphol = changeCoordinate(52, 18, 31, "N", 4, 45, 50, "E");
  //line(0.0, 0.0, 0.0, locateSchiphol[0], locateSchiphol[2], locateSchiphol[1]);

  // Helsinki-Vantaa Airport
  float[] locateHelsinki = new float[3];

  locateHelsinki = changeCoordinate(60, 19, 2, "N", 24, 57, 48, "E");
  //line(0.0, 0.0, 0.0, locateHelsinki[0], locateHelsinki[2], locateHelsinki[1]);

  // Kuala Lumpur International Airport
  float[] locateKuala = new float[3];

  locateKuala = changeCoordinate(2, 44, 36, "N", 101, 41, 53, "E");
  //line(0.0, 0.0, 0.0, locateKuala[0], locateKuala[2], locateKuala[1]);
  
  // Beijing Capital International Airport
  float[] locateBeijing = new float[3];

  locateBeijing = changeCoordinate(40, 4, 48, "N", 116, 35, 5, "E");
  //line(0.0, 0.0, 0.0, locateBeijing[0], locateBeijing[2], locateBeijing[1]);

  // Chicago O'Hare International Airport
  float[] locateChicago = new float[3];

  locateChicago = changeCoordinate(41, 58, 43, "N", 87, 54, 17, "W");
  //line(0.0, 0.0, 0.0, locateChicago[0], locateChicago[2], locateChicago[1]);

  // Jakarta International Soekarno-Hatta Airport
  float[] locateJakarta = new float[3];

  locateJakarta = changeCoordinate(6, 7, 32, "S", 106, 39, 21, "E");
  //line(0.0, 0.0, 0.0, locateJakarta[0], locateJakarta[2], locateJakarta[1]);

  // Gimhae International Airport
  float[] locateGimhae = new float[3];

  locateGimhae = changeCoordinate(35, 10, 46.5, "N", 128, 56, 17, "E");
  //line(0.0, 0.0, 0.0, locateGimhae[0], locateGimhae[2], locateGimhae[1]);

  // Suvarnabhumi International Airport
  float[] locateSuvarnabhumi = new float[3];

  locateSuvarnabhumi = changeCoordinate(13, 41, 33, "N", 100, 45, 0, "E");
  //line(0.0, 0.0, 0.0, locateSuvarnabhumi[0], locateSuvarnabhumi[2], locateSuvarnabhumi[1]);

  // Yangon International Airport
  float[] locateYangon = new float[3];

  locateYangon = changeCoordinate(16, 54, 26, "N", 96, 7, 59, "E");
  //line(0.0, 0.0, 0.0, locateYangon[0], locateYangon[2], locateYangon[1]);

  // Denpasar International Airport
  float[] locateDenpasar = new float[3];

  locateDenpasar = changeCoordinate(8, 44, 53, "S", 115, 10, 3, "E");
  //line(0.0, 0.0, 0.0, locateDenpasar[0], locateDenpasar[2], locateDenpasar[1]);

  // John F. Kennedy International Airport
  float[] locateJohn = new float[3];

  locateJohn = changeCoordinate(40, 38, 23, "N", 73, 46, 44, "W");
  //line(0.0, 0.0, 0.0, locateJohn[0], locateJohn[2], locateJohn[1]);

  // Flughafen Düsseldorf International
  float[] locateFlughafen = new float[3];

  locateFlughafen = changeCoordinate(51, 17, 22, "N", 6, 46, 22, "E");
  //line(0.0, 0.0, 0.0, locateFlughafen[0], locateFlughafen[2], locateFlughafen[1]);

  // Washington Dulles International Airport
  float[] locateWashington = new float[3];

  locateWashington = changeCoordinate(38, 56, 40, "N", 77, 27, 21, "W");
  //line(0.0, 0.0, 0.0, locateWashington[0], locateWashington[2], locateWashington[1]);

  // Singapore Changi Airport
  float[] locateSingapore = new float[3];

  locateSingapore = changeCoordinate(1, 21, 33, "N", 103, 59, 22, "E");
  //line(0.0, 0.0, 0.0, locateSingapore[0], locateSingapore[2], locateSingapore[1]);

  // General Edward Lawrence Logan International Airport
  float[] locateGeneral = new float[3];

  locateGeneral = changeCoordinate(42, 21, 47, "N", 71, 0, 23, "W");
  //line(0.0, 0.0, 0.0, locateGeneral[0], locateGeneral[2], locateGeneral[1]);

  // Vienna International Airport
  float[] locateVienna = new float[3];

  locateVienna = changeCoordinate(48, 6, 37, "N", 16, 34, 11, "E");
  //line(0.0, 0.0, 0.0, locateVienna[0], locateVienna[2], locateVienna[1]);

  // Indira Gandhi International Airport
  float[] locateIndira = new float[3];

  locateIndira = changeCoordinate(28, 33, 59, "N", 77, 6, 11, "E");
  //line(0.0, 0.0, 0.0, locateIndira[0], locateIndira[2], locateIndira[1]);

  // Dallas/Fort Worth International Airport
  float[] locateDallas = new float[3];

  locateDallas = changeCoordinate(32, 53, 49, "N", 97, 2, 17, "W");
  //line(0.0, 0.0, 0.0, locateDallas[0], locateDallas[2], locateDallas[1]);

  // Frankfurt Airport
  float[] locateFrankfurt = new float[3];

  locateFrankfurt = changeCoordinate(50, 2, 0, "N", 8, 34, 14, "E");
  //line(0.0, 0.0, 0.0, locateFrankfurt[0], locateFrankfurt[2], locateFrankfurt[1]);

  // Copenhagen Airport
  float[] locateCopenhagen = new float[3];

  locateCopenhagen = changeCoordinate(55, 37, 43, "N", 12, 38, 49, "E");
  //line(0.0, 0.0, 0.0, locateCopenhagen[0], locateCopenhagen[2], locateCopenhagen[1]);

  // Charles de Gaulle International Airport
  float[] locateCharles = new float[3];

  locateCharles = changeCoordinate(49, 0, 35, "N", 2, 32, 55, "E");
  //line(0.0, 0.0, 0.0, locateCharles[0], locateCharles[2], locateCharles[1]);

  // Atatürk International Airport
  float[] locateAtaturk = new float[3];

  locateAtaturk = changeCoordinate(40, 58, 36, "N", 26, 48, 52, "E");
  //line(0.0, 0.0, 0.0, locateAtaturk[0], locateAtaturk[2], locateAtaturk[1]);

  // Milan Malpensa International Airport
  float[] locateMilan = new float[3];

  locateMilan = changeCoordinate(45, 37, 48, "N", 8, 43, 23, "E");
  //line(0.0, 0.0, 0.0, locateMilan[0], locateMilan[2], locateMilan[1]);

  // Nouméa La Tontouta International Airport
  float[] locateNoumea = new float[3];

  locateNoumea = changeCoordinate(22, 0, 59, "S", 166, 12, 58, "E");
  //line(0.0, 0.0, 0.0, locateNoumea[0], locateNoumea[2], locateNoumea[1]);

  // Kaohsiung International Airport
  float[] locateKaohsiung = new float[3];

  locateKaohsiung = changeCoordinate(22, 34, 38, "N", 120, 20, 33, "E");
  //line(0.0, 0.0, 0.0, locateKaohsiung[0], locateKaohsiung[2], locateKaohsiung[1]);

  // Melbourne Airport
  float[] locateMelbourne = new float[3];

  locateMelbourne = changeCoordinate(37, 40, 24, "S", 144, 50, 36, "E");
  //line(0.0, 0.0, 0.0, locateMelbourne[0], locateMelbourne[2], locateMelbourne[1]);

  // Bandaranaike International Airport
  float[] locateBandaranaike = new float[3];

  locateBandaranaike = changeCoordinate(7, 10, 51, "N", 79, 53, 3, "E");
  //line(0.0, 0.0, 0.0, locateBandaranaike[0], locateBandaranaike[2], locateBandaranaike[1]);

  // Vladivostok International Airport
  float[] locateVladivostok = new float[3];

  locateVladivostok = changeCoordinate(43, 23, 57, "N", 132, 9, 5, "E");
  //line(0.0, 0.0, 0.0, locateVladivostok[0], locateVladivostok[2], locateVladivostok[1]);

  // Mactan-Cebu International Airport
  float[] locateMactan = new float[3];

  locateMactan = changeCoordinate(10, 18, 27, "N", 123, 58, 45, "E");
  //line(0.0, 0.0, 0.0, locateMactan[0], locateMactan[2], locateMactan[1]);

  // Shenzhen Bao'an International Airport
  float[] locateShenzhen = new float[3];

  locateShenzhen = changeCoordinate(22, 38, 22, "N", 113, 48, 39, "E");
  //line(0.0, 0.0, 0.0, locateShenzhen[0], locateShenzhen[2], locateShenzhen[1]);

  // Detroit Metropolitan Wayne County Airport
  float[] locateDetroit = new float[3];

  locateDetroit = changeCoordinate(42, 12, 45, "N", 83, 21, 12, "W");
  //line(0.0, 0.0, 0.0, locateDetroit[0], locateDetroit[2], locateDetroit[1]);

  // George Bush Intercontinental Airport
  float[] locateGeorge = new float[3];

  locateGeorge = changeCoordinate(29, 59, 4, "N", 95, 20, 29, "W");
  //line(0.0, 0.0, 0.0, locateGeorge[0], locateGeorge[2], locateGeorge[1]);

  // Kota Kinabalu International Airport
  float[] locateKota = new float[3];

  locateKota = changeCoordinate(5, 56, 41, "N", 116, 3, 11, "E");
  //line(0.0, 0.0, 0.0, locateKota[0], locateKota[2], locateKota[1]);

  // Mexico City International Airport
  float[] locateMexico = new float[3];

  locateMexico = changeCoordinate(19, 26, 10, "N", 99, 4, 19, "W");
  //line(0.0, 0.0, 0.0, locateMexico[0], locateMexico[2], locateMexico[1]);

  // San Francisco International Airport
  float[] locateSan = new float[3];

  locateSan = changeCoordinate(37, 37, 8, "N", 122, 22, 30, "W");
  //line(0.0, 0.0, 0.0, locateSan[0], locateSan[2], locateSan[1]);

  // Los Angeles International Airport
  float[] locateLos = new float[3];

  locateLos = changeCoordinate(33, 56, 33, "N", 118, 24, 29, "W");
  //line(0.0, 0.0, 0.0, locateLos[0], locateLos[2], locateLos[1]);

  // Seattle-Tacoma International Airport
  float[] locateSeattle = new float[3];

  locateSeattle = changeCoordinate(47, 26, 56, "N", 122, 18, 34, "W");
  //line(0.0, 0.0, 0.0, locateSeattle[0], locateSeattle[2], locateSeattle[1]);

  // Minneapolis-Saint Paul International Airport
  float[] locateMinneapolis = new float[3];

  locateMinneapolis = changeCoordinate(44, 52, 55, "N", 93, 13, 18, "W");
  //line(0.0, 0.0, 0.0, locateMinneapolis[0], locateMinneapolis[2], locateMinneapolis[1]);

  // Hartsfield-Jackson Atlanta International Airport
  float[] locateHartsfield = new float[3];

  locateHartsfield = changeCoordinate(33, 38, 12, "N", 84, 25, 41, "W");
  //line(0.0, 0.0, 0.0, locateHartsfield[0], locateHartsfield[2], locateHartsfield[1]);

  // Calgary International Airport
  float[] locateCalgary = new float[3];

  locateCalgary = changeCoordinate(51, 6, 50, "N", 114, 1, 13, "W");
  //line(0.0, 0.0, 0.0, locateCalgary[0], locateCalgary[2], locateCalgary[1]);

  // Portland International Airport
  float[] locatePortland = new float[3];

  locatePortland = changeCoordinate(45, 35, 19, "N", 122, 35, 51, "W");
  //line(0.0, 0.0, 0.0, locatePortland[0], locatePortland[2], locatePortland[1]);

  // Macau International Airport
  float[] locateMacau = new float[3];

  locateMacau = changeCoordinate(22, 8, 58, "N", 113, 35, 29, "E");
  //line(0.0, 0.0, 0.0, locateMacau[0], locateMacau[2], locateMacau[1]);

  // Tahiti Faa'a International Airport
  float[] locateTahiti = new float[3];

  locateTahiti = changeCoordinate(17, 33, 24, "S", 149, 33, 42, "W");
  //line(0.0, 0.0, 0.0, locateTahiti[0], locateTahiti[2], locateTahiti[1]);

  // Newark Liberty International Airport
  float[] locateNewark = new float[3];

  locateNewark = changeCoordinate(40, 41, 33, "N", 74, 10, 7, "W");
  //line(0.0, 0.0, 0.0, locateNewark[0], locateNewark[2], locateNewark[1]);

  // Denver International Airport
  float[] locateDenver = new float[3];

  locateDenver = changeCoordinate(39, 51, 42, "N", 104, 40, 23.5, "W");
  //line(0.0, 0.0, 0.0, locateDenver[0], locateDenver[2], locateDenver[1]);

  // Xi'an Xianyang International Airport
  float[] locateXi = new float[3];

  locateXi = changeCoordinate(34, 26, 50, "N", 108, 45, 6, "E");
  //line(0.0, 0.0, 0.0, locateXi[0], locateXi[2], locateXi[1]);

  // Vancouver International Airport
  float[] locateVancouver = new float[3];

  locateVancouver = changeCoordinate(49, 11, 38, "N", 123, 11, 4, "W");
  //line(0.0, 0.0, 0.0, locateVancouver[0], locateVancouver[2], locateVancouver[1]);

  // San Diego International Airport
  float[] locateSanD = new float[3];

  locateSanD = changeCoordinate(32, 44, 1, "N", 117, 11, 23, "W");
  //line(0.0, 0.0, 0.0, locateSanD[0], locateSanD[2], locateSanD[1]);

  // Norman Y. Mineta San José International Airport
  float[] locateNorman = new float[3];

  locateNorman = changeCoordinate(37, 21, 46, "N", 121, 55, 45, "W");
  //line(0.0, 0.0, 0.0, locateNorman[0], locateNorman[2], locateNorman[1]);

  // Toronto Pearson International Airport
  float[] locateToronto = new float[3];

  locateToronto = changeCoordinate(43, 40, 38, "N", 79, 37, 50, "W");
  //line(0.0, 0.0, 0.0, locateToronto[0], locateToronto[2], locateToronto[1]);

  // Palau International Airport
  float[] locatePalau = new float[3];

  locatePalau = changeCoordinate(7, 22, 2, "N", 134, 32, 39, "E");
  //line(0.0, 0.0, 0.0, locatePalau[0], locatePalau[2], locatePalau[1]);

  // Auckland International Airport
  float[] locateAuckland = new float[3];

  locateAuckland = changeCoordinate(37, 0, 29, "S", 174, 47, 30, "E");
  //line(0.0, 0.0, 0.0, locateAuckland[0], locateAuckland[2], locateAuckland[1]);

  // Honolulu International Airport
  float[] locateHonolulu = new float[3];

  locateHonolulu = changeCoordinate(21, 19, 7, "N", 157, 55, 20, "W");
  //line(0.0, 0.0, 0.0, locateHonolulu[0], locateHonolulu[2], locateHonolulu[1]);

  // Gold Coast Airport
  float[] locateGold = new float[3];

  locateGold = changeCoordinate(28, 9, 52, "S", 153, 30, 17, "E");
  //line(0.0, 0.0, 0.0, locateGold[0], locateGold[2], locateGold[1]);

  // Port Moresby Jacksons International Airport
  float[] locatePort = new float[3];

  locatePort = changeCoordinate(9, 26, 36, "S", 147, 13, 12, "E");
  //line(0.0, 0.0, 0.0, locatePort[0], locatePort[2], locatePort[1]);

  // Cairns Airport
  float[] locateCairns = new float[3];

  locateCairns = changeCoordinate(16, 53, 12, "S", 145, 45, 18, "E");
  //line(0.0, 0.0, 0.0, locateCairns[0], locateCairns[2], locateCairns[1]);

  // Abu Dhabi International Airport
  float[] locateAbu = new float[3];

  locateAbu = changeCoordinate(24, 25, 58, "N", 54, 39, 4, "E");
  //line(0.0, 0.0, 0.0, locateAbu[0], locateAbu[2], locateAbu[1]);

  // Dubai International Airport
  float[] locateDubai = new float[3];

  locateDubai = changeCoordinate(25, 15, 10, "N", 55, 21, 52, "E");
  //line(0.0, 0.0, 0.0, locateDubai[0], locateDubai[2], locateDubai[1]);

  // Doha International Airport
  float[] locateDoha = new float[3];

  locateDoha = changeCoordinate(25, 15, 40, "N", 51, 33, 54, "E");
  //line(0.0, 0.0, 0.0, locateDoha[0], locateDoha[2], locateDoha[1]);

  // Fiumicino Airport
  float[] locateFiumicino = new float[3];

  locateFiumicino = changeCoordinate(25, 15, 40, "N", 51, 33, 54, "E");
  //line(0.0, 0.0, 0.0, locateFiumicino[0], locateFiumicino[2], locateFiumicino[1]);

  int dpCC = 0;
  int crFF = 0;
  reader.firstRow();
  for (int i = 0; i < reader.getLastRowNum (); i++) {
    int[] dp = int(split(reader.getString(i, 0), ":"));
    float dpH = dp[0];
    int dpHd = int((str(dpH)).charAt(0));
    if(dpHd == 0){
      dpH = float((str(dpH)).charAt(1));
    }
    float dpM = dp[1];
    int dpMd = int((str(dpM)).charAt(0));
    if(dpMd == 0){
      dpM = float((str(dpH)).charAt(1));
    }
    //System.out.println(reader.getRowNum() + ", " + reader.getCellNum() + ", " + dpH + ":" + dpM);
    
    int[] nt = int(split(reader.getString(i, 1), ":"));
    float ntH = nt[0];
    int ntHd = int((str(ntH)).charAt(0));
    if(ntHd == 0){
      ntH = float((str(ntH)).charAt(1));
    }
    float ntM = nt[1];
    int ntMd = int((str(ntM)).charAt(0));
    if(ntMd == 0){
      ntM = float((str(ntM)).charAt(1));
    }
    //System.out.println(reader.getRowNum() + ", " + reader.getCellNum() + ", " + ntH + ":" + ntM);
    
    if(hour * 60 + minute > dpH * 60 + dpM){
      dpCC++;
      dpC = dpCC;
    }
    
    if ((hour * 60 + minute > dpH * 60 + dpM && hour * 60 + minute < (dpH + ntH) * 60 + (dpM + ntM)) || (hour2 * 60 + minute > dpH * 60 + dpM && hour2 * 60 + minute < (dpH + ntH) * 60 + (dpM + ntM))) {
      crFF++;
      crF = crFF;
      float t = 1 - ((((dpH + ntH) * 60 + (dpM + ntM)) - (hour * 60 + minute)) / (ntH * 60 + ntM));
      if((hour2 * 60 + minute > dpH * 60 + dpM && hour2 * 60 + minute < (dpH + ntH) * 60 + (dpM + ntM))){
        t = 1 - ((((dpH + ntH) * 60 + (dpM + ntM)) - (hour2 * 60 + minute)) / (ntH * 60 + ntM));
      }
      String name = reader.getString(i, 2);
      //System.out.println(name);
      if (name.equals("台北")) {
        airRoute2(locate[0], locate[2], locate[1], locateT[0], locateT[2], locateT[1], t);
      } else if (name.equals("成都")) {
        airRoute2(locate[0], locate[2], locate[1], locateChengdu[0], locateChengdu[2], locateChengdu[1], t);
      } else if (name.equals("重慶")) {
        airRoute2(locate[0], locate[2], locate[1], locateChongqing[0], locateChongqing[2], locateChongqing[1], t);
      } else if (name.equals("ソウル")) {
        airRoute2(locate[0], locate[2], locate[1], locateIncheon[0], locateIncheon[2], locateIncheon[1], t);
      } else if (name.equals("マニラ")) {
        airRoute2(locate[0], locate[2], locate[1], locateNinoy[0], locateNinoy[2], locateNinoy[1], t);
      } else if (name.equals("広州")) {
        airRoute2(locate[0], locate[2], locate[1], locateGuangzhou[0], locateGuangzhou[2], locateGuangzhou[1], t);
      } else if (name.equals("グアム")) {
        airRoute2(locate[0], locate[2], locate[1], locateGuam[0], locateGuam[2], locateGuam[1], t);
      } else if (name.equals("ホーチミンシティ")) {
        airRoute2(locate[0], locate[2], locate[1], locateTansonnhat[0], locateTansonnhat[2], locateTansonnhat[1], t);
      } else if (name.equals("香港")) {
        airRoute2(locate[0], locate[2], locate[1], locateHong[0], locateHong[2], locateHong[1], t);
      } else if (name.equals("大連")) {
        airRoute2(locate[0], locate[2], locate[1], locateDalian[0], locateDalian[2], locateDalian[1], t);
      } else if (name.equals("上海")) {
        airRoute2(locate[0], locate[2], locate[1], locateShanghai[0], locateShanghai[2], locateShanghai[1], t);
      } else if (name.equals("済州")) {
        airRoute2(locate[0], locate[2], locate[1], locateJeju[0], locateJeju[2], locateJeju[1], t);
      } else if (name.equals("厦門")) {
        airRoute2(locate[0], locate[2], locate[1], locateXiamen[0], locateXiamen[2], locateXiamen[1], t);
      } else if (name.equals("ハノイ")) {
        airRoute2(locate[0], locate[2], locate[1], locateNoi[0], locateNoi[2], locateNoi[1], t);
      } else if (name.equals("瀋陽")) {
        airRoute2(locate[0], locate[2], locate[1], locateShenyang[0], locateShenyang[2], locateShenyang[1], t);
      } else if (name.equals("杭州")) {
        airRoute2(locate[0], locate[2], locate[1], locateHangzhou[0], locateHangzhou[2], locateHangzhou[1], t);
      } else if (name.equals("青島")) {
        airRoute2(locate[0], locate[2], locate[1], locateQingdao[0], locateQingdao[2], locateQingdao[1], t);
      } else if (name.equals("サイパン")) {
        airRoute2(locate[0], locate[2], locate[1], locateSaipan[0], locateSaipan[2], locateSaipan[1], t);
      } else if (name.equals("チューリッヒ")) {
        airRoute2(locate[0], locate[2], locate[1], locateZurich[0], locateZurich[2], locateZurich[1], t);
      } else if (name.equals("アムステルダム")) {
        airRoute2(locate[0], locate[2], locate[1], locateSchiphol[0], locateSchiphol[2], locateSchiphol[1], t);
      } else if (name.equals("ヘルシンキ")) {
        airRoute2(locate[0], locate[2], locate[1], locateHelsinki[0], locateHelsinki[2], locateHelsinki[1], t);
      } else if (name.equals("クアラルンプール")) {
        airRoute2(locate[0], locate[2], locate[1], locateKuala[0], locateKuala[2], locateKuala[1], t);
      } else if (name.equals("シカゴ")) {
        airRoute2(locate[0], locate[2], locate[1], locateChicago[0], locateChicago[2], locateChicago[1], t);
      } else if (name.equals("ジャカルタ")) {
        airRoute2(locate[0], locate[2], locate[1], locateJakarta[0], locateJakarta[2], locateJakarta[1], t);
      } else if (name.equals("ロンドン")) {
        airRoute2(locate[0], locate[2], locate[1], locateL[0], locateL[2], locateL[1], t);
      } else if (name.equals("釜山")) {
        airRoute2(locate[0], locate[2], locate[1], locateGimhae[0], locateGimhae[2], locateGimhae[1], t);
      } else if (name.equals("バンコク(スワンナプーム)")) {
        airRoute2(locate[0], locate[2], locate[1], locateSuvarnabhumi[0], locateSuvarnabhumi[2], locateSuvarnabhumi[1], t);
      } else if (name.equals("ヤンゴン")) {
        airRoute2(locate[0], locate[2], locate[1], locateYangon[0], locateYangon[2], locateYangon[1], t);
      } else if (name.equals("デンパサール")) {
        airRoute2(locate[0], locate[2], locate[1], locateDenpasar[0], locateDenpasar[2], locateDenpasar[1], t);
      } else if (name.equals("ニューヨーク")) {
        airRoute2(locate[0], locate[2], locate[1], locateJohn[0], locateJohn[2], locateJohn[1], t);
      } else if (name.equals("デュッセルドルフ")) {
        airRoute2(locate[0], locate[2], locate[1], locateFlughafen[0], locateFlughafen[2], locateFlughafen[1], t);
      } else if (name.equals("ワシントン DC")) {
        airRoute2(locate[0], locate[2], locate[1], locateWashington[0], locateWashington[2], locateWashington[1], t);
      } else if (name.equals("シンガポール")) {
        airRoute2(locate[0], locate[2], locate[1], locateSingapore[0], locateSingapore[2], locateSingapore[1], t);
      } else if (name.equals("ボストン")) {
        airRoute2(locate[0], locate[2], locate[1], locateGeneral[0], locateGeneral[2], locateGeneral[1], t);
      } else if (name.equals("ウィーン")) {
        airRoute2(locate[0], locate[2], locate[1], locateVienna[0], locateVienna[2], locateVienna[1], t);
      } else if (name.equals("デリー")) {
        airRoute2(locate[0], locate[2], locate[1], locateIndira[0], locateIndira[2], locateIndira[1], t);
      } else if (name.equals("ダラスフォートワース")) {
        airRoute2(locate[0], locate[2], locate[1], locateDallas[0], locateDallas[2], locateDallas[1], t);
      } else if (name.equals("フランクフルト")) {
        airRoute2(locate[0], locate[2], locate[1], locateFrankfurt[0], locateFrankfurt[2], locateFrankfurt[1], t);
      } else if (name.equals("コペンハーゲン")) {
        airRoute2(locate[0], locate[2], locate[1], locateCopenhagen[0], locateCopenhagen[2], locateCopenhagen[1], t);
      } else if (name.equals("パリ")) {
        airRoute2(locate[0], locate[2], locate[1], locateCharles[0], locateCharles[2], locateCharles[1], t);
      } else if (name.equals("イスタンブール")) {
        airRoute2(locate[0], locate[2], locate[1], locateAtaturk[0], locateAtaturk[2], locateAtaturk[1], t);
      } else if (name.equals("ミラノ")) {
        airRoute2(locate[0], locate[2], locate[1], locateMilan[0], locateMilan[2], locateMilan[1], t);
      } else if (name.equals("ヌーメア")) {
        airRoute2(locate[0], locate[2], locate[1], locateNoumea[0], locateNoumea[2], locateNoumea[1], t);
      } else if (name.equals("高雄")) {
        airRoute2(locate[0], locate[2], locate[1], locateKaohsiung[0], locateKaohsiung[2], locateKaohsiung[1], t);
      } else if (name.equals("メルボルン")) {
        airRoute2(locate[0], locate[2], locate[1], locateMelbourne[0], locateMelbourne[2], locateMelbourne[1], t);
      } else if (name.equals("ローマ")) {
        airRoute2(locate[0], locate[2], locate[1], locateFiumicino[0], locateFiumicino[2], locateFiumicino[1], t);
      } else if (name.equals("コロンボ")) {
        airRoute2(locate[0], locate[2], locate[1], locateBandaranaike[0], locateBandaranaike[2], locateBandaranaike[1], t);
      } else if (name.equals("ウラジオストク")) {
        airRoute2(locate[0], locate[2], locate[1], locateVladivostok[0], locateVladivostok[2], locateVladivostok[1], t);
      } else if (name.equals("セブ")) {
        airRoute2(locate[0], locate[2], locate[1], locateMactan[0], locateMactan[2], locateMactan[1], t);
      } else if (name.equals("シンセン")) {
        airRoute2(locate[0], locate[2], locate[1], locateShenzhen[0], locateShenzhen[2], locateShenzhen[1], t);
      } else if (name.equals("デトロイト")) {
        airRoute2(locate[0], locate[2], locate[1], locateDetroit[0], locateDetroit[2], locateDetroit[1], t);
      } else if (name.equals("ヒューストン")) {
        airRoute2(locate[0], locate[2], locate[1], locateGeorge[0], locateGeorge[2], locateGeorge[1], t);
      } else if (name.equals("コタキナバル")) {
        airRoute2(locate[0], locate[2], locate[1], locateKota[0], locateKota[2], locateKota[1], t);
      } else if (name.equals("メキシコシティ")) {
        airRoute2(locate[0], locate[2], locate[1], locateMexico[0], locateMexico[2], locateMexico[1], t);
      } else if (name.equals("サンフランシスコ")) {
        airRoute2(locate[0], locate[2], locate[1], locateSan[0], locateSan[2], locateSan[1], t);
      } else if (name.equals("ロスアンゼルス")) {
        airRoute2(locate[0], locate[2], locate[1], locateLos[0], locateLos[2], locateLos[1], t);
      } else if (name.equals("シアトル")) {
        airRoute2(locate[0], locate[2], locate[1], locateSeattle[0], locateSeattle[2], locateSeattle[1], t);
      } else if (name.equals("ミネアポリス")) {
        airRoute2(locate[0], locate[2], locate[1], locateMinneapolis[0], locateMinneapolis[2], locateMinneapolis[1], t);
      } else if (name.equals("アトランタ")) {
        airRoute2(locate[0], locate[2], locate[1], locateHartsfield[0], locateHartsfield[2], locateHartsfield[1], t);
      } else if (name.equals("カルガリー")) {
        airRoute2(locate[0], locate[2], locate[1], locateCalgary[0], locateCalgary[2], locateCalgary[1], t);
      } else if (name.equals("ポートランド")) {
        airRoute2(locate[0], locate[2], locate[1], locatePortland[0], locatePortland[2], locatePortland[1], t);
      } else if (name.equals("マカオ")) {
        airRoute2(locate[0], locate[2], locate[1], locateMacau[0], locateMacau[2], locateMacau[1], t);
      } else if (name.equals("パペーテ")) {
        airRoute2(locate[0], locate[2], locate[1], locateTahiti[0], locateTahiti[2], locateTahiti[1], t);
      } else if (name.equals("ニューアーク")) {
        airRoute2(locate[0], locate[2], locate[1], locateNewark[0], locateNewark[2], locateNewark[1], t);
      } else if (name.equals("デンバー")) {
        airRoute2(locate[0], locate[2], locate[1], locateDenver[0], locateDenver[2], locateDenver[1], t);
      } else if (name.equals("西安")) {
        airRoute2(locate[0], locate[2], locate[1], locateXi[0], locateXi[2], locateXi[1], t);
      } else if (name.equals("バンクーバー")) {
        airRoute2(locate[0], locate[2], locate[1], locateVancouver[0], locateVancouver[2], locateVancouver[1], t);
      } else if (name.equals("サンディエゴ")) {
        airRoute2(locate[0], locate[2], locate[1], locateSanD[0], locateSanD[2], locateSanD[1], t);
      } else if (name.equals("サンノゼ")) {
        airRoute2(locate[0], locate[2], locate[1], locateNorman[0], locateNorman[2], locateNorman[1], t);
      } else if (name.equals("トロント")) {
        airRoute2(locate[0], locate[2], locate[1], locateToronto[0], locateToronto[2], locateToronto[1], t);
      } else if (name.equals("コロール")) {
        airRoute2(locate[0], locate[2], locate[1], locatePalau[0], locatePalau[2], locatePalau[1], t);
      } else if (name.equals("オークランド")) {
        airRoute2(locate[0], locate[2], locate[1], locateAuckland[0], locateAuckland[2], locateAuckland[1], t);
      } else if (name.equals("ホノルル")) {
        airRoute2(locate[0], locate[2], locate[1], locateHonolulu[0], locateHonolulu[2], locateHonolulu[1], t);
      } else if (name.equals("シドニー")) {
        airRoute2(locate[0], locate[2], locate[1], locateS[0], locateS[2], locateS[1], t);
      } else if (name.equals("ゴールドコースト")) {
        airRoute2(locate[0], locate[2], locate[1], locateGold[0], locateGold[2], locateGold[1], t);
      } else if (name.equals("ポートモレスビー")) {
        airRoute2(locate[0], locate[2], locate[1], locatePort[0], locatePort[2], locatePort[1], t);
      } else if (name.equals("ケアンズ")) {
        airRoute2(locate[0], locate[2], locate[1], locateCairns[0], locateCairns[2], locateCairns[1], t);
      } else if (name.equals("アブダビ")) {
        airRoute2(locate[0], locate[2], locate[1], locateAbu[0], locateAbu[2], locateAbu[1], t);
      } else if (name.equals("ドバイ")) {
        airRoute2(locate[0], locate[2], locate[1], locateDubai[0], locateDubai[2], locateDubai[1], t);
      } else if (name.equals("ドーハ")) {
        airRoute2(locate[0], locate[2], locate[1], locateDoha[0], locateDoha[2], locateDoha[1], t);
      }
      else if (name.equals("北京")) {
        airRoute2(locate[0], locate[2], locate[1], locateBeijing[0], locateBeijing[2], locateBeijing[1], t);
      }
      else {
        System.out.println(name + "は登録されていない空港名です。");
      }
    }
  }

  // Narita to London
  //airRoute(locate[0], locate[2], locate[1], locateL[0], locateL[2], locateL[1], 10 * 60 + 50, 15 * 60 + 20, 8 * 60, "N");

  // Narita to Sao Paulo
  //airRoute(locate[0], locate[2], locate[1], locateB[0], locateB[2], locateB[1], 20 * 60, 9 * 60, 12 * 60, "Y");

  // Narita to Sydney
  //airRoute(locate[0], locate[2], locate[1], locateS[0], locateS[2], locateS[1], 13 * 60, 23 * 60 + 40, -1 * 60, "N");
  
  // Narita to Beijing
  //airRoute(locate[0], locate[2], locate[1], locateBeijing[0], locateBeijing[2], locateBeijing[1], 13 * 60, 23 * 60 + 40, -1 * 60, "N");
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
    xyz[i] = xyz[i] * 1.0085;
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

void airRoute(float lx1, float ly1, float lz1, float lx2, float ly2, float lz2, int dp, int ar, int td, String YN) {
  float cx, cy, cz, cx1, cy1, cz1, cx2, cy2, cz2;
  cx = (lx1 + lx2) / 2;
  cy = (ly1 + ly2) / 2;
  cz = (lz1 + lz2) / 2;
  if (sqrt((cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 3) {
    while (sqrt ( (cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 2) {
      cx *= 1.01;
      cy *= 1.01;
      cz *= 1.01;
    }
    cx *= 1.5;
    cy *= 1.5;
    cz *= 1.5;
  }
  else if (sqrt((cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 2) {
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
  stroke(22, 233, 159, 40);
  line(0.0, 0.0, 0.0, cx, cy, cz);
  line(0.0, 0.0, 0.0, cx1, cy1, cz1);
  line(0.0, 0.0, 0.0, cx2, cy2, cz2);

  if (YN == "Y") { // over day yes or no
    ar = ar + 24 * 60;
  }
  float nt = (float)(ar - (dp - td)); //neccesaryTime = arriveTime - (departureTime - timeDifference)
  nt = nt * 60; // minute to second
  // System.out.println("nt = " + nt);

  stroke(255, 255, 0, 50);
  bezier(lx1, ly1, lz1, cx1, cy1, cz1, cx2, cy2, cz2, lx2, ly2, lz2);
  float t = sec / nt;
  if (t > 1.0) {
    t = 1.0;
  }
  // System.out.println(t);
  float x = bezierPoint(lx1, cx1, cx2, lx2, t);
  float y = bezierPoint(ly1, cy1, cy2, ly2, t);
  float z = bezierPoint(lz1, cz1, cz2, lz2, t);
  //System.out.println(x + ", " + y + ", " + z + ", " + t);
  pushMatrix();
  translate(x, y, z);
  if (sec >= nt) {
    stroke(0, 0, 255, 50);
  } else if (sec < nt) {
    stroke(255, 0, 0, 50);
  }
  sphere(5);
  popMatrix();
}

void airRoute2(float lx1, float ly1, float lz1, float lx2, float ly2, float lz2, float t) {
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
  }
  else if (sqrt((cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 3) {
    while (sqrt ( (cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 2) {
      cx *= 1.01;
      cy *= 1.01;
      cz *= 1.01;
    }
    cx *= 1.25;
    cy *= 1.25;
    cz *= 1.25;
  }
  else if (sqrt((cx * cx) + (cy * cy) + (cz * cz)) < globeRadius / 2) {
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

  //  if (YN == "Y") { // over day yes or no
  //    ar = ar + 24 * 60;
  //  }
  //  float nt = (float)(ar - (dp - td)); //neccesaryTime = arriveTime - (departureTime - timeDifference)
  //  nt = nt * 60; // minute to second
  //  // System.out.println("nt = " + nt);

  strokeWeight(3);
  if(t > 0.9){
    stroke(255, 0, 38, 30);
  }
  else {
    stroke(15, 60, 241, 30);
  }
  bezier(lx1, ly1, lz1, cx1, cy1, cz1, cx2, cy2, cz2, lx2, ly2, lz2);
  //  float t = sec / nt;
  //  if (t >= 1.0) {
  //    t = 1.0;
  //  }
  // System.out.println(t);
  float x = bezierPoint(lx1, cx1, cx2, lx2, t);
  float y = bezierPoint(ly1, cy1, cy2, ly2, t);
  float z = bezierPoint(lz1, cz1, cz2, lz2, t);
  //System.out.println(x + ", " + y + ", " + z + ", " + t);
  pushMatrix();
  translate(x, y, z);
  //  if (sec >= nt) {
  //    stroke(0, 0, 255, 50);
  //  }
  //  else if (sec < nt) {
  //    stroke(255, 0, 0, 50);
  //  }
  stroke(241, 196, 15, 50);
  sphere(3);
  popMatrix();
}

void clock() {
  second += sec;
  if(second >= 60){
    minute++;
    second = 0;
  }
  if(minute >= 60){
    hour++;
    hour2++;
    minute = 0;
  }
  if(hour >= 24){
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
  text(t, 830, 670);
}

void timeSpeed() {
  float time = map(sx, 40, 290, 1, 3600);
  timer += (int)time;
  sec = timer / 60;
  if(sec > 0){
    timer = 0;
  }
  //System.out.println(timer + ", " + sec);
  textSize(20);
  fill(52, 153, 211);
  text((int)time + "speed", 360, 654);
}

void slideBar() {
  noFill();
  stroke(192, 192, 192);
  strokeWeight(3);
  rectMode(CORNER);
  rect(40, 640, 250, 16);
  noStroke();
  fill(255, 255, 255);
  rectMode(CENTER);
  rect(sx, 648, 16, 32);
  rectMode(CORNER);
  rect(40, 640, sx - 40, 16);
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

void mousePressed() {
  float x = mouseX;
  float y = mouseY;
  if (x > 32 && x < 298 && y > 632 && y < 664) {
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

