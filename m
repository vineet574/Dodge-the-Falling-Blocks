import pygame
import random
import time

pygame.init()

WIDTH, HEIGHT = 500, 600
PLAYER_WIDTH, PLAYER_HEIGHT = 50, 10
BLOCK_WIDTH, BLOCK_HEIGHT = 40, 40
PLAYER_SPEED = 7
BLOCK_SPEED = 5
POWER_UP_TIME = 5

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
BLUE = (0, 0, 255)
BACKGROUND_COLOR = (200, 200, 255)

jump_sound = pygame.mixer.Sound("jump.wav")
score_sound = pygame.mixer.Sound("score.wav")
power_up_sound = pygame.mixer.Sound("powerup.wav")

screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Dodge the Falling Blocks")
clock = pygame.time.Clock()
start_time = time.time()

paused = False
highest_score = 0

class Player:
    def __init__(self):
        self.x = WIDTH // 2 - PLAYER_WIDTH // 2
        self.y = HEIGHT - 50
        self.width = PLAYER_WIDTH
        self.height = PLAYER_HEIGHT
        self.invincible = False
        self.invincibility_timer = 0

    def move(self, keys):
        if keys[pygame.K_LEFT] and self.x > 0:
            self.x -= PLAYER_SPEED
        if keys[pygame.K_RIGHT] and self.x < WIDTH - self.width:
            self.x += PLAYER_SPEED

    def draw(self):
        pygame.draw.rect(screen, BLUE if not self.invincible else RED, (self.x, self.y, self.width, self.height))

class Block:
    def __init__(self):
        self.x = random.randint(0, WIDTH - BLOCK_WIDTH)
        self.y = -BLOCK_HEIGHT
        self.width = BLOCK_WIDTH
        self.height = BLOCK_HEIGHT

    def fall(self, score):
        self.y += BLOCK_SPEED + (score // 10)

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
        self.x = random.randint(100, WIDTH - 100)
        self.y = random.randint(100, HEIGHT - 100)
        self.active = True

    def draw(self):
        if self.active:
            pygame.draw.circle(screen, (255, 255, 0), (self.x, self.y), 15)

    def check_collision(self, player):
        if self.active and abs(player.x - self.x) < 20 and abs(player.y - self.y) < 20:
            self.active = False
            player.invincible = True
            player.invincibility_timer = POWER_UP_TIME
            power_up_sound.play()

def game_loop():
    global highest_score
    player = Player()
    blocks = []
    power_up = PowerUp()
    running = True
    score = 0
    font = pygame.font.Font(None, 36)

    while running:
        global paused
        screen.fill(BACKGROUND_COLOR)

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_p:
                    paused = not paused

        if paused:
            pause_text = font.render("Paused! Press P to resume.", True, BLACK)
            screen.blit(pause_text, (WIDTH // 2 - pause_text.get_width() // 2, HEIGHT // 2))
            pygame.display.update()
            continue

        player.move(pygame.key.get_pressed())
        player.draw()

        if random.randint(1, 50) == 1:
            blocks.append(Block())

        for block in blocks[:]:
            block.fall(score)
            block.draw()
            if block.off_screen():
                blocks.remove(block)
                score += 1
                score_sound.play()
            if block.check_collision(player):
                running = False

        power_up.draw(screen)
        power_up.check_collision(player)

        score_text = font.render(f"Score: {score}", True, BLACK)
        screen.blit(score_text, (10, 10))

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
        
        screen.blit(game_over_text, (WIDTH // 2 - 80, HEIGHT // 2 - 80))
        screen.blit(score_text, (WIDTH // 2 - 100, HEIGHT // 2 - 20))
        screen.blit(high_score_text, (WIDTH // 2 - 100, HEIGHT // 2 + 20))

        restart_text = font.render("Press R to Restart or Q to Quit", True, BLACK)
        screen.blit(restart_text, (WIDTH // 2 - restart_text.get_width() // 2, HEIGHT // 2 + 60))

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                return
            
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r:
                    game_loop()
                elif event.key == pygame.K_q:
                    pygame.quit()
                    return
        
        pygame.display.update()

game_loop()
pygame.quit()
