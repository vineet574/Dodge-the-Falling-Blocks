import pygame
import random
import time

# Initialize pygame
pygame.init()

# Constants
WIDTH, HEIGHT = 500, 600
PLAYER_WIDTH, PLAYER_HEIGHT = 50, 10
BLOCK_WIDTH, BLOCK_HEIGHT = 40, 40
PLAYER_SPEED = 7
BLOCK_SPEED_BASE = 5
POWER_UP_TIME = 5
GRAVITY = 1

# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
BLUE = (0, 0, 255)
CYAN = (0, 255, 255)
BACKGROUND_COLOR = (200, 200, 255)

# Sound and Music
jump_sound = pygame.mixer.Sound("jump.wav")
score_sound = pygame.mixer.Sound("score.wav")
power_up_sound = pygame.mixer.Sound("powerup.wav")
pygame.mixer.music.load("background.mp3")
pygame.mixer.music.play(-1)
music_muted = False

# Display
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Dodge the Falling Blocks")
clock = pygame.time.Clock()

# Game State
paused = False
try:
    with open("high_score.txt", "r") as file:
        highest_score = int(file.read())
except:
    highest_score = 0

class Player:
    def __init__(self):
        self.x = WIDTH // 2 - PLAYER_WIDTH // 2
        self.y = HEIGHT - 50
        self.width = PLAYER_WIDTH
        self.height = PLAYER_HEIGHT
        self.invincible = False
        self.invincibility_timer = 0
        self.is_jumping = False
        self.y_velocity = 0

    def move(self, keys):
        if keys[pygame.K_LEFT] and self.x > 0:
            self.x -= PLAYER_SPEED
        if keys[pygame.K_RIGHT] and self.x < WIDTH - self.width:
            self.x += PLAYER_SPEED
        if not self.is_jumping and keys[pygame.K_SPACE]:
            self.is_jumping = True
            self.y_velocity = -15
            jump_sound.play()
        if self.is_jumping:
            self.y += self.y_velocity
            self.y_velocity += GRAVITY
            if self.y >= HEIGHT - 50:
                self.y = HEIGHT - 50
                self.is_jumping = False
                self.y_velocity = 0

    def draw(self):
        color = RED if self.invincible else BLUE
        pygame.draw.rect(screen, color, (self.x, self.y, self.width, self.height))

class Block:
    def __init__(self):
        self.x = random.randint(0, WIDTH - BLOCK_WIDTH)
        self.y = -BLOCK_HEIGHT
        self.width = BLOCK_WIDTH
        self.height = BLOCK_HEIGHT
        self.speed = BLOCK_SPEED_BASE

    def fall(self, score, slow=False):
        speed = self.speed + (score // 10)
        if slow:
            speed = max(1, speed // 2)
        self.y += speed

    def draw(self):
        pygame.draw.rect(screen, RED, (self.x, self.y, self.width, self.height))

    def off_screen(self):
        return self.y > HEIGHT

    def check_collision(self, player):
        if player.invincible:
            return False
        return (player.x < self.x + self.width and
                player.x + player.width > self.x and
                player.y < self.y + self.height and
                player.y + player.height > self.y)

class PowerUp:
    def __init__(self):
        self.x = random.randint(50, WIDTH - 50)
        self.y = random.randint(50, HEIGHT - 200)
        self.active = True
        self.type = random.choice(['invincible', 'slow_blocks'])

    def draw(self):
        if self.active:
            color = YELLOW if self.type == 'invincible' else CYAN
            pygame.draw.circle(screen, color, (self.x, self.y), 15)

    def check_collision(self, player):
        if self.active and abs(player.x + player.width // 2 - self.x) < 25 and abs(player.y + player.height // 2 - self.y) < 25:
            self.active = False
            power_up_sound.play()
            if self.type == 'invincible':
                player.invincible = True
                player.invincibility_timer = POWER_UP_TIME
            elif self.type == 'slow_blocks':
                return 'slow'
        return None

def game_loop():
    global highest_score, music_muted, paused

    player = Player()
    blocks = []
    power_up = PowerUp()
    running = True
    score = 0
    font = pygame.font.Font(None, 36)
    slow_blocks_timer = 0

    while running:
        screen.fill(BACKGROUND_COLOR)

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_p:
                    paused = not paused
                elif event.key == pygame.K_m:
                    if music_muted:
                        pygame.mixer.music.unpause()
                        music_muted = False
                    else:
                        pygame.mixer.music.pause()
                        music_muted = True

        if paused:
            pause_text = font.render("Paused! Press P to resume.", True, BLACK)
            screen.blit(pause_text, (WIDTH // 2 - pause_text.get_width() // 2, HEIGHT // 2))
            pygame.display.update()
            continue

        keys = pygame.key.get_pressed()
        player.move(keys)
        player.draw()

        if random.randint(1, 50) == 1:
            blocks.append(Block())

        slow = slow_blocks_timer > 0
        if slow_blocks_timer > 0:
            slow_blocks_timer -= 1 / 30

        for block in blocks[:]:
            block.fall(score, slow)
            block.draw()
            if block.off_screen():
                blocks.remove(block)
                score += 1
                score_sound.play()
            elif block.check_collision(player):
                running = False

        power_up.draw()
        pu_effect = power_up.check_collision(player)
        if pu_effect == 'slow':
            slow_blocks_timer = POWER_UP_TIME

        if player.invincible:
            player.invincibility_timer -= 1 / 30
            if player.invincibility_timer <= 0:
                player.invincible = False

        score_text = font.render(f"Score: {score}", True, BLACK)
        screen.blit(score_text, (10, 10))

        mute_text = font.render(f"Press M to {'Unmute' if music_muted else 'Mute'} Music", True, BLACK)
        screen.blit(mute_text, (10, HEIGHT - 30))

        pygame.display.update()
        clock.tick(30)

    highest_score = max(highest_score, score)
    with open("high_score.txt", "w") as file:
        file.write(str(highest_score))
    game_over(score)

def game_over(score):
    font = pygame.font.Font(None, 48)
    while True:
        screen.fill(BACKGROUND_COLOR)
        game_over_text = font.render("Game Over", True, RED)
        score_text = font.render(f"Score: {score}", True, BLACK)
        high_score_text = font.render(f"High Score: {highest_score}", True, BLACK)
        restart_text = font.render("Press R to Restart or Q to Quit", True, BLACK)

        screen.blit(game_over_text, (WIDTH // 2 - 80, HEIGHT // 2 - 80))
        screen.blit(score_text, (WIDTH // 2 - 100, HEIGHT // 2 - 20))
        screen.blit(high_score_text, (WIDTH // 2 - 100, HEIGHT // 2 + 20))
        screen.blit(restart_text, (WIDTH // 2 - restart_text.get_width() // 2, HEIGHT // 2 + 60))

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                return
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r:
                    game_loop()
                    return
                elif event.key == pygame.K_q:
                    pygame.quit()
                    return

        pygame.display.update()

game_loop()
pygame.quit()
