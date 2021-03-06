/*
 
 INTRO TO INTERACTIVE MEDIA
 PROF. MICHAEL SHILOH
 
 MIDTERM PROJECT BY AYUSH PANDEY
 MARCH 4, 2021
 
 GAME TITLE
 Marine Voyage in the Pacific
 
 INSTRUCTIONS
 - Move the Submarine by clicking and dragging the mouse up and down.
 - Press SPACEBAR to fire Missiles.
 
 WIN/LOSE
 - The game runs infinitely, so your task is to kill as many sharks as you can and beat your own high score.
 - If you miss more than more than 5 sharks, you lose.
 - If a shark reaches you before you kill it, you lose.
 
*/

import processing.sound.*;

// class to handle background images with parallax effect
public class Background {
  private PImage img;
  private PImage[] subImg;
  private float xShift; // shift in x-direction

  public Background() {
    
    // loading images
    img = loadImage("images/marine.png");

    subImg = new PImage[3];
    for (int i = 1; i <= 3; i++) {
      subImg[i - 1] = loadImage("images/sub" + i + ".png");
    }

    xShift = 0;
  }

  public void display() {
    image(img, width / 2, height / 2);
    
    // shifting all images to the left
    xShift += 2;

    int count = 1;
    for (PImage sub : subImg) {
      int x;
      
      // change in shift intensity
      if (count == 1) {
        x = (int) xShift / 3;
      } else if (count == 2) {
        x = (int) xShift / 2;
      } else {
        x = (int) xShift;
      }

      // calculating correct positions for images
      int wR, wL;
      wR = x % width;
      wL = width - wR;

      imageMode(CORNER);
      image(sub, 0, 0, wL, height, wR, 0, width, height);
      image(sub, wL, 0, wR, height, 0, 0, wR, height);
      imageMode(CENTER);

      count++;
    }
  }
}

// the main submarine character of the game
public class SubMarine {
  private PImage img;
  public PVector position;
  private int imgCount, cropStart;
  public int size;
  private float rotation, speed;

  public SubMarine() {
    position = new PVector(100, random(100, height / 1.5));
    img = loadImage("images/submarine.png");

    imgCount = 5;
    cropStart = 0;
    
    // for rotation of submarine towards mouse position
    rotation = 0;
    
    size = 120;
    speed = 3;
  }

  public void display() {
    // rotation angle = arctan of the slope
    rotation = atan2(mouseY - position.y, mouseX - position.x);
    
    // limiting rotation
    if (rotation > radians(30)) { 
      rotation = radians(30);
    }
    if (rotation < radians(-30)) { 
      rotation = radians(-30);
    }
    
    // rendering the rotated submarine
    pushMatrix();
    imageMode(CENTER);
    translate(position.x, position.y);
    rotate(rotation);
    image(img, 0, 0, size, size, cropStart * (img.width / imgCount), 0, cropStart * (img.width / imgCount) + (img.width / imgCount), img.height);
    popMatrix();
    
    // for sprite animation
    if (frameCount % 5 == 0 || frameCount == 1) {
      if (cropStart < imgCount - 1) {
        cropStart++;
      } else {
        cropStart = 0;
      }
    }
  }
  
  public void update() {
    float increment = 0;
    if (rotation < radians(-10)) {
      increment = -(speed);
    } else if (rotation > radians(10)) {
      increment = speed;
    }

    if ((position.y + increment) < (height - size / 2) && (position.y + increment) > (size / 2)) {
      position.y += increment;
    }
  }
}

// class for the enemy of game - Shark
public class Shark {
  private PVector position;
  private PImage img;
  private int imgCount, cropStart, size;

  private float speed;

  public Shark() {
    position = new PVector(width + 200, random(100, height / 1.2));
    img = loadImage("images/shark.png");

    imgCount = 6;
    size = 200;
    cropStart = 0;

    speed = random(4, 6);
  }

  public void display() {
    // shark images are not in square dimensions, so calculating ratio
    float ratio = (float) img.height / (img.width / imgCount);

    image(img, position.x, position.y, size, size * ratio, cropStart * (img.width / imgCount), 0, cropStart * (img.width / imgCount) + (img.width / imgCount), img.height);
    update();
    
    if (frameCount % 10 == 0 || frameCount == 1) {
      if (cropStart < imgCount - 1) {
        cropStart++;
      } else {
        cropStart = 0;
      }
    }
  }

