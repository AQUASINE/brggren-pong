<template>
  <div class="score left">{{ leftScore }}</div>
  <div class="score right">{{ rightScore }}</div>
  <canvas class="game-canvas" ref="canvas"></canvas>
</template>

<script>
class Ball {
  constructor(x, y, radius, imageUrl) {
    this.x = x;
    this.y = y;
    this.resetX = x;
    this.resetY = y;
    this.radius = radius;
    this.defaultSpeed = 10;
    this.speed = this.defaultSpeed;
    this.image = new Image();
    this.image.onload = () => {
      console.log("image loaded");
    };
    this.image.src = imageUrl;
    this.generateRandomAngle();
  }

  draw(ctx) {
    ctx.drawImage(this.image, this.x - this.radius, this.y - this.radius, this.radius * 2, this.radius * 2);
  }

  reset() {
    this.x = this.resetX;
    this.y = this.resetY;
    this.speed = this.defaultSpeed;
  }

  generateRandomAngle() {
    this.angle = (Math.random() * Math.PI - Math.PI * 0.5) * 0.77;
    if (Math.abs(this.angle) < Math.PI / 8) {
      this.generateRandomAngle();
    }
    this.dx = Math.cos(this.angle);
    if (Math.random() < 0.5) {
      this.dx *= -1;
    }
    this.dy = Math.sin(this.angle);
  }
}

class ScoringHandler {
  constructor(canvas, ball, leftPaddle, rightPaddle, onLeftScore, onRightScore) {
    this.ball = ball;
    this.canvas = canvas;
    this.onLeftScore = onLeftScore;
    this.onRightScore = onRightScore;
    this.leftPaddle = leftPaddle;
    this.rightPaddle = rightPaddle;
  }

  check() {
    let threshold = this.canvas.width / 80;
    if (this.ball.x + this.ball.radius > this.canvas.width - threshold) {
      this.onLeftScore();
      this.reset();
    } else if (this.ball.x - this.ball.radius < threshold) {
      this.onRightScore();
      this.reset();
    }
  }

  reset() {
    this.ball.reset()
    this.leftPaddle.reset();
    this.rightPaddle.reset();
  }
}

class BallMoveBehavior {
  constructor(ball, canvas, leftPaddle, rightPaddle, scoringHandler) {
    this.ball = ball;
    this.canvas = canvas;
    this.leftPaddle = leftPaddle;
    this.rightPaddle = rightPaddle;
    this.scoringHandler = scoringHandler;
  }

  move() {
    this.ball.x += this.ball.dx * this.ball.speed;
    this.ball.y += this.ball.dy * this.ball.speed;
    this.checkCollision();
  }

  slope() {
    return this.ball.dy / this.ball.dx;
  }

  checkCollision() {
    let ball = this.ball;
    if (ball.x + ball.radius > this.canvas.width || ball.x - ball.radius < 0) {
      ball.dx = -ball.dx;
    }
    if (ball.y + ball.radius > this.canvas.height || ball.y - ball.radius < 0) {
      ball.dy = -ball.dy;
    }
    if (ball.x - ball.radius < this.leftPaddle.x + this.leftPaddle.width &&
      ball.x + ball.radius > this.leftPaddle.x &&
      ball.y + ball.radius > this.leftPaddle.y &&
      ball.y - ball.radius < this.leftPaddle.y + this.leftPaddle.height) {
      ball.dx = -ball.dx;
      ball.x = this.leftPaddle.x + this.leftPaddle.width + ball.radius;
      this.speedUp();
    }
    if (this.ball.x + this.ball.radius > this.rightPaddle.x &&
      this.ball.x - this.ball.radius < this.rightPaddle.x + this.rightPaddle.width &&
      this.ball.y + this.ball.radius > this.rightPaddle.y &&
      this.ball.y - this.ball.radius < this.rightPaddle.y + this.rightPaddle.height) {
      ball.dx = -ball.dx;
      ball.x = this.rightPaddle.x - ball.radius;
      this.speedUp();
    }
    this.scoringHandler.check();
  }

  speedUp() {
    if (this.ball.speed < 35) {
      this.ball.speed += 0.5;
    }
  }
}

class PaddleMoveBehavior {
  constructor(paddle, ballMoveBehavior, canvas) {
    this.paddle = paddle;
    this.canvas = canvas;
    this.ballMoveBehavior = ballMoveBehavior;
    this.speed = 8;
  }

  update() {
    if (Math.sign(this.ballMoveBehavior.ball.dx) !== Math.sign(this.paddle.x - this.ballMoveBehavior.ball.x)) {
      if (Math.abs(this.ballMoveBehavior.ball.x - this.paddle.x) < this.canvas.width / 4) {
        return;
      }
      this.movePaddleTowardsTarget(this.canvas.height / 2)
      return;
    }
    let slope = this.ballMoveBehavior.slope();
    let screenHeight = this.canvas.height;
    let targetX = this.paddle.x + this.paddle.width / 2;
    let trajectoryY = this.ballMoveBehavior.ball.y + (slope * (targetX - this.ballMoveBehavior.ball.x));
    let numBounces = Math.floor(trajectoryY / screenHeight);
    let bounceOffset = trajectoryY - (numBounces * screenHeight);
    let targetY = bounceOffset - this.paddle.height / 2;
    if (numBounces % 2 !== 0) {
      targetY = screenHeight - bounceOffset - this.paddle.height / 2;
    }
    this.movePaddleTowardsTarget(targetY);
    this.ensurePaddleInBounds();
  }

