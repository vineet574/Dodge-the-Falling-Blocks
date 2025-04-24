import pygame
import random

# Initialize Pygame
pygame.init()

# Screen dimensions and constants
WIDTH, HEIGHT = 500, 600
PLAYER_WIDTH, PLAYER_HEIGHT = 50, 10
BLOCK_WIDTH, BLOCK_HEIGHT = 40, 40
PLAYER_SPEED = 7
BLOCK_SPEED = 5
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
BLUE = (0, 0, 255)

# Set up the screen
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Dodge the Falling Blocks")
clock = pygame.time.Clock()

# Player class
class Player:
    def __init__(self):
        self.x = WIDTH // 2 - PLAYER_WIDTH // 2
        self.y = HEIGHT - 50
        self.width = PLAYER_WIDTH
        self.height = PLAYER_HEIGHT

    def move(self, keys):
        if keys[pygame.K_LEFT] and self.x > 0:
            self.x -= PLAYER_SPEED
        if keys[pygame.K_RIGHT] and self.x < WIDTH - self.width:
            self.x += PLAYER_SPEED

    def draw(self):
        pygame.draw.rect(screen, BLUE, (self.x, self.y, self.width, self.height))

# Block class
class Block:
    def __init__(self):
        self.x = random.randint(0, WIDTH - BLOCK_WIDTH)
        self.y = -BLOCK_HEIGHT
        self.width = BLOCK_WIDTH
        self.height = BLOCK_HEIGHT

    def fall(self):
        self.y += BLOCK_SPEED

    def draw(self):
        pygame.draw.rect(screen, RED, (self.x, self.y, self.width, self.height))

    def off_screen(self):
        return self.y > HEIGHT

    def check_collision(self, player_x, player_y, player_width, player_height):
        return (player_x < self.x + self.width and
                player_x + player_width > self.x and
                player_y < self.y + self.height and
                player_y + player_height > self.y)

# Main game loop
def game_loop():
    player = Player()
    blocks = []
    score = 0
    font = pygame.font.Font(None, 36)
    running = True

    while running:
        screen.fill(WHITE)

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        # Player movement
        keys = pygame.key.get_pressed()
        player.move(keys)
        player.draw()

        # Add blocks
        if random.randint(1, 50) == 1:  # Random chance of adding a block
            blocks.append(Block())

        # Move and draw blocks
        for block in blocks[:]:
            block.fall()
            block.draw()
            if block.off_screen():
                blocks.remove(block)
                score += 1
            if block.check_collision(player.x, player.y, player.width, player.height):
                running = False  # Game over

        # Display score
        score_text = font.render(f"Score: {score}", True, BLACK)
        screen.blit(score_text, (10, 10))

        pygame.display.update()
        clock.tick(30)

    # Game over screen
    screen.fill(WHITE)
    game_over_text = font.render("Game Over!", True, BLACK)
    final_score_text = font.render(f"Final Score: {score}", True, BLACK)
    screen.blit(game_over_text, (WIDTH // 2 - 80, HEIGHT // 2 - 40))
    screen.blit(final_score_text, (WIDTH // 2 - 100, HEIGHT // 2))
    pygame.display.update()
    pygame.time.delay(3000)

# Run the game
game_loop()
pygame.quit()