  public void update() {
    position.x -= speed;
    
    // if shark is missed by the player, its object gets deleted
    if (position.x < -200) {
      game.sharks.remove(this);
      game.missed++;
      
      // increasing the missed index
      if (game.missed > 5) {
        game.screen = 2;
      }
    }
    
    // checking if any missile has hit the shark
    for (int i = 0; i < game.missiles.size(); i++) {
      Missile missile = game.missiles.get(i);
      if (dist(missile.position.x, missile.position.y, position.x, position.y) < size / 2) {
        // displaying explosion
        game.explosions.add(new Explosion(missile.position.x + 30, missile.position.y));
        game.explosionAudio.play();
        
        // removing missile and shark from screen
        game.missiles.remove(missile);
        game.sharks.remove(this);
        
        // incrementing the score by 10
        game.score += 10;
      }
    }
    
    // if any shark touches the player, game is over
    if (dist(game.submarine.position.x, game.submarine.position.y, position.x, position.y) < (game.submarine.size / 2 + size / 2 - 20)) {
      game.screen = 2;
      game.gameoverAudio.play();
    }
  }
}

// class for missile object
public class Missile {
  private PImage img;
  public PVector position;

  private int imgCount, cropStart, size;

  public Missile() {
    img = loadImage("images/missile.png");
    position = new PVector(game.submarine.position.x + 20, game.submarine.position.y + 35);

    cropStart = 0;
    imgCount = 5;
    size = 80;
  }

  public void display() {
    // ratio of the missile for display
    float ratio = (float) img.height / (img.width / imgCount);
    
    image(img, position.x, position.y, size, size * ratio, cropStart * (img.width / imgCount), 0, cropStart * (img.width / imgCount) + (img.width / imgCount), img.height);
    update();

    if (frameCount % 7 == 0 || frameCount == 1) {
      if (cropStart < imgCount - 1) {
        cropStart++;
      } else {
        cropStart = 0;
      }
    }
  }

  public void update() {
    // moving missile to the right
    position.x += 3;
    
    // if it does not touch any shark, it just gets removed from the ArrayList
    if (position.x >= width + 50) {
      game.missiles.remove(this);
    }
  }
}

// class for explosion
public class Explosion {
  private PImage img;
  private PVector position;

  private int imgCount, cropStart, size;

  public Explosion(float x, float y) {
    position = new PVector(x, y);
    img = loadImage("images/explosion.png");

    cropStart = 0;
    imgCount = 5;
    size = 100;
  }

  public void display() {
    if (cropStart < imgCount) {
      image(img, position.x, position.y, size, size, cropStart * (img.width / imgCount), 0, cropStart * (img.width / imgCount) + (img.width / imgCount), img.height);
      if (frameCount % 10 == 0) {
        cropStart++;
      }
    } else {
      game.explosions.remove(this);
    }
  }
}

// class that shows a button on given x, y position
public class Button {
  private PVector position;
  private String txt;

  private float w, h;

  public Button(float x, float y, String txt) {

    position = new PVector(x, y);
    this.txt = txt;

    w = 100;
    h = 40;
  }

  public void display() {
    // rectangular container
    rectMode(CENTER);
    noFill();
    stroke(255);
    strokeWeight(2);
    rect(position.x, position.y, w, h);
    
    // button text
    textAlign(CENTER);
    textSize(20);
    text(txt, position.x, position.y + 7);

    // to handle button click events
    handleClick();
  }

  private void handleClick() {
    // in case button is clicked, navigating to respective screens
    if (mousePressed) {
      if (abs(mouseX - position.x) < w / 2 && abs(mouseY - position.y) < h / 2) {
        switch(txt) {
        case "PLAY":
          game.screen = 1;
          break;
        case "EXIT":
          game.screen = 3;
          break;
        case "RESTART":
          game.restart();
          break;
        }
      }
    }
  }
}

// the main Game class
public class Game {
  private PFont font;

  private Background background;
  public SubMarine submarine;

  // objects to frequently render on screen
  public ArrayList<Shark> sharks;
  public ArrayList<Missile> missiles;
  public ArrayList<Explosion> explosions;

  public int screen, score, missed;
  private color scoreColor;

  private String highScoreFile;
  private int highScore;
  
  // sound files
  public SoundFile backgroundAudio, missileAudio, explosionAudio, gameoverAudio, highscoreAudio;
  
  private boolean highScoreDisplayed;

  public Game() {
    screen = score = missed = 0;
    
    // FONT - BIG NOODLE TITLING
    font = createFont("fonts/big_noodle_titling.ttf", 32);
    textFont(font);
    scoreColor = color(255, 255, 255);
    
    background = new Background();
    submarine = new SubMarine();

    sharks = new ArrayList<Shark>();
    missiles = new ArrayList<Missile>();
    explosions = new ArrayList<Explosion>();

    // this will be the file from where high score will be read and stored
    highScoreFile = "high-score.txt";
    highScore = readHighScore();
    highScoreDisplayed = false;
    
    // audio objects
    backgroundAudio = new SoundFile(midtermProject.this, "audio/background.mp3");
    backgroundAudio.loop();
    
    missileAudio = new SoundFile(midtermProject.this, "audio/missile.wav");
    explosionAudio = new SoundFile(midtermProject.this, "audio/explosion.wav");
    gameoverAudio = new SoundFile(midtermProject.this, "audio/gameover.wav");
    highscoreAudio = new SoundFile(midtermProject.this, "audio/highscore.wav");
  }