  movePaddleTowardsTarget(targetY) {
    if (targetY - this.paddle.y > this.speed) {
      this.paddle.y += this.speed;
    } else if (targetY - this.paddle.y < -this.speed) {
      this.paddle.y -= this.speed;
    }
  }

  ensurePaddleInBounds() {
    if (this.paddle.y < 0) {
      this.paddle.y = 0;
    } else if (this.paddle.y + this.paddle.height > this.canvas.height) {
      this.paddle.y = this.canvas.height - this.paddle.height;
    }
  }
}

class Paddle {
  constructor(x, y, width, height, imageUrl) {
    this.x = x;
    this.y = y;
    this.resetX = x;
    this.resetY = y;
    this.width = width;
    this.height = height;
    this.image = new Image();
    this.image.onload = () => {
      console.log("loaded");
    }
    this.image.src = imageUrl;
  }

  draw(ctx) {
    ctx.drawImage(this.image, this.x, this.y, this.width, this.height);
  }

  reset() {
    this.x = this.resetX;
    this.y = this.resetY;
  }
}

class GamePauseTimer {
  constructor() {
    this.isPaused = false;
    this.timerFunction = null;
  }

  pause(time) {
    if (this.timerFunction) {
      clearTimeout(this.timerFunction);
    }
    this.isPaused = true;
    this.timerFunction = setTimeout(() => {
      this.isPaused = false;
    }, time);
  }
}

export default {
  name: 'App',
  mounted() {
    const canvas = this.$refs.canvas;
    this.setUpCanvas(canvas);
    this.createObjects(canvas);
    this.update();
  },
  unmounted() {
    window.removeEventListener('resize', this.onResize);
    cancelAnimationFrame(this.animationFrame);
  },
  methods: {
    update() {
      if (this.pauseTimer.isPaused) {
        this.animationFrame = requestAnimationFrame(this.update);
        return;
      }
      this.moveObjects();
      this.clearCanvas(this.ctx);
      this.draw();
    },
    createObjects(canvas) {
      let imageUrl = "https://cdn.discordapp.com/emojis/1015738796987404489.webp?size=96&quality=lossless";
      let ballImageUrl = "https://cdn.discordapp.com/emojis/1015738795041239080.webp?size=96&quality=lossless";
      this.leftPaddle = new Paddle(canvas.width / 8, canvas.height / 2, canvas.height / 30, canvas.height / 8, imageUrl);
      this.rightPaddle = new Paddle(canvas.width - (canvas.width / 8), canvas.height / 2, canvas.height / 30, canvas.height / 8, imageUrl);
      this.ball = new Ball(canvas.width / 2, canvas.height / 2, canvas.height / 40, ballImageUrl);
      this.scoringHandler = new ScoringHandler(canvas, this.ball, this.leftPaddle, this.rightPaddle, ()=>this.leftScore++, ()=>this.rightScore++);

      this.ballMoveBehavior = new BallMoveBehavior(this.ball, canvas, this.leftPaddle, this.rightPaddle, this.scoringHandler);
      this.leftPaddleMoveBehavior = new PaddleMoveBehavior(this.leftPaddle, this.ballMoveBehavior, canvas);
      this.rightPaddleMoveBehavior = new PaddleMoveBehavior(this.rightPaddle, this.ballMoveBehavior, canvas);
      this.pauseTimer = new GamePauseTimer();
    },
    setUpCanvas(canvas) {
      this.ctx = canvas.getContext('2d');
      this.ctx.canvas.width = window.innerWidth;
      this.ctx.canvas.height = window.innerHeight;
      this.ctx.imageSmoothingEnabled = false;
      this.ctx.fillStyle = 'red';

      window.addEventListener('resize', this.onResize);
    },
    onResize() {
      this.ctx.canvas.width = window.innerWidth;
      this.ctx.canvas.height = window.innerHeight;
      this.setObjectXPositions();
    },
    setObjectXPositions() {
      this.leftPaddle.x = this.ctx.canvas.width / 8;
      this.rightPaddle.x = this.ctx.canvas.width - (this.ctx.canvas.width / 8);
    },
    draw() {
      this.leftPaddle.draw(this.ctx);
      this.rightPaddle.draw(this.ctx);
      this.ball.draw(this.ctx);
      requestAnimationFrame(this.update);
    },
    movePaddles() {
      this.leftPaddleMoveBehavior.update();
      this.rightPaddleMoveBehavior.update();
    },
    moveObjects() {
      this.movePaddles();
      this.ballMoveBehavior.move();
    },
    clearCanvas(ctx) {
      ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    },
  },
  data() {
    return {
      leftScore: 0,
      rightScore: 0
    }
  }
}
</script>

<style>
body {
  margin: 0;
}
.game-canvas {
  width: 100%;
  height: 100%;
  image-rendering: pixelated;
  z-index: 10;
}
#app {
  overflow: hidden;
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
  height: 100vh;
}

.score {
  position: absolute;
  font-family: "Impact", Tahoma, Geneva, Verdana, sans-serif;
  color: white;
  -webkit-text-stroke: 3px black;
  text-shadow: 0 0 3px black;
  font-weight: bold;
  font-size: 4rem;
  z-index: 0;
}

.left {
  left: 30%;
}

.right {
  right: 30%;
}
</style>
