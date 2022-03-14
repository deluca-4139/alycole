require "app/objects.rb"

# Generate a random map
def gen_map args
  map_temp = []

  map_genned = false
  while !map_genned
    # We need to make sure there are enough empty
    # tiles for items/player/exit to generate
    tiles_populated = false
    while !tiles_populated
      map_temp = [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]

      populate_tiles map_temp, 7, 6
      total_cells = 0
      map_temp.each do |row|
        row.each do |tile|
          if tile != 0
            total_cells += 1
          end
        end
      end
      if total_cells > 15
        tiles_populated = true
      end
    end
    populate_items map_temp, args
    populate_enemies map_temp
    create_player map_temp, args
    exit_check = create_exit map_temp, args
    # If exit was not successfully created,
    # force regeneration of map
    if exit_check
      map_genned = true
    end
  end
  map_temp
end

# Called from gen_map to create empty tiles in blank map
def populate_tiles map_temp, x, y
  tile_chance = 52 # Percentage chance that a tile will spawn
  map_temp[y][x] = 1
  if (x < map_temp[0].size)
    if (map_temp[y][x+1] == 0) && (rand(100) < tile_chance)
      populate_tiles map_temp, x+1, y
    end
  end
  if (x > 0)
    if (map_temp[y][x-1] == 0) && (rand(100) < tile_chance)
      populate_tiles map_temp, x-1, y
    end
  end
  if (y < map_temp.size-1)
    if (map_temp[y+1][x] == 0) && (rand(100) < tile_chance)
      populate_tiles map_temp, x, y+1
    end
  end
  if (y > 0)
    if (map_temp[y-1][x] == 0) && (rand(100) < tile_chance)
      populate_tiles map_temp, x, y-1
    end
  end
end

# Called from gen_map to create items in tile-populated map
def populate_items map_temp, args
  # Generate attack items
  attack_base = 3
  attack_max = 7
  has_attack_item = false
  args.state.player.inventory.each do |item|
    if item.type == 1
      has_attack_item = true
    end
  end
  attack_item_spawn = 0 # Chance attack item will spawn
  if has_attack_item
    attack_item_spawn = 40
  else
    attack_item_spawn = 100
  end
  if rand(100) < attack_item_spawn
    attack_item_genned = false
    while !attack_item_genned
      x_rand = rand(map_temp[0].size)
      y_rand = rand(map_temp.size)
      if map_temp[y_rand][x_rand] == 1
        map_temp[y_rand][x_rand] = Item.new(x_rand, y_rand, 1, false, (attack_base + rand(attack_max)))
        attack_item_genned = true
      end
    end
  end

  # Generate defense items
  defense_base = 10
  defense_max = 70
  has_defense_item = false
  args.state.player.inventory.each do |item|
    if item.type == 2
      has_defense_item = true
    end
  end
  defense_item_spawn = 0 # Chance defense item will spawn
  if has_defense_item
    defense_item_spawn = 40
  else
    defense_item_spawn = 100
  end
  if rand(100) < defense_item_spawn
    defense_item_genned = false
    while !defense_item_genned
      x_rand = rand(map_temp[0].size)
      y_rand = rand(map_temp.size)
      if map_temp[y_rand][x_rand] == 1
        map_temp[y_rand][x_rand] = Item.new(x_rand, y_rand, 2, false, (defense_base + rand(defense_max)))
        defense_item_genned = true
      end
    end
  end

  # Generate health potions
  health_diff = (((args.state.player.max_health - args.state.player.current_health) / args.state.player.max_health) * 100).round
  max_potions = 3
  potions_spawned = 0 # Includes potions that were skipped
  max_regen = args.state.player.max_health - 2
  while potions_spawned < max_potions
    a_random_number = rand(100) # Required, otherwise DR goes into an infinite loop on next if check
    if a_random_number < health_diff
      potion_genned = false
      while !potion_genned
        x_rand = rand(map_temp[0].size)
        y_rand = rand(map_temp.size)
        if map_temp[y_rand][x_rand] == 1
          map_temp[y_rand][x_rand] = Item.new(x_rand, y_rand, 0, true, (1 + rand(max_regen)))
          potion_genned = true
        end
      end
    end
    potions_spawned += 1
  end
end

# Called from gen_map to create enemies in item-populated map
def populate_enemies map_temp
  base_health = 4
  base_attack = 2
  max_health = 15
  max_attack = 10

  total_cells = 0
  map_temp.each do |row|
    row.each do |tile|
      if tile != 0
        total_cells += 1
      end
    end
  end

  tiles_per_enemy = 50 # Increase if you want more frequent enemies, decrease if less frequent
  num_enemies = (total_cells / tiles_per_enemy).floor
  while num_enemies > 0
    rand_x = rand(map_temp[0].size)
    rand_y = rand(map_temp.size)
    if map_temp[rand_y][rand_x] == 1
      map_temp[rand_y][rand_x] = Enemy.new(rand_x, rand_y, (base_health + rand(max_health)), (base_attack + rand(max_attack)))
      num_enemies -= 1
    end
  end
end

# Called from gen_map to create player in enemy-populated map
# Required to be here instead of in main.rb so that create_exit
# can properly determine distance from player to generated exit
def create_player map_temp, args
  player_created = false
  while !player_created
    rand_x = rand(map_temp[0].size)
    rand_y = rand(map_temp.size)
    if map_temp[rand_y][rand_x] == 1
      args.state.player.x_pos = rand_x
      args.state.player.y_pos = rand_y
      args.state.player.x = (args.state.START_X + 4) + (rand_x * args.state.TILE_SIZE)
      args.state.player.y = (args.state.START_Y + 4) - (rand_y * args.state.TILE_SIZE)
      player_created = true
    end
  end
end

# Called from gen_map to create exit on fully-populated map
def create_exit map_temp, args
  exit_genned = false
  counter = 0
  while !exit_genned
    if counter > 500
      return false
    else
      rand_x = rand(map_temp[0].size)
      rand_y = rand(map_temp.size)
      distance_from_player = (rand_x - args.state.player.x_pos).abs + (rand_y - args.state.player.y_pos).abs
      if distance_from_player > 7 && map_temp[rand_y][rand_x] == 1
        map_temp[rand_y][rand_x] = 2
        return true
      end
      counter += 1
    end
  end
end