  public void update() {
    // background will be displayed all the time
    background.display();
    
    // navigating player to respective screens
    switch(screen) {
    case 0:{
      // this is the main menu
      fill(scoreColor);
      textSize(60);
      textAlign(CENTER);
      text("Marine Voyage", width / 2, height / 3.5);
      textSize(30);
      text("in the Pacific", width / 2, height / 3.5 + 30);
      
      // PLAY BUTTON
      Button play = new Button(width / 2 - 110 / 2, height / 3.5 + 90, "PLAY");
      play.display();
      
      // EXIT BUTTON
      Button exit = new Button(width / 2 + 110 / 2, height / 3.5 + 90, "EXIT");
      exit.display();
      
      break;
    }
    case 1:{
      // start of the game after Main Menu
      submarine.display();

      if (frameCount % 100 == 0) {
        if (sharks.size() < 4) {
          sharks.add(new Shark());
        }
      }

      // displaying all sharks
      for (int i = 0; i < sharks.size(); i++) {
        sharks.get(i).display();
      }
      
      // displaying all fired missiles
      for (int i = 0; i < missiles.size(); i++) {
        missiles.get(i).display();
      }
  
      // displaying all explosions
      for (int i = 0; i < explosions.size(); i++) {
        explosions.get(i).display();
      }
      
      // showing scores at the top
      showScores();
      
      // handle action on mouse pressed
      if (mousePressed) {
        mouseHandler();
      }
      
      break;
    }
    case 2:{
      // this is the game over screen
      if (score > highScore) {
        // if user has high score, it'll update the file as well
        newHighScore();
      }

      fill(scoreColor);
      textSize(60);
      textAlign(CENTER);
      text("GAME OVER", width / 2, height / 3.5);
      textSize(30);
      text((missed > 5) ? "MISSED MANY SHARKS": "YOU DIED", width / 2, height / 3.5 + 30);
      
      // RESTART BUTTON
      Button restart = new Button(width / 2 - 110 / 2, height / 3.5 + 90, "RESTART");
      restart.display();
      
      // EXIT BUTTON
      Button exit = new Button(width / 2 + 110 / 2, height / 3.5 + 90, "EXIT");
      exit.display();
      showScores();
      break;
    }
    
    case 3:{
      // ON EXIT
      backgroundAudio.stop();
      exit();
    }
    }
  }
  
  // method to show all score texts
  private void showScores() {
    // score
    textAlign(RIGHT);
    fill(scoreColor);
    textSize(35);
    text("SCORE", width - 10, 35);
    textSize(28);
    text(score, width - 10, 65);

    // missed sharks
    textAlign(LEFT);
    textSize(35);
    text("MISSED", 10, 35);
    textSize(28);
    text(missed, 10, 65);
    
    // if high score is beaten
    if(score > highScore){
      textAlign(CENTER);
      textSize(35);
      text("NEW HIGH SCORE!", width / 2, 45);
      
      if(!highScoreDisplayed){
        highscoreAudio.play();
        highScoreDisplayed = true;
      }
    }
  }
  
  private void mouseHandler() {
    submarine.update();
  }
  
  // method to read the high score file
  private int readHighScore() {
    int hs;
    
    // high score file object
    File file = new File(dataPath(highScoreFile));
    
    // read file if exists, otherwise high score is obviously 0
    if (file.exists()) {
      BufferedReader reader = createReader(dataPath(highScoreFile));
      try {
        hs = Integer.parseInt(reader.readLine());
      }
      catch(IOException ioe) {
        hs = 0;
      }
    } else {
      hs = 0;
    }

    return hs;
  }

  // method to write new high score to file
  private void newHighScore() {
    PrintWriter writer = createWriter(dataPath(highScoreFile));
    writer.print(score);
    writer.flush();
    writer.close();
  }
  
  // method to restart the game
  private void restart() {
    backgroundAudio.stop();
    game = new Game();
    game.screen = 1;
  }
}

Game game;
void setup() {
  size(1100, 684);
  imageMode(CENTER);
  
  // when images and sounds are loading, showing Loading... text
  background(0);
  fill(255);
  textAlign(CENTER);
  textSize(25);
  text("Loading...", width / 2, height / 2);
  
  game = new Game();
}

// updating the game screen
void draw() {
  game.update();
}

// keyPressed event - FIRE MISSILE WHEN SPACE IS PRESSED
void keyPressed() {
  if (keyCode == 32 && game.missiles.size() < 4) {
    game.missiles.add(new Missile());
    game.missileAudio.play();
  }
}
